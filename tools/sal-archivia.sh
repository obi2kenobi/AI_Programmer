#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$HERE/SAL.md" "$HERE/SAL-ARCHIVIO.md" "${1:-30}" <<'PY'
import sys, re, os
sal_p, arch_p, giorni = sys.argv[1], sys.argv[2], int(sys.argv[3])
from datetime import datetime, timedelta
limite = (datetime.now() - timedelta(days=giorni)).strftime('%Y-%m-%d')
sal = open(sal_p, encoding='utf-8').read()
idx = sal.find('\n## ', sal.find('## Indice'))
header, body = (sal[:idx if idx > 0 else len(sal)], sal[idx if idx > 0 else len(sal):])
parts = re.split(r'(?=^### )', body, flags=re.M)
vecchie = [p for p in parts if re.match(r'### (\d{4}-\d{2}-\d{2})', p) and re.match(r'### (\d{4}-\d{2}-\d{2})', p).group(1) < limite]
recenti = [p for p in parts if p not in vecchie]
if vecchie:
    with open(arch_p, 'a', encoding='utf-8') as f: f.write('\n' + ''.join(vecchie))
    with open(sal_p, 'w', encoding='utf-8') as f: f.write(header + ''.join(recenti))
    print(f'archiviate {len(vecchie)} voci (<{limite})')
else: print(f'nessuna voce < {limite}')
PY
