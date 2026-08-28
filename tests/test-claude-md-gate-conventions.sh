#!/bin/bash
# test-claude-md-gate-conventions.sh — set 3 giro 9: due convenzioni tacite necessarie al
# funzionamento del gate (prefisso branch, keyword Closes in inglese) vivevano solo in
# commenti di codice o in SAL.md — mai in CLAUDE.md, il file che SI eredita in ogni
# progetto. Verifica che siano documentate lì, e che il documento resti coerente col
# codice reale (il prefisso citato deve essere lo stesso che morning-gate.sh usa davvero).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -qi "night/.*claude/.*glm/\|night/\`, \`claude/\`\|prefisso" "$HERE/CLAUDE.md" \
  && ok "CLAUDE.md documenta il prefisso di branch richiesto dal gate" \
  || ko "CLAUDE.md non menziona il prefisso di branch"

grep -q "Closes #N.*INGLESE\|INGLESE.*Closes\|Closes.*inglese" "$HERE/CLAUDE.md" \
  && ok "CLAUDE.md documenta la regola Closes-in-inglese" \
  || ko "CLAUDE.md non menziona la regola Closes-in-inglese"

# coerenza: il prefisso reale filtrato da morning-gate.sh deve combaciare con quello citato
REGEX_REALE=$(grep -oE '\^night/\|\^claude/\|\^glm/' "$HERE/night-shift/morning-gate.sh")
[ "$REGEX_REALE" = '^night/|^claude/|^glm/' ] && ok "il filtro reale in morning-gate.sh è ancora night/|claude/|glm/ (coerente con CLAUDE.md)" \
  || ko "il filtro reale è cambiato ($REGEX_REALE) — CLAUDE.md andrebbe aggiornato"

# CLAUDE.md viaggia davvero verso i progetti nuovi (altrimenti la documentazione non arriva)
grep -q 'cp "\$HERE/CLAUDE.md" CLAUDE.md' "$HERE/tools/bootstrap-app.sh" \
  && ok "CLAUDE.md (con le nuove convenzioni) viene copiato nei progetti bootstrappati" \
  || ko "bootstrap-app.sh non copia più CLAUDE.md — la documentazione non arriverebbe"

# giri avversari 2026-08-28 (A15): togliere la regola clasp da CLAUDE.md non
# faceva diventare rosso nessun test — la regola del deploy è presidiata qui
grep -qi "clasp" "$HERE/CLAUDE.md" && ok "CLAUDE.md presidia la regola clasp (deploy dell'umano)" \
  || ko "CLAUDE.md ha perso la regola clasp"

# (A17) il union merge driver per i file append-only è dichiarato
grep -q "SAL.md merge=union" "$HERE/.gitattributes" && grep -q "docs/campo/\*.md merge=union" "$HERE/.gitattributes" \
  && ok ".gitattributes presidia il union merge per SAL e campo" \
  || ko ".gitattributes ha perso il union merge driver"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
