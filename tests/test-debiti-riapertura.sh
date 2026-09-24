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
grep -q "APERTI: 2 — di DOMINIO: 1" <<<"$OUT" && ok "conta 2 aperti, 1 di dominio (il saldato escluso)" || ko "conto sbagliato: $(echo "$OUT" | sed -n 2p)"
grep -q "D1. Da decidere col dominio" <<<"$OUT" && ok "il debito di dominio diventa DOMANDA singola (D1)" || ko "dominio non fra le domande"
grep -q "R1. Lavoro tecnico" <<<"$OUT" && ok "il risolvibile finisce in DA FARE SUBITO" || ko "risolvibile non elencato"
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
grep -q "perché conta: | Data" <<<"$OUT3" && ko "D21a: il «perché conta» e' l'intestazione della tabella" \
  || ok "D21a: il «perché conta» non e' l'intestazione della tabella"
grep -q "perché conta: .*decisione di Luca" <<<"$OUT3" && ok "D21a: il «perché conta» e' la riga vera della tabella" \
  || ko "D21a: il perché vero non compare: $(echo "$OUT3" | grep 'perché conta' | head -1)"
grep -q "APERTI: 2 — di DOMINIO: 2" <<<"$OUT3" && ok "D21b: la parola chiave oltre i 600 caratteri classifica comunque DOMINIO" \
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
grep -q "R1. Mista" <<<"$OUT4" && ok "riga viva in sezione con una saldata: la sezione resta APERTA" \
  || ko "la riga saldata nasconde la viva: $(echo "$OUT4" | sed -n 2p)"
grep -q "A1. Solo in attesa" <<<"$OUT4" && ok "riga ⏳: classe IN ATTESA, non «da fare subito»" \
  || ko "riga ⏳ non in attesa: $(echo "$OUT4" | sed -n 2p)"
grep -q "IN ATTESA: primo giro sul Mac" <<<"$OUT4" && ok "l'evento dichiarato si vede" || ko "evento ⏳ non mostrato"
rm -rf "$SB4"

# senza DEBITI.md: dichiarato, non muto (sesto patto)
# (D5, decisione di Luca 2026-09-23: «a») LA PREMESSA INVECCHIA COL CODICE: una voce aperta che
# cita un file cambiato in git DOPO la sua data (la piu' recente scritta nella riga: chi la
# riverifica la aggiorna) chiede di riverificare la premessa. Dal campo REPO-G: le credenziali
# spostate via nella PR #36, e l'obiezione in DEBITI e' rimasta com'era per giorni.
SB4=$(mktemp -d /tmp/debiti-t4.XXXXXX)
g4() { git -C "$SB4" -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null "$@"; }
g4 init -q; mkdir -p "$SB4/tools"
echo v1 > "$SB4/tools/vecchio.sh"; echo v1 > "$SB4/tools/fermo.sh"
g4 add -A; GIT_COMMITTER_DATE="2026-01-01T12:00:00" g4 commit -q --date "2026-01-01T12:00:00" -m base
echo v2 > "$SB4/tools/vecchio.sh"
g4 add -A; GIT_COMMITTER_DATE="2026-03-01T12:00:00" g4 commit -q --date "2026-03-01T12:00:00" -m cambia
cat > "$SB4/DEBITI.md" <<'FIN'
# DEBITI
## Premessa scaduta (dominio)
| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-02-01 | `tools/vecchio.sh` contiene credenziali | decisione di Luca | quando si decide |
## Premessa ferma (dominio)
| 2026-02-01 | `tools/fermo.sh` e `tools/inesistente.sh` | decisione di Luca | quando si decide |
## Premessa riverificata (dominio)
| 2026-02-01 | `tools/vecchio.sh` (riverificato 2026-03-05: ancora vero) | decisione di Luca | quando si decide |
FIN
OUT4=$(bash "$TOOL" "$SB4" 2>&1)
echo "$OUT4" | grep -A3 "Premessa scaduta" | grep -q "premessa da riverificare: tools/vecchio.sh" \
  && ok "file citato cambiato DOPO la voce: premessa da riverificare" || ko "premessa scaduta non segnalata: $(echo "$OUT4" | grep -A3 'Premessa scaduta' | tr '\n' ' ')"
echo "$OUT4" | grep -A3 "Premessa scaduta" | grep -q "2026-03-01" && ok "la segnalazione dice QUANDO e' cambiato" || ko "manca la data del cambio"
echo "$OUT4" | grep -A2 "Premessa ferma" | grep -q "riverificare" && ko "file fermo o inesistente segnalato a vuoto" || ok "file fermo o inesistente: nessuna segnalazione"
echo "$OUT4" | grep -A2 "Premessa riverificata" | grep -q "riverificare" && ko "la data di riverifica nella riga non e' contata" || ok "una data piu' recente nella riga (riverifica) azzera l'orologio"
rm -rf "$SB4"

SB2=$(mktemp -d /tmp/debiti-t2.XXXXXX)
OUT2=$(bash "$TOOL" "$SB2" 2>&1)
grep -q "nessun DEBITI.md: niente da bruciare (dichiarato" <<<"$OUT2" && ok "senza debiti lo DICE (mai muto)" || ko "silenzio senza DEBITI.md"
rm -rf "$SB2"

# (2026-09-23, notte dei giri): «SALDAT[OA]» OVUNQUE nella riga la chiudeva — anche «NON SALDATO» o
# «PARZIALMENTE SALDATA» (sul DEBITI vero una riga cosi' era chiusa dal 2026-08-24). Visto
# scrivendo io stesso «in parte SALDATO» su una riga col debito residuo: sarebbe sparito.
SB5=$(mktemp -d /tmp/debiti-t5.XXXXXX)
aperti_con() {  # $1 = la cella «Data» della sola riga della sezione → il numero di debiti APERTI
  printf '# DEBITI\n## Una riga (2026-01-01)\n| Data | Scorciatoia | Perché | Quando |\n|---|---|---|---|\n| %s | un debito tecnico | x | y |\n' "$1" > "$SB5/DEBITI.md"
  bash "$TOOL" "$SB5" 2>&1 | sed -n 's/^debiti APERTI: \([0-9]*\).*/\1/p'
}
[ "$(aperti_con '2026-01-01 NON SALDATO')" = "1" ] && ok "«NON SALDATO» resta aperto" || ko "«NON SALDATO» contato come saldato"
[ "$(aperti_con '2026-01-01 ✅ PARZIALMENTE SALDATA')" = "1" ] && ok "«PARZIALMENTE SALDATA» resta aperta" || ko "«PARZIALMENTE SALDATA» contata come saldata"
[ "$(aperti_con '2026-01-01 ✅ SALDATO')" = "0" ] && ok "«✅ SALDATO» si chiude" || ko "«✅ SALDATO» non si chiude piu'"
rm -rf "$SB5"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
