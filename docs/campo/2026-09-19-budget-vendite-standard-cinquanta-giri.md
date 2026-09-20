# 2026-09-19 — adozione dello standard su progetto GAS nuovo, cinquanta giri, correzione integrale

**Autore**: sessione Claude Code (cloud, remota) su richiesta di Luca.
**Bersaglio**: Budget Vendite — Google Apps Script, ~820 righe, integrazione Business Central.
Primo contatto del progetto con lo standard AI_Programmer.

**Tre fasi in una sessione**: installazione dello standard → 50 letture indipendenti
(10 aree × 5 lenti) → correzione di tutti i temi emersi.

| | |
|---|---|
| Finding dai cinquanta giri | 255 (95 alta, 108 media, 52 bassa) |
| Temi trasversali corretti | 9 su 9 |
| Attese a banco alla chiusura | 29, 0 fallite |
| Verifiche dichiarate in `.night-verify` | 5, tutte verdi |
| Difetti del METODO trovati sul campo | 4 (3 dello standard + 1 del mio ragionamento) |
| Codice del progetto | 819 → 1265 righe |
| Provato contro il vivo | **niente** (nessuna credenziale, nessun `clasp`) |

Esiti: `docs/giri-2026-09-19/` (51 file), RISULTATO, DEBITI, DOMANDE (file del progetto),
il REGISTRO degli errori del progetto. PR #1, mergiata.

---

## 1. Cosa ho usato

- **`tools/copia-hook.sh`** — eseguito davvero: 3 hook derivati da `settings.json`, zero
  divergenze. È il pezzo dello standard che ha retto meglio, e non per caso: è l'unico che
  **deriva** la sua lista invece di riscriverla.
- **`tools/sync-repo.sh --standard`** — letto, non eseguito (chiama `gh`, assente in cloud).
  Ho replicato a mano la sua lista (la lista degli ITEM di tools/sync-repo.sh + tools/copia-hook.sh).
- **Le tre lenti dello standard** (`cita-verifica`, `fixture-provenienza`, `debiti-riapertura`)
  — tutte eseguite, tutte in `.night-verify`.
- **Gli hook** — attivi dal primo comando. Il reminder sui segreti ha intercettato davvero il
  comando che leggeva la configurazione BC.
- **`docs/campo/README.md`** — il formato di questo file.

**Voluto e NON c'era:**

- **Un gate di sintassi per i `.gs` e per il JS dentro gli `.html`.** `py-gate.sh` esiste per
  Python, nato da E-028 (*«la dashboard era committata non-compilante e passava: nessun gate
  eseguiva la sintassi py»*). Per i `.gs` niente — su un hub con una skill `gas-sviluppo`, 6
  agenti GAS e un canone distillato da ~90 progetti Apps Script. **La lezione E-028 è stata
  imparata per un linguaggio e mai generalizzata all'altro.**
- **I Cinquanta Giri come strumento.** `giri-avversari.sh` e `giri-ignoranti.sh` sono batterie
  meccaniche sull'hub. I Cinquanta Giri su un progetto cliente
  (`docs/campo/2026-08-27-repo-i-cinquanta-giri.md`) esistono solo come artefatto finito: né
  skill, né tool, né formato. Li ho ricostruiti a mano leggendo il risultato di agosto.

---

## 2. Cosa ho improvvisato

1. **`tools/gas-gate.sh`** — `node --check` rifiuta `.gs` con `ERR_UNKNOWN_FILE_EXTENSION` e,
   la parte che conta, **esce comunque `rc=0`** dentro una pipe: la riga in `.night-verify` era
   verde pur avendo stampato un traceback. Il gate copia in `.js` prima di controllare, e
   guarda anche lo script inline degli `.html` (215 righe di JavaScript in produzione che
   nessun gate vedeva).
2. **`tests/fixture-fogli.js`** — la forma dei fogli **derivata da `setupSheets`** con il
   `file:riga` che la autorizza. Nasce da E-001 (§4).
3. **Il brief comune ai 50 giri** (00-BRIEF, file del progetto): contesto, 10 aree ancorate a range di riga,
   5 lenti, regole e formato di uscita in un file solo. I prompt dei singoli giri restano di
   tre righe. È il pezzo più riusabile della sessione.
4. **DOMANDE (file del progetto)** — le 5 domande di dominio che ho rifiutato di indovinare, ognuna con
   *perché conta · cosa può dire il sistema · cosa può dire solo una persona*, e la scelta
   provvisoria che il codice fa nel frattempo, dichiarata e reversibile.

---

## 3. Tre difetti dello standard, pagati oggi

1. **`.campo-rem` non è ignorato da nessuno.** tools/metodo-reminder-hook.sh (la riga che scrive il
   marcatore) scrive il marcatore nella working dir a ogni prompt; `sync-repo --standard` copia l'hook e non
   aggiunge nessuna riga a `.gitignore`. **Ogni repo che adotta lo standard resta con un file
   untracked per sempre.** L'hub lo cancella in tools/giri-avversari.sh — sa che è di runtime,
   ma quella conoscenza non viaggia con lo standard.
   *Cura: `.gitignore` nella lista di `sync-repo --standard`, o l'append di quella riga.*

2. **`fixture-provenienza.sh` cattura se stessa.** La `find` alla riga 24 matcha
   `-name 'fixture-*'`, e lo script si chiama `fixture-provenienza.sh`. Su una repo appena
   portata a standard e **senza nessuna fixture** l'esito è
   `⛔ 1 fixture su 1 non dichiarano il comando che le ha prodotte`: rosso al primo colpo, su
   niente. È il primo output che un nuovo adottante vede, e *il costo di un falso positivo è
   la fiducia*.
   *Cura: escludere `$0` e `tools/` dalla `find`.*

3. **tools/sync-repo.sh non dichiara la dipendenza da `gh`.** tools/onboard-repo.sh (righe 8-19) ha il blocco
   "PERCORSO CLOUD/IBRIDO" proprio per questo, spostato in testa al file da un giro precedente
   con la motivazione scritta. `sync-repo.sh` ha la stessa dipendenza (riga 38, `gh repo clone`
   alla 51) e nessun blocco equivalente — pur essendo **il comando insegnato in
   `docs/benvenuto-collaboratori.md`**: quello che il collaboratore nuovo prova per primo, e
   che da una sessione cloud non può funzionare.
   *Cura: portare in testa a `sync-repo.sh` lo stesso blocco.*

---

## 4. Il quarto difetto era mio, ed è il più istruttivo

**E-001** (`docs/errori/REGISTRO.md`). Ho pubblicato un report che accusava **due** funzioni
di un bug, scrivendo nello stesso paragrafo «difetto provato eseguendo, non dedotto». Una
delle due era sana.

La causa: la fixture del banco dava a tutti i fogli l'intestazione in riga 1. La forma vera,
scritta in `setupSheets`, è asimmetrica — `Actual_Fatturato` ha riga 1 = TOTALE e riga 2 =
intestazioni, tutti gli altri fogli riga 1 = intestazioni. **Lo stesso identico codice
(`getRange(2,...)` + `shift()`) è quindi corretto su un foglio e rotto sull'altro: è il foglio
che decide, non il codice.**

Ho dedotto la forma dei dati dalla forma del codice, invece di leggerla dalla funzione che
quei dati li crea. È esattamente la classe di difetto che `fixture-provenienza.sh` esiste per
prevenire — *«una fixture senza la riga che dichiara come è nata è un'ipotesi travestita da
misura»* — applicata a me, in una sessione in cui quello strumento era installato e verde.

**Perché è successo: ho trattato la convergenza come conferma.** Tre lenti indipendenti
avevano segnalato lo stesso difetto, e tre lenti convergenti mi hanno fatto abbassare la
guardia. Ma i 50 giri leggono tutti **la stessa fonte**: non sono 50 fonti indipendenti, sono
50 letture di una fonte sola. Se la fonte induce una premessa sbagliata, tutte e 50 la
ereditano, e la loro convergenza misura quanto è *convincente* l'errore, non quanto è *vero*.

**Cosa ha salvato la sessione**: la regola «banco prima della correzione». Il banco rifatto
con la fixture vera ha smontato la mia stessa accusa **prima** che toccassi il codice. Se
fosse arrivato dopo, avrei "aggiustato" una funzione funzionante e rotto la lettura dello
storico.

---

## 5. Cosa ha retto

- **`copia-hook.sh`**: derivare invece di riscrivere. Nessun drift. Il contrario esatto del
  problema che il file stesso documenta.
- **"Esegui, non dedurre"** — due volte, in due direzioni: ha *confermato* il difetto vero e
  ha *smontato* quello falso.
- **Il sabotaggio dichiarato**: ogni guardia nuova vista rossa prima di essere creduta. Una di
  queste sembrava verde con `bash tools/gas-gate.sh | tail -4` — ma quell'`rc=0` era della
  pipe, non del gate. La stessa trappola di `node --check` che avevo documentato tre ore prima,
  ripresentata in un'altra forma.
- **"Scarto mai silenzioso"**: la lente che ha prodotto la classe di finding più numerosa
  dell'intero giro (~25 su 255, in 7 aree su 10). Il canone ha trovato nel progetto esattamente
  quello che dice di cercare.
- **DEBITI/DOMANDE**: alla fine di "correggi tutto" il lavoro non finito è *nominato*, non
  sottinteso — 5 domande di dominio e 1 debito di verifica, invece di 5 invenzioni di logica
  di business.

---

## 6. Attrito senza colpa del metodo

20 agenti Opus in parallelo hanno esaurito il limite di sessione a metà del primo blocco.
**16 giri su 20 erano già salvi**, perché il brief impone di scrivere il file *prima* di
rispondere: i 4 persi sono quelli morti nel passo di risposta. Ripartiti su Sonnet, i 34
restanti sono arrivati tutti.

Conseguenza sull'onestà del giro: i primi 16 giri sono girati su Opus, i 34 successivi su
Sonnet. **I 50 giri non sono omogenei**, ed è scritto nel risultato.

---

## 7. Proposta al canone

1. **`tools/gas-gate.sh` nell'hub**, e la riga che `sync-repo --standard` semina nel
   `.night-verify` di destinazione. Il file è pronto in questo repo. Generalizzare E-028:
   **ogni linguaggio tracciato ha il suo gate di sintassi, o l'assenza è dichiarata** — e il
   gate include il codice dentro l'HTML, che in un progetto GAS è metà dell'applicazione.
2. **`.gitignore` nella lista di `sync-repo --standard`** (difetto 1).
3. **`fixture-provenienza.sh`: escludere `$0` e `tools/`** (difetto 2). Un gate che accusa se
   stesso insegna a ignorarlo.
4. **Il blocco cloud/ibrido in testa a `sync-repo.sh`** (difetto 3).
5. **Estendere la convenzione di `fixture-provenienza.sh`**: oggi chiede il *comando* che ha
   prodotto la fixture. Una fixture che rappresenta la **forma** di un dato non nasce da un
   comando ma da una lettura di codice: deve dichiarare il `file:riga` della funzione che
   quella forma la crea. Senza, il banco misura l'idea che l'autore si è fatto del dato — che
   è l'ipotesi che doveva verificare. **Questa è la regola che avrebbe impedito E-001.**
6. **Una skill `cinquanta-giri`.** Il metodo funziona; oggi va ricostruito a mano da un vecchio
   artefatto. Ha una forma stabile:
   - il **brief unico**, con le aree ancorate a `file:riga-riga` e le lenti dichiarate;
   - **una lente per giro, un'area per giro**, mai due;
   - **"nulla in questa lente" è un esito valido e dichiarato** (L3-A1 l'ha usato: la
     motivazione vale quanto un finding, dice dove la lente non morde);
   - il formato **Oggi / Manca / Proposta**, che impedisce il principio generico;
   - **tetto di 6 finding per giro**, che costringe all'ordinamento per gravità;
   - **il modello dichiarato per blocco**, quando i giri non girano tutti sullo stesso.
7. **Regola nuova: il giro scrive il suo file prima di rispondere.** Un giro il cui unico
   prodotto è la risposta finale è perso quando l'agente muore — ed esaurire un limite a metà
   di 50 agenti non è il caso raro, è il caso normale. Misurato oggi: 16 su 20 sopravvissuti a
   un fallimento totale del blocco. Vale per qualsiasi lavoro a ventaglio.
8. **La convergenza di più lenti non è una conferma.** Il documento di consolidamento deve
   separare due colonne — *segnalato da N lenti* e *verificato eseguendo* — e la prima non
   promuove mai la seconda, per nessun valore di N. La convergenza dice **dove guardare**, non
   **cosa concludere**: è il segnale che sceglie quale finding portare a banco, mai il
   sostituto del banco. Costo di non averla avuta: E-001.

---

## 8. Da fare sull'hub — non fatto qui

Questa sessione ha `obi2kenobi/AI_Programmer` in **sola lettura**: le 8 proposte non sono
state aperte come PR. Vanno portate su a mano, o ripetute da una sessione con la repo
attaccata in scrittura. Le prime quattro sono correzioni di una riga; la quinta e l'ottava
sono regole; la sesta è la skill.
