#!/bin/bash
# test-locale-turno.sh — il turno esporta LC_ALL=en_US.UTF-8 (night-shift/night-shift.sh,
# export in testa al turno); la sessione del giorno no. I test delle repo satellite che a
# mano sono verdi possono quindi essere rossi nel turno per due trappole di quel locale,
# trovate su obi2kenobi/Riordino-legno il 2026-10-05 (issue #9, rosso stabile per dieci
# cicli, irriproducibile dal clone pulito):
#   1) «sort» di BSD collaziona senza distinguere maiuscole: !appsscript.json precede
#      !Code.gs e ogni atteso scritto in ordine di byte salta;
#   2) bash 3.2 con quel locale attacca il «»» multibyte al nome della variabile che
#      segue: «$var»» viene letto come la variabile «var+byte» e con set -u muore di
#      «unbound variable».
# Le cure (pattern patterns/locale-del-turno.md): prefisso LC_ALL=C sui sort il cui ordine
# e' parte dell'atteso, e graffe «${var}»» quando una virgoletta tipografica segue la
# variabile. Questo banco le prova NEL locale del turno, e tiene vivo il sapere delle
# trappole: se un domani bash o sort cambiano, le due righe qui sotto diventano rosse e
# dicono che E-059 va aggiornato, non che il banco e' rotto.
# Esiti: 0 tutto verde · 1 almeno un FALLITO.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# il locale ostile del turno, ricreato da zero: niente altro dell'ambiente conta
TURNO="env -i PATH=/usr/bin:/bin LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"
ORDINE_C='!Code.gs !Index.html !appsscript.json '
righe='!Code.gs
!Index.html
!appsscript.json'

# 1) la cura del sort tiene NEL locale del turno
got=$($TURNO sh -c "printf '%s\n' '$righe' | LC_ALL=C sort | tr '\n' ' '" 2>/dev/null)
[ "$got" = "$ORDINE_C" ] && ok "LC_ALL=C sort dà l'ordine di byte sotto il locale del turno" \
                        || ko "LC_ALL=C sort ha dato «${got}» invece di «${ORDINE_C}»"

# 2) la cura delle graffe tiene: la virgoletta tipografica dopo ${var} non morde
$TURNO /bin/bash -uc 'p="no"; [ "$p" = "ok" ] && echo VERDE >/dev/null || echo "KO «${p}»" >/dev/null' 2>/dev/null \
  && ok "«\${var}»» con set -u sopravvive al locale del turno" \
  || ko "«\${var}»» con set -u muore nel locale del turno: la cura non tiene"

# 3) la trappola bash e' ancora li' (bash 3.2 di macOS: se questa diventa verde, bash e'
#    cambiato e E-059 va aggiornato — non e' un falso rosso). Lo snippet con la variabile
#    nuda davanti al «»» si scrive a runtime con printf ottale, come il glifo di E-007:
#    il byte letterale nel sorgente farebbe scattare V4 R1 di test-portabilita.sh su
#    QUESTO banco (la guardia dell'hub copre i file dell'hub, banco compreso).
SNIP=$(mktemp /tmp/trap-locale.XXXXXX)
trap 'rm -f "$SNIP"' EXIT
printf 'p="no"\n[ "$p" = "ok" ] && echo VERDE >/dev/null || echo "KO $p%s" >/dev/null\n' \
  "$(/usr/bin/printf '\302\273')" > "$SNIP"
BV=$(/bin/bash -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null || echo 0)
if [ "${BV:-0}" -eq 3 ]; then
  $TURNO /bin/bash -u "$SNIP" >/dev/null 2>&1 \
    && ko "«\$p» SENZA graffe ora sopravvive: bash 3.2 non incolla piu' il «»» — aggiornare E-059" \
    || ok "la trappola bash 3.2 e' riproducibile (il sapere di E-059 e' vivo)"
else
  echo "--   bash ${BV}: la trappola del «»» e' di bash 3.2, qui non si prova"
fi

# 4) la trappola del sort e' ancora li' (BSD sort di macOS; come sopra: verde = mondo cambiato)
got=$($TURNO sh -c "printf '%s\n' '$righe' | sort | tr '\n' ' '" 2>/dev/null)
if [ "$got" = "$ORDINE_C" ]; then
  ko "sort senza LC_ALL=C dà l'ordine di byte anche nel locale del turno: BSD sort e' cambiato — aggiornare E-059"
else
  ok "sort senza LC_ALL=C riordina nel locale del turno («${got}»): la trappola e' viva"
fi

# 5) il puntatore skills che il generatore scrive nei CLAUDE.md satellite cita il percorso
#    che esiste (~/.night-shift-work): per un intero giro ha detto ~/.night-shift, e in
#    ogni repo onboardata la riga delle skill puntava nel vuoto
TMP=$(mktemp -d)
trap 'rm -f "$SNIP"; rm -rf "$TMP"' EXIT
if bash "$HERE/tools/claude-md-cervello.sh" "$TMP" >/dev/null 2>&1; then
  grep -q 'Skills: `~/.night-shift-work/AI_Programmer/.claude/skills/`' "$TMP/CLAUDE.md" \
    && ok "il puntatore skills del CLAUDE.md satellite cita ~/.night-shift-work" \
    || ko "il puntatore skills del CLAUDE.md satellite non cita ~/.night-shift-work"
  grep -q '`~/\.night-shift/AI_Programmer' "$TMP/CLAUDE.md" \
    && ko "il CLAUDE.md satellite cita ~/.night-shift/... (senza -work): percorso inesistente" \
    || ok "nessun percorso ~/.night-shift/... (senza -work) nel CLAUDE.md satellite"
else
  ko "claude-md-cervello.sh non gira (il banco del typo non ha potuto giudicare)"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
