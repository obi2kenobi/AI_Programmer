#!/bin/bash
# test-roles-sync.sh — il banco della faretra (2026-10-03, decisione di Luca:
# «tutto deve essere disponibile a tutti gli LLM, anche i cinesi open-weight»).
#
# Presidia quattro proprietà:
#   1. gli specchietti (.claude/agents/, .opencode/agent/) DERIVANO da roles/
#      (genera-agenti.sh --controlla): chi edita lo specchietto vede il lavoro
#      cancellato — la deriva tra copie muore qui
#   2. ogni ruolo ha il frontmatter canonico completo (nome, descrizione, quando,
#      domini, edita si|no) — un file monco non entra nella faretra
#   3. il corpo di un ruolo NON cita percorsi di harness (.claude/, .opencode/):
#      il file deve leggersi uguale da qualunque LLM
#   4. il permesso edita=no arriva fino allo specchietto Claude (niente Edit/Write
#      nel tools: del giudice) e opencode (edit: deny)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# ── 1. gli specchietti derivano ───────────────────────────────────────────────
if bash "$HERE/tools/genera-agenti.sh" --controlla 2>/tmp/roles-deriva.txt; then
  ok "specchietti .claude/agents e .opencode/agent derivano da roles/ (idempotenti)"
else
  ko "DERIVA specchietti: $(head -2 /tmp/roles-deriva.txt | tr '\n' ' ')"
fi

# ── 2. frontmatter canonico completo ─────────────────────────────────────────
shopt -s nullglob
RUOLI=("$HERE"/roles/*.md)
[ "${#RUOLI[@]}" -ge 11 ] \
  && ok "la faretra ha ruoli: ${#RUOLI[@]} (>= 11: i 6 migrati + i 5 nuovi)" \
  || ko "la faretra ha solo ${#RUOLI[@]} ruoli (attesi >= 11)"
for f in "${RUOLI[@]}"; do
  n=$(basename "$f" .md)
  [ "$n" = "README" ] && continue
  FM=$(awk '/^---$/{c++; next} c==1{print} c>=2{exit}' "$f")
  for campo in nome descrizione quando domini edita; do
    grep -qE "^${campo}: .+" <<<"$FM" \
      || ko "roles/$n.md: campo '$campo' mancante o vuoto nel frontmatter"
  done
  grep -qE "^edita: (si|no)$" <<<"$FM" \
    || ko "roles/$n.md: 'edita' non è si|no"
  grep -q "^nome: $n$" <<<"$FM" \
    || ko "roles/$n.md: 'nome' non coincide col nome file"
done
ok "frontmatter canonico verificato su ${#RUOLI[@]} file"

# ── 3. nessun percorso di harness nei corpi ──────────────────────────────────
for f in "${RUOLI[@]}"; do
  n=$(basename "$f" .md)
  [ "$n" = "README" ] && continue
  CORPO=$(awk 'c>=2{print} /^---$/{c++; next}' "$f")
  if grep -qE '\.claude/|\.opencode/' <<<"$CORPO"; then
    ko "roles/$n.md: il corpo cita un percorso di harness (deve citare le skill per NOME)"
  fi
done
ok "corpi dei ruoli senza percorsi di harness (leggibili da qualunque LLM)"

# ── 4. edita=no resta senza potere di scrittura ──────────────────────────────
while IFS= read -r R; do
  [ -n "$R" ] || continue
  CL="$HERE/.claude/agents/$R.md"
  OP="$HERE/.opencode/agent/$R.md"
  grep -q "tools: Read, Grep, Glob, Bash$" "$CL" && ! grep -q "Edit" <<<"$(grep '^tools:' "$CL")" \
    && ok "$R: giudice senza Edit nello specchietto Claude" \
    || ko "$R: edita=no ma lo specchietto Claude ha Edit/Write"
  grep -q "edit: deny" "$OP" \
    && ok "$R: edit: deny nello specchietto OpenCode" \
    || ko "$R: edit:deny assente in OpenCode"
done < <(grep -lE '^edita: no' "$HERE"/roles/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.md$//')

echo "── test-roles-sync: $PASS ok · $FAIL fail"
[ "$FAIL" -eq 0 ]
