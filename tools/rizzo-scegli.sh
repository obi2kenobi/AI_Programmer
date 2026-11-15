#!/bin/bash
# rizzo-scegli.sh — router dei cervelli del cantiere AI_Programmer (Rizzo Flow, locale)
# Uso: rizzo-scegli.sh "descrizione del compito"
# Output: economico | coder | frontiera | ricerca   (probabilità su stderr se -v)
# Regola (rev.23): la risposta è un CONSIGLIO di routing, non un ordine.
# Se il server non risponde: exit 1, il chiamante cade sul default (coder) dichiarandolo.
# rev.31: il prompt NON vive più qui — fonte unica: rizzo-flow/calibrazione-camarlinghi/prompt-router.json
# Quarta classe «ricerca»: web/immagini/PDF/ragionamento aperto — MAI al coder (incidente DUO 15/11).

TASK="$1"
VERBOSE="$2"
HERE="$(cd "$(dirname "$0")" && pwd)"
PROMPT_JSON="$HERE/rizzo-flow/calibrazione-camarlinghi/prompt-router.json"

# Costruisce la request dalla fonte unica (python per l'escaping corretto)
REQ=$(TASK="$TASK" python3 - "$PROMPT_JSON" <<'PYEOF'
import json, os, sys
p = json.load(open(sys.argv[1]))
task = os.environ["TASK"]
req = {
    "state": p["state"],
    "questions": {
        p["question_id"]: {
            "type": "choice",
            "instructions": p["instructions_prefix"] + task,
            "options": [{"id": o["id"], "description": o["description"]} for o in p["options"]],
        }
    },
}
print(json.dumps(req, ensure_ascii=False))
PYEOF
)

RISP=$(curl -s --max-time 10 http://127.0.0.1:8017/v1/decisions \
  -H 'Content-Type: application/json' \
  -d "$REQ")

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
