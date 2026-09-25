#!/bin/bash
# test-verifica-visiva-prima.sh — il confronto con la volta prima che la skill verifica-visiva promette
# (2026-09-24, terzo ventaglio, V3#5). Prima: .claude/skills/verifica-visiva/SKILL.md §1.3 diceva di
# confrontare con lo screenshot precedente «allo stesso percorso», ma tools/verifica-visiva.js scriveva
# sopra quel percorso senza guardare: il «prima» spariva proprio mentre lo si voleva confrontare.
# Ora il vecchio file si sposta in <nome>.prima.png e l'uscita dice «prima N byte → dopo M byte».
# Chromium qui e' un finto (CHROME_PATH): il banco giudica lo strumento, non il browser.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
command -v node >/dev/null 2>&1 || { echo "node non disponibile, salto"; exit 0; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# il finto Chromium: --dump-dom stampa una pagina sana, --screenshot=X scrive in X il contenuto di $PNG_FINTO
cat > "$T/chrome" <<'STUB'
#!/bin/bash
for a in "$@"; do
  case "$a" in
    --dump-dom) echo '<html><body>Cruscotto magazzino: giacenze aggiornate, 412 articoli, 3 sotto scorta minima</body></html>' ;;
    --screenshot=*) printf '%s' "$PNG_FINTO" > "${a#--screenshot=}" ;;
  esac
done
STUB
chmod +x "$T/chrome"
vv() { CHROME_PATH="$T/chrome" PNG_FINTO="$1" node "$HERE/tools/verifica-visiva.js" file:///pagina "$T/shot.png" 2>&1; }

# 1. prima volta: nessun precedente, niente .prima, e lo dice
OUT=$(vv "aaaa"); RC=$?
[ $RC -eq 0 ] && [ -f "$T/shot.png" ] && [ ! -e "$T/shot.prima.png" ] \
  && ok "primo screenshot: salvato, nessun .prima inventato" || ko "primo screenshot (rc=$RC): $OUT"

# 2. seconda volta: il vecchio non si perde, si sposta accanto
OUT=$(vv "bbbbbbbbbb"); RC=$?
[ $RC -eq 0 ] && [ "$(cat "$T/shot.prima.png" 2>/dev/null)" = "aaaa" ] && [ "$(cat "$T/shot.png")" = "bbbbbbbbbb" ] \
  && ok "secondo screenshot: il precedente e' conservato in shot.prima.png" \
  || ko "secondo screenshot: il precedente e' stato sovrascritto (rc=$RC): $OUT"

# 3. il confronto grezzo si stampa: prima N byte → dopo M byte
grep -c 'prima 4 byte → dopo 10 byte' <<<"$OUT" >/dev/null \
  && ok "l'uscita dice «prima 4 byte → dopo 10 byte»" || ko "l'uscita non riporta il confronto: $OUT"

# 4. la skill non promette piu' Playwright nel limite dichiarato (il §1 dice «NON Playwright»)
! grep -c 'Playwright/Chromium' "$HERE/.claude/skills/verifica-visiva/SKILL.md" >/dev/null \
  && ok "la skill non cita piu' Playwright come meccanismo" || ko "la skill dice ancora «Playwright/Chromium» nel §3"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
