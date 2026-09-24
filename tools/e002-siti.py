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


INCLUDE = re.compile(r"^\s*(?:source|\.)\s+(.*)$", re.M)   # la riga di inclusione; i nomi .sh si prendono tutti
NOME_SH = re.compile(r"([A-Za-z0-9_.-]+\.sh)\b")


def incluse_sotto_pipefail(percorsi):
    """I nomi dei file che uno script sotto pipefail include con `source`/`.` — girano sotto il SUO pipefail.
    (2026-09-24, terzo ventaglio): night-shift/lib.sh, llm/_timeout.sh e simili non scrivono `pipefail`,
    e il rilevatore li saltava sempre, benche' girino solo dentro script che lo hanno."""
    nomi = set()
    for p in percorsi:
        try:
            t = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        if "pipefail" in t:
            for m in INCLUDE.finditer(t):
                nomi.update(NOME_SH.findall(m.group(1)))
    return nomi


def siti(percorso, incluse=frozenset()):
    """I siti file:riga di un file, solo se gira sotto pipefail: lo dichiara, o lo include chi lo dichiara."""
    testo = open(percorso, encoding="utf-8", errors="replace").read()
    if "pipefail" not in testo and percorso.rsplit("/", 1)[-1] not in incluse:
        return []
    trovati = []
    for n, riga in enumerate(testo.split("\n"), start=1):
        if riga.lstrip().startswith("#"):
            continue
        if any(not dentro_virgolette(riga, m.start()) for m in PIPE_GREP.finditer(riga)):
            trovati.append(f"{percorso}:{n}")
    return trovati


if __name__ == "__main__":
    incluse = incluse_sotto_pipefail(sys.argv[1:])
    for f in sys.argv[1:]:
        for s in siti(f, incluse):
            print(s)
