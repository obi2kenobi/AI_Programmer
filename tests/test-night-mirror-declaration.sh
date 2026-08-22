#!/bin/bash
# test-night-mirror-declaration.sh — set 3 giro 10: night-shift.sh istruiva l'agente a
# rispettare "cartelle specchio dichiarate dalla repo" ma non esisteva nessun meccanismo
# con cui una repo potesse dichiararle — citazione senza presidio. Introdotto .night-mirror
# (una cartella per riga, come .night-verify): se presente, le cartelle vengono elencate
# DAVVERO nel prompt; se assente, la frase non viene nemmeno scritta.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

costruisci_mirror_note() {
  local dir="$1" mirror_note="" mirror_list
  if [ -f "$dir/.night-mirror" ]; then
    mirror_list=$(grep -vE '^\s*#|^\s*$' "$dir/.night-mirror" | tr '\n' ',' | sed 's/,$//')
    [ -n "$mirror_list" ] && mirror_note=" Cartelle specchio/sola lettura DICHIARATE da questa repo (.night-mirror), non scriverci MAI: $mirror_list."
  fi
  echo "$mirror_note"
}

grep -q '\.night-mirror' "$HERE/night-shift/night-shift.sh" \
  && ok "night-shift.sh legge davvero .night-mirror (non solo ne parla)" \
  || ko "nessun riferimento a .night-mirror in night-shift.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

DIR1="$TMP/con-mirror"
mkdir -p "$DIR1"
cat > "$DIR1/.night-mirror" <<'EOF'
# cartelle sola lettura, mai scrivere
vendor/
generated/legacy
EOF
NOTE1=$(costruisci_mirror_note "$DIR1")
grep -q "vendor/" <<<"$NOTE1" && grep -q "generated/legacy" <<<"$NOTE1" \
  && ok "repo CON .night-mirror: le cartelle dichiarate finiscono davvero nel prompt" \
  || ko "repo con .night-mirror: cartelle non trovate nella nota: $NOTE1"

DIR2="$TMP/senza-mirror"
mkdir -p "$DIR2"
NOTE2=$(costruisci_mirror_note "$DIR2")
[ -z "$NOTE2" ] && ok "repo SENZA .night-mirror: nessuna frase sulle cartelle specchio (non evoca un vincolo inesistente)" \
  || ko "repo senza .night-mirror produce comunque una nota: $NOTE2"

grep -q "night-mirror" "$HERE/CLAUDE.md" \
  && ok "CLAUDE.md documenta la convenzione .night-mirror (non solo il codice la conosce)" \
  || ko "CLAUDE.md non documenta .night-mirror"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
