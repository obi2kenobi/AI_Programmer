#!/bin/bash
# morning-digest.sh — il gate arriva nella mailbox, non nel filesystem (giro 3/10).
# Luca non deve ANDARE a leggere ~/morning-gate-report.md: il sistema viene da lui.
# Destinatario: ScriptProperty DIGEST_EMAIL (vuoto = no-op educato, come il digest notturno).
set -euo pipefail

# il destinatario vive in night-shift/repos.key (locale, gitignored): DIGEST_EMAIL=...
KEY="$(cd "$(dirname "$0")" && pwd)/repos.key"
DEST=""
if [ -f "$KEY" ]; then
  DEST=$(grep -E '^DIGEST_EMAIL=' "$KEY" | cut -d= -f2- | xargs)
fi
if [ -z "$DEST" ]; then
  echo "morning-digest: DIGEST_EMAIL non configurata in repos.key — digest saltato (aggiungi DIGEST_EMAIL=tu@esempio.it)"
  exit 0
fi

# (dominio, decisione di Luca 2026-09-23: digest autonomo): il gate e' in
# pensione dal 29/8 (il censore notturno ne ha preso il posto) e il digest non
# dipende piu' dal suo report. Se c'e', entra come allegato; la mattina vera
# sono le lezioni da approvare, gli sospesi e il resoconto della notte.
REPORT="$HOME/morning-gate-report.md"
CORPO_GATE=""
if [ -f "$REPORT" ]; then
  CORPO_GATE="$(cat "$REPORT")

---"
fi

# subject: la riga del totale dal report
SUBJ=$(grep "Totale:" "$REPORT" 2>/dev/null | head -1 | sed 's/[*\`]//g' | head -c 120)
[ -z "$SUBJ" ] && SUBJ="Mattina del sistema — $(date '+%Y-%m-%d')"

# corpo: il report + il summary numerico
BODY="${CORPO_GATE}$(bash "$(dirname "$0")/gate-summary.sh" 0 2>/dev/null || echo '(summary non disponibile)')
$(bash "$(dirname "$0")/gate-summary.sh" 0 2>/dev/null || echo '(summary non disponibile)')
$(SAL_TURNI="$(cd "$(dirname "$0")" && pwd)/.sal-turni.md"; [ -f "$SAL_TURNI" ] && {
  CICLI=$(grep -c "TURNO INIZIATO" "$SAL_TURNI" 2>/dev/null || echo 0)
  PR=$(grep -c "PR bozza" "$SAL_TURNI" 2>/dev/null || echo 0)
  FIX=$(grep -c "auto-fix" "$SAL_TURNI" 2>/dev/null || echo 0)
  echo "**Cicli notturni**: $CICLI / **PR**: $PR / **Fix**: $FIX"
  ASPETTA=$(sed -n "/ASPETTA IL GIORNO/,\$p" "$SAL_TURNI" 2>/dev/null | grep -c "  " || echo 0)
  [ "$ASPETTA" -gt 0 ] && echo "**ASPETTA IL GIORNO**: $ASPETTA decisioni pendenti"
  : > "$SAL_TURNI"
} || echo "(nessuna memoria del turno)")"

# il secondo cervello: gli sospesi compilati dal turno alla prima domanda del giorno
# ($WORK/.cervello-<data> — deterministico, scritto da night-shift.sh). C'e' quando
# c'e': il digest non dipende da lui, lo mostra in coda.
# (if/fi, non [ ]&&: sotto set -e un test falso al fondo di una catena && esce 1
# e ammazzava il digest la mattina che il marker manca)
# (il || true e' DENTRO, prima della pipe: ls su glob senza match esce 2, e con
# pipefail+set -e il digest moriva la mattina senza marker)
CERVMARK=$({ ls -t "$HOME"/night-shift-work/.cervello-????-??-?? 2>/dev/null || true; } | head -1)
if [ -n "$CERVMARK" ]; then
  BODY="$(printf '%s\n\n---\n%s' "$BODY" "$(cat "$CERVMARK")")"
fi

# escaping per AppleScript (giro 3/10, nuovo ciclo): il contenuto del report è testo
# arbitrario (titoli PR, output di comandi) — senza escaping, una virgoletta o un
# backslash al suo interno rompe o inietta nello script AppleScript. Stessa lezione
# già applicata al body della gh issue in morning-gate.sh, mai portata qui.
escape_as() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
SUBJ_ESC=$(escape_as "$SUBJ")
BODY_ESC=$(escape_as "$BODY")
DEST_ESC=$(escape_as "$DEST")

osascript -e "
tell application \"Mail\"
  set newMsg to make new outgoing message with properties {subject:\"[Gate] $SUBJ_ESC\", content:\"$BODY_ESC\", visible:false}
  tell newMsg
    make new to recipient at end of to recipients with properties {address:\"$DEST_ESC\"}
  end tell
  send newMsg
end tell" 2>/dev/null && echo "Digest inviato a $DEST" || {
  # fallback: mail CLI
  echo "$BODY" | mail -s "[Gate] $SUBJ" "$DEST" 2>/dev/null && echo "Digest inviato a $DEST (via mail)" || echo "ERRORE invio"
}
