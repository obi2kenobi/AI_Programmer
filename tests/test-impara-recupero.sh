#!/bin/bash
# test-impara-recupero.sh — (2026-09-25, settimo ventaglio, V3 R6): la lezione del giorno (cervello-impara) si faceva
# solo se un ciclo INIZIAVA fra le 22 e mezzanotte. Un ciclo lungo partito alle 21:50 (un'issue ha 240 minuti) portava
# il ciclo dopo al giorno seguente: la lezione di ieri non si faceva piu', e nessuna riga lo diceva. Qui il blocco VERO
# del turno, con una `date` finta e uno stub di cervello-impara che scrive la data ricevuta.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
NS="$HERE/night-shift/night-shift.sh"

BLOCCO=$(awk '/^IMPRA_/{p=1} /^# il GRAFO SEMANTICO/{exit} p{print}' "$NS")
[ -n "$BLOCCO" ] || { ko "blocco di impara non trovato in night-shift.sh"; echo "$PASS OK, $FAIL FAIL"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/hub/night-shift" "$T/hub/tools" "$T/work"
VERA=$(command -v date)
printf '#!/bin/bash\ncase "$*" in "+%%F") echo "$FAKE_F";; "+%%H") echo "$FAKE_H";; "-v-1d +%%F"|"-d yesterday +%%F") echo "$FAKE_IERI";; *) exec %q "$@";; esac\n' "$VERA" > "$T/bin/date"
printf '#!/bin/bash\necho "lezione del ${IMPARA_DATA:-oggi}" >> %q\necho "lezione proposta"\n' "$T/chiamate" > "$T/hub/tools/cervello-impara.sh"
chmod +x "$T/bin/date"
printf '[2026-09-25 21:50:00] === TURNO INIZIATO\n' > "$T/console.log"
{ echo 'set -uo pipefail'; echo 'log() { echo "LOG: $*"; }'
  printf 'HERE=%q; WORK=%q; export NIGHT_LOG=%q\n' "$T/hub/night-shift" "$T/work" "$T/console.log"
  printf '%s\n' "$BLOCCO"; } > "$T/blocco.sh"
ciclo() { PATH="$T/bin:$PATH" FAKE_F="$1" FAKE_H="$2" FAKE_IERI="$3" bash "$T/blocco.sh" 2>&1; }

OUT=$(ciclo 2026-09-26 01 2026-09-25)
grep -cx 'lezione del 2026-09-25' "$T/chiamate" >/dev/null 2>&1 && [ -f "$T/work/.impara-2026-09-25" ] && grep -c 'ieri' <<<"$OUT" >/dev/null \
  && ok "V3 R6: al primo ciclo del 26 la lezione del 25, mancata, si fa (sul log di ieri) e si dice" \
  || ko "V3 R6: la lezione del 25 non si recupera: $(grep LOG <<<"$OUT" | head -2 | tr '\n' ' ')"
: > "$T/chiamate"; OUT=$(ciclo 2026-09-26 02 2026-09-25)
[ ! -s "$T/chiamate" ] && ok "V3 R6: fatta una volta, non si rifa' al ciclo dopo" || ko "V3 R6: la lezione di ieri si rifa' a ogni ciclo"
: > "$T/chiamate"; rm -f "$T/work/.impara-"*; printf '[2026-09-20 10:00:00] x\n' > "$T/console.log"
OUT=$(ciclo 2026-09-26 03 2026-09-25)
[ ! -s "$T/chiamate" ] && ok "V3 R6: ieri senza righe nel log (il turno era giu'): niente lezione di ieri" || ko "V3 R6: lezione di un giorno senza log"
: > "$T/chiamate"; OUT=$(ciclo 2026-09-26 22 2026-09-25)
grep -cx 'lezione del oggi\|lezione del 2026-09-26' "$T/chiamate" >/dev/null && [ -f "$T/work/.impara-2026-09-26" ] \
  && ok "la lezione del giorno dalle 22 resta com'era" || ko "la lezione del giorno dalle 22 non parte: $(grep LOG <<<"$OUT" | head -1)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
