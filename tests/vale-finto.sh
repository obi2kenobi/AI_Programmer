#!/bin/bash
# vale-finto.sh — da includere (source) nei banchi che usano la lente documenti (2026-11-10).
# Senza Vale (sessioni cloud, Linux minimo) tools/lente-documenti.sh esce 0 «SALTATA» e i banchi
# erano rossi per l'ambiente, non per il codice. Se Vale manca, uno FINTO con la sola regola di casa
# (ASCII, tools/lente-documenti.vale.ini) nel formato line: percorso:riga:colonna:controllo:messaggio.
# Dove Vale c'e', vince il vero. Uso: VALE_FINTO_DIR=<cartella temporanea> ; . tests/vale-finto.sh
if ! command -v vale >/dev/null 2>&1; then
  mkdir -p "$VALE_FINTO_DIR"
  cat > "$VALE_FINTO_DIR/vale" <<'VALE'
#!/bin/bash
f="${*: -1}"
python3 -c 'import sys
for n, r in enumerate(open(sys.argv[1], encoding="utf-8", errors="replace"), 1):
    if any(ord(c) > 127 for c in r): print(f"{sys.argv[1]}:{n}:1:casa.AsciiSolo:carattere non ASCII")' "$f"
VALE
  chmod +x "$VALE_FINTO_DIR/vale"; export PATH="$VALE_FINTO_DIR:$PATH"
  echo "INFO vale assente: il banco usa un vale FINTO (solo la regola ASCII della casa)"
fi
