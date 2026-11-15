#!/bin/bash
# deploy-gas.sh — CLASP finalmente permesso, col protocollo del curatore-rilasci
# (emendamento della legge «clasp push MAI», Luca 14/10: maturita' di progetto
# e partecipanti). La porta non si apre a mano: si apre a REGOLE:
#   1. banco verde  2. lente PULITA sul diff  3. BACKUP del progetto vivo
#   (clasp pull, verificato NON VUOTO)  4. MANIFEST con rollback scritto
#   5. solo allora clasp push — e la riga va nel log.
# Il rollback: il backup in .git/deploy-backup/<ts>/ + la versione GAS precedente.
# Uso: deploy-gas.sh <dir-progetto-clasp>
#
# (15/11, caso PR #128): lo script e' AUTOSUFFICIENTE. Prima caricava
# night-shift/lib.sh e chiamava tools/lente-sicurezza.sh, che vivono solo
# nell'hub: nei satelliti il cancello restava rotto (sempre NO). Ora: se
# l'hub c'e' si usa l'hub (una sola logica, niente duplicati), altrimenti
# fallback interni, dichiarati in uscita. Il cancelliere dei merge (rev.30)
# verifica l'autoconsistenza: ogni percorso referenziato esiste nel ramo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$HERE/night-shift/lib.sh" ]; then
  # shellcheck source=../night-shift/lib.sh
  . "$HERE/night-shift/lib.sh"   # verifica_righe: il banco riga per riga, come lo legge il turno
else
  # ── fallback satellite: ai_timeout (stessa implementazione collaudata
  #    dell'hub, llm/_timeout.sh: GNU timeout/gtimeout, altrimenti perl con
  #    TERM al gruppo, 5s di grazia, poi KILL — rc 124 allo scadere) ─────────
  ai_timeout() {
    local secs="$1"; shift
    local gnu="" t0=$SECONDS rc
    if command -v timeout >/dev/null 2>&1; then gnu=timeout; elif command -v gtimeout >/dev/null 2>&1; then gnu=gtimeout; fi
    if [ -n "$gnu" ]; then
      rc=0; command "$gnu" -k 5 "$secs" "$@" || rc=$?
      case "$secs" in *[!0-9]*|"") ;; *) [ "$rc" -eq 137 ] && [ $((SECONDS - t0)) -ge "$secs" ] && rc=124 ;; esac
      return "$rc"
    fi
    command perl -e '
      my $s = shift; my $pid = 0;
      $SIG{ALRM} = sub {
        if ($pid) {
          kill "TERM", -$pid;
          for (1 .. 50) { last if waitpid($pid, 1) > 0; select(undef, undef, undef, 0.1) }
          kill "KILL", -$pid;
        }
        exit 124 };
      alarm $s;
      $pid = fork();
      if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127 }
      waitpid($pid, 0);
      exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
    ' "$secs" "$@"
  }
  # ── fallback satellite: verifica_righe, il banco riga per riga (stesso
  #    contratto di .night-verify: una riga = un comando, @sec = budget) ──────
  verifica_righe() {
    local dir="$1" hdr riga sec rc=0
    [ -f "$dir/.night-verify" ] || { echo "verifica_righe: $dir/.night-verify assente" >&2; return 2; }
    hdr=$(head -10 "$dir/.night-verify")
    if grep -q '^# FORMATO: script' <<<"$hdr"; then
      (cd "$dir" && ai_timeout 1800 bash .night-verify >/dev/null 2>&1 </dev/null) || { echo "ROSSA: .night-verify (formato script)"; return 1; }
      return 0
    fi
    while IFS= read -r riga; do
      case "$riga" in ''|'#'*) continue ;; esac
      sec=120
      case "$riga" in @*' '*) sec="${riga%% *}"; sec="${sec#@}"; riga="${riga#* }" ;; esac
      if ! (cd "$dir" && ai_timeout "$sec" bash -c "$riga" >/dev/null 2>&1 </dev/null); then
        rc=1; echo "ROSSA: $(printf '%s' "$riga" | cut -c1-110)"
      fi
    done < "$dir/.night-verify"
    return "$rc"
  }
fi
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
# (2026-11-10): era `bash .night-verify` intero — il rc dell'ULTIMA riga: un rosso in mezzo spediva lo stesso
if [ -f .night-verify ]; then RIGHE_R=$(verifica_righe . 2>&1) && echo "1. banco: VERDE (riga per riga)" || { echo "1. banco: ROSSO — $(head -2 <<<"$RIGHE_R" | tr '\n' ' ' | cut -c1-140)"; KO=1; }; else echo "1. banco: assente (dichiarato)"; fi
# (2026-11-10): era `LEN=$(bash lente… ; true)` e poi `LEN_RC=$?` — il $? era quello del `true`: la lente
# risultava SEMPRE «PULITA» e il push partiva anche con RILIEVI (1) o DEGRADATA (2). Ora il rc e' quello della lente.
# (La base era `origin/$(… && echo main || echo main)`: main in ogni caso, scritta per quello che e'.)
# (15/11): la lente §2bis completa vive solo nell'hub. Nei satelliti il fallback
# e' lo strato DETERMINISTICO — le forme di segreto lette dalla stessa fonte
# della lente (tools/privacy-check.sh) piu' le credenziali letterali — sulle
# righe AGGIUNTE del diff origin/main...HEAD. Posizioni stampate, contenuto MAI.
if [ -f "$HERE/tools/lente-sicurezza.sh" ]; then
  LEN=$(bash "$HERE/tools/lente-sicurezza.sh" "$PWD" origin/main 2>/dev/null)
  LEN_RC=$?
  [ "$LEN_RC" -eq 0 ] && echo "2. lente: PULITA" || { echo "2. lente: rc=$LEN_RC — solo PULITA si spedisce"; KO=1; }
else
  SHAPES=$(sed -n "s/^SHAPES='\(.*\)'$/\1/p" "$HERE/tools/privacy-check.sh" 2>/dev/null)
  if [ -z "$SHAPES" ]; then
    echo "2. lente: DEGRADATA (forme di segreto illeggibili da tools/privacy-check.sh) — mai pulita per silenzio"; KO=1
  else
    LETTERALE='(secret|token|password|passwd|api[_-]?key|client[_-]?secret)[A-Za-z_]*["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$[:space:]]{8,}["'"'"']'
    AGG=$(git diff -U0 origin/main...HEAD -- . ':(exclude)graphify-out' 2>/dev/null | awk '/^\+\+\+ /{f=substr($2,3); next} /^@@/{split($3,a,","); n=substr(a[1],2)+0; next} /^\+/{print f ":" n ": " substr($0,2); n++}')
    TROVATI=$( { grep -E "$SHAPES" <<<"$AGG"; grep -iE "$LETTERALE" <<<"$AGG"; } | sort -u | cut -d: -f1-2 | sort -u )
    N_TROV=$(grep -c . <<<"$TROVATI" || true)
    if [ "${N_TROV:-0}" -gt 0 ]; then
      echo "2. lente: RILIEVI ($N_TROV) — possibili segreti nel diff (solo posizioni, il contenuto non si stampa):"
      sed 's/^/   - /' <<<"$TROVATI"
      KO=1
    else
      echo "2. lente: PULITA (solo forme: il cervello §2bis resta un servizio dell'hub)"
    fi
  fi
fi
# (difetto trovato facendo il deploy VERO del Riordino 15/10): il backup va
# fatto in DIRECTORY ISOLATA — un clasp pull qui scaricherebbe i file VECCHI
# sopra i nuovi, e il push dopo spingerebbe il vecchio. Il backup ha la sua
# copia di .clasp.json e tira li'.
BK="$DIR/.git/deploy-backup/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BK"
cp .clasp.json "$BK/.clasp.json" 2>/dev/null
if (cd "$BK" && clasp pull >/dev/null 2>&1); then
  # byte VERI dei file (prima: wc -c sull'ELENCO dei percorsi — il messaggio mentiva)
  N_BK=$(find "$BK" -type f ! -name .clasp.json -exec cat {} + | wc -c | tr -d ' ')
  if [ "${N_BK:-0}" -gt 0 ]; then
    echo "3. backup vivo: $BK ($N_BK byte verificati, isolato)"
  else
    echo "3. BACKUP vuoto — il deploy si ferma (mai senza ritorno)"; KO=1
  fi
else
  echo "3. BACKUP non riuscito — il deploy si ferma (mai senza ritorno)"; KO=1
fi
[ "$KO" -eq 0 ] || { echo "DEPLOY-GAS: NO (cure scritte sopra)"; exit 1; }
printf '# MANIFEST deploy %s\nbackup: %s\nrollback: clasp push < backup o versione GAS precedente (Deploy > Manage versions)\nverificato: banco+lente verdi\n' "$(date '+%F %T')" "$BK" > MANIFEST.md
# l'esito e' quello di clasp, catturato PRIMA di tail (prima: tail lo mascherava e «SI» usciva sempre)
PUSH_OUT=$(clasp push 2>&1); PUSH_RC=$?
echo "$PUSH_OUT" | tail -2
if [ "$PUSH_RC" -ne 0 ]; then
  echo "DEPLOY-GAS: NO — clasp push fallito (rc=$PUSH_RC); il vivo puo' essere a meta': rollback dal backup $BK (vedi MANIFEST.md)"
  exit 1
fi
echo "DEPLOY-GAS: SI — spinto col MANIFEST e il rollback pronti"
