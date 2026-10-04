#!/bin/bash
# test-genera-agenti-repo.sh — il banco della proiezione PER-REPO della faretra
# (giro 2, 2026-10-04). Col cervello centrale il satellite non copia gli agenti
# — ma Claude Code legge .claude/agents DAL repo: senza proiezione le sessioni
# di giorno nei satelliti restano senza specialisti di dominio.
#
# Presidia:
#   1. genera SOLO i ruoli attivi dichiarati (.git/ruoli-attivi)
#   2. i file generati portano il marcatore (si cambia roles/, non il mirror)
#   3. un agente scritto a mano NON viene toccato né sostituito né rimosso
#   4. un ruolo disattivato: il suo file generato SPARISCE, il manuale resta
#   5. idempotente: due giri producono lo stesso albero
#   6. repo senza .git/ruoli-attivi: esce 0 senza scrivere nulla
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d "${TMPDIR:-/tmp}/gen-repo.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

nuovo_repo() { mkdir -p "$TMP/$1" && git -C "$TMP/$1" init -q; echo "$TMP/$1"; }

# ── 1-3: proiezione selettiva + marcatore + manuale intatto ──────────────────
R=$(nuovo_repo magazzino)
printf 'specialista-logistica\nsviluppatore-gas\n' > "$R/.git/ruoli-attivi"
mkdir -p "$R/.claude/agents" "$R/.opencode/agent"
printf -- "---\nname: mio-agente\ndescription: fatto a mano\n---\n\nResta mio.\n" > "$R/.claude/agents/mio-agente.md"
OUT=$(bash "$HERE/tools/genera-agenti.sh" --repo "$R" 2>&1)
grep -q "2 ruoli attivi" <<<"$OUT" && ok "proietta i ruoli attivi dichiarati (2)" || ko "uscita inattesa: $OUT"
[ -f "$R/.claude/agents/specialista-logistica.md" ] && ok "specialista-logistica nel mirror Claude" || ko "manca specialista-logistica"
[ -f "$R/.opencode/agent/sviluppatore-gas.md" ] && ok "sviluppatore-gas nel mirror OpenCode" || ko "manca sviluppatore-gas"
[ ! -f "$R/.claude/agents/analista-trading.md" ] && ok "un ruolo NON attivo NON viene proiettato" || ko "analista-trading proiettato senza essere attivo"
grep -q "GENERATO da tools/genera-agenti.sh" "$R/.claude/agents/specialista-logistica.md" \
  && ok "i generati portano il marcatore" || ko "marcatore assente nel generato"
grep -q "Resta mio." "$R/.claude/agents/mio-agente.md" && ok "l'agente manuale resta intatto" || ko "il manuale è stato toccato"

# ── 5: idempotenza ───────────────────────────────────────────────────────────
bash "$HERE/tools/genera-agenti.sh" --repo "$R" >/dev/null 2>&1
N_PRIMA=$(ls "$R/.claude/agents" | wc -l | tr -d ' ')
bash "$HERE/tools/genera-agenti.sh" --repo "$R" >/dev/null 2>&1
N_DOPO=$(ls "$R/.claude/agents" | wc -l | tr -d ' ')
[ "$N_PRIMA" = "$N_DOPO" ] && ok "idempotente ($N_PRIMA file stabili)" || ko "al secondo giro l'albero cambia ($N_PRIMA → $N_DOPO)"

# ── 4: disattivazione ────────────────────────────────────────────────────────
printf 'sviluppatore-gas\n' > "$R/.git/ruoli-attivi"
bash "$HERE/tools/genera-agenti.sh" --repo "$R" >/dev/null 2>&1
[ ! -f "$R/.claude/agents/specialista-logistica.md" ] && ok "ruolo disattivato: il suo generato SPARISCE" || ko "il generato disattivato resta"
grep -q "Resta mio." "$R/.claude/agents/mio-agente.md" && ok "il manuale sopravvive alla disattivazione" || ko "il manuale è morto con la disattivazione"

# ── 6: nessuna dichiarazione ─────────────────────────────────────────────────
R2=$(nuovo_repo nudo)
OUT2=$(bash "$HERE/tools/genera-agenti.sh" --repo "$R2" 2>&1); RC2=$?
[ "$RC2" -eq 0 ] && [ ! -d "$R2/.claude/agents" ] \
  && ok "repo senza ruoli dichiarati: esce 0 e non scrive nulla" \
  || ko "repo nudo: rc=$RC2, scrittura inattesa"

# ── la modalità HUB non ha il marcatore (i mirror dell'hub sono copia di lavoro) ──
bash "$HERE/tools/genera-agenti.sh" --controlla 2>/dev/null \
  && ! grep -lq "GENERATO da tools/genera-agenti.sh" "$HERE/.claude/agents/sviluppatore-gas.md" 2>/dev/null \
  && ok "hub: mirror derivanti e SENZA marcatore" \
  || ko "hub: i mirror derivano ma portano il marcatore (sbagliato: quello e' del satellite)"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
