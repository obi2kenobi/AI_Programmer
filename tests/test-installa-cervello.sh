#!/bin/bash
# test-installa-cervello.sh — UN comando per installare il cervello AI_Programmer
# in un repo nuovo. Verifica: CLAUDE.md sottile, hook presenti, grafo creato,
# repos.conf aggiornato, .night-verify minimo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/installa-ai-programmer.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }

T=$(mktemp -d /tmp/test-installa.XXXXXX); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# mini repo da installare
git init -q -b main "$T/nuovo"
( cd "$T/nuovo" && echo "// progetto" > Code.gs && git add -A && git commit -qm base
  git remote add origin https://github.com/test/nuovo.git )

# il finto repos.conf (isolato dall'hub vero)
mkdir -p "$T/hub/night-shift" "$T/hub/tools"
cp "$HERE/night-shift/repos.conf" "$T/hub/night-shift/repos.conf" 2>/dev/null || \
  printf 'obi2kenobi/AI_Programmer docs\n' > "$T/hub/night-shift/repos.conf"
# gli hook dal vero hub (il finto ha solo repos.conf)
for h in pattern-reminder-hook.sh clasp-block-hook.sh metodo-reminder-hook.sh skill-reminder-hook.sh graphify-spina.sh gas-gate.sh; do
  cp "$HERE/tools/$h" "$T/hub/tools/$h" 2>/dev/null
done
cp "$HERE/tools/claude-md-cervello.sh" "$T/hub/tools/" 2>/dev/null || true

# installa (con HUB finto per non toccare quello vero)
OUT=$(INSTALLA_HUB="$T/hub" REPO_FINTO=1 bash "$TOOL" "$T/nuovo" 2>&1); RC=$?

[ "$RC" -eq 0 ] && ok "installazione rc=0" || ko "rc=$RC: $(tail -3 <<<"$OUT")"

# 1. CLAUDE.md sottile
grep -q 'metodo AI_Programmer' "$T/nuovo/CLAUDE.md" 2>/dev/null \
  && grep -q 'night-shift-work/AI_Programmer/CLAUDE.md' "$T/nuovo/CLAUDE.md" 2>/dev/null \
  && ok "CLAUDE.md e' un puntatore al cervello" || ko "CLAUDE.md non e' un puntatore"

# 2. hook presenti
[ -f "$T/nuovo/tools/pattern-reminder-hook.sh" ] && ok "hook pattern-reminder presente" || ko "hook mancante"
[ -f "$T/nuovo/tools/clasp-block-hook.sh" ] && ok "hook clasp-block presente" || ko "hook clasp mancante"
[ -f "$T/nuovo/tools/gas-gate.sh" ] && ok "gas-gate copiato (per night-verify)" || ko "gas-gate mancante"
[ -f "$T/nuovo/.claude/settings.json" ] && grep -q 'pattern-reminder' "$T/nuovo/.claude/settings.json" \
  && ok "settings.json con hook registrati" || ko "settings.json senza hook"

# 3. grafo creato (se graphify disponibile)
if command -v graphify >/dev/null 2>&1; then
  [ -d "$T/nuovo/graphify-out" ] && ok "grafo creato" || ko "grafo assente"
else
  echo "⊘ graphify non disponibile — grafo non testato (dichiarato)"
fi

# 4. .night-verify minimo
[ -f "$T/nuovo/.night-verify" ] && ok ".night-verify presente" || ko ".night-verify assente"

# 5. repos.conf aggiornato
grep -q 'test/nuovo' "$T/hub/night-shift/repos.conf" 2>/dev/null \
  && ok "registrato in repos.conf (test/nuovo)" || ko "non registrato: $(tail -3 "$T/hub/night-shift/repos.conf")"

# 6. re-installazione = exit 2 (gia' installato)
OUT2=$(INSTALLA_HUB="$T/hub" bash "$TOOL" "$T/nuovo" 2>&1); RC2=$?
[ "$RC2" -eq 2 ] && ok "re-installazione riconosciuta (exit 2)" || ko "re-installazione rc=$RC2"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
