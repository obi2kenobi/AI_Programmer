#!/bin/bash
# test-verifica-banco.sh — 7° ciclo, set 3 (2026-08-24): il guardiano delle uscite
# dei banchi. Ogni caso nasce da una lezione misurata del corpus: il verde
# raggiungibile, il rosso con fallite, le attese saltate (8/8→6/6 in silenzio),
# la riga mancante (crash o stampa), le righe multiple (sei vocabolari nel parco),
# l'uscita vuota. L'exit code del tool: 0 verde, 1 rosso, 2 forma non riconosciuta.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TOOL="$HERE/tools/verifica_banco.py"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

printf 'setup fixture…\nattese eseguite: 8/8 · fallite: 0\n' > "$TMP/verde.txt"
printf 'attese eseguite: 8/8 · fallite: 3\n' > "$TMP/rosso.txt"
printf 'attese eseguite: 6/8 · fallite: 0\n' > "$TMP/saltate.txt"
printf 'ALL TESTS COMPLETED\n' > "$TMP/stampa.txt"
printf 'attese eseguite: 3/3 · fallite: 0\nattese eseguite: 2/2 · fallite: 0\n' > "$TMP/doppia.txt"
: > "$TMP/vuota.txt"
printf 'attese eseguite: 9/8 · fallite: 0\n' > "$TMP/controtorno.txt"

python3 "$TOOL" "$TMP/verde.txt" >/dev/null 2>&1;  [ $? -eq 0 ] && ok "verde 8/8·0: exit 0" || ko "verde non riconosciuto"
python3 "$TOOL" "$TMP/rosso.txt" >/dev/null 2>&1;  [ $? -eq 1 ] && ok "rosso con 3 fallite: exit 1" || ko "rosso non riconosciuto"
python3 "$TOOL" "$TMP/saltate.txt" >/dev/null 2>&1; [ $? -eq 1 ] && ok "attese saltate 6/8: exit 1 (il banco più piccolo è un difetto)" || ko "saltate non colte"
python3 "$TOOL" "$TMP/stampa.txt" >/dev/null 2>&1; [ $? -eq 2 ] && ok "'ALL TESTS COMPLETED' senza riga-verdetto: NON È UN BANCO (exit 2)" || ko "stampa scambiata per banco"
python3 "$TOOL" "$TMP/doppia.txt" >/dev/null 2>&1; [ $? -eq 2 ] && ok "due righe-verdetto: forma ambigua (exit 2)" || ko "ambiguità non colta"
python3 "$TOOL" "$TMP/vuota.txt" >/dev/null 2>&1;   [ $? -eq 1 ] && ok "uscita vuota: il banco non è partito (exit 1, non silenzio)" || ko "vuota non colta"
python3 "$TOOL" "$TMP/controtorno.txt" >/dev/null 2>&1; [ $? -eq 2 ] && ok "eseguite>dichiarate 9/8: forma rotta (exit 2)" || ko "controtorno non colto"

# (giri lenti 2/10, area 20 rilievo 3, provato eseguendo) un banco vuoto e un banco il cui verdetto precede un sabotaggio che NON cade non sono verdi
printf 'attese eseguite: 0/0 · fallite: 0\n' > "$TMP/vuoto0.txt"
printf 'attese eseguite: 690/690 · fallite: 0\nFAIL G81b — x — cadute 0/1\nsabotaggi: 429/430 hanno fatto cadere esattamente le attese dichiarate\n' > "$TMP/sabotaggio.txt"
printf 'attese eseguite: 5/5 · fallite: 0\nBANCO INCOERENTE: attese registrate 4, dichiarate 5\n' > "$TMP/incoerente.txt"
printf 'attese eseguite: 5/5 · fallite: 0\nsabotaggi: 430/430 hanno fatto cadere esattamente le attese dichiarate\n' > "$TMP/sabotaggio-ok.txt"
python3 "$TOOL" "$TMP/vuoto0.txt" >/dev/null 2>&1;      [ $? -eq 1 ] && ok "0/0·0: un banco senza attese non è verde (exit 1)" || ko "banco vuoto giudicato verde"
python3 "$TOOL" "$TMP/sabotaggio.txt" >/dev/null 2>&1;  [ $? -eq 1 ] && ok "riga canonica verde ma sabotaggi 429/430 e FAIL: rosso (exit 1)" || ko "sabotaggio non caduto giudicato verde"
python3 "$TOOL" "$TMP/incoerente.txt" >/dev/null 2>&1;  [ $? -eq 1 ] && ok "BANCO INCOERENTE dopo la riga canonica: rosso (exit 1)" || ko "banco incoerente giudicato verde"
python3 "$TOOL" "$TMP/sabotaggio-ok.txt" >/dev/null 2>&1; [ $? -eq 0 ] && ok "sabotaggi 430/430 tutti intercettati: resta verde (exit 0)" || ko "falso rosso sui sabotaggi tutti intercettati"

OUT=$(python3 "$TOOL" "$TMP/saltate.txt")
grep -q "2 attese sono SPARITE in silenzio" <<<"$OUT" \
  && ok "il verdetto dice QUANTE attese sono sparite (il conto sta scritto)" || ko "il conteggio delle sparite manca"
OUT=$(python3 "$TOOL" "$TMP/verde.txt")
grep -q "resta una prova solo se un sabotaggio l'ha visto cadere" <<<"$OUT" \
  && ok "il verde ricorda che senza sabotaggio il banco non è una prova" || ko "il verde si accontenta"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
