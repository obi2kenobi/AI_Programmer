#!/usr/bin/env python3
"""e002-siti.py — elenca i siti della famiglia E-002 nei file bash sotto pipefail: `… | grep -q`.

Uso: python3 tools/e002-siti.py <file.sh>...   (stampa file:riga, uno per riga; esce 0 comunque)

Perché (2026-09-23, notte dei giri): sotto `set -o pipefail`, `produttore | grep -q` e' un esito a
caso — grep esce al primo riscontro, il produttore muore di SIGPIPE (rc 141) e la condizione diventa
FALSA proprio quando il riscontro c'e'. Misurato: tests/test-suite-meta-audit.sh rosso 18 volte su 20
sotto carico. Una regex di grep non sa dire se il `| grep -q` sta dentro una stringa (un messaggio,
una fixture): qui si guarda lo stato delle virgolette, e i commenti non contano.
"""
import re
import sys

PIPE_GREP = re.compile(r"(?<!\|)\|(?!\|)\s*grep\s+-[a-zA-Z]*q")


def dentro_virgolette(riga, pos):
    """True se la posizione pos della riga sta dentro '…' o "…" (le barre rovesciate contano)."""
    q = None
    i = 0
    while i < pos:
        c = riga[i]
        if q:
            if c == "\\" and q == '"':
                i += 2
                continue
            if c == q:
                q = None
        elif c == "\\":
            i += 2
            continue
        elif c in "\"'":
            q = c
        i += 1
    return q is not None


def siti(percorso):
    """I siti file:riga di un file, solo se il file e' sotto pipefail (altrove la forma non morde)."""
    testo = open(percorso, encoding="utf-8", errors="replace").read()
    if "pipefail" not in testo:
        return []
    trovati = []
    for n, riga in enumerate(testo.split("\n"), start=1):
        if riga.lstrip().startswith("#"):
            continue
        if any(not dentro_virgolette(riga, m.start()) for m in PIPE_GREP.finditer(riga)):
            trovati.append(f"{percorso}:{n}")
    return trovati


if __name__ == "__main__":
    for f in sys.argv[1:]:
        for s in siti(f):
            print(s)
