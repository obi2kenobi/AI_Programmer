#!/bin/bash
# test-dashboard.sh — la finestra di osservazione sotto prova (E-028: era committata
# senza compilare e senza test; il processo vivo in memoria mascherava il danno).
# Prova la LOGICA (stats) con un log finto a casi noti: i conteggi di oggi, le
# verifiche rosse SOLO dell'ultimo ciclo, il feed recente.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DASH="$HERE/tools/dashboard.py"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

python3 -c "compile(open('$DASH').read(),'dashboard.py','exec')" && ok "compila (E-028: prima non compilava)" || { ko "non compila"; exit 1; }

OGGI=$(date '+%Y-%m-%d')
TMP=$(mktemp -d /tmp/test-dashboard.XXXXXX); trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/finto.log" <<EOF
[$OGGI 10:00:00] === TURNO INIZIATO (1 repo in coda) ===
[$OGGI 10:01:00] REPO r/x: VERIFICA ROSSA: shellcheck (VECCHIA — deve sparire)
[$OGGI 10:02:00] REPO r/x: auto-fix: indice SAL rigenerato
[$OGGI 10:05:00] === TURNO INIZIATO (1 repo in coda) ===
[$OGGI 10:06:00] REPO r/x: PR di caccia → https://github.com/r/x/pull/9
[$OGGI 10:07:00] REPO r/x: VERIFICA ROSSA: suite (NUOVA — deve restare)
[$OGGI 10:08:00] ⛔ ERRORE generico
EOF

VER=$(NIGHT_LOG="$TMP/finto.log" python3 - "$DASH" <<'PY'
import sys, os
sys.path.insert(0, os.path.dirname(sys.argv[1]))
import importlib.util
spec = importlib.util.spec_from_file_location("dash", sys.argv[1])
dash = importlib.util.module_from_spec(spec); spec.loader.exec_module(dash)
s = dash.stats()
campi = {k: s[k] for k in ("cicli","tot","pr","fix","errori")}
print(campi["cicli"], campi["tot"], campi["pr"], campi["fix"], campi["errori"], len(s["verifiche"]), s["verifiche"])
PY
)
# atteso: 2 cicli oggi, 2 turni totali, 1 PR, 1 fix, 1 errore, 1 verifica rossa
# (solo quella DOPO l'ultimo TURNO INIZIATO; la vecchia deve sparire)
[ "$(echo "$VER" | awk '{print $1}')" = "2" ] && ok "cicli oggi = 2" || ko "cicli oggi: $(echo "$VER" | awk '{print $1}') (atteso 2)"
[ "$(echo "$VER" | awk '{print $2}')" = "2" ] && ok "cicli totali = 2" || ko "tot: $(echo "$VER" | awk '{print $2}')"
[ "$(echo "$VER" | awk '{print $3}')" = "1" ] && ok "PR oggi = 1" || ko "PR: $(echo "$VER" | awk '{print $3}')"
[ "$(echo "$VER" | awk '{print $4}')" = "1" ] && ok "fix oggi = 1" || ko "fix: $(echo "$VER" | awk '{print $4}')"
[ "$(echo "$VER" | awk '{print $5}')" = "1" ] && ok "errori oggi = 1" || ko "errori: $(echo "$VER" | awk '{print $5}')"
NRO=$(echo "$VER" | tail -1 | grep -o "VERIFICA ROSSA" | wc -l | tr -d ' ')
[ "$NRO" = "1" ] && ok "solo la verifica rossa dell'ULTIMO ciclo (v3)" || ko "verifiche rosse contate: $NRO (atteso 1)"
echo "$VER" | tail -1 | grep -q "NUOVA" && ok "restata la rossa nuova" || ko "restata la rossa sbagliata"
echo "$VER" | tail -1 | grep -q "VECCHIA" && ko "la rossa del ciclo vecchio non sparisce" || ok "sparita la rossa del ciclo vecchio"

# la pagina si costruisce con i numeri veri e cita le sezioni
PAG=$(NIGHT_LOG="$TMP/finto.log" python3 - "$DASH" <<'PY'
import sys, os
sys.path.insert(0, os.path.dirname(sys.argv[1]))
import importlib.util
spec = importlib.util.spec_from_file_location("dash", sys.argv[1])
dash = importlib.util.module_from_spec(spec); spec.loader.exec_module(dash)
print(dash.page(dash.stats()))
PY
)
echo "$PAG" | grep -q "CICLI OGGI" && ok "pagina: cards presenti" || ko "pagina senza cards"
echo "$PAG" | grep -q "Attività" && ok "pagina: feed attività" || ko "pagina senza attività"
echo "$PAG" | grep -q "NUOVA" && ok "pagina: la rossa corrente visibile" || ko "la rossa corrente non appare in pagina"

# ── v4: il FUNNEL conta gli stadi dalle righe firmate ──────────────────────────
# (D19, test del sistema completo 2026-09-20): questo blocco stava DOPO il cancello finale
# (il verdetto del test era quello dell'ultima riga, non della somma) e chiamava un
# `--stats` che non esisteva: partiva il server e il test restava appeso. Ora --stats
# esiste, e il cancello e' l'ultima riga.
OGGI4=$(date '+%Y-%m-%d')
{
  echo "[$OGGI4 10:00:00] === TURNO INIZIATO (1 repo in coda) ==="
  echo "[$OGGI4 10:01:00] REPO r/x: nessuna issue — attivo la CACCIA"
  echo "[$OGGI4 10:02:00] REPO r/x: debito: applicato dal TRASFORMATORE deterministico"
  echo "[$OGGI4 10:03:00] REPO r/x: caccia: sana e nessuna miglioria trovata"
  echo "[$OGGI4 10:04:00] REPO r/x: caccia: AGENTE FALLITO (Ollama?)"
  echo "[$OGGI4 10:05:00] REPO r/x: gate BOCCIA: 516 righe"
  echo "[$OGGI4 10:06:00] REPO r/x: MIGLIORIA pronta: [debito] f"
  echo "[$OGGI4 10:07:00] REPO r/x: commit/push della miglioria fallito — ripristino"
  echo "[$OGGI4 10:08:00] REPO r/x: DELIBERA: APPROVA PR #7"
  echo "[$OGGI4 10:09:00] REPO r/x: DELIBERA: RIGETTA PR #8"
  echo "[$OGGI4 10:10:00] Ollama wedged al via del turno"
  echo "[$OGGI4 10:11:00] Ollama rianimato dal watchdog del turno"
  echo "[$OGGI4 10:12:00] REPO repo-x: standard: DIVERGENTE dall'hub"
} > "$TMP/finto4.log"
V4=$(NIGHT_LOG="$TMP/finto4.log" timeout 20 python3 "$DASH" --stats 2>/dev/null | python3 -c '
import sys, json
s = json.load(sys.stdin); f = s["funnel"]
print(f["finestre"], f["trasformatore"], f["agente_ok"], f["agente_morto"], f["gate"], f["consegne"], f["push_fail"], f["approvate"], f["rigettate"], s["ollama_wedge"], s["ollama_revive"], s["drift"].get("repo-x", "?"))')
ATTESO4="1 1 1 1 1 1 1 1 1 1 1 DIVERGENTE"
[ "$V4" = "$ATTESO4" ] && ok "v4 funnel: tutti gli stadi contati dal log firmato (via --stats, che ora esiste e termina)" || ko "v4 funnel: [$V4] atteso [$ATTESO4]"

# (D18): niente finestra di 4000 righe — un log lungo di OGGI si conta tutto
python3 - "$OGGI4" > "$TMP/lungo.log" <<'PY'
import sys
oggi = sys.argv[1]
print(f"[{oggi} 00:00:01] === TURNO INIZIATO (1 repo in coda) ===")
for i in range(4500):
    print(f"[{oggi} 01:{(i//60)%60:02d}:{i%60:02d}] REPO r/x: nessuna issue — attivo la CACCIA")
PY
FIN=$(NIGHT_LOG="$TMP/lungo.log" timeout 20 python3 "$DASH" --stats 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["funnel"]["finestre"])')
[ "$FIN" = "4500" ] && ok "D18: 4500 finestre in un log di 4501 righe → 4500 contate (nessuna finestra che sottostima)" \
  || ko "D18: finestre contate $FIN su 4500 (la dashboard legge solo una coda del log)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
