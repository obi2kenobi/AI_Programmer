#!/bin/bash
# test-chiarezza.sh — la lente della chiarezza (100 giri di chiarezza, 2026-08-28).
# Il commento non è decorazione: è lo strumento che rende la SECONDA lettura una
# verifica del pensiero. Se l'intenzione non è scritta, una rilettura non può
# trovare la discordanza fra ciò che si pensava e ciò che il codice fa — l'ha
# trovata davvero, una volta: l'header di ciclo-vivo descriveva un ciclo A-B-C
# con memoria in stato.json MAI ESISTITI. Tre sonde:
#   S1 ogni file di codice dichiara l'INTENZIONE in testa (perché esiste)
#   S2 densità (commenti + docstring) >= 15% del codice, o file brevi
#   S3 ogni def python ha docstring o è banale (<= 4 righe)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# S1 — l'intenzione in testa: un trattone narrativo, un perché, o un Uso:
SENZA_INTENT=""
for f in "$HERE"/tools/*.sh "$HERE"/night-shift/*.sh "$HERE"/llm/*.sh; do
  head -12 "$f" | grep -qE "—|perch|Uso:|uso:|il contrato|contratto" || SENZA_INTENT="$SENZA_INTENT $(basename $f)"
done
for f in "$HERE"/tools/*.py; do
  head -20 "$f" | grep -qE '"""|—|perch' || SENZA_INTENT="$SENZA_INTENT $(basename $f)"
done
[ -z "$SENZA_INTENT" ] && ok "S1 ogni file di codice dichiara la sua intenzione in testa" \
  || ko "S1 file senza intenzione dichiarata:$SENZA_INTENT"

# S2 — densità di chiarezza (commenti + docstring contati, i # da soli mentono
# sui .py ben documentati: la lezione del censimento che chiamò «nudo» il file
# più commentato del repo)
python3 - "$HERE" <<'EOF' && ok "S2 densità di chiarezza >= 15% ovunque (o file breve)" || ko "S2 file sotto soglia (vedi sopra)"
import glob, os, ast, sys
here = sys.argv[1]
pessimi = []
def clarity(f):
    src = open(f, errors='ignore').read()
    lines = src.split('\n')
    comments = sum(1 for l in lines if l.strip().startswith('#'))
    doc = 0
    if f.endswith('.py'):
        try:
            for node in ast.walk(ast.parse(src)):
                if isinstance(node, (ast.Module, ast.FunctionDef, ast.ClassDef)):
                    d = ast.get_docstring(node)
                    if d: doc += len(d.split('\n'))
        except SyntaxError: pass
    code = sum(1 for l in lines if l.strip() and not l.strip().startswith('#') and '"""' not in l)
    return comments + doc, max(1, code)
# esenzione DICHIARATA (non in silenzio): l'harness avversario si autodescrive
# nei verdetti-echo — la sua nota di chiarezza in testa spiega perché
ESENTI = {f'{here}/tools/giri-avversari.sh'}
for f in glob.glob(f'{here}/tools/*.py') + glob.glob(f'{here}/tools/*.sh') + glob.glob(f'{here}/night-shift/*.sh') + glob.glob(f'{here}/llm/*.sh'):
    if f in ESENTI: continue
    c, n = clarity(f)
    if n > 30 and c / n < 0.15:
        pessimi.append(f"{os.path.basename(f)}: {c/n:.2f}")
if pessimi:
    print("  sotto soglia: " + ", ".join(pessimi)); sys.exit(1)
sys.exit(0)
EOF

# S3 — ogni funzione python dichiara cosa intende (o è così breve che si spiega)
python3 - "$HERE" <<'EOF' && ok "S3 ogni def python ha docstring o è banale (<= 4 righe)" || ko "S3 funzioni opache (vedi sopra)"
import glob, ast, sys
here = sys.argv[1]
opache = []
for f in glob.glob(f'{here}/tools/*.py'):
    try: tree = ast.parse(open(f, errors='ignore').read())
    except SyntaxError: continue
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and not ast.get_docstring(node):
            lunghezza = getattr(node, 'end_lineno', node.lineno) - node.lineno
            if lunghezza > 4:
                opache.append(f"{f.split('/')[-1]}:{node.name} ({lunghezza} righe)")
if opache:
    print("  senza docstring: " + ", ".join(opache[:6])); sys.exit(1)
sys.exit(0)
EOF

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
