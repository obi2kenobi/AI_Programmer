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
# --- (revisione 10 giri, 2026-09-23): altre vie aperte, riprodotte prima della cura ---
# `&` singolo non separava (il secondo comando girava in background senza esame); git grep -O
# ESEGUE il programma che gli si passa; --output= fa SCRIVERE file a diff/log/show; le
# redirezioni > e >> scrivevano (il banco e' in sola lettura).
check "& in background"             1 "grep -q x README.md & python3 -c 'print(1)'"
check "& con rm"                    1 'grep x f & rm -rf ~/qualcosa'
check "git grep -O (pager)"         1 'git grep -Otouch -e foo'
check "git grep --open-files-in-pager" 1 'git grep --open-files-in-pager=vim x'
check "git diff --output"           1 'git diff --output=/tmp/x'
check "git log --output"            1 'git log --output=../x'
check "git diff --ext-diff"         1 'git diff --ext-diff HEAD~1'
# (2026-09-23, giro A6 della notte): due vie ancora aperte, riprodotte prima della cura — le
# opzioni corte RAGGRUPPATE (-iO) e le lunghe ABBREVIATE, che git accetta se non ambigue
check "git grep -iO raggruppata"    1 "git grep -iO'touch /tmp/PWN1' x"
check "git grep --open-files= (abbreviata)" 1 'git grep --open-files=touch x'
check "git grep --open= (abbreviata)" 1 'git grep --open=touch x'
check "git diff --out= (abbreviata)" 1 'git diff --out=/tmp/x'
check "git diff --ext (abbreviata)" 1 'git diff --ext HEAD~1'
# (2026-09-24, terzo ventaglio, V2 S24a): aggiungere `config` a GIT_RO restava verde qui — e `git config
# core.fsmonitor "touch …"` seguito da un `git status` ESEGUE il comando (provato dal giro). Anche le
# configurazioni passate da riga di comando (-c, --config-env) e il cambio di cartella (-C .) si rifiutano.
check "git config (scrive la config)" 1 'git config core.fsmonitor "touch x"'
check "git -c (config da riga di comando)" 1 'git -c core.fsmonitor=touch status'
check "git --config-env"            1 'git --config-env=core.pager=X status'
# (2026-09-24, quarto ventaglio, Q5 R1): tre vie ancora aperte, provate eseguendo dal giro — un A CAPO
# separa i comandi ma non i segmenti (la seconda riga girava senza esame, in agente.sh con eval); il `..`
# si scriveva senza scriverlo (apici, backslash, graffe: la shell lo ricompone); `jq env` leggeva
# l'ambiente senza un `$` (il caso T5#2 riaperto).
check "a capo: seconda riga python3"   1 $'echo ok\npython3 -c "print(42)"'
check "a capo: seconda riga touch"     1 $'grep x f.txt\ntouch scritto'
check "carattere di controllo (CR)"    1 $'grep x f.txt\rtouch scritto'
check "graffe che fanno ..: .{.,}/"    1 'cat .{.,}/fuori.txt'
check "apici che fanno ..: '.''.'/"   1 "cat '.''.'/fuori.txt"
check "backslash che fa ..: \\../"      1 'cat \../fuori.txt'
check "virgolette che fanno ..: \".\".\"/\"" 1 'cat "."."/fuori.txt"'
check "jq env (l'ambiente senza \$)"    1 'jq -n env.QUALCOSA'
check "jq '\$ENV' fra apici singoli"   1 "jq -n '\$ENV'"
check "jq -s length (legittimo)"       0 'jq -s length out.json'
check "grep di una regex con graffe (legittimo)" 0 'grep -cE "a{2}" f.txt'
check "git log --textc (abbreviata)" 1 'git log --textc -p'
check "git grep -i -e (legittimo)"  0 'git grep -i -e foo'
check "git log --oneline (legittimo)" 0 'git log --oneline -3'
check "git diff --stat (legittimo)" 0 'git diff --stat HEAD~1'
check "redirezione >"               1 'grep x f > out.txt'
check "redirezione >>"              1 'cat f >> g'
check "& e > fra virgolette sono dati" 0 "grep -q 'a & b > c' f"
check "2>/dev/null e 2>&1 ammessi"   0 'grep -c x f 2>/dev/null && git log --oneline -3 2>&1'
check ">/dev/null ammesso"           0 'grep -q x f >/dev/null'
check "> verso un file dopo /dev/null" 1 'grep x f 2>/dev/null > out.txt'
# (2026-09-23, notte dei giri, T5#2): l'allowlist guardava QUALE strumento gira, non COSA legge —
# 11 letture di segreti su 11 ammesse; agente.sh poi le scriveva in un file che `git add -A` spinge.
# Il confine e' il progetto: niente percorsi assoluti, niente ~, niente .. come cartella, niente $.
check "cat ~/.git-credentials"      1 'cat ~/.git-credentials'
check "cat ~/.netrc (fra virgolette)" 1 'cat "~/.netrc"'
check "cat /proc/self/environ"      1 'cat /proc/self/environ'
check "echo \$VARIABILE"            1 'echo $ZHIPUAI_API_KEY'
check "echo \${GH_TOKEN}"           1 'echo ${GH_TOKEN}'
check "grep -r in ~/.config"        1 'grep -r TOKEN ~/.config'
check "cat ../fuori"                1 'cat ../night-shift/repos.key'
check "cat dentro/../../fuori"      1 'cat src/../../x'
check "git -C /altrove"             1 'git -C /home/u/altro log'
check "grep --file=/assoluto"       1 'grep --file=/etc/passwd x'
check "git diff HEAD~1..HEAD (intervallo, legittimo)" 0 'git diff HEAD~1..HEAD'
check "grep in src/ (legittimo)"    0 'grep -rn foo src/'
check "\$ fra apici singoli e' un dato (legittimo)" 0 "grep -c 'fine\$' f"
# --- I LEGITTIMI: devono PASSARE (falsi positivi = banco zoppo) ---
check "grep semplice"               0 grep -q "AVVISO" file.js
# caso speciale: stringa GREZZA (le virgolette devono arrivare intere alla lib)
if gate_allowlist_ok 'grep -c "a;b" file.txt'; then ok "grep con ; nelle virgolette (falso positivo storico, stringa grezza)"; else ko "grep con ; nelle virgolette (stringa grezza)"; fi
# (revisione 10 giri, 2026-09-23): i tre casi composti sotto erano scritti SENZA virgolette —
# la shell del test interpretava `|` e `&&` prima di check(): l'allowlist vedeva solo il primo
# pezzo, `git diff --stat` e `tail -2 file` giravano DAVVERO nell'hub, e l'esito di «cat | wc»
# finiva dentro wc (conteggio perso nella subshell). Tre verdi che non provavano niente.
check "cat | wc"                    0 'cat out.txt | wc -l'   # (T5#2: /tmp e' fuori dal progetto, il caso prova la pipe)
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

# --- (revisione 10 giri, 2026-09-23): run_guarded uccideva solo il figlio diretto, col solo
# TERM, e restituiva l'rc del comando: un nipote che tiene aperta la pipe teneva il chiamante
# per l'intera durata, e un comando che ignora TERM tornava VERDE dopo la sua durata intera.
T0=$(date +%s); X=$(run_guarded 1 bash -c 'sleep 6; true' | cat); T1=$(date +%s)
[ $((T1-T0)) -le 3 ] && ok "run_guarded: il nipote nella pipe muore col gruppo ($((T1-T0))s, non 6)" || ko "run_guarded: il nipote ha tenuto la pipe $((T1-T0))s"
T0=$(date +%s); run_guarded 1 bash -c 'trap "" TERM; sleep 12; true'; RCG=$?; T1=$(date +%s)
[ "$RCG" -ne 0 ] && [ $((T1-T0)) -le 9 ] && ok "run_guarded: chi ignora TERM muore di KILL e l'esito e' ROSSO (rc=$RCG, $((T1-T0))s)" \
  || ko "run_guarded: TERM ignorato → rc=$RCG dopo $((T1-T0))s (verde falso o watchdog aggirato)"

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

# --- (2026-09-23, notte dei giri, T3#6): il turno scrive nel log con quale bash, quale ramo di timeout e
# quale sandbox gira — senza, le differenze Mac/Linux (T3#1, T3#2) non si misurano dal log del Mac
command -v ambiente_turno >/dev/null && AMB=$(ambiente_turno) || AMB=""
grep -cE "^ambiente: bash [0-9]+\.[0-9]+.* · timeout: .+ · sandbox: .+" <<<"$AMB" >/dev/null \
  && ok "ambiente_turno: bash, ramo di timeout e sandbox in una riga" || ko "ambiente_turno assente o incompleta: '$AMB'"
grep -c "timeout: perl" <<<"$(AI_TIMEOUT_FORCE_PERL=1 ambiente_turno 2>/dev/null)" >/dev/null \
  && ok "ambiente_turno: col ramo perl forzato dice perl" || ko "ambiente_turno non vede il ramo perl"
grep -c 'log "$(ambiente_turno)"' "$HERE/night-shift/night-shift.sh" >/dev/null \
  && ok "night-shift.sh scrive l'ambiente nel log" || ko "night-shift.sh non scrive l'ambiente nel log"

# --- (2026-09-24, terzo ventaglio, V4#1): esegui_verifica — lo sforo del budget non e' un rosso qualunque.
# Il turno scriveva «VERIFICA ROSSA» per ogni rc != 0 e buttava l'uscita: uno sforo (124) e un banco rotto
# erano lo stesso evento, e nessuno sapeva dove la suite si era fermata.
if command -v esegui_verifica >/dev/null; then
  VD=$(mktemp -d)
  E1=$(esegui_verifica "$VD" 5 'echo tutto bene' "$VD/v.log"); R1=$?
  E2=$(esegui_verifica "$VD" 5 'echo banco rotto >&2; exit 1' "$VD/r.log"); R2=$?
  E3=$(esegui_verifica "$VD" 1 'echo "▶ tests/test-lento.sh" >&2; sleep 5' "$VD/s.log"); R3=$?
  [ "$R1" -eq 0 ] && grep -cE '^VERDE in [0-9]+ s$' <<<"$E1" >/dev/null && ok "esegui_verifica: verde, con la durata («$E1»)" || ko "esegui_verifica verde: rc $R1 «$E1»"
  [ "$R2" -eq 1 ] && grep -c 'ROSSA (rc 1)' <<<"$E2" >/dev/null && grep -c 'banco rotto' <<<"$E2" >/dev/null && ok "esegui_verifica: rosso, con rc e ultima riga («$E2»)" || ko "esegui_verifica rosso: rc $R2 «$E2»"
  [ "$R3" -eq 124 ] && grep -c 'SFORO DEL BUDGET (1 s)' <<<"$E3" >/dev/null && grep -c 'test-lento' <<<"$E3" >/dev/null && ok "esegui_verifica: sforo distinto dal rosso, e dice dove («$E3»)" || ko "esegui_verifica sforo: rc $R3 «$E3»"
  [ -s "$VD/r.log" ] && ok "esegui_verifica: l'uscita resta in un file, non in /dev/null" || ko "esegui_verifica: uscita buttata"
  # (2026-09-24, quinto ventaglio, R4 R6): con la verifica verde nel log arrivava solo «VERDE in N s» — la
  # «⚠ SENTINELLA» della suite (budget oltre il 70%) restava nel file d'uscita, sovrascritto al ciclo dopo
  E4=$(esegui_verifica "$VD" 5 'echo "⚠ SENTINELLA: la suite ha usato il 81% del budget"; echo "Suite: 3/3"' "$VD/t.log")
  grep -c '^VERDE in [0-9]* s — ⚠ SENTINELLA: la suite ha usato il 81%' <<<"$E4" >/dev/null && ok "R4 R6: la sentinella della suite arriva nella riga VERDE («$E4»)" || ko "R4 R6: sentinella persa: «$E4»"
  rm -rf "$VD"
else
  ko "esegui_verifica assente da night-shift/lib.sh"
fi
grep -c 'esegui_verifica "\$DIR"' "$HERE/night-shift/night-shift.sh" >/dev/null && ok "night-shift.sh esegue .night-verify con esegui_verifica" || ko "night-shift.sh esegue .night-verify buttando l'uscita"

# --- (2026-09-24, terzo ventaglio, V1#1 e V1#5, V4#6): gate_banchi — il gate del fixer notturno lanciava
# ogni banco SENZA tetto (un banco che si annida ha fermato il turno per sempre, E-046) e lo lanciava sulla
# copia VIVA dell'hub, non sul ramo con i fix: il commit diceva «banco CHIUSO su questo branch» senza averlo
# mai provato. La funzione esegue i banchi di <dir>, ciascuno sotto tetto.
if command -v gate_banchi >/dev/null; then
  GB=$(mktemp -d); mkdir -p "$GB/tests"
  printf '#!/bin/bash\ntouch "$(dirname "$0")/../girato-qui"; echo "1 OK, 0 FAIL"\n' > "$GB/tests/test-verde.sh"
  printf '#!/bin/bash\necho "FAIL rotto davvero"; exit 1\n' > "$GB/tests/test-rosso.sh"
  printf '#!/bin/bash\nsleep 30\n' > "$GB/tests/test-appeso.sh"
  T0=$(date +%s); OUTG=$(gate_banchi "$GB" 2); DURG=$(( $(date +%s) - T0 ))
  [ -f "$GB/girato-qui" ] && ok "gate_banchi: esegue i banchi della copia che giudica (non quella viva)" || ko "gate_banchi: i banchi di <dir> non sono girati"
  grep -qx "TOTALE 1 2" <<<"$OUTG" && ok "gate_banchi: 1 verde, 2 rossi contati" || ko "gate_banchi: conteggio «$(tail -1 <<<"$OUTG")»"
  grep -c "rosso test-appeso.sh — SFORO" <<<"$OUTG" >/dev/null && [ "$DURG" -lt 25 ] && ok "gate_banchi: il banco appeso muore al tetto e si dice sforo (${DURG}s)" || ko "gate_banchi: banco appeso non fermato (${DURG}s): $OUTG"
  grep -c "rosso test-rosso.sh — FAIL rotto davvero" <<<"$OUTG" >/dev/null && ok "gate_banchi: il rosso dice la sua riga FAIL" || ko "gate_banchi: rosso senza motivo: $OUTG"
  rm -rf "$GB"
else
  ko "gate_banchi assente da night-shift/lib.sh"
fi
grep -c 'gate_banchi "\$DIR"' "$HERE/night-shift/night-shift.sh" >/dev/null && ok "il gate del fixer usa gate_banchi sulla copia del ramo" || ko "il gate del fixer lancia i banchi della copia viva, senza tetto"
# solo nel blocco del gate del fixer: l'auto-esame dell'hub (ciclo-vivo, banco veloce) giudica la copia viva
# PER DISEGNO — dopo l'allineamento e' main
VIVI=$(sed -n '/IL GATE DEL FIXER/,/&& GATE_OK=1/p' "$HERE/night-shift/night-shift.sh" | grep -E 'bash "\$HERE/\.\./tools/(banco-passaggio|giri-ignoranti)\.sh"' || true)
[ -z "$VIVI" ] && ok "il gate del fixer giudica col banco e le sonde del ramo, non della copia viva" || ko "banco/sonde del gate dalla copia viva: $VIVI"

# (2026-09-24, quinto ventaglio, R5 R5): lo stesso errore, nell'auto-fix «indice del SAL»: rigenerava il SAL della
# COPIA VIVA (dove lavora il giorno) e poi guardava il diff della copia del ramo, intatta — il fix non arrivava
# mai nel ramo e il SAL del giorno veniva toccato. Ora lo strumento e il SAL sono quelli del ramo.
grep -c 'bash "\$HERE/\.\./tools/sal-indice\.sh"' "$HERE/night-shift/night-shift.sh" >/dev/null && ko "R5 R5: l'auto-fix del SAL riscrive il SAL della copia viva" \
  || { grep -c 'bash "\$DIR/tools/sal-indice\.sh"' "$HERE/night-shift/night-shift.sh" >/dev/null && ok "R5 R5: l'auto-fix del SAL lavora sul SAL del ramo" || ko "R5 R5: l'auto-fix del SAL non c'e' piu'"; }

# --- (2026-09-24, terzo ventaglio, V1#3): «GIA' IMPLEMENTATA?» — la funzione «e' chiamata» se `nome(` compare
# nel file: vero gia' sulla riga che la DEFINISCE. Ogni issue che nomina foo() veniva saltata per sempre.
if command -v funzione_definita_e_chiamata >/dev/null; then
  FC=$(mktemp -d)
  printf 'function foo(a) {\n  return a;\n}\nfunction fooBar() {}\n' > "$FC/solo-def.gs"
  printf 'function foo(a) {\n  return a;\n}\nfunction usa() { return foo(1); }\n' > "$FC/chiamata.gs"
  printf 'function fooBar() {}\nvar x = fooBar();\n' > "$FC/altra.gs"
  funzione_definita_e_chiamata "$FC/solo-def.gs" foo && ko "funzione solo definita data per chiamata (la riga della definizione conta come chiamata)" || ok "funzione solo definita: non «chiamata»"
  funzione_definita_e_chiamata "$FC/chiamata.gs" foo && ok "funzione definita e chiamata altrove: si'" || ko "funzione definita e chiamata non riconosciuta"
  funzione_definita_e_chiamata "$FC/altra.gs" foo && ko "fooBar scambiata per foo" || ok "fooBar non e' foo"
  rm -rf "$FC"
else
  ko "funzione_definita_e_chiamata assente da night-shift/lib.sh"
fi
grep -c 'funzione_definita_e_chiamata "\$TF" "\$FN"' "$HERE/night-shift/night-shift.sh" >/dev/null && ok "il controllo GIA' IMPLEMENTATA usa la funzione" || ko "il controllo GIA' IMPLEMENTATA conta la definizione come chiamata"

# --- (2026-09-24, terzo ventaglio, V1#2): la caccia riapriva la STESSA PR a ogni ciclo — il sito torna libero su
# main finche' la PR non e' fusa, e il trasformatore lo risalda. caccia_gia_aperta: 0 se un ramo remoto di
# caccia porta gia' lo stesso diff (git patch-id) del commit appena fatto.
if command -v caccia_gia_aperta >/dev/null; then
  CG=$(mktemp -d); g() { git -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null -c commit.gpgsign=false "$@"; }
  g init -q --bare "$CG/o.git"; g clone -q "$CG/o.git" "$CG/w" 2>/dev/null
  echo base > "$CG/w/a.sh"; g -C "$CG/w" add -A; g -C "$CG/w" commit -qm base; g -C "$CG/w" push -q origin HEAD:main 2>/dev/null
  g -C "$CG/w" checkout -q -b night/caccia-1; echo "cura" >> "$CG/w/a.sh"; g -C "$CG/w" commit -qam c1; g -C "$CG/w" push -q origin night/caccia-1 2>/dev/null
  g -C "$CG/w" checkout -q main; g -C "$CG/w" checkout -q -b night/caccia-2; echo "cura" >> "$CG/w/a.sh"; g -C "$CG/w" commit -qam c2
  caccia_gia_aperta "$CG/w" origin/main "night/caccia-1" && ok "caccia_gia_aperta: lo stesso diff su una caccia aperta → gia' aperta" || ko "caccia_gia_aperta: il duplicato non si vede"
  g -C "$CG/w" commit -q --amend -m c2 --allow-empty; echo "altra" >> "$CG/w/a.sh"; g -C "$CG/w" commit -qam c3
  caccia_gia_aperta "$CG/w" origin/main "night/caccia-1" && ko "caccia_gia_aperta: un diff diverso scambiato per doppione" || ok "caccia_gia_aperta: un diff diverso non e' un doppione"
  rm -rf "$CG"
else
  ko "caccia_gia_aperta assente da night-shift/lib.sh"
fi
grep -c 'caccia_gia_aperta "\$DIR"' "$HERE/night-shift/night-shift.sh" >/dev/null && ok "la consegna della caccia salta i doppioni" || ko "la consegna della caccia non guarda le PR gia' aperte"

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
M4=$(echo 'risposta: gh''p_ABCDEFGHIJKLMNOPQRST1234 fine' | mask_secrets)
grep -qE "$IMPRONTA" <<<"$M4" && ! grep -q 'gh''p_ABCDEFGHIJKLMNOPQRST1234' <<<"$M4" \
  && ok "mask_secrets: token nudo (ghp_...) mascherato" || ko "mask_secrets token nudo: $M4"
M5=$( (echo 'x token=AAAABBBBCCCC'; echo 'y token=AAAABBBBCCCC') | mask_secrets | grep -oE '[0-9a-f]{8} ·' | sort -u | wc -l | tr -d ' ')
[ "$M5" = "1" ] && ok "mask_secrets: stesso segreto → stessa impronta (confrontabile senza vederlo)" || ko "mask_secrets impronta instabile ($M5 impronte)"

# (revisione 10 giri): i valori FRA VIRGOLETTE passavano interi — JSON e assegnazioni quotate
M6=$(echo '{"password": "hunter2hunter2", "api_key": "abcd1234efgh"}' | mask_secrets)
! grep -q 'hunter2hunter2\|abcd1234efgh' <<<"$M6" && [ "$(grep -o '«segreto' <<<"$M6" | wc -l | tr -d ' ')" = 2 ] \
  && ok "mask_secrets: chiavi JSON quotate mascherate (2 impronte)" || ko "mask_secrets JSON: $M6"
M7=$(echo 'export GH_TOKEN="valoresegreto123"' | mask_secrets)
! grep -q 'valoresegreto123' <<<"$M7" && grep -qE "$IMPRONTA" <<<"$M7" \
  && ok "mask_secrets: assegnazione quotata mascherata" || ko "mask_secrets quotata: $M7"

M3=$(echo 'niente da mascherare qui' | mask_secrets)
[ "$M3" = "niente da mascherare qui" ] && ok "mask_secrets: testo senza segreti passa invariato" \
  || ko "mask_secrets falso positivo: $M3"
# (2026-09-23, notte dei giri, T5#3): le credenziali di QUESTO parco passavano intere — Google OAuth
# (quelle di clasp, cioe' la produzione: access ya29., refresh 1//0, client GOCSPX-), l'URL con
# credenziali, la chiave Zhipu nuda, PASSWD=. I valori finti si compongono a runtime.
F20=ABCDEFGHIJKLMNOPQRST
for campione in "tok ya2""9.$F20" "REFRESH=1/""/0$F20" "cliente=GOCSP""X-$F20" \
                "remote=https:/""/luca:$F20""@github.com/x" "glm $(printf '%032d' 7 | tr 0 a).$F20" "PASSW""D=$F20"; do
  M=$(mask_secrets <<<"$campione")
  grep -cF "$F20" <<<"$M" >/dev/null && ko "mask_secrets: valore intero in «${campione:0:8}…»" || ok "mask_secrets: mascherato «${campione:0:12}…»"
done

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
  # (2026-09-24, terzo ventaglio, V1#2): gh elenca le PR piu' RECENTI prima — il censore prendeva la piu' nuova,
  # in quarantena, e le cacce vecchie non tornavano piu' davanti a lui. Si sceglie la piu' vecchia.
  J2='[{"number":12,"headRefName":"night/caccia-b","isDraft":true,"title":"caccia: nuova","createdAt":"2026-09-24T03:00:00Z"},{"number":11,"headRefName":"night/caccia-a","isDraft":true,"title":"caccia: vecchia","createdAt":"2026-09-24T01:00:00Z"}]'
  C=$(candidata_censore <<<"$J2")
  [ "$C" = "11" ] && ok "candidata_censore: fra due cacce, la piu' vecchia (la nuova e' in quarantena)" || ko "candidata_censore sceglie '$C' (attesa 11, la piu' vecchia)"
else
  ko "candidata_censore non definita in lib.sh"
fi

# --- verifica_issue_comando (2026-09-23, giro A5 della notte): la «## Verifica» di un'issue e' testo
#     ESTERNO (l'autore puo' modificarlo dopo la label) che il turno esegue. Prima la regex accettava
#     `npm install <pacchetto>`, `npm exec`, `python3 -m pip install`: codice arbitrario installato.
#     Ora si esegue solo un FILE del progetto (node|python3 <file.js|py> [argomenti]) o `npm test`.
if declare -F verifica_issue_comando >/dev/null; then
  VI=$(mktemp)
  vi() { printf '## Richiesta\nx\n## Verifica\n%s\n## Altro\n' "$1" > "$VI"; verifica_issue_comando "$VI"; }
  for C in "node tests/test-sconto.js" "python3 tools/oracolo.py dati.csv" "npm test"; do
    [ "$(vi "$C")" = "$C" ] && ok "verifica ammessa: $C" || ko "verifica legittima rifiutata: $C ('$(vi "$C")')"
  done
  for C in "npm install leftpad-evil" "npm exec cowsay" "npm i x" "python3 -m pip install x" "node -e 1" "node --eval 1" "python3 -c 1" "npm run deploy" "node x.js; rm -rf ~"; do
    [ -z "$(vi "$C")" ] && ok "verifica RIFIUTATA: $C" || ko "verifica pericolosa ammessa: $C"
  done
  rm -f "$VI"
else
  ko "verifica_issue_comando non definita in lib.sh"
fi

# --- prendi_lock_turno (Q10, 2026-09-23, giro A5 della notte): il lock globale del turno si
#     prendeva DOPO il self-pull (reset --hard dell'hub sotto un turno vivo) e il pkill degli
#     opencode (l'agente del turno vivo): un secondo turno — quello manuale accanto a quello
#     delle 23:00, patterns/lock-per-risorsa.md — faceva il danno e solo dopo usciva. E il lock
#     «scadeva» a 1h mentre un ciclo con l'issue lenta dura fino a 4h (watchdog): rubato a un
#     turno vivo. Ora conta il PID: vivo e del turno = occupato, a qualunque eta'; morto = orfano
#     (E-026) e si prende subito; lo stesso PID (il ciclo dopo l'exec) = suo.
if declare -F prendi_lock_turno >/dev/null; then
  LT=$(mktemp -d)
  lock_da_altro() { bash -c 'source "$1/night-shift/lib.sh"; prendi_lock_turno "$2"' _ "$HERE" "$1"; }
  lock_da_altro "$LT/l1"; RC=$?
  [ "$RC" -eq 0 ] && [ -s "$LT/l1/pid" ] && ok "lock turno: libero → preso, col PID dentro" || ko "lock turno: libero non preso (rc=$RC)"
  ( exec -a night-shift-finto sleep 30 ) & VIVO=$!
  mkdir "$LT/l2"; echo "$VIVO" > "$LT/l2/pid"; python3 -c 'import os,sys,time; t=time.time()-7200; os.utime(sys.argv[1],(t,t))' "$LT/l2"
  lock_da_altro "$LT/l2"; RC=$?
  [ "$RC" -eq 1 ] && [ "$(cat "$LT/l2/pid")" = "$VIVO" ] && ok "lock turno: tenuto da un turno VIVO da 2h → occupato (non si ruba per eta')" || ko "lock turno: rubato a un turno vivo (rc=$RC)"
  kill "$VIVO" 2>/dev/null; wait "$VIVO" 2>/dev/null
  lock_da_altro "$LT/l2"; RC=$?
  [ "$RC" -eq 0 ] && [ "$(cat "$LT/l2/pid")" != "$VIVO" ] && ok "lock turno: PID morto (orfano, E-026) → preso subito" || ko "lock turno: orfano di un turno morto non preso (rc=$RC)"
  sleep 30 & ALTRO=$!
  mkdir "$LT/l3"; echo "$ALTRO" > "$LT/l3/pid"
  lock_da_altro "$LT/l3"; RC=$?
  [ "$RC" -eq 0 ] && ok "lock turno: PID vivo ma NON del turno (PID riusato) → orfano, preso" || ko "lock turno: un PID riusato blocca il turno (rc=$RC)"
  kill "$ALTRO" 2>/dev/null; wait "$ALTRO" 2>/dev/null
  RC=$(bash -c 'source "$1/night-shift/lib.sh"; prendi_lock_turno "$2"; a=$?; prendi_lock_turno "$2"; echo "$a$?"' _ "$HERE" "$LT/l4")
  [ "$RC" = "00" ] && ok "lock turno: stesso PID (il ciclo dopo exec) → e' suo" || ko "lock turno: il turno non riconosce il proprio lock dopo l'exec ($RC)"
  mkdir "$LT/l5"; lock_da_altro "$LT/l5"; RC=$?
  [ "$RC" -eq 1 ] && ok "lock turno: senza PID (versione vecchia) e fresco → occupato" || ko "lock turno: lock senza PID fresco rubato (rc=$RC)"
  rm -rf "$LT"
  NSH="$HERE/night-shift/night-shift.sh"
  R_LOCK=$(grep -n 'prendi_lock_turno "' "$NSH" | head -1 | cut -d: -f1)
  R_RESET=$(grep -n 'reset -q --hard' "$NSH" | head -1 | cut -d: -f1)
  R_PKILL=$(grep -n 'pkill -f "opencode run"' "$NSH" | grep -v '^[0-9]*:[[:space:]]*#' | head -1 | cut -d: -f1)
  [ -n "$R_LOCK" ] && [ "$R_LOCK" -lt "${R_RESET:-0}" ] && [ "$R_LOCK" -lt "${R_PKILL:-0}" ]     && ok "night-shift.sh: il lock del turno si prende PRIMA del self-pull e del pkill"     || ko "night-shift.sh: lock (riga ${R_LOCK:-assente}) dopo reset (${R_RESET:-?}) o pkill (${R_PKILL:-?})"
else
  ko "prendi_lock_turno non definita in lib.sh"
fi

# --- commenta_una_volta (Q11, 2026-09-23, giro A5 della notte): il cancello Design/Territorio
#     commentava l'issue a OGNI ciclo — e il turno riparte subito, a ciclo continuo: centinaia di
#     commenti identici in una notte sulla stessa issue. Ora il commento porta un marcatore
#     invisibile e non si ripete; se i commenti non si leggono (gh giu'), non si commenta.
if declare -F commenta_una_volta >/dev/null; then
  CU=$(mktemp -d)
  cat > "$CU/gh" <<'EOF'
#!/bin/bash
D=$(dirname "$0")
[ -f "$D/rotto" ] && exit 1
case "$1 $2" in
  "issue view")    cat "$D/commenti" 2>/dev/null; exit 0 ;;
  "issue comment") shift 2; while [ $# -gt 0 ]; do [ "$1" = "--body" ] && { printf '%s\n---\n' "$2" >> "$D/commenti"; }; shift; done; exit 0 ;;
esac
EOF
  chmod +x "$CU/gh"
  PATH="$CU:$PATH" commenta_una_volta 7 o/r territorio-assente "🌙 Saltata: manca Territorio"
  PATH="$CU:$PATH" commenta_una_volta 7 o/r territorio-assente "🌙 Saltata: manca Territorio"
  N=$(grep -c 'Saltata: manca Territorio' "$CU/commenti" 2>/dev/null)
  [ "$N" = "1" ] && ok "commenta_una_volta: due cicli, UN commento" || ko "commenta_una_volta: $N commenti per due cicli"
  PATH="$CU:$PATH" commenta_una_volta 7 o/r design-povero "🌙 Saltata: Design povero"
  grep -q 'Design povero' "$CU/commenti" && ok "commenta_una_volta: un motivo NUOVO si commenta" || ko "commenta_una_volta: il motivo nuovo non e' stato commentato"
  : > "$CU/commenti"; touch "$CU/rotto"
  PATH="$CU:$PATH" commenta_una_volta 7 o/r territorio-assente "🌙 Saltata: manca Territorio"; RC=$?
  [ "$RC" -ne 0 ] && [ ! -s "$CU/commenti" ] && ok "commenta_una_volta: commenti illeggibili → non commenta, e lo dice (rc=$RC)" || ko "commenta_una_volta: con gh giu' ha commentato o taciuto (rc=$RC)"
  rm -rf "$CU"
  NSH="$HERE/night-shift/night-shift.sh"
  REGIONE=$(sed -n '/MOTIVO=$(cancello_design "$BODY")/,/Idempotenza: PR aperta/p' "$NSH")
  NUDI=$(grep -c 'gh issue comment' <<<"$REGIONE")
  [ -n "$REGIONE" ] && [ "$NUDI" = "0" ] && grep -q 'commenta_una_volta' <<<"$REGIONE" && ok "night-shift.sh: il cancello Design/Territorio commenta solo con commenta_una_volta" || ko "night-shift.sh: $NUDI commenti nudi nel cancello Design/Territorio"
else
  ko "commenta_una_volta non definita in lib.sh"
fi

# --- candidata_parere (D10, Luca 2026-09-23: «b»): la PR di ISSUE che il censore giudica col solo
#     parere — bozza su night/issue-*, e mai due volte lo stesso commit (il parere dato si ricorda)
if declare -F candidata_parere >/dev/null; then
  SP=$(mktemp -d)
  J='[{"number":8,"headRefName":"night/caccia-x","isDraft":true,"title":"caccia: m","headRefOid":"aaa"},{"number":9,"headRefName":"night/issue-4","isDraft":true,"title":"fix","headRefOid":"bbb"},{"number":10,"headRefName":"night/issue-5","isDraft":true,"title":"fix","headRefOid":"ccc"}]'
  C=$(candidata_parere "$SP" <<<"$J")
  [ "$C" = "9" ] && ok "candidata_parere: la prima PR di issue (la caccia resta al censore che fonde)" || ko "candidata_parere sceglie '$C' (attesa 9)"
  touch "$SP/parere-9-bbb"
  C=$(candidata_parere "$SP" <<<"$J")
  [ "$C" = "10" ] && ok "candidata_parere: salta la PR col parere gia' dato su quel commit" || ko "candidata_parere: '$C' (attesa 10: la 9 ha gia' il parere)"
  touch "$SP/parere-10-ccc"
  C=$(candidata_parere "$SP" <<<"$J")
  [ -z "$C" ] && ok "candidata_parere: tutte giudicate → vuoto" || ko "candidata_parere: '$C' con tutti i pareri dati"
  rm -rf "$SP"
else
  ko "candidata_parere non definita in lib.sh"
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
# (2026-09-24, quinto ventaglio, R5 R2): la scopa delle 48h cancellava sul remoto dell'hub anche i rami del
# GIORNO (claude/*, glm/*) senza PR — per esempio il ramo di una sessione web gia' chiusa, di cui non resta
# copia. Scelta provvisoria dichiarata (la domanda e' in DEBITI): la scopa tocca solo i rami del turno.
NSH_SC="$HERE/night-shift/night-shift.sh"
RIGA_48=$(grep -n 'rami_da_scopare "$(date +%s)" 48' "$NSH_SC" | head -1)
grep -cE "grep -E '\^\(night\|notte\)/'" <<<"$RIGA_48" >/dev/null && ok "scopa 48h: solo rami del turno (night/, notte/), mai claude/ o glm/" || ko "scopa 48h senza filtro di prefisso: $RIGA_48"
grep -c 'gh pr list -R obi2kenobi/AI_Programmer --state all --limit 1000' "$NSH_SC" >/dev/null && ok "scopa: la lista delle PR arriva a 1000 (con 200 una PR aperta vecchia usciva dalla lista)" || ko "scopa: PR lette solo fino a 200"

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
