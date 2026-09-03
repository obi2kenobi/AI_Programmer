# 2026-09-03 — REPO-W, secondo tempo: due misure ribaltano una richiesta già inviata

Autore: Luca + sessione Claude Code (remota). Repo: REPO-W (GAS+BC, fatture estere).
Seguito di `2026-09-03-repo-w-fatture-estere-fase2.md`, che si fermava a metà pomeriggio.
Esito: **otto ore di sviluppo esterno non acquistate**, perché due misure fatte dopo hanno
smentito la premessa su cui la richiesta era stata scritta.

## Il fatto, in tre righe

Chiuso il ciclo tecnico (registrazione via API, 204), la conclusione sembrava ovvia: serve una
piccola deroga applicativa per modificare un campo su documenti in stato rilasciato, otto ore,
confermate al fornitore esterno per mail. Poi abbiamo misurato **quanto spesso** quel campo vada
davvero modificato: **0,2%** — 3 righe su 1315. E abbiamo misurato l'altro ostacolo, che nessuno
aveva quantificato: **51,3%** delle righe. Avevamo comprato la soluzione al problema sbagliato.

## Cosa ha retto

- **Il registro delle scoperte come strumento di decisione, non di archivio.** Ogni numero è
  annotato con l'ora in cui è arrivato. Quando la raccomandazione si è ribaltata, la traccia
  scritta ha reso il dietrofront **difendibile** invece che imbarazzante: si vede che il numero
  non c'era, non che si è cambiato idea.
- **Una guardia proposta la mattina in questo stesso ciclo ha pagato la sera.** La regola
  *"una sonda che può restituire zero deve distinguere zero da domanda sbagliata"* (proposta #2 del
  primo report) ha intercettato un bug la sera stessa: la seconda misura ha stampato
  `1315 righe il cui articolo non è stato letto` invece di `righe interessate: 0 (0,0%)`. Senza
  quel contatore separato avremmo concluso che il secondo ostacolo non esisteva — con un numero
  falso dall'aria vera, dentro una decisione su un preventivo. **Proposta al canone verificata sul
  campo poche ore dopo essere stata scritta.**

## Cosa ha ostacolato

- **Una pipe nasconde l'esito.** `node test.mjs | tail -2 && git commit …`: il test non era nemmeno
  partito (cartella sbagliata), `tail` è andato a buon fine, la catena `&&` ha proseguito, e il
  commit è stato **spinto con un messaggio che descriveva file che non conteneva**.
- **Un `$select` condiviso è un contratto implicito.** Riusare la funzione di query di una misura
  per la misura successiva è giusto (scala del codice minimo), ma trasforma la proiezione dei campi
  in **interfaccia**: mancava un campo che la prima misura non chiedeva, e la seconda ha misurato
  zero.
- **Un impegno verso l'esterno preso mentre una verifica pianificata era ancora aperta.** La mail
  che confermava le otto ore è partita alle 17:45. Le due misure che ne hanno smentito la premessa
  erano **già state proposte** e sono arrivate alle 21:07 e alle 21:22. Non è stato un cambio di
  idea: il numero non c'era, ed era noto che non c'era.

## Proposta al canone (numerazione continua dal primo report)

### 4. Mai far dipendere una catena `&&` da un comando che finisce in pipe
Una pipe restituisce l'esito dell'**ultimo** comando: `set -o pipefail`, oppure si controlla
l'esito prima di procedere. Vale doppio quando a valle c'è un `git commit`, perché il risultato è
un commit il cui messaggio mente sul proprio contenuto.

### 5. Quando una funzione di query viene riusata, la sua proiezione diventa un'interfaccia
Il `$select` (o l'equivalente: colonne di una SELECT, campi di una projection) va commentato **nel
punto in cui vive il vincolo**, non nella documentazione: chi "pulisce" i campi apparentemente
inutilizzati rompe silenziosamente un altro chiamante, e il sintomo è un valore plausibile, non un
errore.

### 6. Nessun impegno verso l'esterno mentre una verifica pianificata è ancora aperta
Se una misura è **già stata proposta** e non è ancora stata eseguita, una mail che conferma un
preventivo, una stima o una data non parte: si aspetta il numero, oppure si scrive esplicitamente
che è pendente. È la proposta che conta di più delle tre, perché il costo non lo paga chi sviluppa
ma il rapporto con la controparte.

## Numeri della giornata

| | |
|---|---|
| Sezioni di documentazione vivente scritte | 17 |
| PR aperte e unite | 11 |
| Errori propri documentati | 4 (identità, sonda muta, pipe, `$select` condiviso) |
| Ore di sviluppo esterno **non** acquistate grazie alla misura | **8** |
| Rapporto fra i due ostacoli misurati | 0,2% contro 51,3% |

## Nota per chi tria

Le proposte 1 e 2 (primo report) sono già ancorate a codice vivo in REPO-W. Le 4, 5 e 6 sono
ancorate a `docs/fatture_estere/README.md` §25.43-§25.46 dello stesso repo. La casella
**NON RAGGIUNGIBILE** dichiarata nel primo report resta aperta: senza `post-mortem` e registro
errori installati lì, i quattro errori di questa giornata non hanno prodotto nessuna guardia
automatica.
