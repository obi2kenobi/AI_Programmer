#!/bin/bash
# test-rating-dso-clienti.sh — banco di regressione nato dalla revisione "L'Hub Allo
# Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in tools/rating_dso_clienti.py,
# un pagamento scartato dalla guardia anti-falsi-match (giorni<0 o giorni>365) spariva del
# tutto — non contato in "non matchati", nonostante il docstring dichiari esplicitamente
# "scarto mai silenzioso". Nessun test esisteva per questo tool: questo è il primo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# Caso 1 — bug reale: pagamento abbinabile per cliente/importo ma con data PRECEDENTE la
# fattura (giorni negativi) — la guardia lo scarta giustamente come falso matching, ma
# prima del fix spariva anche dal conteggio "non matchati".
OUT1=$(printf 'tipo,data_documento,data_registrazione,nr_doc,cliente,descrizione,importo\nfattura,2026-01-10,2026-01-10,1,Mario Rossi,,1000\npagamento,2026-01-01,2026-01-01,2,Mario Rossi,,1000\n' \
  | python3 "$HERE/tools/rating_dso_clienti.py")
echo "$OUT1" | grep -q "Non matchati: 1" \
  && ok "pagamento scartato dalla guardia anti-falsi-match: contato in non matchati" \
  || ko "pagamento scartato sparito dal conteggio — output: $OUT1"
echo "$OUT1" | grep -q "NON MATCHATO: 2026-01-01 1000.00" \
  && ok "pagamento scartato: riga NON MATCHATO stampata con data/importo" \
  || ko "riga NON MATCHATO mancante — output: $OUT1"

# Caso 2 — matching normale (giorni validi, entro la finestra di fallback di 7 giorni sul
# confronto cliente+importo+data): deve continuare a funzionare come prima.
OUT2=$(printf 'tipo,data_documento,data_registrazione,nr_doc,cliente,descrizione,importo\nfattura,2026-01-01,2026-01-01,1,Anna Bianchi,,500\npagamento,2026-01-06,2026-01-06,2,Anna Bianchi,,500\n' \
  | python3 "$HERE/tools/rating_dso_clienti.py")
echo "$OUT2" | grep -q "Non matchati: 0" \
  && ok "matching normale: nessun falso 'non matchato'" \
  || ko "matching normale rotto — output: $OUT2"
echo "$OUT2" | grep -qE "anna bianchi\s+1\s+5 gg" \
  && ok "matching normale: DSO = 5 giorni per anna bianchi" \
  || ko "DSO atteso non trovato — output: $OUT2"

# Caso 3 — pagamento senza nessun candidato (cliente/importo/data non corrispondono a
# nulla): deve restare in non matchati come prima (nessuna regressione sul percorso già
# corretto).
OUT3=$(printf 'tipo,data_documento,data_registrazione,nr_doc,cliente,descrizione,importo\npagamento,2026-01-01,2026-01-01,2,Sconosciuto,,999\n' \
  | python3 "$HERE/tools/rating_dso_clienti.py")
echo "$OUT3" | grep -q "Non matchati: 1" \
  && ok "pagamento senza candidati: resta non matchato (invariato)" \
  || ko "pagamento senza candidati rotto — output: $OUT3"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
