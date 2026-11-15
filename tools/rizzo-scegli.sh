#!/bin/bash
# rizzo-scegli.sh — router dei cervelli del cantiere AI_Programmer (Rizzo Flow, locale)
# Uso: rizzo-scegli.sh "descrizione del compito"
# Output: economico | coder | frontiera   (più probabilità, una riga JSON su stderr se -v)
# Regola (rev.23): la risposta è un CONSIGLIO di routing, non un ordine.
# Se il server non risponde: exit 1, il chiamante cade sul default (coder) dichiarandolo.

TASK="$1"
VERBOSE="$2"

RISP=$(curl -s --max-time 10 http://127.0.0.1:8017/v1/decisions \
  -H 'Content-Type: application/json' \
  -d "{\"state\": \"Router dei cervelli del cantiere AI_Programmer. economico: grep, lettura file, ricerche, conteggi, verifiche di stato. coder: scrivere o modificare codice, fix bug, nuove feature, test. frontiera: architettura, decisioni costose o irreversibili, revisioni di diff, scelte che toccano la produzione.\", \"questions\": {\"cervello\": {\"type\": \"choice\", \"instructions\": \"Quale cervello serve per questo compito? Compito: ${TASK//\"/\\\"}\", \"options\": [{\"id\": \"economico\", \"description\": \"grep, lettura file, ricerca, conteggio, verifica stato: nessuna riga di codice scritta\"}, {\"id\": \"coder\", \"description\": \"scrivere o modificare codice sorgente, fix bug, feature, test automatizzati\"}, {\"id\": \"frontiera\", \"description\": \"architettura, decisioni costose o irreversibili, revisioni difficili, impatto su produzione\"}]}}}")

if [ -z "$RISP" ]; then
  echo "rizzo-scegli: server non raggiungibile (127.0.0.1:8017)" >&2
  exit 1
fi

echo "$RISP" | python3 -c "
import json,sys
try:
    a = json.load(sys.stdin)['answers']['cervello']
except Exception:
    sys.stderr.write('rizzo-scegli: risposta non valida\n'); sys.exit(1)
if '$VERBOSE' == '-v':
    sys.stderr.write(json.dumps(a['probabilities']) + '\n')
print(a['choice'])
"
