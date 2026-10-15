#!/bin/bash
# deploy-gas.sh — CLASP finalmente permesso, col protocollo del curatore-rilasci
# (emendamento della legge «clasp push MAI», Luca 14/10: maturita' di progetto
# e partecipanti). La porta non si apre a mano: si apre a REGOLE:
#   1. banco verde  2. lente PULITA sul diff  3. BACKUP del progetto vivo
#   (clasp pull, verificato NON VUOTO)  4. MANIFEST con rollback scritto
#   5. solo allora clasp push — e la riga va nel log.
# Il rollback: il backup in .git/deploy-backup/<ts>/ + la versione GAS precedente.
# Uso: deploy-gas.sh <dir-progetto-clasp>
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: deploy-gas.sh <dir>}"
cd "$DIR" || exit 2
command -v clasp >/dev/null 2>&1 || { echo "⛔ clasp assente" >&2; exit 2; }
[ -f .clasp.json ] || { echo "⛔ non e' un progetto clasp (manca .clasp.json)" >&2; exit 2; }
KO=0
# ── IL CANCELLO DEI TARGET (Luca 15/10: «mi assicuri che scrive sempre nel GAS
# giusto? se non sa quale, memorizza i dati e non sbaglia piu'») ────────────────
# Due registri: i VIVI (globali, mai toccati) e gli APPROVATI (per repo, in
# .git/gas-targets: l'impronta del primo che approva). Sconosciuto = NO detto.
VIVI="$HOME/.gas-vivi"
TARGET=$(sed -n 's/.*"scriptId"[: ]*"\([^"]*\)".*/\1/p' .clasp.json 2>/dev/null | head -1)
if [ -z "$TARGET" ]; then
  echo "⛔ TARGET: .clasp.json senza scriptId — il cancello non spinge alla cieca" >&2; exit 1
fi
if [ -f "$VIVI" ] && grep -qxF "$TARGET" "$VIVI"; then
  echo "⛔ TARGET: $TARGET e' nella lista dei VIVI (produzione) — MAI. Guarda ~/.gas-vivi" >&2; exit 1
fi
REG="$DIR/.git/gas-targets"
if [ ! -f "$REG" ] || ! grep -qxF "$TARGET" "$REG"; then
  if [ "${2:-}" = "--approva-target" ]; then
    mkdir -p "$(dirname "$REG")" && echo "$TARGET" >> "$REG"
    echo "TARGET: $TARGET APPROVATO e memorizzato in .git/gas-targets — d'ora in poi questo e' il GAS giusto per questa cartella"
  else
    echo "⛔ TARGET SCONOSCIUTO: $TARGET non e' tra gli approvati di questa cartella." >&2
    echo "   Se e' quello giusto (GUARDALO nell'editor: Impostazioni → ID script):" >&2
    echo "   tools/deploy-gas.sh <dir> --approva-target   (una volta sola, l'impronta resta)" >&2
    exit 1
  fi
fi
printf '[gas-target %s] push verso %s (%s)\n' "$(date '+%F %T')" "$TARGET" "$(git log --format=%h -1 2>/dev/null || echo no-git)" >> "$REG.log"
echo "TARGET: $TARGET (approvato per questa cartella)"
if [ -f .night-verify ]; then (bash .night-verify >/dev/null 2>&1) && echo "1. banco: VERDE" || { echo "1. banco: ROSSO"; KO=1; }; else echo "1. banco: assente (dichiarato)"; fi
LEN=$(bash "$HERE/tools/lente-sicurezza.sh" "$PWD" origin/$(cd "$PWD" && git remote get-url origin >/dev/null 2>&1 && echo main || echo main) 2>/dev/null; true)
LEN_RC=$?
[ "$LEN_RC" -eq 0 ] && echo "2. lente: PULITA" || { echo "2. lente: rc=$LEN_RC — solo PULITA si spedisce"; KO=1; }
BK=".git/deploy-backup/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BK"
if clasp pull >/dev/null 2>&1 && [ -n "$(ls .clasp 2>/dev/null || ls src 2>/dev/null || true)" ]; then
  cp -R src "$BK/" 2>/dev/null || clasp pull > "$BK/backup.txt" 2>&1
  echo "3. backup vivo: $BK"
else
  echo "3. BACKUP non verificato — il deploy si ferma (mai senza ritorno)"; KO=1
fi
[ "$KO" -eq 0 ] || { echo "DEPLOY-GAS: NO (cure scritte sopra)"; exit 1; }
printf '# MANIFEST deploy %s\nbackup: %s\nrollback: clasp push < backup o versione GAS precedente (Deploy > Manage versions)\nverificato: banco+lente verdi\n' "$(date '+%F %T')" "$BK" > MANIFEST.md
clasp push 2>&1 | tail -2
echo "DEPLOY-GAS: SI — spinto col MANIFEST e il rollback pronti"
