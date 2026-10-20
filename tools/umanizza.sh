#!/bin/bash
# umanizza.sh — il digest in italiano naturale (furto da blader/humanizer:
# le 26 regole contro lo stile AI, applicate dal nostro gemma locale).
# Il digest tecnico (bilancino, SACCA, legge) diventa un rapporto che
# una persona legge in 30 secondi e capisce cosa è successo.
#
# Uso: umanizza.sh <file-dati-grezzi>    (i dati sullo stdin o nel file)
# Esce: il testo umanizzato su stdout (pronto per la mail)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${MODELLO:-gemma4:26b-notturno}"

DATI=$(cat)

PROMPT="Sei il curatore del digest mattutino di un sistema di sviluppo autonomo. Scrivi il rapporto in italiano naturale, per una persona che ha 30 secondi per capire cosa è successo stanotte.

REGOLE DI STILE (furto da humanizer — Wikipedia Signs of AI Writing):
- Di' il punto direttamente. Mai «non è X ma Y», mai chiusure drammatiche.
- Mai preparazioni teatrali («entriamo nel merito», «vediamo insieme»).
- Mai parole gonfie: delve, landscape, testament, pivotal, journey, unlock.
- Mai triadi forzate: se sono 2 cose, dì 2. Se sono 5, dì 5.
- Mai «potrebbe potenzialmente»: una sola qualifica, quella supportata.
- Vero soggetto e verbo attivo: «il censore ha approvato», non «è stata espressa approvazione».
- Grassetto solo per i numeri che contano (consegne, sacche, rossi).
- Se un numero è 0, dillo: «zero problemi» è meglio di «assenza di problematiche».
- La lunghezza giusta: abbastanza per capire, abbastanza breve per rileggerlo domani.

STRUTTURA (rispetta l'ordine):
1. Una frase che dice com'è andata (bene, male, misto — e perché).
2. Le consegne: quante PR, quante fuse, quante sacche spedite.
3. I problemi: rossi, muti, degradati — con il motivo, senza gergo.
4. Cosa guardare oggi (se c'è qualcosa che richiede una decisione).

Ecco i DATI GREZZI da cui scrivi (sono log tecnici: estrai i fatti, scrivi in umano):

$DATI

Scrivi SOLO il rapporto (nessun titolo, nessuna firma, nessun «Ecco il rapporto»): inizia direttamente con la prima frase."
RISP=$(printf '%s' "$PROMPT" | QWEN_MODEL="$MODEL" ASK_TIMEOUT=120 bash "$HERE/llm/ask-qwen.sh" "Rispondi alla richiesta qui sotto." 2>/dev/null)
[ -n "$RISP" ] || { echo "umanizza: cervello muto — resto il digest tecnico" >&2; printf '%s\n' "$DATI"; exit 1; }
printf '%s\n' "$RISP"
