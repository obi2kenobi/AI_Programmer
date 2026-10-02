#!/bin/bash
# morning-digest.sh — la mattina nella mailbox, con i numeri VERI (v3, 2026-09-30).
#
# v1-2 trascinavano fossili: il report del gate in pensione da 31+ giorni, il
# gate-summary di REPO-A/REPO-B (sistema pilota morto il 21/8) e i contatori
# cumulativi del SAL («196 cicli / 156 PR» — di SEMPRE, non di stanotte).
# La verita' del mattino ora e' IL BILANCINO (tools/bilancino.sh): una riga per
# repo per notte, letta dal log dal vivo, col delta dei debiti sulla notte prima.
# Restano del SAL solo le decisioni ASPETTA IL GIORNO: quelle contano ancora.
# Destinatario: repos.key DIGEST_EMAIL (vuoto = no-op educato, come il digest notturno).
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

# (dominio, decisione di Luca 2026-09-23: digest autonomo) — v3 (2026-09-30): il gate
# e' in pensione dal 29/8 e il suo report e' un fossile: non si allega e non si cita
# piu'. I numeri della notte vengono dal bilancino.
WORK="${MORNING_WORK:-$HOME/night-shift-work}"
FUNNEL="${MORNING_FUNNEL:-$WORK/funnel.csv}"
IERI=$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F 2>/dev/null || echo "")
SUBJ="Mattina del sistema — $(date '+%Y-%m-%d')"

# LA NOTTE: le righe di IERI dal bilancino, col delta debiti sulla notte precedente
CORPO_NOTTE=""
TOT_CICLI=0; TOT_FUSE=0; TOT_RIGETTATE=0; TOT_GPU=0
if [ -n "$IERI" ] && [ -f "$FUNNEL" ]; then
  while IFS=, read -r data repo cicli vv vr ap fu rg rd gpu deb lez; do
    [ "$data" = "$IERI" ] || continue
    case "$repo" in ""|data) continue ;; esac
    # (2026-10-01, giro accurato): una riga monca (campo vuoto) mandrebbe in errore
    # l'aritmetica sotto set -e e la mail morirebbe in silenzio — la peggiore delle
    # degradazioni. Ogni campo numerico ha il suo default: la riga monca non conta,
    # la mail parte.
    cicli=${cicli:-0}; fu=${fu:-0}; rg=${rg:-0}; gpu=${gpu:-0}; deb=${deb:-0}; lez=${lez:-0}
    DELTA=""
    PREV_DEB=$(awk -F, -v r="$repo" -v d="$IERI" '$2==r && $1!="" && $1<d {print $11}' "$FUNNEL" 2>/dev/null | tail -1)
    if [ -n "$PREV_DEB" ] && [ "$PREV_DEB" != "$deb" ]; then
      DELTA=" · debiti ${PREV_DEB}→$deb"
    fi
    # (2026-10-02, approvato da Luca): il costo in EURO della GPU — il modello del
    # costo e' DICHIARATO: watt stimati del Mac sotto carico GPU (profilo o repos.key:
    # GPU_WATT, default 45) x ore x prezzo kWh (GPU_EUR_KWH, default 0.35, ISEE non
    # incluso perche' il contatore non e' del turno). E' una stima onesta, non una
    # fattura: lo dice ogni volta che appare.
    GPU_WATT_T=$( { grep -E '^GPU_WATT=' "$KEY" 2>/dev/null || true; } | cut -d= -f2 | xargs); GPU_WATT_T=${GPU_WATT_T:-45}
    GPU_KWH_T=$( { grep -E '^GPU_EUR_KWH=' "$KEY" 2>/dev/null || true; } | cut -d= -f2 | xargs); GPU_KWH_T=${GPU_KWH_T:-0.35}
    COSTO=$(python3 -c "print(f'{($gpu / 3600) * ($GPU_WATT_T / 1000) * $GPU_KWH_T:.4f}')" 2>/dev/null || echo "—")
    CORPO_NOTTE="$CORPO_NOTTE
- $repo: ${cicli} cicli · PR: ${ap} aperte, ${fu} fuse, ${rg} rigettate · ${gpu}s GPU ≈ €$COSTO (stima: ${GPU_WATT_T}W × €$GPU_KWH_T/kWh) · ${lez} lezioni$DELTA"
    TOT_CICLI=$(( TOT_CICLI + cicli )); TOT_FUSE=$(( TOT_FUSE + fu ))
    TOT_RIGETTATE=$(( TOT_RIGETTATE + rg )); TOT_GPU=$(( TOT_GPU + gpu ))
  done < "$FUNNEL"
fi
if [ -n "$CORPO_NOTTE" ]; then
  TOT_COSTO=$(python3 -c "print(f'{($TOT_GPU / 3600) * (45 / 1000) * 0.35:.3f}')" 2>/dev/null || echo "?")
  SUBJ="Mattina $IERI — cicli $TOT_CICLI · fuse $TOT_FUSE · rigettate $TOT_RIGETTATE · ${TOT_GPU}s GPU ≈ €$TOT_COSTO"
  BODY="LA NOTTE (dal bilancino, letta dal log vero)$CORPO_NOTTE"
else
  BODY="LA NOTTE: nessuna riga di ieri ($IERI) nel bilancino — il turno e' girato? (la risposta e' nel log)"
fi

# il SAL del turno: resta SOLO l'elenco delle decisioni pendenti (i contatori
# cumulativi «196 cicli / 156 PR» erano di sempre, non di stanotte: quella
# verita' ora vive nel bilancino, sopra)
SAL_TURNI="$(cd "$(dirname "$0")" && pwd)/.sal-turni.md"
if [ -f "$SAL_TURNI" ]; then
  ASPETTA=$(awk '/ASPETTA IL GIORNO/{dentro=1; next} /^### /{dentro=0} dentro && /^  [^ ]/{n++} END{print n+0}' "$SAL_TURNI" 2>/dev/null); ASPETTA=${ASPETTA:-0}
  if [ "$ASPETTA" -gt 0 ]; then
    BODY="$(printf '%s\n\n---\n**ASPETTA IL GIORNO**: %s decisioni pendenti del turno' "$BODY" "$ASPETTA")"
  fi
fi

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
  # (settimo ventaglio, V3 R1): il segno piu' recente puo' essere di un altro giorno (il turno giu', il Mac spento):
  # allora i sospesi si dicono per data, non come quelli di stamattina
  CERV_DATA="${CERVMARK##*.cervello-}"
  [ "$CERV_DATA" = "$(date +%F)" ] || BODY="$(printf '%s\n\n---\n(sospesi del %s, non di oggi: il turno non ha fatto la domanda del giorno)' "$BODY" "$CERV_DATA")"
  BODY="$(printf '%s\n\n---\n%s' "$BODY" "$(cat "$CERVMARK")")"
fi

# (2026-09-28, la direzione): la roadmap di ogni repo nel digest — il passo corrente e
# da quanto e' fermo. Il tool c'era da giorni (costruito, banchi verdi) ma nessuno lo
# guardava: senza questa riga nessuno chiede «perche' ferma?» e la notte vaga a debiti
# senza direzione. I placeholder di advance e l'assenza si saltano in silenzio.
ROADMAP_OUT=""
if [ -f "$(dirname "$0")/repos.conf" ]; then
  while read -r ENTRY _rm; do
    case "$ENTRY" in ''|'#'*) continue ;; esac
    NOME="${ENTRY##*/}"
    RM="$HOME/night-shift-work/$NOME/.git/roadmap"
    [ -f "$RM" ] || continue
    PASSO=$(head -1 "$RM" 2>/dev/null || true)
    case "$PASSO" in ""|"(nessuna roadmap)"|"(prossimo passo da impostare)"|"("*) continue ;; esac
    ROADMAP_OUT="$ROADMAP_OUT
- $NOME: $PASSO — ferma da $(eta_giorni "$RM") giorni"
  done < "$(dirname "$0")/repos.conf"
fi
if [ -n "$ROADMAP_OUT" ]; then
  BODY="$(printf '%s\n\n---\nLA DIREZIONE (roadmap per repo)\n%s' "$BODY" "$ROADMAP_OUT")"
fi

# (2026-10-02, approvato da Luca): i GOAL per repo — la issue di lungo corso che
# da' la direzione alla caccia (goal-issue.sh: .git/goal-issue-N). Nel digest con
# l'eta': un goal fermo da settimane e' una domanda del mattino.
GOAL_OUT=""
if [ -f "$(dirname "$0")/repos.conf" ] && [ -x "$(dirname "$0")/../tools/goal-issue.sh" ]; then
  while read -r ENTRY _gm; do
    case "$ENTRY" in ''|'#'*) continue ;; esac
    NOME="${ENTRY##*/}"
    G_DIR="$HOME/night-shift-work/$NOME"
    [ -d "$G_DIR/.git" ] || continue
    G_SHOW=$(bash "$(dirname "$0")/../tools/goal-issue.sh" "$G_DIR" list 2>/dev/null | head -2) || true
    [ -n "$G_SHOW" ] || continue
    G_FILE=$(ls "$G_DIR/.git/"goal-issue-* 2>/dev/null | head -1)
    G_GIORNI=0
    [ -n "$G_FILE" ] && G_GIORNI=$(python3 -c 'import os,sys,time; print(int((time.time()-os.path.getmtime(sys.argv[1]))//86400))' "$G_FILE" 2>/dev/null || echo 0)
    GOAL_OUT="$GOAL_OUT
- $NOME: $(printf '%s' "$G_SHOW" | head -1 | cut -c1-80) — da $G_GIORNI giorni"
  done < "$(dirname "$0")/repos.conf"
fi
if [ -n "$GOAL_OUT" ]; then
  BODY="$(printf '%s\n\n---\nI GOAL (issue di lungo corso, per repo)\n%s' "$BODY" "$GOAL_OUT")"
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
  set newMsg to make new outgoing message with properties {subject:\"$SUBJ_ESC\", content:\"$BODY_ESC\", visible:false}
  tell newMsg
    make new to recipient at end of to recipients with properties {address:\"$DEST_ESC\"}
  end tell
  send newMsg
end tell" 2>/dev/null && INVIATO="Digest inviato a $DEST" || {
  # fallback: mail CLI. (2026-09-25, ottavo ventaglio, O5 R2): il suo rc 0 vuol dire «accettato nella coda LOCALE», non
  # «arrivato» — sul Mac senza relay il messaggio resta li'. Si dice cosi', la memoria del turno non si svuota, e lo
  # stderr di mail va nel log invece che nel vuoto. Il ripiego resta (D37, 2026-09-25).
  echo "$BODY" | mail -s "$SUBJ" "$DEST" 2>>"$HOME/morning-digest.log" \
    && { INVIATO="Digest messo nella coda locale di mail(1) per $DEST — consegna NON verificata (Mail non e' partito); la memoria del turno resta"; SOLO_CODA=1; } \
    || INVIATO=""
}
# (revisione 10 giri): la memoria del turno si svuota SOLO a invio riuscito; un invio fallito
# e' un rosso (rc 1), non un «ERRORE invio» con esito 0 — e la memoria resta per domani
if [ -n "${INVIATO:-}" ]; then
  echo "$INVIATO"
  if [ -f "$SAL_TURNI" ] && [ "${SOLO_CODA:-0}" != 1 ]; then : > "$SAL_TURNI"; fi
else
  echo "ERRORE invio: digest NON consegnato — la memoria del turno resta in $SAL_TURNI" >&2
  exit 1
fi
