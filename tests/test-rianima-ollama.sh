#!/bin/bash
# test-rianima-ollama.sh — un solo gesto per riavviare Ollama, che chiede al custode se c'e'
# (2026-09-24, terzo ventaglio, V5 R4; pattern cuore-unico-proprietario). Prima: tre punti riavviavano il
# server. La sonda di night-shift/night-shift.sh guardava `launchctl list` e faceva kickstart al custode;
# il watchdog d'inizio ciclo dello stesso file e night-shift/agente.sh facevano `pkill -f "ollama serve"`
# e aspettavano che «launchd lo riparta», senza chiedersi se un custode esistesse. Senza custode
# l'istanza uccisa non la rialzava nessuno: «il turno gira senza cervello».
# launchctl, pkill, curl, sleep e id qui sono finti: il banco giudica la scelta, non launchd.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"
for c in launchctl pkill curl sleep id; do
  printf '#!/bin/bash\necho "%s $*" >> "%s/chiamate.log"\n' "$c" "$T" > "$T/bin/$c"
done
# (2026-10-01, E-054): anche pgrep e' finto e controllato — il banco non puo' dipendere
# da cio' che gira davvero sulla macchina (col pgrep vero, il caso custode cambiava
# esito se Ollama era acceso o spento)
printf '%s\n' '[ -n "${PGREP_SERVE:-}" ] && echo "$PGREP_SERVE" || exit 1' > "$T/bin/pgrep"; chmod +x "$T/bin/pgrep"
# shellcheck disable=SC2016
printf '%s\n' '[ "$1" = list ] && [ -n "${CUSTODE:-}" ] && printf "123\t0\t%s\n" "$CUSTODE"' 'exit 0' >> "$T/bin/launchctl"
echo 'echo 501' >> "$T/bin/id"
chmod +x "$T/bin/"*
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"
type rianima_ollama >/dev/null 2>&1 && ok "rianima_ollama e' definita in night-shift/lib.sh" \
  || { ko "rianima_ollama non esiste in night-shift/lib.sh"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }

# 1. con un custode launchd e NESSUN serve che tiene la porta: kickstart al custode, niente pkill
rm -f "$T/chiamate.log"
( PATH="$T/bin:$PATH" CUSTODE=homebrew.mxcl.ollama PGREP_SERVE='' rianima_ollama ) 2>"$T/err"; RC=$?
L=$(cat "$T/chiamate.log" 2>/dev/null)
[ $RC -eq 0 ] && grep -c 'launchctl kickstart -k gui/501/homebrew.mxcl.ollama' <<<"$L" >/dev/null && ! grep -c 'pkill' <<<"$L" >/dev/null \
  && ok "custode presente, porta libera: kickstart al custode, nessun pkill" || ko "custode presente, porta libera (rc=$RC): $L"

# 1b. (E-054, dalla notte del 30/9) custode presente MA un serve appeso tiene la porta:
# prima si toglie l'istrione, POI il kickstart — altrimenti la resurrezione muore sulla porta occupata
rm -f "$T/chiamate.log"
( PATH="$T/bin:$PATH" CUSTODE=homebrew.mxcl.ollama PGREP_SERVE=999 rianima_ollama ) 2>"$T/err2"; RC=$?
L=$(cat "$T/chiamate.log" 2>/dev/null)
ORDINE=$(grep -n 'pkill\|launchctl kickstart' <<<"$L" | head -2 | grep -oE 'pkill|launchctl kickstart' | tr '\n' ' ')
[ $RC -eq 0 ] && [ "$ORDINE" = "pkill launchctl kickstart " ] \
  && ok "E-054: serve che tiene la porta → pkill PRIMA del kickstart (ordine: $ORDINE)" || ko "E-054 ordine sbagliato (rc=$RC): $ORDINE — $L"
grep -c 'custode' "$T/err" >/dev/null && ok "la scelta e' detta (sesto patto)" || ko "rianima_ollama tace la scelta: $(cat "$T/err")"
grep -c 'rianima_ollama: esito OK' "$T/err" >/dev/null && ok "l'esito si dice (OK), non solo la scelta (R4 R3)" || ko "rianima_ollama tace l'esito: $(cat "$T/err")"

# 2. senza custode: kill del serve e istanza propria (nessun kickstart a vuoto)
rm -f "$T/chiamate.log"
( PATH="$T/bin:$PATH" CUSTODE='' rianima_ollama ) 2>/dev/null
L=$(cat "$T/chiamate.log" 2>/dev/null)
grep -c 'pkill -f ollama serve' <<<"$L" >/dev/null && ! grep -c 'kickstart' <<<"$L" >/dev/null \
  && ok "nessun custode: pkill e istanza propria, nessun kickstart" || ko "nessun custode: $L"

# 3. nessun altro punto riavvia Ollama a mano
FUORI=$(grep -n 'pkill -f "ollama serve"\|launchctl kickstart' "$HERE/night-shift/night-shift.sh" "$HERE/night-shift/agente.sh" | grep -v ':[0-9]*:[[:space:]]*#' || true)
[ -z "$FUORI" ] && ok "night-shift.sh e agente.sh riavviano Ollama solo con rianima_ollama" || ko "riavvii a mano rimasti: $FUORI"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
