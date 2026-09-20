#!/bin/bash
# salda-e002.sh — il trasformatore deterministico della famiglia E-002 (2026-09-20,
# «chiudi ora»): il fix cattura-prima e' MECCANICO, non serve un modello che
# improvvisi. Il 14b leggeva bene i siti e poi riscriveva il file intero (516
# righe per un tubo): dieci debiti provati, zero saldati. Questo tool applica
# la trasformazione canonica alla riga esatta, verifica la sintassi, e il
# diff e' pronto per il gate. L'agente resta per le forme non riconosciute.
#
# Forme riconosciute (le dominanti nel censimento):
#   A) if PRODUCER | grep FLAG 'PAT'; then
#        →  _cp=$(PRODUCER)
#           if grep FLAG 'PAT' <<<"$_cp"; then
#   B) [ ... ] || PRODUCER | grep FLAG 'PAT'; then   (condizione composta)
#        →  _cp=$(PRODUCER)
#           [ ... ] || grep FLAG 'PAT' <<<"_cp"; then
#
# Uso: salda-e002.sh <file> <riga>
# Esce: 0 trasformato (diff nel working tree) · 1 forma non riconosciuta (all'agente)
#       · 2 errore d'uso
set -uo pipefail
FILE="${1:?uso: salda-e002.sh <file> <riga>}"
RIGA="${2:?uso: salda-e002.sh <file> <riga>}"
[ -f "$FILE" ] || { echo "⛔ file inesistente" >&2; exit 2; }
case "$FILE" in *.sh) ;; *) echo "⛔ solo .sh" >&2; exit 2;; esac

python3 - "$FILE" "$RIGA" <<'PY'
import re, sys, subprocess, tempfile, os

f, n = sys.argv[1], int(sys.argv[2])
righe = open(f).readlines()
i = n - 1
if not (0 <= i < len(righe)):
    print("riga fuori range", file=sys.stderr); sys.exit(1)
linea = righe[i].rstrip("\n")

# nome variabile che non collide
contenuto = "".join(righe)
v = "_cp"
k = 2
while v in contenuto:
    v = f"_cp{k}"; k += 1

# Forma A: ^(\s*)if (PRODUCER) | grep (RESTO...); then
mA = re.match(r"^(\s*)if\s+(.+?)\s*\|\s*grep\s+(.+?);?\s*then\s*$", linea)
# Forma B: ^(\s*)if (COND ||)+ PRODUCER | grep (RESTO); then  — la condizione
# resta nell'if, la cattura contiene SOLO il produttore dell'ultima pipe
mB = re.match(r"^(\s*)if\s+((?:\[[^\]]*\]\s*\|\|\s*)+)(.+?)\s*\|\s*grep\s+(.+?);?\s*then\s*$", linea)

nuovo = None
# mB PRIMA di mA: mB e' piu' specifica (condizione composta) e mA e' un superset
# che altrimenti cattura anche le forme B, mettendo la condizione nella cattura
if mB:
    ind, cond, prod, resto = mB.group(1), mB.group(2), mB.group(3), mB.group(4)
    nuovo = [f"{ind}{v}=$({prod})\n", f'{ind}if {cond}grep {resto} <<<"${v}"; then\n']
elif mA:
    ind, prod, resto = mA.group(1), mA.group(2), mA.group(3)
    nuovo = [f"{ind}{v}=$({prod})\n", f'{ind}if grep {resto} <<<"${v}"; then\n']
else:
    print("forma non riconosciuta — all'agente", file=sys.stderr); sys.exit(1)

righe[i:i+1] = nuovo
open(f, "w").writelines(righe)

# sintassi: il file trasformato deve compilare
r = subprocess.run(["bash", "-n", f], capture_output=True)
if r.returncode != 0:
    # ripristina: mai lasciare un file rotto
    righe[i:i+2] = [linea + "\n"]
    open(f, "w").writelines(righe)
    print("sintassi rotta dopo la trasformazione — ripristinato", file=sys.stderr)
    sys.exit(1)
print(f"trasformato: riga {n} in cattura-prima (var {v})")
PY
