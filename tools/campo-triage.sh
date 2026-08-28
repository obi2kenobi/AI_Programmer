#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOTAL=$(ls "$HERE"/docs/campo/*.md "$HERE"/docs/campo/*.html 2>/dev/null | wc -l | tr -d ' ')
NON_PROC=0
for f in "$HERE"/docs/campo/*.md "$HERE"/docs/campo/*.html; do
  [ -f "$f" ] || continue
  grep -q "$(basename "${f%.*}")" "$HERE/SAL.md" 2>/dev/null || { echo "  non processato: $(basename $f)"; NON_PROC=$((NON_PROC+1)); }
done
echo "docs/campo/: $TOTAL report, $NON_PROC non processati"
[ "$NON_PROC" -eq 0 ]
