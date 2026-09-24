#!/bin/bash
# test-mutation-atomico.sh — nato dalla SECONDA troncatura di giri-ignoranti.sh
# (283 righe → 2, 2026-09-19 e poi 2026-09-21): un kill durante il banco di
# mutazione lasciava il tool monco, perche' il cp di ripristino non era atomico
# e non c'era trap. Il banco e' il tool che SPENGE i tool: se lui sporca l'albero,
# il danno e' silenzioso e lo scopre la notte dopo.
#
# Prova su un fixture minimale (repo git + 1 tool + 1 test che DORME: la
# mutazione e' certamente viva quando arriva il kill):
#   A. SIGKILL a meta' mutazione  → il tool o è l'originale o è il payload
#      ESATTO di due righe — mai byte a meta' (atomicita' del mv)
#   B. SIGTERM a meta' mutazione  → il tool è l'originale (il trap ripristina)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d /tmp/mutation-atomico.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# fixture: mini-repo con git, un tool e un test che dorme 30s quando il tool e' mutato
git init -q "$TMP/repo"
mkdir -p "$TMP/repo/tools" "$TMP/repo/tests"
printf '#!/bin/bash\necho "sono il tool foo, riga 3"\n' > "$TMP/repo/tools/foo.sh"
chmod +x "$TMP/repo/tools/foo.sh"
# (Q32, 2026-09-23): il banco di mutazione ora esegue ogni test PRIMA col tool intatto (un banco gia'
# rosso non prova niente): il test passa subito col tool sano e dorme solo col tool mutato
printf '#!/bin/bash\ngrep -q "riga 3" "$(dirname "$0")/../tools/foo.sh" && exit 0\nsleep 30\nexit 1\n' > "$TMP/repo/tests/test-foo.sh"
cp "$HERE/tools/mutation-tests.sh" "$TMP/repo/tools/"
git -C "$TMP/repo" add -A && git -C "$TMP/repo" commit -qm base
ORIG=$(cat "$TMP/repo/tools/foo.sh")
PAYLOAD=$(printf '#!/bin/bash\nexit 0\n')   # $(...) strippa il newline finale: come ATTUALE

# ── A. SIGKILL: il peggiore dei casi ────────────────────────────────────────
( cd "$TMP/repo" && exec bash tools/mutation-tests.sh ) >/dev/null 2>&1 &
PID=$!
sleep 3   # il banco ha gia' mutato foo.sh: test-foo dorme 30s
# (revisione 10 giri, 2026-09-23): «integro» era accettato anche se la mutazione NON era mai
# avvenuta (il banco sostituito da `exit 0` passava A, B e C). Prima del colpo, la mutazione
# dev'essere IN CORSO — altrimenti la prova e' vuota, non verde.
[ "$(cat "$TMP/repo/tools/foo.sh")" = "$PAYLOAD" ] && ok "A: la mutazione e' in corso al momento del colpo (prova non vuota)" \
  || ko "A: al colpo foo.sh non era mutato — la prova di atomicita' sarebbe vuota"
kill -KILL "$PID" 2>/dev/null
pkill -KILL -P "$PID" 2>/dev/null
wait "$PID" 2>/dev/null
sleep 1
ATTUALE=$(cat "$TMP/repo/tools/foo.sh")
if [ "$ATTUALE" = "$ORIG" ] || [ "$ATTUALE" = "$PAYLOAD" ]; then
  ok "A: SIGKILL a meta' mutazione — il tool e' integro o esattamente neutralizzato (mai troncato)"
else
  ko "A: SIGKILL ha lasciato il tool monco: $(echo "$ATTUALE" | wc -l | tr -d ' ') righe su $(echo "$ORIG" | wc -l | tr -d ' ') dell'originale — atomicita' rotta"
fi
# ripulisco il possibile neutralizzato per la prova B
printf '#!/bin/bash\necho "sono il tool foo, riga 3"\n' > "$TMP/repo/tools/foo.sh"
chmod +x "$TMP/repo/tools/foo.sh"
git -C "$TMP/repo" checkout -q -- tools/foo.sh 2>/dev/null || true

# ── B. SIGTERM: il caso gentile, il trap deve ripristinare ──────────────────
( cd "$TMP/repo" && exec bash tools/mutation-tests.sh ) >/dev/null 2>&1 &
PID=$!
sleep 3
[ "$(cat "$TMP/repo/tools/foo.sh")" = "$PAYLOAD" ] && ok "B: la mutazione e' in corso al momento del colpo (prova non vuota)" \
  || ko "B: al colpo foo.sh non era mutato — la prova del trap sarebbe vuota"
kill -TERM "$PID" 2>/dev/null
wait "$PID" 2>/dev/null
sleep 1
ATTUALE=$(cat "$TMP/repo/tools/foo.sh")
if [ "$ATTUALE" = "$ORIG" ]; then
  ok "B: SIGTERM a meta' mutazione — il trap ha ripristinato l'originale"
else
  ko "B: SIGTERM ha lasciato il tool sporco (payload o monco): il trap non ripristina"
fi
# il banco deve anche lasciare l'albero senza file temporanei .mut/.rest
if ! ls "$TMP/repo/tools/" | grep -q "foo.sh.mut\|foo.sh.rest"; then
  ok "nessun file temporaneo .mut/.rest abbandonato"
else
  ko "file temporaneo .mut/.rest abbandonato in tools/"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
