#!/bin/bash
# installa-citati.sh <cartella-repo> [--solo-mancanti] — gli strumenti e i file che lo standard CITA
# viaggiano con lui. UNA lista sola per tools/sync-repo.sh --standard, tools/bootstrap-app.sh e
# tools/onboard-repo.sh (Q15, 2026-09-23, giro A8 della notte): la lista viveva scritta a mano in
# sync-repo, e il bootstrap e l'onboard non la vedevano — una repo nuova riceveva un CLAUDE.md che
# cita `bash tools/debiti-riapertura.sh`, il REGISTRO e i guardiani del commit, senza nessuno di loro
# (lo stesso difetto del report REPO-I, curato in un installatore su tre).
#
# Stampa i percorsi scritti, relativi alla repo, uno per riga: chi chiama li aggiunge a git.
# --solo-mancanti: non sovrascrive nulla che ci sia gia' (l'onboard di una repo esistente).
# Lo STATO del satellite (DEBITI.md, il REGISTRO) non si sovrascrive MAI: da zero arriva lo
# scheletro, l'intestazione dell'hub fino alla prima voce (Q13).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:?uso: installa-citati.sh <cartella-repo> [--solo-mancanti]}"
SOLO_MANCANTI=0; [ "${2:-}" = "--solo-mancanti" ] && SOLO_MANCANTI=1
[ -d "$DEST" ] || { echo "installa-citati: $DEST non esiste" >&2; exit 1; }

# le lenti dello standard coi loro dati (report REPO-F: la lente senza la sua lista di esclusione
# non e' la lente — 10 rossi il giorno zero); gli strumenti citati (report REPO-I, Budget Vendite,
# audit 2026-09-23); i guardiani del commit (D13; l'attivazione resta `git config core.hooksPath
# .githooks`); il formato del report di campo, MAI le voci (docs/campo/ dell'hub ha voci di altri
# clienti: privacy); il garante (report REPO-F, difetto 5).
LENTI="tools/fixture-provenienza.sh tools/cita-verifica.sh tools/debiti-riapertura.sh tools/.file-del-target"
CITATI="docs/ngiri-paralleli.md tools/privacy-check.sh tests/test-errori.sh tools/gas-gate.sh tools/py-gate.sh tools/fork-stato.sh tools/presidio.sh tools/polilivello.sh"
GUARDIANI=".githooks tools/pre-commit.sh"
FORMATI="docs/campo/README.md tools/garante-standard.sh"
STATO="DEBITI.md docs/errori/REGISTRO.md"

N=0
for P in $STATO; do
  [ -e "$HERE/$P" ] || continue
  [ -e "$DEST/$P" ] && continue
  mkdir -p "$DEST/$(dirname "$P")"
  awk '/^## /{exit} {print}' "$HERE/$P" > "$DEST/$P" || exit 1
  echo "$P"; N=$((N+1))
done
for P in $LENTI $CITATI $GUARDIANI $FORMATI; do
  [ -e "$HERE/$P" ] || continue
  if [ -d "$HERE/$P" ]; then
    # il CONTENUTO nella directory (cp -r dir dir annida: .githooks/.githooks), file per file
    while IFS= read -r F; do
      R="$P/${F#"$HERE/$P/"}"
      [ "$SOLO_MANCANTI" -eq 1 ] && [ -e "$DEST/$R" ] && continue
      mkdir -p "$DEST/$(dirname "$R")"
      cp -p "$F" "$DEST/$R" || exit 1
      echo "$R"; N=$((N+1))
    done < <(find "$HERE/$P" -type f)
  else
    [ "$SOLO_MANCANTI" -eq 1 ] && [ -e "$DEST/$P" ] && continue
    mkdir -p "$DEST/$(dirname "$P")"
    cp -p "$HERE/$P" "$DEST/$P" || exit 1
    echo "$P"; N=$((N+1))
  fi
done
# (2026-09-24, quinto ventaglio, R2 R6): PROJECT.md — il CLAUDE.md del satellite lo cita (§6), ma lo creava
# solo il bootstrap. Da onboard e sync arriva lo stesso scheletro, se manca; mai sopra quello del progetto.
if [ ! -e "$DEST/PROJECT.md" ]; then
  printf '# PROJECT.md — contesto specifico di %s\n\nSezione per progetto: comandi, validation artifact (regola "Done means proven"),\nconvenzioni locali. Le regole universali stanno in CLAUDE.md (ereditate dal hub\nAI_Programmer: aggiornale LÌ, non qui).\n' "$(basename "$(cd "$DEST" && pwd)")" > "$DEST/PROJECT.md"
  echo "PROJECT.md"; N=$((N+1))
fi
# (R2 R6): il gate GAS si seminava solo se .night-verify MANCAVA (sync-repo) — l'onboard ne scrive uno di
# soli commenti, e la prima notte il turno apriva «verifiche-vuote» su una repo che ha il suo gate. Ora: repo
# GAS (file .gs/.html in git) e nessun comando dichiarato → la riga del gate. Una dichiarazione vera
# («# NON-VERIFICABILE: <motivo>» a inizio riga, non l'esempio del modello) e' la scelta di una persona: resta.
NV="$DEST/.night-verify"
if [ -n "$(git -C "$DEST" ls-files '*.gs' '*.html' 2>/dev/null)" ] && ! grep -qvE '^[[:space:]]*(#|$)' "$NV" 2>/dev/null \
   && ! grep -qE '^#[[:space:]]*NON-VERIFICABILE:[[:space:]]*[^<[:space:]]' "$NV" 2>/dev/null; then
  [ -f "$NV" ] || printf '# Verifiche dichiarate del turno di notte (una riga per comando).\n# VUOTO = il gate lo dice. Dichiara i comandi appena puoi.\n' > "$NV"
  echo "bash tools/gas-gate.sh" >> "$NV"
  echo ".night-verify"; N=$((N+1))
fi
echo "installa-citati: $N file scritti in $DEST$([ "$SOLO_MANCANTI" -eq 1 ] && echo ' (solo i mancanti: quelli già presenti restano intatti)')" >&2
exit 0
