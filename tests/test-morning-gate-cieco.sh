#!/bin/bash
# test-morning-gate-cieco.sh — il gate del mattino con gli occhi chiusi (test del
# sistema completo 2026-09-20, D7 e D8). Due difetti riprodotti prima della cura:
#   D7: senza `gh` (assente o non autenticato) il gate scriveva «0 PR notturne aperte —
#       Nessuna. Il sistema ha lavorato o non aveva coda.»: il silenzio era un verdetto,
#       esattamente il caso che il file dichiara di combattere.
#   D8: la sezione «Diff:» del report era SEMPRE vuota al primo passaggio: il diff --stat
#       girava prima che il ramo della PR esistesse in locale (checkout dopo).
# Il gate gira INTERO su un repo scratch: gh e' uno stub (una volta rotto, una volta che
# risponde dal file), HOME e le metriche sono in quarantena, il banco e' spento
# (ADVERSARY=none: nessun cervello nella suite).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$HERE/night-shift/morning-gate.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SB=$(mktemp -d /tmp/gate-cieco.XXXXXX)
trap 'rm -rf "$SB"' EXIT
export HOME="$SB/home"; mkdir -p "$HOME/night-shift-work" "$SB/bin"
export HUB_METRICS="$SB/gate.csv"     # mai la metrica viva dell'hub (E-032)

# il repo del campo: main + una PR night/* che cambia un file
SRC="$SB/src"; mkdir -p "$SRC"
git -C "$SRC" init -q -b main
printf 'function somma(a,b){ return a+b; }\n' > "$SRC/calc.js"
printf '# verifiche\nnode --check calc.js\n' > "$SRC/.night-verify"
git -C "$SRC" add -A && git -C "$SRC" -c user.name=t -c user.email=t@t commit -qm base
git -C "$SRC" checkout -q -b night/issue-7
printf 'function somma(a,b){ return a+b; } // commento\n' > "$SRC/calc.js"
git -C "$SRC" -c user.name=t -c user.email=t@t commit -qam "night: fix"
git -C "$SRC" checkout -q main
# la copia di lavoro del gate: clone con origin/HEAD noto (come sul Mac)
git clone -q "$SRC" "$HOME/night-shift-work/repo-t3" && git -C "$HOME/night-shift-work/repo-t3" remote set-head origin -a >/dev/null

# --- D7: gh ROTTO (assente o non autenticato) ---------------------------------
printf '#!/bin/bash\necho "gh: not logged in" >&2\nexit 4\n' > "$SB/bin/gh"; chmod +x "$SB/bin/gh"
OUT=$(PATH="$SB/bin:$PATH" ADVERSARY=none bash "$GATE" sandbox/repo-t3 2>&1)
REPORT="$HOME/morning-gate-report.md"
[ -f "$REPORT" ] && ok "D7: il report esiste anche con gh rotto" || { ko "D7: nessun report"; echo "$OUT" | tail -3; }
grep -q "Nessuna. Il sistema ha lavorato" "$REPORT" 2>/dev/null \
  && ko "D7: gh rotto e il report dice «Nessuna. Il sistema ha lavorato o non aveva coda»: il silenzio e' un verdetto" \
  || ok "D7: gh rotto NON viene raccontato come coda vuota"
grep -q "gate CIECO" "$REPORT" 2>/dev/null \
  && ok "D7: il report dichiara il gate CIECO (gh non ha risposto)" \
  || ko "D7: il report non dichiara che il gate non vedeva: $(grep -A1 'PR notturne' "$REPORT" | tr '\n' ' ')"
grep -q "gate-cieco" "$HUB_METRICS" 2>/dev/null \
  && ok "D7: la memoria (metrics) registra gate-cieco, non una notte vuota" \
  || ko "D7: nessuna riga gate-cieco in metrics: $(cat "$HUB_METRICS" 2>/dev/null | tail -1)"

# --- D8: gh che RISPONDE (stub dal file): la sezione Diff deve avere il file --------
cat > "$SB/bin/gh" <<'EOF'
#!/bin/bash
case "$1 $2" in
  "pr list") printf '[{"number":7,"headRefName":"night/issue-7","title":"night: fix","mergeable":"MERGEABLE"}]\n' ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$SB/bin/gh"
OUT=$(PATH="$SB/bin:$PATH" ADVERSARY=none bash "$GATE" sandbox/repo-t3 2>&1)
grep -q "PR #7" "$REPORT" && ok "D8: la PR #7 e' nel report" || { ko "D8: PR #7 assente dal report"; echo "$OUT" | tail -3; }
DIFF_RIGA=$(awk '/^\*\*Diff:\*\*/{getline; print}' "$REPORT")
echo "$DIFF_RIGA" | grep -q "calc.js" \
  && ok "D8: la sezione Diff mostra il file cambiato (calc.js)" \
  || ko "D8: la sezione Diff e' vuota al primo passaggio (riga dopo Diff: '$DIFF_RIGA')"
grep -q "verifiche-ok" "$HUB_METRICS" && ok "D8: le verifiche dichiarate girano sul ramo della PR (verifiche-ok)" \
  || ko "D8: verdetto atteso verifiche-ok, metrics: $(tail -1 "$HUB_METRICS")"

# --- D40 (giro 28, 2026-09-20): il gate spogliava la riga con ${cmd%%#*} — un `#` fra virgolette
# (grep -qv "^#" file) veniva troncato in un comando rotto: ROSSO al gate, VERDE al turno e al
# censore che la riga la passano intera a bash -c. Tre lettori, un contratto.
aggiorna_verify() { # $1 = contenuto di .night-verify su main
  printf '%s\n' "$1" > "$SRC/.night-verify"
  git -C "$SRC" -c user.name=t -c user.email=t@t commit -qam "verify" && git -C "$HOME/night-shift-work/repo-t3" fetch -q origin
}
aggiorna_verify 'grep -qv "^#" calc.js'
OUT=$(PATH="$SB/bin:$PATH" ADVERSARY=none bash "$GATE" sandbox/repo-t3 2>&1)
tail -1 "$HUB_METRICS" | grep -q "verifiche-ok" \
  && ok "D40: una riga con # fra virgolette passa intera a bash -c (verifiche-ok, come turno e censore)" \
  || ko "D40: riga troncata al # — verdetto $(tail -1 "$HUB_METRICS" | cut -d, -f5): $(grep -A1 'grep -qv' "$REPORT" | tail -1 | cut -c1-90)"

# --- D41 (giro 28): l'output di una verifica rossa finiva nel report e nella proposta di issue
# SENZA maschera — solo il banco avversariale passava da mask_secrets («Mask, don't omit»).
# il segreto sta nell'OUTPUT (base64 nel comando: la riga di .night-verify e' pubblica nel repo,
# non e' lei il segreto — e il gate la stampa com'e')
aggiorna_verify "echo $(printf 'token=SEGRETO123\n' | base64) | base64 -d; exit 1"
OUT=$(PATH="$SB/bin:$PATH" ADVERSARY=none bash "$GATE" sandbox/repo-t3 2>&1)
if grep -q "SEGRETO123" "$REPORT"; then
  ko "D41: il valore del token e' nel report del gate in chiaro ($(grep -c SEGRETO123 "$REPORT") volte)"
else
  grep -q "MASCHERATO" "$REPORT" && ok "D41: l'output della verifica rossa e' mascherato nel report e nella proposta di issue" \
    || ko "D41: ne' il valore ne' la maschera nel report: l'output e' stato OMESSO (mask, don't omit)"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
