#!/bin/bash
# test-lib.sh — suite funzionale per night-shift/lib.sh (giro 1 dei 10, 2026-08-22).
# REGRESSION TEST veri: i sei bypass storici dell'allowlist (documentati nel SAL) devono
# restare bloccati per sempre — chi tocca la funzione senza volerlo li rivede cadere qui.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# mutation-testing 2026-08-28: un lib.sh neutralizzato (`exit 0`) faceva passare
# il test PER VUOTEZZA — il source eseguiva exit 0 DENTRO il test, che moriva
# verde. La funzione deve esistere nel sorgente PRIMA di caricarlo.
grep -q 'gate_allowlist_ok()' "$HERE/night-shift/lib.sh" \
  || { echo "FAIL lib.sh non definisce gate_allowlist_ok"; exit 1; }
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
# (revisione 10 giri, 2026-09-23): i tre casi composti sotto erano scritti SENZA virgolette —
# la shell del test interpretava `|` e `&&` prima di check(): l'allowlist vedeva solo il primo
# pezzo, `git diff --stat` e `tail -2 file` giravano DAVVERO nell'hub, e l'esito di «cat | wc»
# finiva dentro wc (conteggio perso nella subshell). Tre verdi che non provavano niente.
check "cat | wc"                    0 'cat /tmp/out | wc -l'
check "git diff readonly"           0 git diff HEAD~1
check "git log"                     0 git log --oneline -5
check "git status concatenato"      0 'git status && git diff --stat'
check "head/tail"                   0 'head -3 file && tail -2 file'
check "legittimo && vietato"        1 'git status && rm -rf x'
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

# bug reale, alta severità (set 2 giro 9, 2026-08-22): il test sopra (fuori da una command
# substitution) NON avrebbe mai visto il bug — un `sleep` orfano tiene aperta una pipe di
# $(...) finché non finisce DA SOLO, quindi run_guarded impiegava SEMPRE l'intera durata
# del watchdog quando chiamato dentro $(...), esattamente come lo chiama morning-gate.sh
# per OGNI comando .night-verify e per il banco avversariale. Verificato dal vivo: 10.0s
# esatti per un comando istantaneo con watchdog 10s, prima del fix.
T0=$(date +%s)
OUT_CS=$(run_guarded 8 bash -c "true" 2>&1)
RC_CS=$?
T1=$(date +%s)
DUR_CS=$((T1-T0))
[ $DUR_CS -le 3 ] && ok "run_guarded dentro command substitution: comando veloce torna subito (${DUR_CS}s, non 8s)" \
  || ko "run_guarded dentro \$(...): ${DUR_CS}s — il bug del sleep orfano è tornato"

# nessun processo sleep residuo dopo un giro rapido (l'orfano del bug vecchio restava vivo)
if command -v pgrep >/dev/null 2>&1; then
  sleep 1
  RESIDUI=$(pgrep -f "sleep 8$" 2>/dev/null | wc -l | tr -d ' ')
  [ "${RESIDUI:-0}" -eq 0 ] && ok "run_guarded: nessun processo sleep orfano residuo" \
    || ko "run_guarded: $RESIDUI processo/i sleep orfano/i ancora vivo/i"
else
  ok "run_guarded: pgrep assente, controllo residui saltato (non bloccante)"
fi

# --- repo_code: i codici anonimi sono RITIRATI (dominio, Luca 2026-09-23) ---
# (revisione 10 giri, 2026-09-23): questo blocco pretendeva ancora la mappatura da
# repos.key (REPO-X) — rosso sul codice giusto dal giorno del ritiro. Ora presidia la
# decisione: il nome esce invariato, anche se una repos.key residua lo mapperebbe.
KEYTMP=$(mktemp -d)
printf '# test\nREPO-X=finto/proprio\n' > "$KEYTMP/repos.key"
OUT=$( HERE="$KEYTMP" bash -c "source '$HERE/night-shift/lib.sh'; repo_code 'finto/proprio'; repo_code 'altra/qualunque'" 2>/dev/null )
[ "$(echo "$OUT" | head -1)" = "finto/proprio" ] && ok "repo_code: nome invariato anche con una repos.key residua (codici ritirati)" || ko "repo_code mappa ancora: $OUT"
[ "$(echo "$OUT" | tail -1)" = "altra/qualunque" ] && ok "repo_code: nome qualunque passa invariato" || ko "repo_code ignoto: $OUT"
rm -rf "$KEYTMP"

# --- mask_secrets: forme di segreto note devono uscire mascherate (giro 6/10, nuovo ciclo) ---
# (revisione 10 giri, 2026-09-23): il formato e' quello della regola vincolante di CLAUDE.md
# («Mask, don't omit») e del pattern segreto-come-impronta — «segreto <impronta> · N caratteri».
# Prima usciva ***MASCHERATO***: si vedeva che c'era un segreto, non quanto era lungo ne' se
# due righe portavano lo stesso.
IMPRONTA='«segreto [0-9a-f]{8} · [0-9]+ caratteri»'
M1=$(echo 'export GH_TOKEN=ghp_abcdef1234567890' | mask_secrets)
grep -qE "$IMPRONTA" <<<"$M1" && ! grep -q 'ghp_abcdef1234567890' <<<"$M1" \
  && ok "mask_secrets: token=valore mascherato con impronta" || ko "mask_secrets token=: $M1"
grep -q '· 20 caratteri»' <<<"$M1" && ok "mask_secrets: la lunghezza del valore e' dichiarata (20: ghp_ + 16)" || ko "mask_secrets lunghezza: $M1"

# bug reale trovato con dogfooding: "Authorization: Bearer <jwt>" passava intero,
# perché "Authorization" non è tra le parole chiave (secret|token|password|key)
M2=$(echo 'curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.super.secretpayload"' | mask_secrets)
grep -qE "$IMPRONTA" <<<"$M2" && ! grep -q 'secretpayload' <<<"$M2" \
  && ok "mask_secrets: Authorization Bearer mascherato (bug reale corretto)" || ko "mask_secrets bearer: $M2"
M2b=$(echo 'curl -H "Authorization: Token abcdefghijklmnop"' | mask_secrets)
[ "$(grep -o '«segreto' <<<"$M2b" | wc -l | tr -d ' ')" = "1" ] && ok "mask_secrets: schema Token mascherato UNA volta (la maschera non si rimaschera)" || ko "mask_secrets doppia maschera: $M2b"

# (revisione 10 giri): un token NUDO, senza parola chiave davanti, passava intero
M4=$(echo 'risposta: ghp_ABCDEFGHIJKLMNOPQRST1234 fine' | mask_secrets)
grep -qE "$IMPRONTA" <<<"$M4" && ! grep -q 'ghp_ABCDEFGHIJKLMNOPQRST1234' <<<"$M4" \
  && ok "mask_secrets: token nudo (ghp_...) mascherato" || ko "mask_secrets token nudo: $M4"
M5=$( (echo 'x token=AAAABBBBCCCC'; echo 'y token=AAAABBBBCCCC') | mask_secrets | grep -oE '[0-9a-f]{8} ·' | sort -u | wc -l | tr -d ' ')
[ "$M5" = "1" ] && ok "mask_secrets: stesso segreto → stessa impronta (confrontabile senza vederlo)" || ko "mask_secrets impronta instabile ($M5 impronte)"

M3=$(echo 'niente da mascherare qui' | mask_secrets)
[ "$M3" = "niente da mascherare qui" ] && ok "mask_secrets: testo senza segreti passa invariato" \
  || ko "mask_secrets falso positivo: $M3"

# --- candidata_censore: la PR portata al censore deve essere una che il censore accetta ---
# (revisione 10 giri, 2026-09-23): il turno prendeva la PRIMA bozza night/* (`head -1`), il
# censore accetta solo titoli `caccia:` (revisore.sh, guardia del titolo): con una PR di issue
# in testa, «non mio» a ogni ciclo e le caccia dietro di lei mai giudicate.
if declare -F candidata_censore >/dev/null; then
  J='[{"number":9,"headRefName":"night/issue-4","isDraft":true,"title":"fix: issue 4"},{"number":8,"headRefName":"night/caccia-x","isDraft":true,"title":"caccia: miglioria"},{"number":7,"headRefName":"claude/y","isDraft":true,"title":"caccia: altro"}]'
  C=$(candidata_censore <<<"$J")
  [ "$C" = "8" ] && ok "candidata_censore: salta la PR di issue in testa, sceglie la prima caccia: su night/*" || ko "candidata_censore sceglie '$C' (attesa 8)"
  C=$(candidata_censore <<<'[{"number":9,"headRefName":"night/issue-4","isDraft":true,"title":"fix"}]')
  [ -z "$C" ] && ok "candidata_censore: nessuna caccia: → vuoto (nessun giudizio sprecato)" || ko "candidata_censore: '$C' senza caccia"
else
  ko "candidata_censore non definita in lib.sh"
fi

# --- rami_da_scopare: la scopa del turno non tocca il lavoro vivo (revisione 10 giri) ---
# La scopa cancellava OGNI ramo senza PR (la soglia di 48h era solo nel commento) e ogni ramo
# con una PR fusa/chiusa anche se una PR APERTA riusa lo stesso nome (night/issue-N, o un ramo
# di sessione ripartito dopo il merge) — chiudendo la PR viva.
if declare -F rami_da_scopare >/dev/null; then
  ORA=1000000; H=3600
  RAMI=$(printf '%s\t%s\n' main 1 vecchio-fuso $((ORA-100*H)) riusato $((ORA-100*H)) orfano-vecchio $((ORA-49*H)) orfano-giovane $((ORA-1*H)) chiuso-giovane $((ORA-1*H)))
  PRS=$(printf '%s\t%s\n' vecchio-fuso MERGED riusato MERGED riusato OPEN chiuso-giovane CLOSED)
  OUT=$(rami_da_scopare "$ORA" 48 <(printf '%s\n' "$RAMI") <(printf '%s\n' "$PRS") | sort | tr '\n' ' ')
  [ "$OUT" = "chiuso-giovane orfano-vecchio vecchio-fuso " ] && ok "rami_da_scopare: fusi/chiusi e orfani oltre 48h si', PR aperta e orfano giovane no, main mai" \
    || ko "rami_da_scopare: '$OUT' (attesi: chiuso-giovane orfano-vecchio vecchio-fuso)"
else
  ko "rami_da_scopare non definita in lib.sh"
fi

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

# bug reale (revisione 14 lenti, 2026-08-28): ok() era chiamata incondizionatamente qui
# — nessun controllo di $? né verifica che non fosse stato creato un file spurio.
# Verificato dal vivo iniettando una regressione (errore su stderr, .1 spurio, exit 3)
# in rotate_log_if_big: la suite continuava a dire "OK", l'asserzione non provava nulla.
rotate_log_if_big "$LOGTMP/assente.log" 1; RC_ASSENTE=$?
[ "$RC_ASSENTE" -eq 0 ] && [ ! -e "$LOGTMP/assente.log" ] && [ ! -e "$LOGTMP/assente.log.1" ] \
  && ok "rotate_log_if_big: file assente, no-op senza errore (exit 0, nessun file creato)" \
  || ko "rotate_log_if_big: file assente non gestito pulito (rc=$RC_ASSENTE)"
rm -rf "$LOGTMP"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
