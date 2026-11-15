#!/bin/bash
# graphify-patch-gs.sh — insegna a graphify che i file .gs (Google Apps Script)
# sono JavaScript: estrazione AST, famiglia jsts, risoluzione richiami.
# IDEMPOTENTE: se la patch c'è già esce 0 senza toccare nulla.
# Da rilanciare dopo OGNI upgrade di graphify (l'upgrade cancella la patch).
# Lezione 15/11/2026: senza questa patch i grafi delle repo GAS non contengono
# il backend (Centrale_Rischi: 837 nodi senza .gs → 962 con, +118 funzioni).
set -euo pipefail

PKG=$(find ~/.local/share/uv/tools/graphifyy ~/.local/share/pipx/venvs/graphifyy \
  -type d -name "graphify" -path "*site-packages*" 2>/dev/null | head -1 || true)
[ -z "$PKG" ] && { echo "KO: pacchetto graphify non trovato"; exit 1; }

if grep -q '"\.gs": extract_js' "$PKG/extract.py" 2>/dev/null; then
  echo "OK: patch .gs già presente in $PKG — niente da fare"
  exit 0
fi

python3 - "$PKG" << 'PYEOF'
import sys
GP = sys.argv[1]

def patch(path, old, new, nome):
    p = f"{GP}/{path}"
    s = open(p).read()
    if new.strip() in s:
        print(f"  {nome}: già presente")
        return
    assert old in s, f"{nome}: punto non trovato in {p}"
    open(p, "w").write(s.replace(old, new, 1))
    print(f"  {nome}: applicata")

patch("detect.py",
  "'.cls', '.trigger', '.lisp'",
  "'.cls', '.trigger', '.gs', '.lisp'",
  "CODE_EXTENSIONS")
patch("extract.py",
  '".vue": "jsts", ".svelte": "jsts", ".astro": "jsts",',
  '".vue": "jsts", ".svelte": "jsts", ".astro": "jsts",\n    ".gs": "jsts",',
  "famiglia jsts")
patch("extract.py",
  '    ".js": extract_js,\n',
  '    ".gs": extract_js,\n    ".js": extract_js,\n',
  "dispatch extract_js")
patch("extractors/resolution.py",
  '_JS_RESOLVE_EXTS = (".ts", ".tsx", ".mts", ".cts", ".svelte", ".js", ".jsx", ".mjs", ".cjs")',
  '_JS_RESOLVE_EXTS = (".ts", ".tsx", ".mts", ".cts", ".svelte", ".js", ".jsx", ".mjs", ".cjs", ".gs")',
  "risoluzione import")
patch("extract.py",
  '_JS_TS_CALL_SUFFIXES = (".ts", ".tsx", ".mts", ".cts", ".js", ".jsx", ".mjs", ".cjs")',
  '_JS_TS_CALL_SUFFIXES = (".ts", ".tsx", ".mts", ".cts", ".js", ".jsx", ".mjs", ".cjs", ".gs")',
  "call suffixes")
print("patch applicata")
PYEOF

find ~/.local/share/uv/tools/graphifyy ~/.local/share/pipx/venvs/graphifyy \
  -name "__pycache__" -type d -path "*graphify*" -exec rm -rf {} + 2>/dev/null || true
echo "OK: patch .gs applicata in $PKG (cache Python pulita)"
