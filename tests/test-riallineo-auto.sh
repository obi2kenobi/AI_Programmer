#!/bin/bash
# test-riallineo-auto.sh — il riallineo AUTO-FUSO (2026-10-02, approvato da Luca):
# la PR «adotta lo standard» si fonde da sola SOLO se il suo branch e' ESATTAMENTE
# lo standard (un giro di sync-repo sul branch dice ALLINEATO). Altrimenti resta al
# giorno. Blocco estratto dal turno (pattern del banco del grafo).
# (AUDIT-KIMI Q10/P0.2, 15/11): regressioni anti-bypass — 1) SPENTO di default;
# 2) acceso + branch identico → fonde; 3) acceso + divergente → non fonde;
# 4) due PR aperte: si sceglie per TITOLO, mai la prima dell'elenco (era head -1).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

T=$(mktemp -d /tmp/test-riall-auto.XXXXXX); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
BIN="$T/bin"; mkdir -p "$BIN"

# gh finto: PR sul branch std/branch; merge registrato col numero (anti head -1)
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

# il blocco riallineo-auto, estratto dal turno: dal commento d'apertura al
# «fi» che chiude il ramo RIALLINEO_AUTO (marcatore esatto — prima si chiudeva
# a meta', dopo il ramo «illeggibile», e il blocco estratto era sbilanciato)
BLOCCO=$(awk '/il riallineo auto-verificato/{f=1} f{print} f && /fine ramo RIALLINEO_AUTO/{exit}' "$HERE/night-shift/night-shift.sh")
[ -n "$BLOCCO" ] && printf '#!/bin/bash\n%s\n' "$BLOCCO" | bash -n \
  && ok "blocco riallineo-auto trovato e sintatticamente chiuso" || { ko "blocco non trovato o sbilanciato"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

corri() { # corri <verdetto-di-sync> [pr_sync] [riallineo_auto 0/1]
  local verdetto="$1" pr_sync="${2:-#9 chore: adotta lo standard AI_Programmer}" auto="${3:-0}"
  mkdir -p "$T/hub/tools"
  printf '#!/bin/bash\necho "sync-repo: %s — CLAUDE.md coincide"\n' "$verdetto" > "$T/hub/tools/sync-repo.sh"; chmod +x "$T/hub/tools/sync-repo.sh"
  : > "$T/ghlog"
  printf '%s\n' '#!/bin/bash' 'set -uo pipefail' 'log() { echo "LOG: $*"; }' \
    "DIR=$(printf %q "$T/repo")" "REPO=pippo/x" "DB=main" "HERE=$(printf %q "$T/hub/night-shift")" \
    "RIALLINEO_AUTO=$auto" \
    "PR_SYNC=$(printf %q "$pr_sync")" \
    "$BLOCCO" > "$T/ciclo.sh"
  PATH="$BIN:$PATH" bash "$T/ciclo.sh" 2>&1
}

# il repo finto col branch std/branch (checkout vera, merge finto)
git init -q -b main "$T/repo" && (cd "$T/repo" && echo base > f.txt && git add -A && git commit -qm base && git branch std/branch && git remote add origin "$T/repo" && git push -q origin std/branch)
mkdir -p "$T/hub/night-shift"

# 1. SPENTO di default (audit P0.2): anche col branch identico NON si fonde
OUT=$(corri "sync-repo: ALLINEATO")
grep -q "auto-merge SPENTO" <<<"$OUT" && [ ! -s "$T/ghlog" ] \
  && ok "spento di default: branch identico ma NESSUNA fusione (resta al revisore)" || ko "spento di default: $OUT / $(cat "$T/ghlog" 2>/dev/null)"

# 2. acceso + il branch porta ESATTAMENTE lo standard → AUTO-FUSO
OUT=$(corri "sync-repo: ALLINEATO" "#9 chore: adotta lo standard AI_Programmer" 1)
grep -q 'riallineo AUTO-FUSO: PR #9' <<<"$OUT" && grep -q 'pr merge 9' "$T/ghlog" \
  && ok "acceso + branch identico allo standard → PR fusa da sola" || ko "non fuso: $OUT / $(cat "$T/ghlog" 2>/dev/null)"

# 3. acceso + il branch NON e' solo standard → resta al giorno
OUT=$(corri "sync-repo: DIVERGENTE — CLAUDE.md dista 3 righe" "#9 chore: adotta lo standard AI_Programmer" 1)
grep -q "NON e' solo standard" <<<"$OUT" && [ ! -s "$T/ghlog" ] \
  && ok "acceso + branch divergente → NESSUNA fusione, al giorno" || ko "fuso comunque?! $OUT"

# 4. due PR aperte: la PRIMA e' estranea — si fonde SOLO quella col titolo (era head -1)
OUT=$(corri "sync-repo: ALLINEATO" $'#7 fix: roba senza rapporto\n#9 chore: adotta lo standard AI_Programmer' 1)
grep -q 'pr merge 9' "$T/ghlog" && ! grep -q 'pr merge 7' "$T/ghlog" \
  && ok "due PR aperte: scelta per TITOLO (#9 fusa, la #7 estranea ignorata)" || ko "selezione titolo: $OUT / $(cat "$T/ghlog" 2>/dev/null)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
