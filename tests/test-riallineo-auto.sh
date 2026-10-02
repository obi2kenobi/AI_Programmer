#!/bin/bash
# test-riallineo-auto.sh — il riallineo AUTO-FUSO (2026-10-02, approvato da Luca):
# la PR «adotta lo standard» si fonde da sola SOLO se il suo branch e' ESATTAMENTE
# lo standard (un giro di sync-repo sul branch dice ALLINEATO). Altrimenti resta al
# giorno. Blocco estratto dal turno (pattern del banco del grafo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

T=$(mktemp -d /tmp/test-riall-auto.XXXXXX); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
BIN="$T/bin"; mkdir -p "$BIN"

# gh finto: PR #9 aperta «adotta lo standard» sul branch std/branch; merge registrato
cat > "$BIN/gh" <<EOF
#!/bin/bash
case "\$1 \$2" in
  "pr view") shift 2; while [ \$# -gt 0 ]; do case "\$1" in -q) echo "std/branch"; exit 0;; esac; shift; done; exit 0;;
  "pr list") echo "#9 chore: adotta lo standard AI_Programmer"; exit 0;;
  "pr merge") echo "gh \$*" >> "$T/ghlog"; exit 0;;
esac
exit 0
EOF
chmod +x "$BIN/gh"

# il blocco riallineo-auto, estratto dal turno
# dal commento d'apertura al fi che chiude il ramo illeggibile (marcatore fine esatto)
BLOCCO=$(awk '/il riallineo auto-verificato/{f=1} f{print} f && /illeggibile/{getline; print; exit}' "$HERE/night-shift/night-shift.sh")
[ -n "$BLOCCO" ] && ok "blocco riallineo-auto trovato nel turno" || { ko "blocco non trovato"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

corri() { # corri <verdetto-di-sync> — sync-repo finto al PERCORSO che il blocco usa
  mkdir -p "$T/hub/tools"
  printf '#!/bin/bash\necho "sync-repo: %s — CLAUDE.md coincide"\n' "$1" > "$T/hub/tools/sync-repo.sh"; chmod +x "$T/hub/tools/sync-repo.sh"
  : > "$T/ghlog"
  printf '%s\n' '#!/bin/bash' 'set -uo pipefail' 'log() { echo "LOG: $*"; }' \
    "DIR=$(printf %q "$T/repo")" "REPO=pippo/x" "DB=main" "HERE=$(printf %q "$T/hub/night-shift")" \
    'PR_SYNC="#9 chore: adotta lo standard AI_Programmer"' \
    "$BLOCCO" > "$T/ciclo.sh"
  PATH="$BIN:$PATH" bash "$T/ciclo.sh" 2>&1
}

# il repo finto col branch std/branch (checkout vera, merge finto)
git init -q -b main "$T/repo" && (cd "$T/repo" && echo base > f.txt && git add -A && git commit -qm base && git branch std/branch && git remote add origin "$T/repo" && git push -q origin std/branch)
mkdir -p "$T/hub/night-shift"

# 1. il branch porta ESATTAMENTE lo standard → AUTO-FUSO
OUT=$(corri "sync-repo: ALLINEATO")
grep -q 'riallineo AUTO-FUSO: PR #9' <<<"$OUT" && grep -q 'pr merge 9' "$T/ghlog" \
  && ok "branch identico allo standard → PR fusa da sola" || ko "non fuso: $OUT / $(cat "$T/ghlog" 2>/dev/null)"

# 2. il branch NON e' solo standard → resta al giorno
OUT=$(corri "sync-repo: DIVERGENTE — CLAUDE.md dista 3 righe")
grep -q "NON e' solo standard" <<<"$OUT" && [ ! -s "$T/ghlog" ] \
  && ok "branch divergente → NESSUNA fusione, al giorno" || ko "fuso comunque?! $OUT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
