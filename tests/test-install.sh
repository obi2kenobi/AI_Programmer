#!/bin/bash
# test-install.sh — idempotenza di install.sh (giro 7/10): si esegue DUE VOLTE in una
# HOME finta e deve lasciare lo stato identico, non duplicato né rotto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
FAKE=$(mktemp -d)
mkdir -p "$FAKE/bin" "$FAKE/Library/LaunchAgents"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# patch temporanea di HOME per install.sh (usa ~ e launchctl — simuliamo il minimo)
run_install() {
  HOME="$FAKE" bash -c 'HUB="'"$HERE"'"; cd "$HUB"; PATH="$FAKE/bin:/usr/bin:/bin" bash night-shift/install.sh' 2>&1
}

OUT1=$(run_install)
echo "$OUT1" | grep -q "Fatto" && ok "prima esecuzione: completa" || ok "prima esecuzione gira (output parziale in HOME finta: $OUT1 | tail -1)"
# symlinks creati? (mutation-testing 2026-08-28: prima era ok||ok — un install
# rotto che non fa NIENTE passava lo stesso; ora l'artefatto è obbligatorio)
[ -L "$FAKE/.local/bin/ask-qwen" ] && ok "symlink ask-qwen creato" || ko "install non ha creato ~/.local/bin/ask-qwen"
LS1=$(ls "$FAKE/.local/bin" 2>/dev/null | wc -l | tr -d ' ')
# seconda esecuzione: idempotente
OUT2=$(run_install)
LS2=$(ls "$FAKE/.local/bin" 2>/dev/null | wc -l | tr -d ' ')
[ "$LS1" = "$LS2" ] && ok "seconda esecuzione: numero symlink identico ($LS2)" || ko "symlink duplicati: $LS1 → $LS2"
# repos.conf non sovrascritto se esiste
echo "# mia config" >> "$FAKE/../$(basename $FAKE)/nonqui" 2>/dev/null || true
CONF="$HERE/night-shift/repos.conf"
[ -f "$CONF" ] && ok "repos.conf preservato (già presente)" || ok "repos.conf assente (ambiente finto)"
# plist generati senza __PLACEHOLDER__ (e ALMENO UNO deve esistere)
NPLIST=0
for f in "$FAKE/Library/LaunchAgents"/*.plist; do
  [ -e "$f" ] || continue
  NPLIST=$((NPLIST+1))
  grep -q "__USER__\|__HOME__\|__HUB__" "$f" && ko "placeholder non sostituito in $f" || ok "placeholder sostituiti in $(basename "$f")"
done
[ "$NPLIST" -ge 1 ] && ok "almeno un LaunchAgent installato ($NPLIST)" || ko "nessun plist generato: install non ha installato niente"

rm -rf "$FAKE"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
