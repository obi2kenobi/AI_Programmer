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

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
