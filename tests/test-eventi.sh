#!/bin/bash
# test-eventi.sh — il guardiano del catalogo eventi (studio deepseek-harness,
# 2026-09-23: una firma senza consumatori e' un contatore cieco — audit-2
# l'ha dimostrato col funnel: DELIBERA: contava zero da sempre).
#
# Il catalogo docs/eventi.md e' generato dal codice reale. Il guardiano
# verifica che sia ANCORA vero: ogni produttore contiene la firma, ogni
# consumatore esiste, e nessuna firma e' rimasta orfana per sbaglio
# (le orfane dichiarate con "log" sono consumite dal battito: legittime).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$HERE/docs/eventi.md" ] || { echo "FAIL catalogo assente"; exit 1; }
N=0; ORFANE=0
while IFS='|' read -r _scarta _firma _prod _cons _guard; do
  FIRMA=$(echo "$_firma" | tr -d '\`' | sed 's/^ *//;s/ *$//')
  PROD=$(echo "$_prod" | tr -d '\`' | sed 's/^ *//;s/ *$//')
  CONS=$(echo "$_cons" | tr -d '\`' | sed 's/^ *//;s/ *$//')
  [ -z "$FIRMA" ] && continue
  case "$FIRMA" in Firma*|---*) continue ;; esac
  N=$((N+1))
  PAT=$(printf '%s' "$FIRMA" | cut -c1-18)

  # ogni produttore dichiarato deve contenere la firma
  OLDIFS=$IFS; IFS=','
  for P in $PROD; do
    IFS=$OLDIFS; P=$(echo "$P" | sed 's/^ *//;s/ *$//')
    [ -f "$HERE/$P" ] || ko "#$N produttore inesistente: $P"
    grep -qF "$PAT" "$HERE/$P" 2>/dev/null || ko "#$N produttore $P non contiene '$PAT'"
    IFS=','; done; IFS=$OLDIFS

  # ogni consumatore dichiarato deve esistere (il file basta: il catalogo
  # e' generato dal reale, se un consumatore sparisce il test del file becca)
  OLDIFS=$IFS; IFS=','
  for C in $CONS; do
    IFS=$OLDIFS; C=$(echo "$C" | sed 's/^ *//;s/ *$//')
    case "$C" in *console.log*|*battito*) continue ;; esac
    [ -f "$HERE/$C" ] || ko "#$N consumatore inesistente: $C"
    # (2026-09-24, quinto ventaglio, R4 R6): bastava che il FILE esistesse — cervello-impara cercava «registro:
    # debiti» e il produttore scrive «registro: debito famiglie»: una firma morta dalla nascita, e verde
    grep -qF "$PAT" "$HERE/$C" 2>/dev/null || ko "#$N consumatore $C non cerca '$PAT'"
    IFS=','; done; IFS=$OLDIFS

  # orfane: "⚠ NESSUNO" = firma che nessuno legge — conteggiata e dichiarata
  case "$CONS" in *NESSUNO*) ORFANE=$((ORFANE+1)) ;; esac
done < <(grep '^| `' "$HERE/docs/eventi.md")

# (R4 R6): le firme nate il 24/9 non erano nel catalogo, e il guardiano restava verde
for F in 'coda ILLEGGIBILE' '⛔ MANCA' 'SENTINELLA' 'rianima_ollama: esito' 'SFORO DEL BUDGET'; do
  grep -qF "| \`$F" "$HERE/docs/eventi.md" || ko "R4 R6: la firma «${F}» non e' nel catalogo"
done
# (2026-09-24, quinto ventaglio, R4 R6 — il censimento inverso): ogni riga «⚠»/«⛔» che il turno scrive nel log ha
# una riga nel catalogo, o e' dichiarata fra quelle che legge solo il battito (una persona che guarda il log).
# La chiave e' il primo tratto letterale di almeno 8 caratteri dopo il simbolo, fino a «(», e al piu' 18.
# Una riga nuova senza dichiarazione e' un contatore cieco in potenza: rosso.
NONDETTE=$(python3 - "$HERE/night-shift/night-shift.sh" "$HERE/docs/eventi.md" <<'PY'
import re, sys
cat = open(sys.argv[2], encoding="utf-8").read()
for i, l in enumerate(open(sys.argv[1], encoding="utf-8"), 1):
    if l.lstrip().startswith("#"):
        continue
    m = re.search(r'log "([^"]*[⚠⛔][^"]*)', l)
    if not m:
        continue
    s = m.group(1)
    s = s[max(s.rfind("⚠"), s.rfind("⛔")) + 1:].split("(")[0]
    parti = re.split(r"\$\([^)]*\)?|\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*", s)
    k = next((p.strip(" :—-$") for p in parti if len(p.strip(" :—-$")) >= 8), "")[:18].strip()
    if k and k not in cat:
        print(f"night-shift.sh:{i} «{k}»")
PY
)
[ -z "$NONDETTE" ] && ok "R4 R6: ogni riga ⚠/⛔ del turno e' nel catalogo o dichiarata letta dal battito" \
  || ko "R4 R6: righe ⚠/⛔ del turno non dichiarate nel catalogo: $(tr '\n' ' ' <<<"$NONDETTE")"
[ "$N" -ge 25 ] && ok "$N firme nel catalogo, produttori e consumatori verificati" || ko "solo $N firme"
[ "$ORFANE" -le 2 ] && ok "orfane dichiarate: $ORFANE (tolleranza 2: battito del log)" || ko "troppe firme orfane: $ORFANE — qualcuna e' un contatore cieco"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
