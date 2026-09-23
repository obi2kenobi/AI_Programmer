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
# (revisione 10 giri, 2026-09-23): il riepilogo del gate entrava DUE volte; «PR» contava le
# intestazioni dei turni che contengono «PR bozza» (non le PR: si sommano i numeri); «ASPETTA»
# contava ogni riga con due spazi dal primo marcatore alla FINE del file (il log dei turni
# dopo compreso: si contano le sole voci sotto ciascun marcatore, fino al turno successivo);
# e la memoria si svuotava QUI, prima dell'invio — ora solo a invio riuscito, in fondo.
SAL_TURNI="$(cd "$(dirname "$0")" && pwd)/.sal-turni.md"
BODY="${CORPO_GATE}$(bash "$(dirname "$0")/gate-summary.sh" 0 2>/dev/null || echo '(summary non disponibile)')
$([ -f "$SAL_TURNI" ] && {
  # (revisione 10 giri): `grep -c … || echo 0` stampava «0» due volte a conteggio zero
  CICLI=$(grep -c "TURNO INIZIATO" "$SAL_TURNI" 2>/dev/null || true); CICLI=${CICLI:-0}
  PR=$(grep -oE '[0-9]+ PR bozza' "$SAL_TURNI" 2>/dev/null | awk '{s+=$1} END{print s+0}')
  FIX=$(grep -c "auto-fix" "$SAL_TURNI" 2>/dev/null || true); FIX=${FIX:-0}
  echo "**Cicli notturni**: $CICLI / **PR**: $PR / **Fix**: $FIX"
  ASPETTA=$(awk '/ASPETTA IL GIORNO/{dentro=1; next} /^### /{dentro=0} dentro && /^  [^ ]/{n++} END{print n+0}' "$SAL_TURNI" 2>/dev/null); ASPETTA=${ASPETTA:-0}
  [ "$ASPETTA" -gt 0 ] && echo "**ASPETTA IL GIORNO**: $ASPETTA decisioni pendenti"
  true
} || echo "(nessuna memoria del turno)")"

# il secondo cervello: gli sospesi compilati dal turno alla prima domanda del giorno
# ($WORK/.cervello-<data> — deterministico, scritto da night-shift.sh). C'e' quando
# c'e': il digest non dipende da lui, lo mostra in coda.
# (if/fi, non [ ]&&: sotto set -e un test falso al fondo di una catena && esce 1
# e ammazzava il digest la mattina che il marker manca)
# (il || true e' DENTRO, prima della pipe: ls su glob senza match esce 2, e con
# pipefail+set -e il digest moriva la mattina senza marker)
# (audit-2): i deploy pronti si guardano ORA, non solo via marker del mattino —
# un pacchetto preparato stamattina scade domattina
if ls "$HOME"/deploy-pronto/*/MANIFEST.md >/dev/null 2>&1; then
  BODY="$(printf '%s\n\n---\nDEPLOY PRONTI (il gesto: deploy-ora <repo>)\n%s' "$BODY" "$(grep -H '' "$HOME"/deploy-pronto/*/MANIFEST.md 2>/dev/null | grep -E 'commit:|preparato:' | sed 's|.*/deploy-pronto/||;s|MANIFEST.md:||' | head -8)")"
fi
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
end tell" 2>/dev/null && INVIATO="Digest inviato a $DEST" || {
  # fallback: mail CLI
  echo "$BODY" | mail -s "[Gate] $SUBJ" "$DEST" 2>/dev/null && INVIATO="Digest inviato a $DEST (via mail)" || INVIATO=""
}
# (revisione 10 giri): la memoria del turno si svuota SOLO a invio riuscito; un invio fallito
# e' un rosso (rc 1), non un «ERRORE invio» con esito 0 — e la memoria resta per domani
if [ -n "${INVIATO:-}" ]; then
  echo "$INVIATO"
  if [ -f "$SAL_TURNI" ]; then : > "$SAL_TURNI"; fi
else
  echo "ERRORE invio: digest NON consegnato — la memoria del turno resta in $SAL_TURNI" >&2
  exit 1
fi
