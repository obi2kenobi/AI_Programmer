#!/bin/bash
# test-catena-viva.sh — LA PROVA DEL FUOCO (2026-09-20, Luca: «fai test fino a che
# non funziona, poi altri 100 test per capire se funziona davvero»).
# La catena INTERA, deterministica, in sandbox: censimento vede il debito →
# caccia-miglioria lo prende → TRASFORMATORE applica cattura-prima → gate passa →
# sito marcato SALDATO → il censore (stub) delibera APPROVA sul diff → il censimento
# SCENDE e il delta lo dice. Nessun Ollama per il meccanico; il censore e' stub
# per ruolo. Se questa catena e' verde, il sistema consegna.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SB=$(mktemp -d /tmp/catena.XXXXXX)
trap 'rm -rf "$SB" "$GHDIR" "$STUBC"' EXIT
export GHDIR=$(mktemp -d) STUBC=$(mktemp)

# ── il repo del campo: un debito E-002 e un bug ─────────────────────────────────
mkdir -p "$SB/tools"
PDQ="| gre""p -q"   # esemplare a pezzi: il guardiano dei tubi legge il sorgente
printf '#!/bin/bash\nset -uo pipefail\nif echo "$ORDINE" %s consegnato; then\n  echo si\nfi\n' "$PDQ" > "$SB/tools/vendite.sh"
# le verifiche dichiarate vivono sul ramo di DEFAULT (D1, 2026-09-20): il censore le
# legge da li', e una PR che le tocca viene rinviata — prima la fixture le metteva sul
# ramo notte, esattamente la forma che il censore ora rifiuta
printf '# Verifiche dichiarate\nbash -n tools/vendite.sh\n' > "$SB/.night-verify"
git -C "$SB" init -q -b main && git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm base

# ── 1. il censimento VEDE il debito ────────────────────────────────────────────
bash "$HERE/tools/caccia-registro.sh" --prossimo "$SB" | grep -c "E-002|tools/vendite.sh:3" >/dev/null \
  && ok "1. censimento: il debito è in coda (E-002|tools/vendite.sh:3)" \
  || ko "1. censimento non vede il debito"

# baseline del censimento (il delta dopo la caccia ha bisogno di un PRIMA)
bash "$HERE/tools/caccia-registro.sh" "$SB" >/dev/null 2>&1

# ── 2. la caccia lo prende e il TRASFORMATORE lo salda (nessun modello) ─────────
OUT=$(cd "$SB" && bash "$HERE/night-shift/caccia-miglioria.sh" "$SB" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "2. caccia-miglioria: rc 0 — miglioria consegnata" || ko "2. caccia rc=$RC: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
grep -q '_cp=$(echo "$ORDINE")' "$SB/tools/vendite.sh" && grep -q '<<<"$_cp"' "$SB/tools/vendite.sh" \
  && ok "3. trasformatore: cattura-prima applicata alla riga esatta" || ko "3. forma sbagliata: $(grep -n _cp "$SB/tools/vendite.sh" | head -1)"
bash -n "$SB/tools/vendite.sh" && ok "4. sintassi del file trasformato" || ko "4. sintassi rotta"

# ── 3. il gate ha già ragionato (rc 0 = gate passato): diff entro budget ────────
RIGHE=$(git -C "$SB" diff --numstat | awk '{a+=$1+$2} END{print a+0}')
[ "$RIGHE" -le 40 ] && ok "5. gate: diff $RIGHE righe (≤40)" || ko "5. diff $RIGHE"
grep -q "tools/vendite.sh:3" "$SB/.git/caccia-registro/saldati" \
  && ok "6. il sito è nei SALDATI (esce dalla coda)" || ko "6. sito non saldato"

# ── 4. il censimento SCENDE e il delta lo urla ─────────────────────────────────
OUT=$(bash "$HERE/tools/caccia-registro.sh" "$SB" 2>&1)
grep -q "tot=0" <<<"$OUT" && ok "7. censimento dopo: debito a zero" || ko "7. censimento non sceso: $OUT"
grep -q "debito sceso" <<<"$OUT" && ok "8. il delta urla: 'debito sceso'" || ko "8. delta muto: $OUT"

# ── 5. il CENSORE delibera sul diff (guardie + prove + verdetto) ────────────────
# la miglioria committata su un ramo night/ VERO: il censore ci fa checkout
git -C "$SB" checkout -q -b night/caccia-test
# (T6#1): il commit della PR ha l'eta' della PR — la quarantena del censore conta anche il commit
QUANDO=$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(minutes=30)).isoformat())")
git -C "$SB" add -A && GIT_COMMITTER_DATE="$QUANDO" GIT_AUTHOR_DATE="$QUANDO" git -C "$SB" -c user.name=t -c user.email=t@t commit -qm "improve: test" >/dev/null
git -C "$SB" checkout -q main
printf '#!/bin/bash\nif [ "$1" = "pr" ] && [ "$2" = "view" ]; then cat "$GHDIR_JSON"; fi\nexit 0\n' > "$GHDIR/gh"; chmod +x "$GHDIR/gh"
export GHDIR_JSON="$GHDIR/pr.json"
# (2026-09-23, T5#1): il censore esegue le prove solo in sandbox-exec; qui un finto che esegue il resto
# (la sandbox vera si prova in tests/test-revisore.sh; questa catena prova il flusso)
printf '#!/bin/bash\nshift 2; exec "$@"\n' > "$GHDIR/sandbox-exec"; chmod +x "$GHDIR/sandbox-exec"
python3 - "$(git -C "$SB" rev-parse night/caccia-test)" > "$GHDIR_JSON" <<'PY'
import json, sys
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 9, "title": "caccia: miglioria al codice dall'agente notturno",
  "headRefName": "night/caccia-test", "headRefOid": sys.argv[1], "isDraft": True, "state": "OPEN",
  "createdAt": (datetime.now(timezone.utc)-timedelta(minutes=40)).isoformat()}))
PY
# stub censore per ruolo (il modello unico non si distingue per nome)
cat > "$STUBC" <<'STUBEOF'
#!/bin/bash
M="$1"; shift; P=$(cat)
case "$P" in
  *"LENTE SICUREZZA"*) printf '{"sicuro":true,"rilievi":[]}\n' ;;  # D2: la lente fra le prove del censore
  *SMASCHERA*) printf '%s\n' '```' 'grep -c _cp tools/vendite.sh' '```' ;;
  *CENSORE*) printf '{"verdetto":"APPROVA","rischio":"basso","motivi":["conversione meccanica, comportamento identico"]}\n' ;;
esac
STUBEOF
chmod +x "$STUBC"
OUT=$(cd "$SB" && PATH="$GHDIR:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUBC" bash "$HERE/night-shift/revisore.sh" "$SB" 9 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "APPROVA" <<<"$OUT" \
  && ok "9. censore: guardie, banco e verdetto — APPROVA (deliberazione DRY)" \
  || ko "9. censore rc=$RC: $(echo "$OUT" | tail -2 | tr '\n' ' ')"

# ── 6. il rinvio onesto: forma ignota → agente muto → rinvii, il sito NON riproposto ──
SB2=$(mktemp -d /tmp/catena2.XXXXXX); mkdir -p "$SB2/tools"
printf '#!/bin/bash\nzzz_strana_forma %s x\n' "$PDQ" > "$SB2/tools/strano.sh"
git -C "$SB2" init -q -b main && git -C "$SB2" add -A && git -C "$SB2" -c user.name=t -c user.email=t@t commit -qm b
STUBMUTO=$(mktemp); printf '#!/bin/bash\nexit 0\n' > "$STUBMUTO"; chmod +x "$STUBMUTO"
OUT=$(cd "$SB2" && MIGLIORIA_AGENT="$STUBMUTO" bash "$HERE/night-shift/caccia-miglioria.sh" "$SB2" 2>&1); RC=$?
[ "$RC" -eq 1 ] && grep -q "strano.sh:2" "$SB2/.git/caccia-registro/rinviati" \
  && ok "10. forma ignota: rinviata onesta (un colpo solo)" || ko "10. rinvio rotto: rc=$RC"
PROSS=$(bash "$HERE/tools/caccia-registro.sh" --prossimo "$SB2" 2>/dev/null)
case "$PROSS" in *"strano.sh:2"*) ko "11. il rinvio viene riproposto!";; *) ok "11. il censimento passa oltre il rinviato";; esac
rm -rf "$SB2" "$STUBMUTO"

echo ""
echo "$PASS OK, $FAIL FAIL — la catena: $([ $FAIL -eq 0 ] && echo VIVA ✓ || echo ROTTA)"
[ $FAIL -eq 0 ]
