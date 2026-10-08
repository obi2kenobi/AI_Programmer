#!/bin/bash
# test-non-converge.sh — il banco del riposo delle issue che non convergono (v2,
# 2026-10-08). La v1 contava SOLO i watchdog rc-124: Centrale_Rischi falliva con
# rc=1 dopo aver bruciato tutta l'inferenza (~300s) e la cascata moriva a parte —
# 5101s GPU in una notte, ZERO riposi scattati. Il segnale e' composito e il
# conteggio vive in lib.sh (issue_non_converge_oggi / conta_non_convergenza).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/nonconv.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
git -C "$TMP" init -q

# a) zero segnali → zero
N=$(issue_non_converge_oggi "$TMP" 42)
[ "$N" = "0" ] && ok "senza storia: 0 segnali" || ko "atteso 0, trovato $N"

# b) il ciclo COMPOSITO di Centrale_Rischi: budget pieno + cascata fallita
conta_non_convergenza "$TMP" 42 "solver a budget pieno (rc=1, 300s)"
conta_non_convergenza "$TMP" 42 "agente in cascata non converto (rc=1)"
N=$(issue_non_converge_oggi "$TMP" 42)
[ "$N" = "2" ] && ok "un ciclo composito (solver+cascata) = 2 segnali → riposa al ciclo dopo" || ko "atteso 2, trovato $N"

# c) i segnali di IERI non contano oggi (il riposo e' per giorno)
YESTERDAY=$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F)
printf '%s watchdog\n%s watchdog\n' "$YESTERDAY" "$YESTERDAY" >> "$TMP/.git/non-converge/7"
N=$(issue_non_converge_oggi "$TMP" 7)
[ "$N" = "0" ] && ok "i segnali di ieri non contano oggi (domani si riprota)" || ko "ieri contati: $N"

# d) il watchdog rc-124 conta anche lui (v1 non era sbagliata, era stretta)
conta_non_convergenza "$TMP" 9 "watchdog 5min"
conta_non_convergenza "$TMP" 9 "watchdog 5min"
N=$(issue_non_converge_oggi "$TMP" 9)
[ "$N" = "2" ] && ok "due watchdog oggi = soglia raggiunta" || ko "atteso 2, trovato $N"

# e) la riga scritta dice il PERCHE' (il giorno legge e decide: spezzare o alzare)
grep -q "solver a budget pieno" "$TMP/.git/non-converge/42" \
  && ok "il segnale porta il motivo (il giorno puo' decidere cosa fare)" \
  || ko "il segnale e' muto"

# (furto #1 da mainline): la storia dei tentativi falliti entra nel prompt
STORIA=$(storia_tentativi "$TMP" 42)
grep -q "TENTATIVI PRECEDENTI" <<<"$STORIA" && grep -q "solver a budget pieno" <<<"$STORIA" \
  && grep -q "Cambia strategia" <<<"$STORIA" \
  && ok "la storia delle vie abbandonate si inietta (con i motivi e l'avviso)" \
  || ko "storia mancante o muta: $(head -2 <<<"$STORIA")"
STORIA_VUOTA=$(storia_tentativi "$TMP" 999)
[ -z "$STORIA_VUOTA" ] && ok "senza storia non si inietta niente" || ko "storia per issue ignota"

# (furto #3): la guardia sintattica per estensione
F3=$(mktemp "$TMP/edit.XXXXXX")
echo 'function sana(){ return 0; }' > "$F3.sh"
edit_sintassi_ok "$F3.sh" && ok "edit .sh sano passa" || ko "edit .sh sano bocciato"
printf 'function rotta(){ return 0 }' > "$F3.sh"
if edit_sintassi_ok "$F3.sh"; then ko "edit .sh rotto passa"; else ok "edit .sh rotto bocciato (rifiutato sul posto)"; fi
echo 'const x = 1;' > "$F3.gs" && edit_sintassi_ok "$F3.gs" && ok "edit .gs sano passa" || ko "edit .gs sano bocciato"
printf 'def rotto(: pass' > "$F3.py"
if edit_sintassi_ok "$F3.py"; then ko "edit .py rotto passa"; else ok "edit .py rotto bocciato"; fi
echo '# solo markdown' > "$F3.md" && edit_sintassi_ok "$F3.md" && ok "estensione ignota: passa (dichiarato)" || ko "ignoto bocciato"

# (furto #4): i trailer del mandato
T=$(trailers_notte "goal #164" "docs" "prompt-vero")
grep -q "^Night-Goal: goal #164$" <<<"$T" && grep -q "^Night-Category: docs$" <<<"$T" && grep -q "^Night-Prompt-Sha: .\{16\}$" <<<"$T" \
  && ok "i trailer dichiarano mandato, categoria e sha del prompt" || ko "trailer incompleti: $T"
T2=$(trailers_notte "" "" "")
[ -z "$T2" ] && ok "senza mandato niente trailer vuoti" || ko "trailer vuoti prodotti"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
