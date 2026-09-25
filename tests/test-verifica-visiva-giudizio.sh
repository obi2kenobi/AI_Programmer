#!/bin/bash
# test-verifica-visiva-giudizio.sh — il giudizio di tools/verifica-visiva.js su pagine VERE (Q21,
# 2026-09-23, giro A7 della notte). Misurato stanotte con Chromium headless: tre pagine che non sono
# la webapp davano exit 0, «verde»:
#   - la pagina d'accesso di Google (una webapp che chiede il login, aperta da un browser anonimo);
#   - la pagina d'errore del certificato («Privacy error … net::ERR_CERT_AUTHORITY_INVALID»);
#   - la pagina di rete irraggiungibile («This site can’t be reached … ERR_TUNNEL_CONNECTION_FAILED»).
# Nessun segnale d'errore noto e piu' di 40 caratteri di testo: per il tool erano pagine sane.
# E il Chromium di default era il percorso di questa cloud: sul Mac mancava, e l'errore diceva
# «impossibile aprire l'URL (rete, auth, timeout)».
#
# I testi qui sotto: prodotto da: /opt/pw-browsers/chromium --headless=new --dump-dom <url>, poi
# estraiTesto(), primi caratteri — accounts.google.com/ServiceLogin?hl=it e ?hl=en (con
# --ignore-certificate-errors, solo per misurare), la stessa senza (errore di certificato del
# proxy), https://host-inesistente.invalid/ (2026-09-23).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
command -v node >/dev/null 2>&1 || { echo "node non disponibile, salto"; exit 0; }

OUT=$(node -e '
const m = require(process.argv[1]);
if (typeof m.giudica !== "function") { console.log("KO giudica() non esportata: il giudizio non e provabile"); process.exit(0); }
const casi = [
  [2, "login Google (it)", "Accedi - Account Google Accedi Utilizza il tuo Account Google Email o telefono Non ricordi l indirizzo email? Non si tratta del tuo computer? Utilizza una finestra di navigazione privata per accedere."],
  [2, "login Google (en)", "Sign in - Google Accounts Sign in Use your Google Account Email or phone Forgot email? Not your computer? Use a private browsing window to sign in."],
  [2, "errore di certificato", "Privacy error Your connection is not private Attackers might be trying to steal your information from accounts.google.com (for example, passwords, messages, or credit cards). Learn more about this warning net::ERR_CERT_AUTHORITY_INVALID"],
  [2, "rete irraggiungibile", "host-inesistente.invalid This site can’t be reached The webpage at https://host-inesistente.invalid/ might be temporarily down or it may have moved permanently to a new web address. ERR_TUNNEL_CONNECTION_FAILED"],
  [1, "errore di script", "Errore di script: TypeError impossibile leggere la proprieta del foglio Vendite alla riga 12 del progetto"],
  [1, "pagina quasi vuota", "Caricamento"],
  [0, "webapp sana", "Cruscotto magazzino Treviso — giacenze aggiornate al 23/09, 412 articoli, 3 sotto scorta minima, ultimo movimento ore 18:40"],
];
for (const [atteso, nome, testo] of casi) {
  const g = m.giudica(testo);
  console.log((g.esito === atteso ? "OK " : "KO ") + nome + ": esito " + g.esito + " (atteso " + atteso + ") — " + g.motivo);
}' "$HERE/tools/verifica-visiva.js")
while IFS= read -r line; do
  case "$line" in
    OK*) PASS=$((PASS+1)); echo "OK   ${line#OK }";;
    KO*) FAIL=$((FAIL+1)); echo "FAIL ${line#KO }";;
  esac
done <<< "$OUT"

# il browser assente si dice come tale, non come «rete, auth, timeout»
OUT=$(CHROME_PATH=/percorso/inesistente/chrome node "$HERE/tools/verifica-visiva.js" https://example.invalid/ /tmp/nonserve.png 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -qi "chromium" <<<"$OUT" && ! grep -q "impossibile aprire" <<<"$OUT" \
  && ok "browser assente: exit 2 e lo dice (non «impossibile aprire l'URL»)" \
  || ko "browser assente detto male (rc=$RC): $OUT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
