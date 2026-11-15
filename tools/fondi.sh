#!/bin/bash
# fondi.sh — l'AUTO-MERGE a condizioni (emendamento D10, Luca 14/10: «la maturita'
# del progetto e dei partecipanti ci impone... pull push in maniera automatica»).
# Il cancello umano NON sparisce: cambia guardia. La PR si fonde SOLO se:
#   1. e' fondibile (GitHub pulito)
#   2. la lente sicurezza ha detto PULITA (o RILIEVI gia' curati: verdetto nel commento)
#   3. il banco del repo e' verde (.night-verify)
#   4. il CENSORE APPROVA (parere del revisore — l'umano resta informato, decide il sistema)
# Ogni condizione mancata = NO con la riga che dice quale. Mai silenzio.
# Uso: fondi.sh <dir-repo> <n-pr>
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# (15/11, stessa cura di deploy-gas.sh, caso PR #128): lo script e'
# AUTOSUFFICIENTE. Se l'hub c'e' si usa l'hub (una sola logica), altrimenti
# fallback interni, dichiarati in uscita: nei satelliti la cartella
# night-shift/ NON c'e' e il source nudo rompeva il cancello.
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
  echo "fondi: hub assente — fallback interni (ai_timeout, verifica_righe)" >&2
fi
DIR="${1:?uso: fondi.sh <dir> <n-pr>}"; N="${2:?}"
REPO=$(cd "$DIR" && git remote get-url origin 2>/dev/null | sed -e 's#.*github.com[:/]##' -e 's#\.git$##')
[ -n "$REPO" ] || { echo "⛔ origin non GitHub" >&2; exit 2; }
KO=0
ST=$(gh pr view "$N" --repo "$REPO" --json mergeable,state,isDraft --jq '"\(.state) \(.mergeable) \(.isDraft)"' 2>/dev/null)
if [[ "$ST" == *MERGEABLE*true* ]]; then
  echo "1. fondibile: SI — bozza promossa a pronta (le 4 condizioni sono la review)"
  gh pr ready "$N" --repo "$REPO" >/dev/null 2>&1 || true
elif [[ "$ST" == *MERGEABLE*false* ]]; then
  echo "1. fondibile: SI ($ST)"
else
  echo "1. fondibile: NO ($ST) — conflitti"; KO=1
fi
VER=$(gh pr view "$N" --repo "$REPO" --json comments --jq '.comments[].body' 2>/dev/null | grep -oE 'LENTE SICUREZZA: [A-Z]+' | tail -1)
case "$VER" in *"PULITA") echo "2. lente: $VER";; *) echo "2. lente: ${VER:-ASSENTE} — serve il verdetto PULITA nel commento"; KO=1;; esac
if [ -f "$DIR/.night-verify" ]; then
  # (2026-11-10): era `bash .night-verify` intero — il rc dell'ULTIMA riga: un rosso in mezzo fondeva lo stesso
  RIGHE_R=$(verifica_righe "$DIR" 2>&1) && echo "3. banco: VERDE (riga per riga)" || { echo "3. banco: ROSSO — $(head -2 <<<"$RIGHE_R" | tr '\n' ' ' | cut -c1-140)"; KO=1; }
else
  echo "3. banco: assente (dichiarato)"
fi
# (18/10): prima LEGGI il parere gia' scritto nella PR (il censore non si ripete:
# se ha gia' giudicato questo commit, il suo verdetto e' nel commento). Solo se
# non c'e' ancora un parere, lo chiedi — e con GIORNO_SUBITO il censore ripete.
PAR_ESISTE=$(gh pr view "$N" --repo "$REPO" --json comments --jq '.comments[].body' 2>/dev/null   | grep -oE "(PARERE: APPROVA|DELIBERA: APPROVA|NON APPROVABILE)" | tail -1)
# (15/11, rassegna frontiera): le formule di approvazione si confrontano
# ESATTE, mai col glob *APPROVA* — «NON APPROVABILE» contiene «APPROVA» e un
# veto veniva contato come approvazione. Formule canoniche dell'audit 06/11:
# «PARERE: APPROVA» e «DELIBERA: APPROVA».
if [ -n "$PAR_ESISTE" ]; then
  case "$PAR_ESISTE" in
    "PARERE: APPROVA"|"DELIBERA: APPROVA") echo "4. censore: APPROVA (parere gia' nel commento)";;
    *) echo "4. censore: $PAR_ESISTE (gia' detto nel commento — senza APPROVA esatto non si fonde)"; KO=1;;
  esac
else
  PAR=$(GIORNO_PARERE=1 GIORNO_SUBITO=1 bash "$HERE/night-shift/revisore.sh" "$DIR" "$N" 2>&1)
  PAR_VER=$(grep -oE "(PARERE: APPROVA|DELIBERA: APPROVA|NON APPROVABILE)" <<<"$PAR" | tail -1)
  case "$PAR_VER" in
    "PARERE: APPROVA"|"DELIBERA: APPROVA") echo "4. censore: APPROVA";;
    *) echo "4. censore: ${PAR_VER:-muto} — senza APPROVA esatto non si fonde"; KO=1;;
  esac
fi
[ "$KO" -eq 0 ] || { echo "FONDI: NO ($KO condizioni mancate, scritte sopra)"; exit 1; }
gh pr merge "$N" --repo "$REPO" --merge 2>&1 | tail -1
echo "FONDI: SI — PR #$N fusa dal sistema (4 condizioni verdi, censore approva)"
