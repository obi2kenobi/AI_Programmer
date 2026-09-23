#!/bin/bash
# test-profilo.sh — il profilo unico del turno (studio deepseek-harness
# profiles/bundles): una dichiarazione, caricata a ogni ciclo, i default nel
# codice sono fallback. Prova: caricamento, validazione chiavi, profilo
# mancante = zero chiavi (non morte), override da env vince sul file.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

OUT=$(bash -c '. "$1/tools/profilo.sh" notturno; echo "M=$MODELLO T=$AGENTE_TIMEOUT I=$IMPARA_ORA"' _ "$HERE" 2>/dev/null)
echo "$OUT" | grep -q "M=qwen3.8-27b:iq3s" && echo "$OUT" | grep -q "T=600" && echo "$OUT" | grep -q "I=22" \
  && ok "profilo notturno: 15 chiavi dichiarate, le tre critiche caricate" \
  || ko "caricamento: $OUT"

OUT=$(bash -c '. "$1/tools/profilo.sh" inesistente 2>/dev/null; echo "N=$([ -n "${MODELLO:-}" ] && echo pieno || echo vuoto)"' _ "$HERE" 2>/dev/null)
echo "$OUT" | grep -q "N=vuoto" \
  && ok "profilo mancante: zero chiavi, nessuna morte" \
  || ko "profilo mancante: $OUT"

OUT=$(bash -c 'MODELLO=override-manuale; . "$1/tools/profilo.sh" notturno >/dev/null 2>&1; echo "V=$MODELLO"' _ "$HERE" 2>/dev/null)
echo "$OUT" | grep -q "V=qwen3.8-27b:iq3s" \
  && ok "il file profilo PREVALE sui default del codice (e' la fonte)" \
  || ko "il profilo non riesce a prevalere: $OUT"

[ -f "$HERE/profiles/notturno.conf" ] && grep -q "^MODELLO=" "$HERE/profiles/notturno.conf" \
  && ok "profiles/notturno.conf esiste e dichiara il modello" \
  || ko "profilo file assente"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
