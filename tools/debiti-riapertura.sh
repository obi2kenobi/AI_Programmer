#!/bin/bash
# debiti-riapertura.sh — IL DEBITO SI BRUCIA ALLA RIAPERTURA (regola di Luca, 2026-09-09):
# alla riapertura di un progetto, i debiti DI DOMINIO diventano DOMANDE SINGOLE (una alla
# volta, col perché) e quelli RISOLVIBILI si fanno PRIMA di procedere. Il debito non è un
# backlog che invecchia: è un passivo che matura interessi.
# ⚠ QUESTO TOOL NON SCRIVE: legge DEBITI.md e le domande aperte, e prepara la riapertura.
#
# Uso: bash tools/debiti-riapertura.sh [dir-progetto]   (default: repo corrente)
# Esce: 0 sempre (informa, non blocca — la pressione sta nel farla visibile)
set -uo pipefail
DIR="${1:-.}"
cd "$DIR" || { echo "⛔ dir inesistente: $DIR"; exit 1; }
echo "== RIAPERTURA: il debito si brucia qui =="

python3 - <<'PY'
import re, os, sys

def leggi(p):
    try: return open(p, encoding="utf-8", errors="ignore").read()
    except FileNotFoundError: return ""

deb = leggi("DEBITI.md")
if not deb:
    print("nessun DEBITI.md: niente da bruciare (dichiarato, non taciuto)")
    sys.exit(0)

# le sezioni aperte = senza SALDATO/saldato nel corpo
sezioni = re.split(r"^## ", deb, flags=re.M)[1:]
aperte = []
for s in sezioni:
    titolo = s.split("\n")[0].strip()
    if re.search(r"SALDATO|saldata|saldato", s, re.I):
        continue
    aperte.append((titolo, s))

# classificazione: DI DOMINIO se la sezione chiede una decisione/contains domande/dominio/Luca;
# RISOLVIBILE altrimenti (lavoro tecnico che la sessione può fare da sola)
dominio, risolvibili = [], []
for titolo, corpo in aperte:
    t = titolo.lower()
    if re.search(r"dominio|decis|domanda|luca|valutare da|da decidere|censire", t + " " + corpo.lower()[:600]):
        dominio.append((titolo, corpo))
    else:
        risolvibili.append((titolo, corpo))

print(f"debiti APERTI: {len(aperte)} — di DOMINIO: {len(dominio)} (domande, una alla volta) · RISOLVIBILI: {len(risolvibili)} (da fare PRIMA di procedere)")
print()
if risolvibili:
    print("DA FARE SUBITO (risolvibile — il prossimo lavoro parte dopo questi):")
    for i, (t, _) in enumerate(risolvibili, 1):
        print(f"  R{i}. {t}")
    print()
if dominio:
    print("DOMANDE SINGOLE PER IL PADRONE DEL DOMINIO (una alla volta, nell'ordine — ogni risposta chiude un debito):")
    for i, (t, c) in enumerate(dominio, 1):
        # la prima riga 'perché' utile dalla sezione, se c'è
        perche = next((l.strip("- #* ") for l in c.split("\n") if re.search(r"perch|serve|decide", l, re.I)), "")
        print(f"  D{i}. {t}")
        if perche: print(f"      perché conta: {perche[:100]}")
    print()
    print("Modello: una domanda per messaggio, risposta → subito codice/regola, poi la prossima.")
print(f"chiusi/storici: {len(sezioni) - len(aperte)} sezioni saldate restano come memoria.")
PY
