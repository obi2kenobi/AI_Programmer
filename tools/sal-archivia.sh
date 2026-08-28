#!/bin/bash
# sal-archivia.sh — ruota il SAL: le voci più vecchie di N giorni (default 30)
# lasciano SAL.md e si ACCODANO a SAL-ARCHIVIO.md. Perché la rotazione: il SAL è
# la memoria VIVA del diario — se cresce senza limite, chi cerca l'ultima
# lezione paga tutte le precedenti a ogni lettura. L'archivio non si cancella
# mai: la memoria si sposta, non si perde. (Perché N giorni e non "a mano":
# una regola meccanica non dipende da nessuno che se ne ricordi.)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# I path sono overridabili (SAL= ARCHIVIO=) per il test in sandbox: il default
# resta il repo — il test NON ruota il SAL vero.
SAL="${SAL:-$HERE/SAL.md}"; ARCHIVIO="${ARCHIVIO:-$HERE/SAL-ARCHIVIO.md}"
python3 - "$SAL" "$ARCHIVIO" "${1:-30}" <<'PY'
import sys, re, os
sal_p, arch_p, giorni = sys.argv[1], sys.argv[2], int(sys.argv[3])
from datetime import datetime, timedelta
limite = (datetime.now() - timedelta(days=giorni)).strftime('%Y-%m-%d')
sal = open(sal_p, encoding='utf-8').read()
# Il punto di taglio NON è il primo "## ": è il primo DO l'indice. L'indice del
# diario (rigenerato da sal-indice.sh) elenca tutte le voci — tagliare prima
# significherebbe archiviare l'indice stesso insieme alle voci vecchie, e il
# SAL che resta resterebbe senza navigazione.
idx = sal.find('\n## ', sal.find('## Indice'))
header, body = (sal[:idx if idx > 0 else len(sal)], sal[idx if idx > 0 else len(sal):])
# Lo split (?=^### ) conserva il delimitatore in testa a ogni pezzo: ogni voce
# resta un blocco autosufficiente con il proprio "### data — titolo".
parts = re.split(r'(?=^### )', body, flags=re.M)
# Solo le voci CON data nel titolo sono candidate all'archivio: una voce senza
# data (per errore di scrittura) resta nel vivo — meglio un SAL lungo che una
# lezione persa per una regex golosa.
vecchie = [p for p in parts if re.match(r'### (\d{4}-\d{2}-\d{2})', p) and re.match(r'### (\d{4}-\d{2}-\d{2})', p).group(1) < limite]
recenti = [p for p in parts if p not in vecchie]
if vecchie:
    # ACCODA all'archivio (mai sovrascrive): l'archivio è append-only per lo
    # stesso principio dei report di campo — la storia non si riscrive.
    with open(arch_p, 'a', encoding='utf-8') as f: f.write('\n' + ''.join(vecchie))
    with open(sal_p, 'w', encoding='utf-8') as f: f.write(header + ''.join(recenti))
    print(f'archiviate {len(vecchie)} voci (<{limite})')
else: print(f'nessuna voce < {limite}')
PY
