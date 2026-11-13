#!/bin/bash
# ocr-estrai.sh — estrae testo da PDF/immagini in markdown per gli agenti
# Subito: tesseract (installato, universale, CPU)
# Futuro mini: PaddleOCR (più preciso, serve Python ≤3.12)
set -euo pipefail
F="${1:?file}"; OUT="${2:-${1%.*}.md}"
if command -v tesseract >/dev/null 2>&1; then
  # tesseract: rapido, funziona subito
  if [[ "$F" == *.pdf ]]; then
    # PDF: converti in immagini poi OCR (richiede pdftoppm o sips)
    pdftoppm -png -r 300 "$F" /tmp/ocr_page 2>/dev/null || \
      sips -s format png "$F" --out /tmp/ocr_page.png 2>/dev/null
    for img in /tmp/ocr_page*.png; do
      tesseract "$img" - -l ita+eng 2>/dev/null
    done > "$OUT"
  else
    tesseract "$F" "$OUT" -l ita+eng 2>/dev/null && cat "$OUT"
  fi
  echo "→ $OUT ($(wc -l < "$OUT") righe)"
elif command -v paddleocr >/dev/null 2>&1; then
  # PaddleOCR: più preciso (quando installato sul mini)
  python3 -c "from paddleocr import PaddleOCR; ocr=PaddleOCR(lang='it'); print(ocr.ocr('$F'))" > "$OUT"
else
  echo "⚠ Nessun OCR disponibile. Installa: brew install tesseract tesseract-lang"
  exit 1
fi
