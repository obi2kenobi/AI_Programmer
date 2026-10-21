# 2026-10-21 — riordino-legno: 20 giri di revisione su posta, solleciti, contratti, gruppi e ricerca
**Autore**: sessione Claude Code (utente: Luca) — 20 agenti `revisore-gas` in lettura (una lente e un'area per giro), poi 4 agenti `sviluppatore-gas` che correggono a banco, uno per area, ognuno nel proprio worktree e ramo.

## Cosa ho usato
- Skill `n-giri`: brief unico con aree × lenti (`BRIEF.md`), rapporti grezzi scritti dal giro PRIMA di rispondere, formato Oggi / Manca / Prova / Proposta, tetto di 6 voci per giro, «nulla in questa lente» ammesso.
- Metodo di correzione per area: banco rosso prima, correzione minima, voce di sabotaggio `GIRI-Gxx-n` vista rossa, un commit per correzione. Giudice `tests/banco-acq-mutazioni.js` (`MUT_SOLO`, `MUT_GATE=browser`), controllo ancore, `fixcit.py` per le citazioni.
- Esito dei giri: circa 115 voci (28 ALTA/MEDIA-ALTA provate eseguendo, le altre MEDIA/BASSA), 24 domande di dominio (`docs/progetto-acquisti/DOMANDE-GIRI.md` nel repo del progetto). Tutte le correzioni sono sui rami delle PR #129, #131, #132 (catena senza conflitti).
- **Tema trasversale più forte**: quattro giri indipendenti (G09, G10, G18, G19) hanno trovato lo stesso difetto — l'avviso di scadenza dei contratti riscriveva il contratto com'era PRIMA dell'invio, annullando una disdetta fatta nel frattempo. Il secondo tema (almeno 6 giri): «visto/segnato» scritto prima di sapere se Chat o la mail sono arrivate; il terzo: una cella scritta ma illeggibile sparisce e la riga si registra lo stesso (validità «presunta» al posto di quella scritta).

## Cosa ho improvvisato
- I correttori in parallelo su worktree separati (uno per PR della catena) hanno richiesto un'unione finale a mano: voci di sabotaggio con lo stesso id in rami diversi (rinominate con un suffisso `-rN` da `dedup.py`), ancore delle voci cadute dentro codice cambiato dall'altro agente, e due meccanismi di «errore in Chat una volta al giorno» scritti in parallelo da due agenti (uniti in uno solo).
- Le correzioni a scelta di dominio non dichiarata: regola data agli agenti = la scelta più prudente (mai perdere un dato, mai una mail in più, mai registrare un prezzo sul dubbio: «da guardare») dichiarata come ASSUNTO nel commit. Le domande vere sono nel file delle domande.

## Cosa ha retto / ostacolato
- Ha retto: il giro che ESEGUE (script in /tmp/giro-Gxx) invece di leggere soltanto: quasi tutti i rilievi alti arrivano con una prova riproducibile, e la convergenza di giri indipendenti ha indicato dove guardare.
- Ha ostacolato: i conteggi duri e le citazioni `file:riga` nei banchi di struttura e nella guida (ogni unione li rompe); il giudice dei sabotaggi sull'intero insieme richiede ore sotto carico, quindi si lancia a fette (`MUT_SOLO`) e il cancello intero resta da eseguire a macchina libera; la memoria dei prompt dei correttori non è condivisa: due hanno risolto lo stesso problema (errori in Chat) in modi diversi.

## Proposta al canone
Una: quando più agenti correggono in parallelo aree che condividono un registro (qui `tests/lib/mutazioni-acq.js`), l'id delle voci nuove deve avere il prefisso dell'agente (`GIRI-<agente>-Gxx-n`) per costruzione, così la fusione non rinomina niente.
