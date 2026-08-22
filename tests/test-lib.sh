#!/bin/bash
# test-lib.sh — suite funzionale per night-shift/lib.sh (giro 1 dei 10, 2026-08-22).
# REGRESSION TEST veri: i sei bypass storici dell'allowlist (documentati nel SAL) devono
# restare bloccati per sempre — chi tocca la funzione senza volerlo li rivede cadere qui.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/night-shift/lib.sh"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "OK   $1"; }
ko()   { FAIL=$((FAIL+1)); echo "FAIL $1"; }
check() { # check <descrizione> <atteso:0|1> <cmd...>
  local desc="$1" atteso="$2"; shift 2
  if gate_allowlist_ok "$*"; then locale_r=0; else locale_r=1; fi
  [ "$locale_r" -eq "$atteso" ] && ok "$desc" || ko "$desc (atteso $([ $atteso -eq 0 ] && echo passa || echo blocca), reale $([ $locale_r -eq 0 ] && echo passa || echo blocca)): $*"
}

# --- I SEI BYPASS STORICI: devono restare BLOCCATI (dev-critic 2026-08-21) ---
check "bypass1: bash -c"            1 bash -c "cat ~/.ssh/id_rsa"
check "bypass2: python3 -c"         1 python3 -c "import os"
check "bypass3: awk system()"       1 awk 'BEGIN{system("id")}'
check "bypass4: sed /e"             1 sed "s/x/e/g" f
check "bypass5: node -e"            1 node -e "1"
check "bypass6: npm run"            1 npm run evil
# --- le vie nuove che la sicurezza ha chiuso dopo (opzione c) ---
check "find -delete"                1 find . -delete
check "git reset --hard"            1 git reset --hard origin/main
check "git push"                    1 git push origin main
check "rm"                          1 rm -rf /
check "sudo"                        1 sudo id
check "curl"                        1 curl http://evil.example
# --- I LEGITTIMI: devono PASSARE (falsi positivi = banco zoppo) ---
check "grep semplice"               0 grep -q "AVVISO" file.js
# caso speciale: stringa GREZZA (le virgolette devono arrivare intere alla lib)
if gate_allowlist_ok 'grep -c "a;b" file.txt'; then ok "grep con ; nelle virgolette (falso positivo storico, stringa grezza)"; else ko "grep con ; nelle virgolette (stringa grezza)"; fi
check "cat | wc"                    0 cat /tmp/out | wc -l
check "git diff readonly"           0 git diff HEAD~1
check "git log"                     0 git log --oneline -5
check "git status concatenato"      0 git status && git diff --stat
check "head/tail"                   0 head -3 file && tail -2 file
check "diff"                        0 diff a.txt b.txt
check "jq"                          0 jq -s length out.json
check "wc standalone"               0 wc -l accessi.log

# --- run_guarded: il watchdog uccide davvero un comando che dorme ---
T0=$(date +%s)
run_guarded 2 sleep 30
RC=$?
T1=$(date +%s)
DUR=$((T1-T0))
[ $DUR -le 4 ] && ok "run_guarded: sleep 30 ucciso entro ~2s (durato $DUR s)" || ko "run_guarded: durato $DUR s — il watchdog non morde"
run_guarded 5 true && ok "run_guarded: comando veloce passa pulito" || ko "run_guarded: fallisce su comando sano"

# --- repo_code: anonimizzazione con chiave (repo fittizia in tmp) ---
KEYTMP=$(mktemp -d)
printf '# test\nREPO-X=finto/proprio\n' > "$KEYTMP/repos.key"
# repo_code legge $HERE/repos.key: patch temporanea del HERE... la funzione usa $HERE globale
ORIG_HERE="$HERE"
( HERE="$KEYTMP"
  source "$ORIG_HERE/night-shift/lib.sh" 2>/dev/null || true
  R1=$(repo_code "finto/proprio"); R2=$(repo_code "altra/qualunque")
  [ "$R1" = "REPO-X" ] && echo "OK   repo_code: nome privato → codice" || echo "FAIL repo_code: $R1"
  [ "$R2" = "altra/qualunque" ] && echo "OK   repo_code: nome ignoto passa tale" || echo "FAIL repo_code ignoto: $R2"
) >> /dev/null 2>&1 # nota: le echo sopra finiscono nella subshell — rifacciamo fuori
OUT=$( HERE="$KEYTMP" bash -c "source '$ORIG_HERE/night-shift/lib.sh'; repo_code 'finto/proprio'; repo_code 'altra/qualunque'" 2>/dev/null )
echo "$OUT" | head -1 | grep -q "REPO-X" && ok "repo_code: nome in chiave → codice anonimo" || ko "repo_code chiave: $OUT"
echo "$OUT" | tail -1 | grep -q "altra/qualunque" && ok "repo_code: nome fuori chiave passa invariato" || ko "repo_code ignoto"
rm -rf "$KEYTMP"

# --- mask_secrets: forme di segreto note devono uscire mascherate (giro 6/10, nuovo ciclo) ---
M1=$(echo 'export GH_TOKEN=ghp_abcdef1234567890' | mask_secrets)
grep -q '\*\*\*MASCHERATO\*\*\*' <<<"$M1" && ! grep -q 'ghp_abcdef1234567890' <<<"$M1" \
  && ok "mask_secrets: token=valore mascherato" || ko "mask_secrets token=: $M1"

# bug reale trovato con dogfooding: "Authorization: Bearer <jwt>" passava intero,
# perché "Authorization" non è tra le parole chiave (secret|token|password|key)
M2=$(echo 'curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.super.secretpayload"' | mask_secrets)
grep -q '\*\*\*MASCHERATO\*\*\*' <<<"$M2" && ! grep -q 'secretpayload' <<<"$M2" \
  && ok "mask_secrets: Authorization Bearer mascherato (bug reale corretto)" || ko "mask_secrets bearer: $M2"

M3=$(echo 'niente da mascherare qui' | mask_secrets)
[ "$M3" = "niente da mascherare qui" ] && ok "mask_secrets: testo senza segreti passa invariato" \
  || ko "mask_secrets falso positivo: $M3"

# --- rotate_log_if_big: debito saldato (giro 10/10, nuovo ciclo) ---
LOGTMP=$(mktemp -d)
echo "riga piccola" > "$LOGTMP/small.log"
rotate_log_if_big "$LOGTMP/small.log" 10
[ ! -f "$LOGTMP/small.log.1" ] && ok "rotate_log_if_big: file sotto soglia non ruota" \
  || ko "rotate_log_if_big: ha ruotato un file piccolo"

head -c 2000000 /dev/zero > "$LOGTMP/big.log"; echo "marker-fine" >> "$LOGTMP/big.log"
rotate_log_if_big "$LOGTMP/big.log" 1
[ -f "$LOGTMP/big.log.1" ] && grep -q "marker-fine" "$LOGTMP/big.log.1" \
  && ok "rotate_log_if_big: file oltre soglia ruotato, contenuto preservato in .1" \
  || ko "rotate_log_if_big: rotazione mancata o contenuto perso"
[ -f "$LOGTMP/big.log" ] && [ ! -s "$LOGTMP/big.log" ] && ok "rotate_log_if_big: nuovo log vuoto pronto" \
  || ko "rotate_log_if_big: il nuovo log non è vuoto"

rotate_log_if_big "$LOGTMP/assente.log" 1
ok "rotate_log_if_big: file assente, no-op senza errore"
rm -rf "$LOGTMP"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
