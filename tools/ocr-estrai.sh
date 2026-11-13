#!/bin/bash
# ocr-estrai.sh — estrae testo da PDF/immagini in markdown per gli agenti
# Setup: pip install paddleocr paddlepaddle (funziona su CPU, Air incluso)
# Uso: tools/ocr-estrai.sh <file.pdf|png|jpg> [output.md]
set -euo pipefail
F="${1:?file}"; OUT="${2:-${1%.*}.md}"
python3 -c "
from paddleocr import PaddleOCR
import sys
ocr = PaddleOCR(use_angle_cls=True, lang='it')
result = ocr.ocr('$F', cls=True)
lines = []
for page in result:
    for line in (page or []):
        text = line[1][0]
        conf = line[1][1]
        lines.append(text)
open('$OUT','w').write('\n'.join(lines))
print(f'estratte {len(lines)} righe -> $OUT')" 2>/dev/null || {
  echo "⚠ PaddleOCR non installato. Setup:"
  echo "  pip install paddleocr paddlepaddle"
  echo "Fallback: nessuno (OCR richiede il setup)"
  exit 1
}
