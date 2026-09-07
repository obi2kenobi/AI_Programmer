# 2026-09-07 — l'asse sbagliato, e le fixture che mentono
**Autore**: sessione Claude Code (remota), con Luca come proprietario del dominio.
**Voto dato dal proprietario del dominio: 1 su 100.** Sta in cima perché è il dato più
importante del report: la sessione ha prodotto lavoro lato server e **nessun pannello
funzionante** in una giornata dichiarata «in consegna domattina».

> ⚠️ Se questo report viene portato nell'hub PUBBLICO va anonimizzato (codici REPO-*,
> nessun nome di persona o d'azienda). Qui i nomi restano perché la repo è privata.

## Cosa ho usato

- **`esegui-non-dedurre`** — quando l'ho usato ha pagato ogni volta, e le due volte più
  importanti sono le ultime della sessione: la sonda in `scratchpad/verifica.js` sul caso
  vero del dominio ha dato `ddt_attribuiti: 12` su **un** documento (`DEBITI` #183), e la
  lettura di `Programma.conDocumenti` ha mostrato che la mia fixture degli orfani inventava
  un campo che gli orfani non hanno (#184). **Nessuno dei due difetti era deducibile: erano
  entrambi verdi al banco.**
- **`banco prima della correzione`** — applicato per il pannello di attribuzione: 13 attese
  (XO1-XO13) scritte e **viste rosse** (`29/39 · 13 fallite`) prima di una riga di pannello.
- **`gas-agent` / specialista `sviluppatore-gas`** — consultato prima di scrivere il
  pannello, come pretende la preferenza del proprietario. **Ha trovato due difetti veri che
  io non avevo visto** (#183 e #184) più due domande di dominio che decidono la forma del
  pannello (#185, #186). Costo: ~5 minuti di attesa. Valore: ha impedito un pannello che
  moltiplicava i documenti e un banco verde su un dato inventato.
- **`agente censitore-forma-dati`** — usato per la forma dei campi BC.
- **Il cancello** (`tools/cancello.sh`), il blocco di `clasp push`, l'hook del commit.
- **NON RAGGIUNGIBILE: Business Central da questa sessione.** Ogni verifica sul vivo è
  passata per Luca che eseguiva e incollava i log. È il vincolo che ha dettato il ritmo di
  tutta la giornata, e non l'ho mai dichiarato come tale a inizio sessione.

## Cosa ho improvvisato

**Il ponte finto del banco in browser esteso a un endpoint che ritarda.** Per provare che il
doppio click scrive una volta sola serviva che la risposta del server **si facesse
aspettare**: senza attesa il secondo click non è nemmeno tentabile, e l'attesa sarebbe stata
una stampa. `attribuisciOrdine` finto risponde a 60 ms e **registra tutte** le chiamate in
un array, non solo l'ultima — `window.ULTIMA_DATA` (una sola) non basta per questa classe
di attese. Proposta al canone sotto.

## Cosa ha retto / ostacolato

### Ha retto: il cancello e gli hook hanno preso errori che io avevo lasciato passare

- `T16` ha pretesa la rimozione di `abbinamentoPer_` rimasto senza chiamanti; rimuovendolo
  **mi sono portato via anche `codiceFornitoreDa_`**, e `T10` — l'attesa nata da un
  incidente identico sulla stessa funzione — l'ha preso.
- `test-moduli-coperti.sh` **ha smascherato un mio falso verde**: avevo scritto `BcToken`
  nell'elenco MODULI del mio banco, e la lente lo contava come coperto senza che nessuna
  attesa lo provasse.

### ⛔ Ha ostacolato niente: quel che segue sono errori miei, e sono tanti

**1. L'ERRORE CHE HA COSTATO LA GIORNATA — ho costruito l'asse sbagliato senza chiedere.**
Ho progettato e costruito la risoluzione **per fornitore** (`src/BcFornitore.gs`, R48: partita
IVA dal documento → scheda BC → codice fornitore), e l'asse vero era **per ordine**. Luca ha
dovuto dirlo: «non deve cercare il fornitore ma l'ordine a cui è associato il fornitore».
⚠️ **Avevo già in mano la misura che lo diceva**: il DDT non porta il nostro numero d'ordine
(7 documenti su 7), il contratto del fornitore non è fra i campi di `purchaseDocumentLines`,
e BC restituiva **12 righe candidate** per un solo DDT. Cioè: la misura mostrava che risolvere
il fornitore **non chiudeva il problema**, e io ho costruito comunque la scala del fornitore
invece di fermarmi a chiedere. CLAUDE.md §1 dice *«Surface interpretations and tradeoffs —
don't pick silently»*: **ho scelto in silenzio l'asse dell'intera funzionalità.**

**2. E la domanda che valeva la giornata l'ho fatta per ultima.** «Quando BC dà 12 candidati,
chi scegli e come?» era il perno: la risposta («è una scelta umana») determina il pannello,
e con essa il conteggio, la coda, la forma del foglio. L'ho posta **a fine giornata**, dopo
aver costruito tutto quello che ci stava intorno.

**3. Le fixture scritte a mano hanno dato un banco verde e un vivo che rifiutava tutto.**
Le fixture di `banco-estrazione` venivano dal lettore di Drive in linguaggio naturale, non
dalla conversione PDF→Doc che l'app usa davvero: **due layout diversi**. Il banco era verde,
e sul vivo **tutti e quattro i DDT** finivano in «non è un DDT riconosciuto». Costo: più giri
di debug dal vivo, ognuno un viaggio attraverso Luca.

**4. La stessa famiglia, di nuovo, oggi, da me** (`DEBITI` #184): nella fixture degli orfani
del banco del pannello ho scritto `pdf_link`, che gli orfani **non hanno** (sono righe grezze
del foglio: portano `pdf_drive_id`). Non l'ha trovato il banco: l'ha trovato lo specialista.

**5. E la stessa famiglia una terza volta, nella forma peggiore** (`DEBITI` #183): le mie
`PR13-PR16` sono verdi perché **ogni fixture ha un ordine con una riga sola**, e in produzione
lo stesso ordine ha 12 righe aperte. Sotto la forma vera, `ddt_attribuiti` conta **un
documento dodici volte**. Ho aggiunto la funzione e la sua guardia nello stesso commit, e la
guardia provava una forma che non esiste. **Settima ricorrenza di `#165`** (un filtro/una
fixture che presuppone la forma del dato), introdotta da me.

**6. Ho fatto scrivere una repo dichiarata in SOLA LETTURA** (`E-016`): ho detto a un agente
di eseguire `tools/bc_index.py` chiamandolo «un indice». È un **generatore**: ha riscritto
`docs/bc/README.md` nel progetto gemello. Ripristinato con `git checkout --`; scoperto per
di più che **non è deterministico**.

**7. Ho committato col cancello ROSSO** (`E-017`, `c1f83e1`) — **terzo commit rosso** della
storia di questo progetto. L'hook funzionava: il buco è strutturale (`PreToolUse` gira PRIMA
del comando, e quel comando scriveva `DEBITI.md` prima di committare). ⚠️ **E il dente che ho
provato a mettere ha negato i miei stessi comandi** perché il loro testo citava `git commit`
— stallo, rimosso da me. È **la stessa lezione già scritta tre righe sopra nell'hook**
(«un grep libero negava un commit il cui MESSAGGIO citava la forma»), reintrodotta da me un
livello sopra.

**8. Ho dato a Luca un'istruzione che il codice vieta esplicitamente.** Gli ho detto di
mettere il proprio indirizzo in `UTENTI_SCARICO`. Con `executeAs: USER_DEPLOYING` quella
guardia passerebbe **sempre**, e `scaricaAnnunci` diventerebbe un endpoint di scrittura
aperto a tutto il dominio. Corretto separando `UTENTI_CARTELLA`, ma **l'ho detto io**.

**9. Il libretto delle istruzioni diceva una cosa falsa.** Ci avevo scritto che
`numero_viaggio` fosse il numero del Lieferschein. Misurato: `ddt-29285981` →
`numero_ddt=29285981` ma `numero_viaggio=511754`. Chi lo seguiva rompeva il caricamento a
mano **in silenzio**. Trovato dallo specialista, che ci ha perso un ciclo sul mio numero
sbagliato.

**10. Tre citazioni file:riga sbagliate** in `docs/design/024` (`number :19`→`:17`,
`description :22`→`:21`, `type :15`→`:16`). Trovate da un controllore usa-e-getta, **non
rileggendo**: cioè le avevo scritte senza verificarle.

**11. Il mio stesso codice buttava via il motivo che avevo appena aggiunto.** `ScaricoCartella`
**riscriveva** il motivo dello scarto sopra quello dell'estrattore, e così l'impronta che
avevo aggiunto per capire perché i DDT venivano rifiutati **non arrivava nei log**. Un ciclo
intero di debug dal vivo perso su un difetto mio, nel codice che stavo scrivendo per
diagnosticare.

**12. La mia lente ha letto una CITAZIONE come una DICHIARAZIONE**: `#177` cita
«Attesi 19 file…» fra virgolette e il parser l'ha contata. Quinta ricorrenza di `#165`.

## Proposta al canone

**1. ⭐⭐ Una misura che rivela un'AMBIGUITÀ IRRIDUCIBILE è un punto di decisione di dominio,
e si porta al proprietario PRIMA di costruire qualunque cosa a valle.** È l'errore n.1 di
oggi e non è coperto: il canone ha «esegui non dedurre» (che misura) e «non scegliere in
silenzio» (che vale per le interpretazioni), ma **non ha la regola che collega le due**.
Quando la misura dice *«per un ingresso ci sono N candidati e nessuna chiave»*, quel numero
non è un dettaglio da gestire: è la domanda che decide l'architettura. Forma proposta:
> Se una misura produce N>1 candidati senza chiave, **fermati e chiedi**. Non costruire la
> scala di risoluzione a monte sperando che riduca N: se N>1 resta, l'hai costruita per
> niente. Oggi: costruita la risoluzione per fornitore, e N restava 12.

**2. ⭐⭐ Una fixture nasce da un'ESECUZIONE del cammino vero, mai scritta a mano — e lo
dichiara.** Tre ricorrenze in un giorno (testo DDT, `pdf_link`, righe fratelle). La cura
strutturale non è «stare attenti»: è che **ogni file di fixture porti in testa il comando
che l'ha prodotto**, e una lente meccanica faccia rosso su una fixture senza quella riga.
Una fixture scritta a mano è un'ipotesi travestita da misura, e produce **banchi verdi su
software rotto** — che è il difetto peggiore che questo metodo possa produrre, perché spegne
l'unico segnale che resta.

**3. ⭐ Quando il dominio misura una CARDINALITÀ, quella cardinalità diventa una forma
obbligatoria di fixture.** «12 righe aperte sullo stesso ordine» era misurato e nessuna
fixture ne aveva più di una. Proposta: le cardinalità misurate si scrivono accanto alla
regola di dominio, e il banco deve contenerne una fixture — altrimenti la guardia prova una
forma che in produzione non esiste (`#183`).

**4. ⭐ Un banco che prova un GESTO ASINCRONO ha bisogno di un ponte finto che RITARDI e che
registri TUTTE le chiamate**, non solo l'ultima. `window.ULTIMA_*` (il pattern in uso) non
può provare «il doppio click scrive una volta»: serve un array e una risposta lenta.
Improvvisato oggi, va in `patterns/banco-browser-per-webapp-gas.md`.

**5. ⚠️ Un nome che mente è un difetto dell'hub.** `tools/bc_index.py` si chiama come un
lettore ed è un **generatore che riscrive file** (`E-016`). Un agente che legge il nome non
ha modo di saperlo. Proposta: o si rinomina, o porta in testa una riga che dichiara che
scrive — e le repo in sola lettura elencano gli strumenti che NON si eseguono.

**6. ⚠️ `scrivere e committare sono DUE comandi, sempre` va promossa da commento dell'hook a
regola di CLAUDE.md.** Oggi vive solo dentro
`tools/cancello-prima-del-commit-hook.sh:54`, cioè nel posto che si legge **dopo** aver
sbagliato. È la condizione perché il dente del cancello possa dire la verità, e un commit
rosso è già passato tre volte.
