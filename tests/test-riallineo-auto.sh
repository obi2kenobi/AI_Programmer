#!/bin/bash
# test-riallineo-auto.sh — il riallineo non ha un merge laterale: verifica il
# commit esatto della PR standard e passa dal wrapper fondi→revisore fresco.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d /tmp/test-riall-auto.XXXXXX); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
BIN="$T/bin"; mkdir -p "$BIN"

cat > "$BIN/gh" <<EOF
#!/bin/bash
case "\$1 \$2" in
  "pr list") echo "#9 chore: adotta lo standard AI_Programmer"; exit 0;;
  "pr view")
    sha=\$(git -C "$T/repo" rev-parse std/branch)
    printf '{"headRefName":"std/branch","headRefOid":"%s"}\n' "\$sha"; exit 0;;
  "pr merge") echo "gh \$*" >> "$T/ghlog"; exit 0;;
esac
exit 0
EOF
chmod +x "$BIN/gh"

BLOCCO=$(awk '/il riallineo auto-verificato/{f=1} f{print} f && /fine ramo RIALLINEO_AUTO/{exit}' "$HERE/night-shift/night-shift.sh")
[ -n "$BLOCCO" ] && printf '#!/bin/bash\n%s\n' "$BLOCCO" | bash -n \
  && ok "blocco riallineo-auto trovato e sintatticamente chiuso" || { ko "blocco non trovato o sbilanciato"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

corri() { # corri <verdetto-di-sync> [pr_sync] [riallineo_auto 0/1] [fondi_rc]
  local verdetto="$1" pr_sync="${2:-#9 chore: adotta lo standard AI_Programmer}" auto="${3:-0}" fondi_rc="${4:-0}"
  mkdir -p "$T/hub/tools" "$T/hub/night-shift"
  cat > "$T/hub/tools/sync-repo.sh" <<EOF
#!/bin/bash
git rev-parse HEAD >> "$T/sync-heads"
echo "sync-repo: $verdetto — CLAUDE.md coincide"
EOF
  cat > "$T/hub/tools/fondi.sh" <<EOF
#!/bin/bash
printf 'class=%s auto=%s args=%s\n' "\${FONDI_CLASSE:-}" "\${FONDI_AUTO:-}" "\$*" >> "$T/fondilog"
echo 'FONDI: SI — finto'
exit $fondi_rc
EOF
  chmod +x "$T/hub/tools/sync-repo.sh" "$T/hub/tools/fondi.sh"
  : > "$T/ghlog"; : > "$T/fondilog"
  printf '%s\n' '#!/bin/bash' 'set -uo pipefail' 'log() { echo "LOG: $*"; }' \
    "DIR=$(printf %q "$T/repo")" "REPO=pippo/x" "DB=main" "HERE=$(printf %q "$T/hub/night-shift")" \
    "RIALLINEO_AUTO=$auto" "PR_SYNC=$(printf %q "$pr_sync")" "$BLOCCO" > "$T/ciclo.sh"
  PATH="$BIN:$PATH" bash "$T/ciclo.sh" 2>&1
}

# La PR ha un commit proprio: il checkout deve finire su quello, non su main o
# su un ramo locale omonimo rimasto indietro.
git init -q -b main "$T/repo"
(cd "$T/repo" && echo base > f.txt && git add -A && git commit -qm base)
git -C "$T/repo" checkout -q -b std/branch
echo standard > "$T/repo/standard.txt"
git -C "$T/repo" add -A && git -C "$T/repo" commit -qm standard
STD_SHA=$(git -C "$T/repo" rev-parse std/branch)
git -C "$T/repo" checkout -q main
git -C "$T/repo" remote add origin "$T/repo"
git -C "$T/repo" push -q origin std/branch

# 1. Default spento: nessun merge diretto e nessuna chiamata al wrapper.
OUT=$(corri "sync-repo: ALLINEATO")
grep -q "auto-merge SPENTO" <<<"$OUT" && [ ! -s "$T/ghlog" ] && [ ! -s "$T/fondilog" ] \
  && ok "spento di default: nessuna fusione né review auto-assolta" || ko "spento: $OUT"

# 2. Acceso: sync sullo SHA della PR, poi UNA delega standard a fondi.
OUT=$(corri "sync-repo: ALLINEATO" "#9 chore: adotta lo standard AI_Programmer" 1)
grep -q 'riallineo AUTO-FUSO: PR #9' <<<"$OUT" && grep -q 'class=standard auto=1' "$T/fondilog" \
  && [ "$(tail -1 "$T/sync-heads")" = "$STD_SHA" ] && [ ! -s "$T/ghlog" ] \
  && ok "checkout headRefOid + delega a fondi; nessun gh pr merge laterale" \
  || ko "verde: $OUT / $(cat "$T/fondilog") / $(tail -1 "$T/sync-heads" 2>/dev/null)"

# 3. Divergente o wrapper non approvato: nessun successo annunciato.
OUT=$(corri "sync-repo: DIVERGENTE — CLAUDE.md dista 3 righe" "#9 chore: adotta lo standard AI_Programmer" 1)
grep -q "NON e' solo standard" <<<"$OUT" && [ ! -s "$T/fondilog" ] \
  && ok "branch divergente: non arriva al merge" || ko "divergente: $OUT"
OUT=$(corri "sync-repo: ALLINEATO" "#9 chore: adotta lo standard AI_Programmer" 1 1)
! grep -q 'AUTO-FUSO' <<<"$OUT" && grep -q 'NON fusa' <<<"$OUT" \
  && ok "review/merge del wrapper fallito: il turno dice NON fusa" || ko "fondi rosso ma successo: $OUT"

# 4. Due PR: la selezione resta per titolo, non per posizione.
OUT=$(corri "sync-repo: ALLINEATO" $'#7 fix: estranea\n#9 chore: adotta lo standard AI_Programmer' 1)
grep -q 'args=.*/repo 9' "$T/fondilog" && ! grep -q ' 7$' "$T/fondilog" \
  && ok "due PR: solo la #9 standard arriva al wrapper" || ko "selezione: $OUT / $(cat "$T/fondilog")"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
