#!/bin/bash
# test-debiti-riapertura.sh — il settimo patto ha il suo canarino (regola dell'antivirus):
# un DEBITI sintetico con le tre classi (dominio / risolvibile / saldato) deve uscire
# contato e classificato GIUSTO. Un classificatore non provato e' un'opinione in uniforme.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/debiti-riapertura.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }

SB=$(mktemp -d /tmp/debiti-t.XXXXXX); trap 'rm -rf "$SB"' EXIT
cat > "$SB/DEBITI.md" <<'FIN'
# DEBITI
## Da decidere col dominio (2026-01-01)
Va chiesto a Luca quale soglia usare per lo sconto. Decide il proprietario.
## Lavoro tecnico rimandabile (2026-01-01)
Refactor della funzione X: si può fare da soli.
## GIÀ SALDATO
| 2026-01-01 ✅ SALDATO | cosa vecchia | perché | come |
FIN
OUT=$(bash "$TOOL" "$SB" 2>&1)
echo "$OUT" | grep -q "APERTI: 2 — di DOMINIO: 1" && ok "conta 2 aperti, 1 di dominio (il saldato escluso)" || ko "conto sbagliato: $(echo "$OUT" | sed -n 2p)"
echo "$OUT" | grep -q "D1. Da decidere col dominio" && ok "il debito di dominio diventa DOMANDA singola (D1)" || ko "dominio non fra le domande"
echo "$OUT" | grep -q "R1. Lavoro tecnico" && ok "il risolvibile finisce in DA FARE SUBITO" || ko "risolvibile non elencato"
OUT0=$(bash "$TOOL" "$SB" >/dev/null 2>&1; echo $?)
[ "$OUT0" = "0" ] && ok "esce 0: informa e non blocca (la pressione e' la visibilita')" || ko "esce $OUT0"
# (D21, test del sistema completo 2026-09-20): due difetti visti sul DEBITI vero.
#  a) «perché conta» pescava l'INTESTAZIONE della tabella («| Data | Scorciatoia | Perché
#     rimandata |…») per tutte le 8 domande: la regex `perch` combacia col titolo colonna.
#  b) la classificazione guardava 600 caratteri: «Valutare Qwen 3.8 Flash» aveva la parola
#     chiave (decisione hardware di Luca) a offset 754 e finiva tra i RISOLVIBILI.
SB3=$(mktemp -d /tmp/debiti-t3.XXXXXX)
RIEMPI=$(python3 -c "print('x ' * 400)")
cat > "$SB3/DEBITI.md" <<FIN
# DEBITI
## Con tabella (2026-01-01)
| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-01-01 | niente lock | serve una decisione di Luca sul dominio | quando Luca decide |
## Parola chiave in fondo (2026-01-01)
$RIEMPI
La scelta finale spetta a Luca: e' una decisione di acquisto hardware.
FIN
OUT3=$(bash "$TOOL" "$SB3" 2>&1)
echo "$OUT3" | grep -q "perché conta: | Data" && ko "D21a: il «perché conta» e' l'intestazione della tabella" \
  || ok "D21a: il «perché conta» non e' l'intestazione della tabella"
echo "$OUT3" | grep -q "perché conta: .*decisione di Luca" && ok "D21a: il «perché conta» e' la riga vera della tabella" \
  || ko "D21a: il perché vero non compare: $(echo "$OUT3" | grep 'perché conta' | head -1)"
echo "$OUT3" | grep -q "APERTI: 2 — di DOMINIO: 2" && ok "D21b: la parola chiave oltre i 600 caratteri classifica comunque DOMINIO" \
  || ko "D21b: classificazione su finestra corta: $(echo "$OUT3" | sed -n 2p)"
rm -rf "$SB3"

# (revisione 10 giri, 2026-09-23): la granularita' e' la RIGA, non la sezione.
#  a) una sezione con una riga SALDATA e una viva era chiusa per intero (8+ righe vive
#     invisibili sul DEBITI vero);
#  b) le righe che aspettano un evento esterno (⏳) non sono «da fare subito».
SB4=$(mktemp -d /tmp/debiti-t4.XXXXXX)
cat > "$SB4/DEBITI.md" <<'FIN'
# DEBITI
## Mista (2026-01-01)
| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-01-01 ✅ SALDATO | vecchia cosa chiusa | - | - |
| 2026-01-02 | refactor ancora aperto | tempo | prossimo giro |
## Solo in attesa (2026-01-01)
| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-01-03 | provare sul Mac | serve il Mac | ⏳ IN ATTESA: primo giro sul Mac |
FIN
OUT4=$(bash "$TOOL" "$SB4" 2>&1)
echo "$OUT4" | grep -q "R1. Mista" && ok "riga viva in sezione con una saldata: la sezione resta APERTA" \
  || ko "la riga saldata nasconde la viva: $(echo "$OUT4" | sed -n 2p)"
echo "$OUT4" | grep -q "A1. Solo in attesa" && ok "riga ⏳: classe IN ATTESA, non «da fare subito»" \
  || ko "riga ⏳ non in attesa: $(echo "$OUT4" | sed -n 2p)"
echo "$OUT4" | grep -q "IN ATTESA: primo giro sul Mac" && ok "l'evento dichiarato si vede" || ko "evento ⏳ non mostrato"
rm -rf "$SB4"

# senza DEBITI.md: dichiarato, non muto (sesto patto)
SB2=$(mktemp -d /tmp/debiti-t2.XXXXXX)
OUT2=$(bash "$TOOL" "$SB2" 2>&1)
echo "$OUT2" | grep -q "nessun DEBITI.md: niente da bruciare (dichiarato" && ok "senza debiti lo DICE (mai muto)" || ko "silenzio senza DEBITI.md"
rm -rf "$SB2"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
