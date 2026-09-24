#!/bin/bash
# test-patterns-ancore-esistono.sh — 5° ciclo, set 3 giro 5. patterns/README.md dichiara
# la regola "l'ancora deve esistere, o la voce non sopravvive" (ereditata da REPO-A) ma
# nessun test la verificava mai meccanicamente per questo hub — un'ancora hub-locale
# (non un repo esterno/REPO-X, non un onboardato) che punta a un file mai esistito o
# rimosso sarebbe passata inosservata. Verifica solo le ancore hub-locali: quelle
# esterne (REPO-[A-Z], "progetto onboardato", nomi di repo esterni pre-esistenti) non
# sono verificabili da qui e non è compito di questo hub controllarle.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

shopt -s nullglob
CHECKED=0
for f in "$HERE"/patterns/*.md; do
  [ "$(basename "$f")" = "README.md" ] && continue
  nome="$(basename "$f" .md)"
  ANCORA=$(sed -n '2p' "$f" | grep -oE '^\*\*Àncora\*\*: [^·]+' | sed 's/^\*\*Àncora\*\*: //')
  [ -z "$ANCORA" ] && { ko "$nome: riga Àncora non trovata o malformata"; continue; }

  case "$ANCORA" in
    REPO-*|"progetto onboardato"*|Bilancio_periodico*|"standard di"*|"regola di"*)
      continue ;;  # ancora esterna o di processo (prosa), non un percorso di questo hub
  esac

  REF=$(printf '%s' "$ANCORA" | grep -oE '[A-Za-z0-9_./-]+\.[a-z]{2,4}' | head -1)
  [ -z "$REF" ] && { ko "$nome: ancora hub-locale senza un percorso riconoscibile: $ANCORA"; continue; }
  CHECKED=$((CHECKED+1))
  [ -e "$HERE/$REF" ] && ok "$nome: l'ancora ($REF) esiste davvero" \
    || { ko "$nome: l'ancora cita $REF ma il file non esiste — ancora morta"; continue; }
  # (2026-09-24, terzo ventaglio, V5): il file esisteva, ma il SIMBOLO no — rinominata run_guarded o
  # gate_allowlist_ok, questo banco restava verde. Un'ancora «file:simbolo» vuole il simbolo nel file.
  SIMBOLO=$(printf '%s' "$ANCORA" | grep -oE "$(printf '%s' "$REF" | sed 's/[.]/\\./g'):[A-Za-z_][A-Za-z0-9_-]*" | head -1 | cut -d: -f2)
  if [ -n "$SIMBOLO" ]; then
    # la DEFINIZIONE, non una menzione: il nome compare anche nei commenti (rinominata run_guarded, la
    # sola ricerca del nome restava verde): funzione bash, def python, o assegnazione
    grep -qE "^[[:space:]]*(function[[:space:]]+)?$SIMBOLO[[:space:]]*\(\)|^[[:space:]]*def $SIMBOLO\(|^[[:space:]]*$SIMBOLO=" "$HERE/$REF" \
      && ok "$nome: il simbolo $SIMBOLO e' definito in $REF" \
      || ko "$nome: l'ancora cita $REF:$SIMBOLO ma $SIMBOLO non vi e' piu' definito — ancora morta"
  fi
done

# (V5): README.md e' il registro, non un pattern — non si conta fra i pattern
[ "$CHECKED" -gt 0 ] && ok "verificate $CHECKED ancore hub-locali su $(ls "$HERE"/patterns/*.md | grep -vc '/README\.md$') pattern totali" \
  || ko "nessuna ancora hub-locale trovata da verificare — controllare la logica del test"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
