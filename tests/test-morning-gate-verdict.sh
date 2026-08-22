#!/bin/bash
# test-morning-gate-verdict.sh — set 2 giro 9: bug reale, alta severità. Un .night-verify
# con SOLO righe di commento — ESATTAMENTE il default generato da tools/bootstrap-app.sh
# per ogni repo nuova — faceva collassare ogni riga del loop di verifica (continue su
# ogni riga), zero comandi eseguiti, V_RC restava 0 invariato → VERDICT="verifiche-ok".
# Falso verde: ogni repo appena bootstrappata mostrava "tutto verificato" finché qualcuno
# non riempiva davvero il file. Riproduce la logica REALE di morning-gate.sh (estratta,
# non ridigitata) su repo git sintetici.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/night-shift/lib.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

verdetto_per() {
  local dir="$1" db="$2"
  local night_verify v_rc=0 cmd_eseguiti=0 out
  night_verify=$(git -C "$dir" show "$db:.night-verify" 2>/dev/null || true)
  [ -z "$night_verify" ] && { echo "non-dichiarate"; return; }
  while IFS= read -r cmd; do
    cmd="${cmd%%#*}"; [ -z "$(echo "$cmd" | tr -d '[:space:]')" ] && continue
    cmd_eseguiti=$((cmd_eseguiti+1))
    out=$( cd "$dir" && run_guarded 120 bash -c "$cmd" 2>&1 ) || v_rc=1
  done <<< "$night_verify"
  if [ "$cmd_eseguiti" -eq 0 ]; then echo "verifiche-vuote"
  elif [ "$v_rc" -eq 0 ]; then echo "verifiche-ok"
  else echo "verifiche-fallite"
  fi
}

mkrepo() {
  local tmp="$1" contenuto="$2"
  git -C "$tmp" init -q
  printf '%s' "$contenuto" > "$tmp/.night-verify"
  git -C "$tmp" add .night-verify
  git -C "$tmp" -c user.email=t@t -c user.name=t commit -q -m init
}

# stesso template esatto generato da tools/bootstrap-app.sh per ogni repo nuova
TMP1=$(mktemp -d)
mkrepo "$TMP1" "$(cat <<'EOF'
# Verifiche dichiarate del turno di notte (una riga per comando, eseguite dal morning-gate).
# Esempi: node tools/test.js · pnpm test · python3 -m pytest
# VUOTO = il gate lo dice ("il silenzio non è un verdetto"): dichiarale appena puoi.
EOF
)"
V1=$(verdetto_per "$TMP1" "master")
[ "$V1" = "verifiche-vuote" ] && ok "night-verify SOLO commenti (default bootstrap-app.sh): verifiche-vuote, non più il falso 'verifiche-ok'" \
  || ko "falso verde ancora presente: VERDICT=$V1 (atteso verifiche-vuote)"
rm -rf "$TMP1"

TMP2=$(mktemp -d)
mkrepo "$TMP2" "true"
V2=$(verdetto_per "$TMP2" "master")
[ "$V2" = "verifiche-ok" ] && ok "night-verify con un comando reale che passa: verifiche-ok" \
  || ko "caso sano rotto: VERDICT=$V2"
rm -rf "$TMP2"

TMP3=$(mktemp -d)
mkrepo "$TMP3" "false"
V3=$(verdetto_per "$TMP3" "master")
[ "$V3" = "verifiche-fallite" ] && ok "night-verify con un comando reale che fallisce: verifiche-fallite" \
  || ko "caso fallito rotto: VERDICT=$V3"
rm -rf "$TMP3"

TMP4=$(mktemp -d)
git -C "$TMP4" init -q
git -C "$TMP4" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
V4=$(verdetto_per "$TMP4" "master")
[ "$V4" = "non-dichiarate" ] && ok "nessun file .night-verify: non-dichiarate (invariato)" \
  || ko "caso file assente rotto: VERDICT=$V4"
rm -rf "$TMP4"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
