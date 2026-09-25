#!/bin/bash
# test-giri-avversari-verdetto.sh — gli attacchi leggono il VERDETTO della sonda, non il suo nome
# (Q17, 2026-09-23, giro A2 della notte). tools/giri-ignoranti.sh stampa l'etichetta in tutti e due i
# casi («OK   S7 …» o «FIND S7 …»), e nove attacchi di tools/giri-avversari.sh cercavano solo «S7»:
# combaciava sempre, e il verdetto era TIENE qualunque cosa fosse successa (famiglia «verde senza
# verdetto»). Il riferimento giusto c'era gia': tools/prova-rilevatori.sh cerca «FIND <sonda>».
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
AVV="$HERE/tools/giri-avversari.sh"

# la premessa, misurata: sull'albero PULITO la batteria stampa gia' «OK   S7 …» — un grep sul solo
# nome della sonda combacia senza nessun attacco
OUT=$(cd "$HERE" && bash tools/giri-ignoranti.sh 2>/dev/null)
grep -qE '^OK +S7 ' <<<"$OUT" && ok "premessa: a albero pulito la sonda S7 stampa il suo nome anche quando dice OK" \
  || ko "premessa cambiata: S7 non stampa piu' «OK   S7» a albero pulito — rivedere questo banco"

NUDI=$(grep -nE 'grep -[a-zA-Z]*[qc][a-zA-Z]* +"(S[0-9]+(\|S[0-9]+)*)"' "$AVV")
[ -z "$NUDI" ] && ok "nessun attacco cerca il solo nome della sonda" \
  || ko "attacchi che cercano il nome della sonda, non il verdetto FIND: $(cut -d: -f1 <<<"$NUDI" | tr '\n' ' ')"
N_FIND=$(grep -cE 'grep -[a-zA-Z]*[qc][a-zA-Z]* +"\^FIND \+\(?S[0-9]' "$AVV")
[ "$N_FIND" -ge 9 ] && ok "gli attacchi sulle sonde leggono «^FIND +S…» ($N_FIND)" \
  || ko "attacchi che leggono il verdetto FIND: $N_FIND, attesi almeno 9"


# (2026-09-25, settimo ventaglio, V5 R3): A20 e G4 giudicavano dall'RC di privacy-check. La batteria gira in un clone,
# senza night-shift/repos.key (gitignored): li' privacy-check esce 1 («GATE DEGRADATO») anche ad albero pulito, e
# l'attacco diceva TIENE con le forme di segreto sabotate. Il verdetto e' la riga «FORMA DI SEGRETO».
C=$(mktemp -d); trap 'rm -rf "$C"' EXIT
git clone -q "$HERE" "$C/hub" 2>/dev/null
PC=$(cd "$C/hub" && bash tools/privacy-check.sh 2>&1 >/dev/null); PRC=$?
[ "$PRC" -ne 0 ] && ! grep -c 'FORMA DI SEGRETO' <<<"$PC" >/dev/null \
  && ok "premessa: nel clone della batteria privacy-check esce $PRC ad albero pulito (l'rc non e' un verdetto)" \
  || ko "premessa cambiata: nel clone privacy-check esce $PRC — rivedere questo banco"
RC_NUDI=$(grep -n 'bash tools/privacy-check.sh >/dev/null 2>&1 &&' "$AVV" || true)
[ -z "$RC_NUDI" ] && ok "V5 R3: nessun attacco giudica privacy-check dal suo rc" || ko "V5 R3: attacchi che leggono l'rc di privacy-check: $(cut -d: -f1 <<<"$RC_NUDI" | tr '\n' ' ')"
N_FORMA=$(grep -c "grep -c 'FORMA DI SEGRETO'" "$AVV")
[ "$N_FORMA" -ge 2 ] && ok "V5 R3: A20 e G4 leggono «FORMA DI SEGRETO» ($N_FORMA)" || ko "V5 R3: attacchi che leggono «FORMA DI SEGRETO»: $N_FORMA, attesi 2"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
