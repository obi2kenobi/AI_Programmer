# 2026-10-02 — registrazione-gemelle-in-produzione
**Autore**: sessione Claude (con Luca) su `registrazione_fatture_acquisto`

## Cosa ho usato
Il banco del progetto (gate: banco, sabotaggi, lenti), tre agenti `revisore-gas` in sola lettura (test ridondanti, spazio degli errori, mail), le PR #306–#312 del repo di lavoro, `tools/debiti-riapertura.sh`. Non c'era una lente che elenchi le uscite anticipate di `valutaFattura_`.

## Cosa ho improvvisato
Uno script che dichiara in automatico le cascate dei sabotaggi (appende i nomi delle attese cadute a `devonoCadere`, scanner che ignora commenti e virgolette). Quattro errori miei della stessa famiglia in due giorni (percorso nuovo che omette passi del flusso vero: prova sandbox, PDF della coppia, PDF delle note, guardie della coppia), tutti a `docs/errori/REGISTRO.md` del progetto.

## Cosa ha retto / ostacolato
Ha retto: sonda in sola lettura → sandbox → piano letto da Luca → prima coppia con le guardie accese; l'analisi con mutazioni ha trovato ciò che il banco verde non eseguiva. Ostacolato: PR impilate che si conflittano a ogni merge (README e `ATTESE_DICHIARATE`), risolte a mano ogni volta.

## Proposta al canone
Una lente del banco che richieda un'attesa eseguita per ogni `return` anticipato di una funzione di valutazione; un criterio nel canone: un percorso nuovo che entra nel giro si confronta con il flusso normale voce per voce prima della consegna. Per le PR impilate: un branch alla volta, o merge dello stesso ordine di creazione.
