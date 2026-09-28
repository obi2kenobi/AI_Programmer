#!/bin/bash
# test-specchio.sh — il sistema si specchia (2026-09-28): i rossi diventano issue
# idempotenti, i gialli si dichiarano soltanto, i verdi non dicono niente.
# Stub in PATH: launchctl, curl, gh — il resto (git, i cloni) e' vero.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SPEC="$HERE/tools/specchio.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$SPEC" && ok "sintassi" || { ko "sintassi"; exit 1; }

RADICE=$(mktemp -d /tmp/test-specchio.XXXXXX)
trap 'rm -rf "$RADICE"' EXIT
STUBS=$(mktemp -d "$RADICE/stubs.XXXXXX")

# stub launchctl: risponde dal file $LAUNCHCTL_FINTO ("stato label" per riga)
cat > "$STUBS/launchctl" <<EOF
#!/bin/bash
[ "\$1" = list ] && cat "\${LAUNCHCTL_FINTO:-/dev/null}"
exit 0
EOF
# stub curl: porta 0 = tutti giu'; porta 1 = tutti su (i check usano solo l'esito)
cat > "$STUBS/curl" <<'EOF'
#!/bin/bash
case "$CURL_ESITO" in
  giu) exit 7 ;;
  *) exit 0 ;;
esac
EOF
# stub gh: registra le issue create in $GH_CREATE, risponde alla lista da $GH_APERTE
cat > "$STUBS/gh" <<'EOF'
#!/bin/bash
if [ "$1" = "issue" ] && [ "$2" = "create" ]; then
  for a in "$@"; do case "$a" in --title) shift_seen=1;; esac; done
  echo "$*" >> "${GH_CREATE:?}"
  echo "https://github.com/x/y/issues/1"
  exit 0
fi
if [ "$1" = "issue" ] && [ "$2" = "list" ]; then
  cat "${GH_APERTE:-/dev/null}" 2>/dev/null
  exit 0
fi
exit 0
EOF
chmod +x "$STUBS/launchctl" "$STUBS/curl" "$STUBS/gh"

# il mondo dei test: un WORK con un clone sano, un repos.conf, un digest-log fresco
WORK="$RADICE/work"; mkdir -p "$WORK"
printf 'pippo/uno docs\n# commento\npippo/due feat\n' > "$RADICE/repos.conf"
for n in uno due; do
  git -C "$WORK" init -q "$WORK/$n" 2>/dev/null || git init -q "$WORK/$n"
  git -C "$WORK/$n" remote add origin https://x/y.git
done
git -C "$WORK/uno" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git -C "$WORK/due" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
DIGLOG="$RADICE/morning-digest.log"; touch "$DIGLOG"

PATHSAVED="$PATH"
corri() { # corri [esito-curl]: lancia lo specchio nel mondo dei test
  env PATH="$STUBS:$PATHSAVED" HOME="$RADICE" SPECCHIO_WORK="$WORK" SPECCHIO_CONF="$RADICE/repos.conf" \
    SPECCHIO_REPO="pippo/hub" LAUNCHCTL_FINTO="$RADICE/launchctl.out" CURL_ESITO="${1:-su}" \
    GH_CREATE="$RADICE/gh-create.log" GH_APERTE="$RADICE/gh-aperte.txt" bash "$SPEC" 2>&1
}

# 1. tutto verde: nessuna issue, la casa e' in ordine
printf -- '- 0 com.luca.morningdigest\n' > "$RADICE/launchctl.out"
: > "$RADICE/gh-aperte.txt"
OUT=$(corri)
grep -q "0 rossi — casa in ordine" <<<"$OUT" && ok "mondo sano: casa in ordine, nessun rosso" || ko "$OUT"
[ ! -s "$RADICE/gh-create.log" ] && ok "mondo sano: nessuna issue aperta" || ko "issue aperta senza rosso: $(cat "$RADICE/gh-create.log")"

# 2. il digest 127: rosso + issue; la seconda corsa NON duplica (idempotenza)
printf -- '- 127 com.luca.morningdigest\n' > "$RADICE/launchctl.out"
OUT=$(corri)
grep -q "ROSSO digest" <<<"$OUT" && ok "digest exit 127: rosso dichiarato" || ko "$OUT"
grep -q "specchio: digest — degradato" <<<"$OUT" && ok "digest: issue aperta" || ko "niente issue: $OUT"
grep -c -- '--title specchio: digest' "$RADICE/gh-create.log" | grep -q '^1$' && ok "una sola issue per il digest" || ko "issue multiple: $(grep -c -- '--title specchio: digest' "$RADICE/gh-create.log")"

# 3. idempotenza: l'issue e' gia' aperta → si dice, non si duplica
printf 'specchio: digest — degradato\n' > "$RADICE/gh-aperte.txt"
N_PRIMA=$(grep -c -- '--title specchio: digest' "$RADICE/gh-create.log")
OUT=$(corri)
N_DOPO=$(grep -c -- '--title specchio: digest' "$RADICE/gh-create.log")
grep -q "gia' aperta per digest" <<<"$OUT" && [ "$N_PRIMA" = "$N_DOPO" ] && ok "issue aperta per il digest: niente doppioni" || ko "duplicato digest: $N_PRIMA → $N_DOPO"

# 4. la ricaduta E-052: clone due single-branch → rosso + issue sua
printf -- '- 0 com.luca.morningdigest\n' > "$RADICE/launchctl.out"
git -C "$WORK/due" config remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'
: > "$RADICE/gh-aperte.txt"
OUT=$(corri)
grep -q "ROSSO clone due.*single-branch" <<<"$OUT" && grep -q "specchio: clone due — degradato" <<<"$OUT" \
  && ok "clone single-branch: rosso con la sua issue (E-052 presidia)" || ko "$OUT"

# 5. Ollama giu' e' ROSSO; razzo e pii giu' sono GIALLI senza issue
: > "$RADICE/gh-aperte.txt"
rm -f "$RADICE/gh-create.log"; touch "$RADICE/gh-create.log"
OUT=$(corri giu)
grep -q "ROSSO server-iq3s" <<<"$OUT" && ok "Ollama giu': rosso" || ko "$OUT"
grep -q "GIALLO server-razzo" <<<"$OUT" && grep -q "GIALLO server-pii" <<<"$OUT" \
  && ok "razzo e pii giu': gialli dichiarati" || ko "$OUT"
grep -q "server-razzo\|server-pii" "$RADICE/gh-create.log" && ko "gialli che aprono issue!" || ok "i gialli non aprono issue"

# 6. la lezione manca e il turno ieri girava: giallo
printf -- '- 0 com.luca.morningdigest\n' > "$RADICE/launchctl.out"
git -C "$WORK/due" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
IERI=$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F)
printf '[%s 01:00:00] REPO pippo/uno: ciclo\n' "$IERI" > "$RADICE/night-shift.log"
OUT=$(corri)
grep -q "GIALLO impara" <<<"$OUT" && ok "lezione manca col turno attivo: giallo" || ko "$OUT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
