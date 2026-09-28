#!/bin/bash
# test-bilancino.sh — la riga di conto della notte (2026-09-28): quel che c'e' nel
# log e' quel che e' successo; la riga di oggi si RISCRIVE senza duplicati; i repo
# con lo stesso prefisso non si contano insieme; niente log = niente riga (rc 3).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BIL="$HERE/tools/bilancino.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$BIL" && ok "sintassi" || { ko "sintassi"; exit 1; }

RADICE=$(mktemp -d /tmp/test-bilancino.XXXXXX)
trap 'rm -rf "$RADICE"' EXIT
cat > "$RADICE/log" <<'EOF'
[2026-09-27 23:00:00] REPO pippo/alpha: ===== REPO pippo/alpha (commit: docs) =====
[2026-09-27 23:01:00] REPO pippo/alpha: verifica VERDE in 12s
[2026-09-27 23:02:00] REPO pippo/alpha: VERIFICA ROSSA — il banco dice no
[2026-09-27 23:05:00] REPO pippo/alpha: 🎯 MIGLIORIA pronta (45s GPU): [docs] tools/x.sh
[2026-09-27 23:06:00] REPO pippo/alpha: PR di miglioria → https://github.com/p/alpha/pull/9
[2026-09-27 23:30:00] REPO pippo/alpha: ✅ censore ha DELIBERATO il merge: PR #9
[2026-09-27 23:31:00] REPO pippo/alpha: ===== REPO pippo/alpha (commit: docs) =====
[2026-09-27 23:40:00] REPO pippo/alphabeta: ===== REPO pippo/alphabeta (commit: feat) =====
[2026-09-27 23:41:00] REPO pippo/alphabeta: ✅ censore ha DELIBERATO il merge: PR #99
[2026-09-27 23:50:00] impara: lezione proposta → cervello/lezione-x.md (da approvare al mattino)
EOF

# 1. i conti del giorno, letti dal log vero
OUT=$(BILANCINO_CSV="$RADICE/funnel.csv" BILANCINO_WORK="$RADICE/work" BILANCINO_DATA=2026-09-27 \
  BILANCINO_LOG_EXTRA="$RADICE/log" bash "$BIL" pippo/alpha 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "^bilancino: " <<<"$OUT" && ok "rc 0 con la firma bilancino:" || ko "rc $RC: $OUT"
RIGA=$(grep '^2026-09-27,alpha,' "$RADICE/funnel.csv")
[ "$RIGA" = "2026-09-27,alpha,2,1,1,1,1,0,0,45,0,1" ] && ok "i numeri veri: $RIGA" || ko "riga: $RIGA"

# 2. l'upsert: una fusione in piu' → la riga si SOSTITUISCE, il CSV non cresce di righe di oggi
echo "[2026-09-27 23:59:00] REPO pippo/alpha: ✅ censore ha DELIBERATO il merge: PR #10" >> "$RADICE/log"
BILANCINO_CSV="$RADICE/funnel.csv" BILANCINO_WORK="$RADICE/work" BILANCINO_DATA=2026-09-27 \
  BILANCINO_LOG_EXTRA="$RADICE/log" bash "$BIL" alpha >/dev/null 2>&1
N_OGGI=$(grep -c '^2026-09-27,alpha,' "$RADICE/funnel.csv")
[ "$N_OGGI" -eq 1 ] && grep -q ',2,1,1,1,2,' "$RADICE/funnel.csv" && ok "upsert: riga unica aggiornata (fuse=2)" || ko "righe di oggi: $N_OGGI"

# 3. il vicino col nome simile non si conta: alphabeta ha la SUA riga, coi SUOI numeri
BILANCINO_CSV="$RADICE/funnel.csv" BILANCINO_WORK="$RADICE/work" BILANCINO_DATA=2026-09-27 \
  BILANCINO_LOG_EXTRA="$RADICE/log" bash "$BIL" pippo/alphabeta >/dev/null 2>&1
N_BETA=$(grep -c '^2026-09-27,alphabeta,' "$RADICE/funnel.csv")
[ "$N_BETA" -eq 1 ] && grep -q '^2026-09-27,alphabeta,1,0,0,0,1,' "$RADICE/funnel.csv" \
  && ok "isolamento per repo (alphabeta a parte, 1 ciclo 1 fusione)" || ko "alphabeta: $N_BETA righe"

# 4. niente log per il repo: rc 3, nessuna riga inventata
OUT=$(BILANCINO_CSV="$RADICE/funnel.csv" BILANCINO_WORK="$RADICE/work" BILANCINO_DATA=2026-09-27 \
  BILANCINO_LOG_EXTRA="$RADICE/log" bash "$BIL" gamma 2>&1); RC=$?
[ "$RC" -eq 3 ] && ! grep -q ',gamma,' "$RADICE/funnel.csv" && ok "repo senza log: rc 3, niente riga" || ko "rc $RC: $OUT"

# 5. la dashboard digerisce il CSV (e dichiara l'assenza senza errore)
python3 -c "
import os, sys
os.environ['NIGHT_FUNNEL'] = '$RADICE/funnel.csv'
sys.path.insert(0, '$HERE/tools')
import importlib.util
spec = importlib.util.spec_from_file_location('dash', '$HERE/tools/dashboard.py')
dash = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dash)
h = dash.andamento()
assert 'alpha' in h and 'fuse' in h, h
os.environ['NIGHT_FUNNEL'] = '$RADICE/inesistente.csv'
h2 = dash.andamento()
assert 'bilancino non ha ancora scritto' in h2, h2
print('ok')" && ok "dashboard: trend renderizzato e assenza dichiarata" || ko "andamento() rotta"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
