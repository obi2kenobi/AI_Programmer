#!/bin/bash
# test-dipendenze-turno.sh — senza jq il turno accusava Ollama e ne uccideva un'istanza sana
# (2026-09-24, quarto ventaglio, Q2 R2). Il ping di generazione si costruisce e si legge con jq: senza jq
# restava vuoto, il turno scriveva «Ollama wedged» e chiamava rianima_ollama (pkill del serve); agente.sh
# faceva la stessa catena e finiva «NESSUN rianimamento ha funzionato». «jq: command not found» andava
# solo su stderr. La diagnosi «wedged» si da' solo dopo aver escluso l'attrezzo che la misura.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/nojq" "$T/prog"
for b in /usr/local/bin/* /usr/bin/* /bin/*; do n=${b##*/}; case "$n" in jq|pkill|curl) continue ;; esac; [ -e "$T/nojq/$n" ] || ln -s "$b" "$T/nojq/$n" 2>/dev/null; done
printf '#!/bin/bash\necho "pkill $*" >> "%s/pkill.log"\n' "$T" > "$T/nojq/pkill"
printf '#!/bin/bash\necho "{\\"message\\":{\\"content\\":\\"OK\\"}}"\n' > "$T/nojq/curl"   # Ollama SANO
chmod +x "$T/nojq/pkill" "$T/nojq/curl"

# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"
type dipendenze_mancanti >/dev/null 2>&1 && ok "dipendenze_mancanti e' definita in night-shift/lib.sh" || ko "dipendenze_mancanti non esiste"
M=$(PATH="$T/nojq" dipendenze_mancanti jq curl git 2>/dev/null)
[ "$M" = "jq" ] && ok "dipendenze_mancanti nomina solo quella che manca (jq)" || ko "dipendenze_mancanti: «$M»"

OUT=$(PATH="$T/nojq" bash "$HERE/night-shift/agente.sh" "$T/prog" "correggi" 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -c 'MANCA jq' <<<"$OUT" >/dev/null && [ ! -s "$T/pkill.log" ] \
  && ok "agente senza jq: esce 2 dicendo «MANCA jq», e non tocca Ollama" \
  || ko "agente senza jq: rc=$RC, pkill: $(cat "$T/pkill.log" 2>/dev/null), $(tail -1 <<<"$OUT")"

NS="$HERE/night-shift/night-shift.sh"
L_DIP=$(grep -n 'dipendenze_mancanti ' "$NS" | head -1 | cut -d: -f1)
L_RIAN=$(grep -n 'rianima_ollama 2>&1' "$NS" | head -1 | cut -d: -f1)
[ -n "$L_DIP" ] && [ -n "$L_RIAN" ] && [ "$L_DIP" -lt "$L_RIAN" ] \
  && ok "il turno controlla le dipendenze (riga $L_DIP) prima di qualunque rianimazione (riga $L_RIAN)" \
  || ko "il turno non controlla le dipendenze prima di rianimare Ollama (dip=${L_DIP:-?}, rianima=${L_RIAN:-?})"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
