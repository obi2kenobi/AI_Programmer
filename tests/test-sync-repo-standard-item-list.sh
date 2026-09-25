#!/bin/bash
# test-sync-repo-standard-item-list.sh — banco di regressione nato dalla revisione
# "L'Hub Allo Specchio" (14 lenti indipendenti, 2026-08-28): sync-repo.sh --standard
# (lo strumento nato apposta per chiudere la divergenza silenziosa dopo l'onboarding, F2)
# non includeva .opencode/skills né patterns/ nell'elenco ITEM — ogni skill OpenCode o
# pattern aggiunto al hub DOPO l'onboarding di un progetto non lo raggiungeva mai più.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

LINEA=$(grep -n 'for ITEM in' "$HERE/tools/sync-repo.sh" | head -1)

# giri avversari 2026-08-28 (A14/G8): la lista era DRIFTATA da tools/sync-repo.sh
# (mancava .opencode/plugins) e non presidiava il flag --standard
# (D13, test del sistema completo 2026-09-20): i guardiani del commit viaggiano
for item in .claude/skills .claude/agents .claude/settings.json .opencode/agent .opencode/skills .opencode/plugins; do
  grep -qF "$item" <<<"$LINEA" \
    && ok "ITEM list di sync-repo.sh --standard include: $item" \
    || ko "ITEM list di sync-repo.sh --standard NON include: $item"
done
# (Q15, 2026-09-23): i file singoli dello standard (guardiani del commit, formato del report di
# campo, strumenti citati) vivono nella lista UNICA di tools/installa-citati.sh, che sync-repo,
# bootstrap-app e onboard-repo chiamano tutti e tre
for item in docs/campo/README.md .githooks tools/pre-commit.sh tools/debiti-riapertura.sh tools/cita-verifica.sh; do
  grep -qE "^[A-Z]+=\"(.* )?$item([ \"]|$)" "$HERE/tools/installa-citati.sh" \
    && ok "la lista unica (installa-citati.sh) include: $item" \
    || ko "la lista unica (installa-citati.sh) NON include: $item"
done
for S in sync-repo bootstrap-app onboard-repo; do
  grep -q 'tools/installa-citati.sh" "' "$HERE/tools/$S.sh" \
    && ok "$S.sh installa gli strumenti citati dalla lista unica" \
    || ko "$S.sh non chiama tools/installa-citati.sh"
done
# (D8, Luca 2026-09-23): CLAUDE.md viaggia fuori dalla lista, nella versione per i satelliti
grep -qF 'cp "$HUB_CLAUDE" CLAUDE.md && git add CLAUDE.md' "$HERE/tools/sync-repo.sh" \
  && grep -q 'HUB_CLAUDE="$TMP/claude-satellite.md"' "$HERE/tools/sync-repo.sh" \
  && ok "--standard installa CLAUDE.md nella versione per i satelliti (senza i blocchi solo-hub)" \
  || ko "--standard non installa il CLAUDE.md dei satelliti"
# (audit-3, 2026-09-23, commit 4db9af4): patterns/ NON viaggia piu' — e' un registro PER
# REPO (il sync aveva sovrascritto quello di un satellite: 12 ancore morte, 14 rossi, 7 PR
# bloccate). Questa lente pretendeva ancora il contrario ed era rossa sul codice giusto
# (revisione 10 giri, 2026-09-23): ora presidia la decisione.
grep -qE '[[:space:]]patterns([[:space:]]|/)' <<<"$LINEA" \
  && ko "ITEM list di sync-repo.sh --standard copia patterns/ (registro per repo: non deve viaggiare)" \
  || ok "ITEM list di sync-repo.sh --standard NON copia patterns/ (registro per repo, decisione 2026-09-23)"

# giri avversari 2026-08-28 (A14): --standard deve essere un FLAG REALE (case),
# non solo un nome citato nei commenti — il benvenuto insegna quel comando
grep -qE '^[[:space:]]*--standard\)' "$HERE/tools/sync-repo.sh" \
  && ok "sync-repo implementa --standard come flag reale" \
  || ko "sync-repo ha perso il flag --standard (restava solo nei commenti)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
