#!/bin/bash
# test-ai-timeout.sh — 6° ciclo, giro 0 (baseline), 2026-08-24. macOS non porta GNU
# coreutils: `timeout` non esiste sulla shell stock e tre wrapper + due test morivano
# con "command not found" prima ancora di raggiungere il cervello. llm/_timeout.sh
# introduce ai_timeout (GNU timeout → gtimeout → fallback perl). Il ramo perl viene
# esercitato FORZANDOLO (AI_TIMEOUT_FORCE_PERL=1) sul codice spedito, non su una copia
# nel test: sul Mac dell'autore `timeout` esiste e il fallback resterebbe mai provato.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/llm/_timeout.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# 1. il ramo perl FORZATO uccide il gruppo a tempo: il nipote (sleep dentro bash -c)
#    NON deve sopravvivere tenendo aperta la pipe della command substitution
#    (regressione "sleep orfano", già pagata da run_guarded in tests/test-lib.sh)
# (2026-09-24, terzo ventaglio, V4#3): i casi che aspettano un timeout vero (1, 6, 7) sono indipendenti:
# in fila costavano 19 s, ora girano insieme e i verdetti si contano alla fine (MK: gli esiti, uno per caso)
MK=$(mktemp -d); trap 'rm -rf "$MK"' EXIT
caso1() {
T0=$(date +%s)
OUT=$(AI_TIMEOUT_FORCE_PERL=1 ai_timeout 3 bash -c 'echo partito; sleep 100' 2>&1); RC=$?
T1=$(date +%s); DUR=$((T1-T0))
[ "$RC" -eq 124 ] && [ "$DUR" -le 8 ] \
  && ok "timeout di gruppo (ramo perl): ucciso in ${DUR}s con rc=124, nipote compreso" \
  || ko "timeout perl: rc=$RC durata=${DUR}s — il gruppo non viene ucciso"
}
( caso1 ) > "$MK/esito1" 2>&1 &

# 2. exit code del comando preservato (7, non 0 e non 124)
AI_TIMEOUT_FORCE_PERL=1 ai_timeout 10 bash -c 'exit 7'; RC2=$?
[ "$RC2" -eq 7 ] && ok "exit code del comando preservato (rc=7)" || ko "exit code perso: rc=$RC2"

# 3. stdout passa intatto
OUT3=$(AI_TIMEOUT_FORCE_PERL=1 ai_timeout 10 echo "contenuto")
[ "$OUT3" = "contenuto" ] && ok "stdout passa intatto" || ko "stdout perso: '$OUT3'"

# 4. senza forzatura, un comando sano passa (ramo timeout/gtimeout/perl qualunque)
ai_timeout 10 true && ok "ai_timeout: comando sano passa" || ko "ai_timeout rompe un comando sano"

# 5. il fallback perl è presente nel file spedito e la stringa non è rotta da
#    apostrofi nei commenti (un apostrofo italiano l'ha chiusa — errore pagato il
#    2026-08-24: zsh eseguiva "alarm" come comando). La chiamata al punto 1-3 già
#    dimostra che la stringa sana; qui si verifica che il file dichiari la funzione
grep -q "^ai_timeout()" "$HERE/llm/_timeout.sh" \
  && ok "ai_timeout dichiarata in llm/_timeout.sh" \
  || ko "ai_timeout non trovata in llm/_timeout.sh"

# 6. bug reale (revisione 14 lenti, 2026-08-28): tutti i casi sopra forzano il ramo perl
# (AI_TIMEOUT_FORCE_PERL=1) — il ramo PRIMARIO (GNU timeout/gtimeout, il caso normale su
# coreutils presenti) non era mai esercitato su un comando che ignora SIGTERM. Senza "-k",
# GNU timeout manda TERM e poi ASPETTA che il comando termini da solo — un comando con
# trap '' TERM non veniva mai forzato a chiudere. Questo caso NON forza il ramo perl.
caso6() {
if command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1; then
  T2=$(date +%s)
  ai_timeout 2 bash -c 'trap "" TERM; sleep 20'
  RC6=$?
  T3=$(date +%s); DUR6=$((T3-T2))
  [ "$DUR6" -le 10 ] \
    && ok "ramo primario (GNU timeout): comando che ignora TERM ucciso entro ${DUR6}s, non atteso per 20s (rc=$RC6)" \
    || ko "ramo primario: comando che ignora TERM NON forzato — durata=${DUR6}s (atteso <=10s)"
else
  echo "SKIP: né timeout né gtimeout disponibili in questo ambiente, ramo primario non esercitabile"
fi
}
( caso6 ) > "$MK/esito6" 2>&1 &

# 7. (2026-09-23, notte dei giri, T3#1): i due rami davano garanzie DIVERSE. GNU manda TERM al gruppo e
# KILL dopo 5s; il perl (il Mac senza coreutils) mandava KILL subito — i trap EXIT dei comandi
# interrotti non giravano mai sul Mac (un lock lasciato sporco). Stesso comando, due rami.
caso7a() {
AI_TIMEOUT_FORCE_PERL=1 ai_timeout 2 bash -c "trap 'touch $MK/perl' EXIT; sleep 30" >/dev/null 2>&1; RC7=$?
[ -f "$MK/perl" ] && ok "ramo perl: TERM prima del KILL, il trap EXIT del comando gira (rc=$RC7)" \
  || ko "ramo perl: KILL diretto, il trap EXIT del comando NON gira (rc=$RC7)"
[ "$RC7" -eq 124 ] && ok "ramo perl: allo scadere rc 124 come GNU" || ko "ramo perl: rc $RC7 (atteso 124)"
}
caso7c() {
T4=$(date +%s); AI_TIMEOUT_FORCE_PERL=1 ai_timeout 2 bash -c 'trap "" TERM; sleep 20' >/dev/null 2>&1; DUR7=$(( $(date +%s) - T4 ))
[ "$DUR7" -le 10 ] && ok "ramo perl: chi ignora TERM muore di KILL entro ${DUR7}s" || ko "ramo perl: chi ignora TERM vive ${DUR7}s"
}
( caso7a ) > "$MK/esito7a" 2>&1 &
( caso7c ) > "$MK/esito7c" 2>&1 &
wait
for e in 1 6 7a 7c; do cat "$MK/esito$e"; done
PASS=$((PASS + $(cat "$MK"/esito* | grep -c '^OK')))
FAIL=$((FAIL + $(cat "$MK"/esito* | grep -c '^FAIL')))

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
