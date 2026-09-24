#!/bin/bash
# test-doc-non-corrotti.sh — i documenti non portano l'USCITA di un comando al posto del suo nome
# (Q19, 2026-09-23, giro A10 della notte). Un heredoc non quotato esegue i backtick: in AGENTS.md
# §0 il nome del promemoria del metodo era diventato il JSON che l'hook stampa, e il comando dello
# standard era sparito («e  lo porta tutto»); in docs/eventi.md una frase finiva in «Generato dal
# codice reale:» senza seguito. Il primo file che un agente legge diceva il falso sul metodo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# la firma generale: l'uscita JSON di un hook dentro un documento (docs/giri/ sono appunti grezzi
# ignorati da git, fuori)
JSON=$(git -C "$HERE" ls-files '*.md' | (cd "$HERE" && xargs grep -ln '"hookSpecificOutput"' 2>/dev/null) || true)
[ -z "$JSON" ] && ok "nessun documento porta l'uscita JSON di un hook" || ko "uscita JSON di un hook in: $(tr '\n' ' ' <<<"$JSON")"

A=$(cat "$HERE/AGENTS.md")
grep -qF 'tools/metodo-reminder-hook.sh' <<<"$A" && ok "AGENTS.md §0 nomina il promemoria del metodo" || ko "AGENTS.md §0 non nomina tools/metodo-reminder-hook.sh"
grep -qF 'tools/sync-repo.sh <owner/repo> --standard' <<<"$A" && ok "AGENTS.md §0 dice il comando che porta lo standard" || ko "AGENTS.md §0 senza il comando dello standard"
grep -qE ' e  lo porta' <<<"$A" && ko "AGENTS.md: «e  lo porta tutto» — il comando e' stato mangiato" || ok "AGENTS.md: nessun comando mangiato in §0"
grep -qE 'Generato dal codice reale:[[:space:]]*$' "$HERE/docs/eventi.md" && ko "docs/eventi.md: «Generato dal codice reale:» senza seguito" \
  || ok "docs/eventi.md: la frase d'apertura e' intera"

# (2026-09-23, notte dei giri, T4): AGENTS.md insegnava `bash .night-verify` come «suite completa» —
# eseguito, esce 0 senza far girare un solo banco («@540: command not found»; l'rc e' dell'ultima
# riga). Un documento vivo non insegna quel comando come verifica.
INSEGNA=$(cd "$HERE" && grep -ln '`bash \.night-verify`' AGENTS.md README.md METHOD.md PROJECT.md docs/*.md night-shift/README.md 2>/dev/null | grep -v REGISTRO || true)
[ -z "$INSEGNA" ] && ok "nessun documento vivo insegna «bash .night-verify» come verifica" || ko "insegnano «bash .night-verify» (esce 0 senza banchi): $INSEGNA"

# (2026-09-24, T4): night-shift/README.md diceva che il censore rinvia «non mio» le PR delle issue —
# da D10 (2026-09-23) le giudica in modo parere (night-shift/revisore.sh, MODO=parere).
NONMIO=$(cd "$HERE" && grep -ln 'rinvia «non mio»' README.md METHOD.md AGENTS.md docs/*.md night-shift/README.md 2>/dev/null || true)
[ -z "$NONMIO" ] && ok "nessun documento vivo dice che il censore rinvia «non mio» le PR delle issue" || ko "dicono ancora «non mio» sulle PR di issue: $NONMIO"
grep -c 'MODO="parere"' "$HERE/night-shift/revisore.sh" >/dev/null && ok "(il modo parere esiste davvero nel censore)" || ko "il modo parere non esiste piu' nel censore: il documento va rivisto"

# (E-045, 2026-09-24): ho scritto che `/nuova-commessa` «in questo repo non esiste» — il wizard e'
# .zcode-commands-nuova-commessa.md (col suo banco). L'avevo cercato con `find -name 'nuova-commessa*'`.
# Finche' il file c'e', nessun documento vivo lo dice assente.
if [ -f "$HERE/.zcode-commands-nuova-commessa.md" ]; then
  FALSO=$(cd "$HERE" && grep -nE 'nuova-commessa.{0,80}(non esist|assent|nel repo no)|(non esist|assent).{0,80}nuova-commessa' docs/MANUALE-OPERATIVO.md DEBITI.md AGENTS.md README.md METHOD.md 2>/dev/null || true)
  [ -z "$FALSO" ] && ok "nessun documento vivo dice assente il wizard /nuova-commessa (che esiste)" || ko "wizard dato per assente: $(cut -c1-120 <<<"$FALSO" | tr '\n' ' ')"
fi

# (2026-09-24, terzo ventaglio, V3 fuori tetto): tre skill dicevano il vecchio stato del sistema.
SK="$HERE/.claude/skills"
! grep -c 'banco avversariale del turno notturno (`night-shift/morning-gate.sh`)' "$SK/goal/SKILL.md" >/dev/null \
  && ok "goal: il banco avversariale non e' attribuito al morning-gate (in pensione)" || ko "goal cita ancora il morning-gate come sede del banco avversariale"
! grep -c 'controlla che ogni voce abbia i sette' "$SK/post-mortem/SKILL.md" >/dev/null \
  && ok "post-mortem: la lente non e' descritta con «sette campi» (sono otto, CLAUDE.md §5)" || ko "post-mortem dice ancora «sette campi»"
if [ -f "$HERE/graphify-out/graph.json" ]; then
  ! grep -c 'il grafo non è installato qui)' "$SK/design-doc/SKILL.md" >/dev/null \
    && ok "design-doc non dice il grafo assente dove e' versionato" || ko "design-doc dice «il grafo non è installato qui», ma graphify-out/graph.json c'e'"
fi

# (2026-09-24, quarto ventaglio, Q1 R4): `pkill -f "opencode run"` eseguito da un agente uccide la sua stessa
# shell — l'espressione compare nella riga di comando dello strumento (provato con pgrep: 2 processi, la
# shell esterna e la bash -c). La forma con la classe, `[o]pencode run`, trova il processo ma non la riga.
NUDI=$(grep -n 'pkill -f "opencode run"\|pkill -f \\"night-shift/night-shift.sh' "$HERE/docs/MANUALE-OPERATIVO.md" "$HERE/tools/turno-vivo.sh" 2>/dev/null || true)
[ -z "$NUDI" ] && ok "le pulizie da eseguire (manuale, turno-vivo) non si riconoscono da sole" || ko "pkill che uccide la propria shell: $NUDI"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
