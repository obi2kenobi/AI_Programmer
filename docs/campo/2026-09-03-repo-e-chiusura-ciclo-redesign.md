# 2026-09-03 (AGGIORNATO coi numeri veri post-merge: 9 controlli, 254 attese, 7+4 backlog) — Chiusura del ciclo: due audit, un redesign, tre presidi nuovi

**Autore**: sessione Claude Code (remoto), branch `claude/routine-controlli-redesign-ui-walw0b`,
[PR #54](https://github.com/obi2kenobi/Sistema-Gestione-Magazzino/pull/54).
Report consolidato al metodo AI_Programmer. I due report di dettaglio sono
2026-09-02-audit-conta-fisica (file del progetto) e
2026-09-03-perimetro-a-soglie (file del progetto).

**Richiesta di partenza**: «una routine di controlli e correzioni errori, più ridisegnare e
razionalizzare l'interfaccia». Due lavori distinti, separati deliberatamente: **prima i controlli,
poi il redesign** — su un monolite di 5.292 righe non esiste modo di distinguere una regressione
da un difetto preesistente senza una baseline pulita.

---

## Il consuntivo, in numeri

| | Prima | Dopo |
|---|---|---|
| Controlli nel gate | 5 | **8** |
| Attese eseguite dal gate | 173 | **227** |
| Difetti chiusi | — | 1 bloccante, 6 seri, 3 minori |
| Voci a backlog **dichiarate** | — | 11 |
| Righe di `Dashboard.html` | 5.292 | 5.279 |
| Articoli visibili a schermo | 6 | 14 |

Tre commit, tutti con gate verde prima del push. Nessun deploy: `clasp` resta un gesto umano.

## Cosa è stato chiuso

**Il bloccante** — `chiudiCicloRettificheImpl_` chiudeva e contabilizzava rettifiche **mai contate e
mai spedite a BC**. Una cella "Qty Fisica" con dentro uno spazio veniva letta come "contato a zero":
su un articolo da 800 pz a 12,50 € l'email a operations partiva con 1 riga, la chiusura ne chiudeva
2, e la chiusura contabile mensile riportava **−10.125 € invece di −125 €**. Diecimila euro di
rettifica che in Business Central nessuno aveva mai registrato.

**Cinque seri**: lo stesso predicato ingenuo in altri 3 siti (archivio + 2 KPI); il TSV per BC che
non neutralizzava le formule; le ubicazioni azzerate in silenzio; le soglie messe a 0 rimpiazzate
dal default; un movimento senza data che avvelenava l'intero articolo.

**Il redesign**: sistema visivo unico (105 esadecimali sparsi → token per ruolo), gerarchia delle
azioni (14 bottoni allo stesso volume → tre pesi dichiarati), densità della tabella (righe da
~100px a ~40px), lo stato dei bottoni spostato dal colore hardcoded nel JS a una classe CSS.

## Cosa NON è stato fatto, e perché

Onestà prima del bilancio: **11 voci restano aperte**, e nessuna per dimenticanza.

- **4 per decisione esplicita del proprietario** — lo schema di `Articoli_Ubicazioni` (cambio di
  schema sul vivo con migrazione), la verifica se il bloccante abbia già morso in produzione, e due
  minori.
- **2 non decidibili senza il vivo** — il lock tenuto attraverso la fetch a BC (difetto
  architetturale certo, **materializzazione non misurata**: serve un cronometro) e la presenza di
  movimenti con `Location_Code` vuoto (diagnostica pronta, mai eseguita).
- **5 minori a costo/beneficio sfavorevole in questo giro** — fra cui i 221 `style=` inline che
  nessun tema può raggiungere.

Restano fuori anche **le altre due tab e le altre dieci modali** del redesign: non sono state
fotografate. Usano gli stessi componenti già verificati, ma *"stessi componenti"* è un'inferenza,
non una prova.

---

## Le tre cose che il metodo ha prodotto e che valgono oltre questo progetto

### 1. La domanda di dominio decide il VERSO della correzione, non il suo dettaglio

Due volte in un giorno la correzione dipendeva da una risposta che il codice non conteneva:

- *Cosa intende un addetto scrivendo qualcosa di non numerico in "Qty Fisica"?* Se «non l'ho
  contato» → indurire il test. Se «l'ho guardato e non c'è niente» → indurirlo **spegnerebbe
  rettifiche legittime**, e la correzione giusta è l'opposta.
- *Cosa significa una soglia messa a 0?* Se «spegni il controllo» → i consumatori sono sbagliati. Se
  «usa il default» → è il fix del round precedente a essere inutile.

In entrambi i casi le due letture non erano una più prudente dell'altra: erano **simmetriche**.
Sceglierne una in autonomia sarebbe stato indovinare al 50% su codice che muove cifre contabili.
Il canone dice già «se non è chiaro, chiedi»; quello che aggiungo è **come riconoscere il caso**:
quando le due interpretazioni portano a correzioni opposte e nessuna è il default sicuro, la
domanda non è rimandabile.

### 2. Un sabotaggio che resta verde è un buco nel banco, non un sollievo

Su cinque sabotaggi del perimetro A, **uno è rimasto verde**. Togliendo il controllo
`isNaN(getTime())` il banco non se ne accorgeva — le attese usavano `undefined` e `null`, entrambi
intercettati dall'early-return **prima** di arrivare a quel controllo. Mancava il caso vero: una
data **presente ma illeggibile**.

**Una guardia che nessuna attesa fa fallire non è presidiata, anche quando il codice è giusto.**
Il sabotaggio non serve solo a provare che il codice regge: serve a provare che *il banco guarda*.

Stessa famiglia, altra forma: un'attesa su `valoreAltoEuro = 0` passava perché la riga di prova
valeva 100 € e non superava comunque il default di 50.000 — sarebbe passata **anche col difetto
presente**. Un'attesa così è peggio di un'attesa assente: dà la sensazione di copertura.

### 3. Un fix può essere «riparato» senza essere «riparato-verificato»

Il caso più istruttivo della giornata. Il round 3 del 2026-09-01 aveva corretto la **lettura** delle
soglie (`num >= 0` invece di `num > 0`) con un commento esplicito: *«una soglia esplicita 0 veniva
scartata e sostituita in silenzio dal default»*. Corretto. Ma **tre consumatori** riapplicavano `||`
e ributtavano lo zero sul default: il fix era arrivato a metà strada, e per due giorni è stato
contato come chiuso.

Lo stesso schema si è ripetuto altre due volte oggi: `_hasPhysicalCount` esisteva ed era usato da
6 siti mentre 4 usavano ancora la copia ingenua; la regola anti-formula esisteva lato client e non
sul cammino server, a 40 righe di distanza.

**Proposta al canone**: quando un fix introduce un helper o una regola, il giro non è chiuso finché
non si è **censita la popolazione** dei siti che dovrebbero usarlo. Un `grep` sul pattern vecchio,
con il conteggio dichiarato: *«4 siti ingenui contro 6 usi di quello indurito»* è una riga che vale
un round di audit.

---

## Proposte operative al canone

1. **`node --check` dentro la funzione di sabotaggio, più il `diff` col file buono.** Un sabotaggio
   che rompe la sintassi, o un `replace` che non trova la stringa, non falliscono: producono un
   verde che sembra un successo. Entrambi mi sono capitati, a un giorno di distanza.
2. **Normalizzare le attese cross-realm nei banchi `vm`** (`Array.from`, o valutare il nome per le
   `const` top-level, che non diventano proprietà del contesto). Un banco che fallisce sul prototipo
   invece che sul difetto mente — e mente peggio di un banco assente.
3. **Il debito come attesa VERDE che fotografa il limite.** Quando una correzione piena viene
   rimandata per decisione, invece di lasciare un'attesa rossa per sempre (che smette di essere una
   guardia) o di cancellarla (che rende il debito silenzioso): un'attesa che descrive il
   comportamento attuale, così il giorno in cui il limite cade sarà **lei** a diventare rossa e a
   chiedere di essere riscritta. Applicato qui a `LIMITE NOTO: due magazzini collassano su una chiave`.
4. **Un rilievo di un agente si verifica come si verifica il codice.** Uno su dieci non reggeva — e
   era proprio quello che avrebbe generato lavoro inutile (proponeva di «collegare» una funzione già
   collegata). Costo della verifica: un `grep`.
5. **Il presidio si scrive PRIMA del lavoro che potrebbe romperlo.** Prima del redesign è nato
   `verifica-elementi-ui.js`, che verifica che ogni `getElementById` trovi un id dichiarato e ogni
   `onclick` una funzione definita: l'equivalente frontend del ponte staccato, invisibile a push e a
   deploy. Era verde sullo stato di partenza — cioè non è nato per riparare, è nato per **permettere**
   di toccare.

---

## Il gesto umano che resta

- **Il deploy**, dal Mac di Luca. Come sempre in questo repo: `clasp` è negato tecnicamente dalla
  sessione.
- **`diagnoseBCLocationVuota_()`** eseguita una volta dall'editor (sola lettura): risponde alle due
  domande che il codice non può risolvere da solo — quanti movimenti hanno `Location_Code` vuoto e
  quanti hanno `Posting_Date` mancante, cioè quanto due dei rilievi mordessero davvero.
- **Una review visiva sul vivo** dopo il deploy: gli screenshot del redesign sono su dati sintetici,
  e coprono la pagina principale e una modale su undici.


## AGGIORNAMENTO (post-merge, 2026-09-03)
- Numeri riverificati: 9 controlli (non 8), 254 attese (non 227), 7 chiuse + 4 aperte (non 11 aperte)
- QUARTA LEZIONE: scrivere una lezione non basta a non ripeterla (la proposta cross-realm violata il giorno dopo dallo stesso autore)
- DUE PROPOSTE NUOVE: misurare prima di correggere quando il difetto è certo ma il danno no; un elenco che conta due volte la stessa voce non è un elenco
- RILIEVI AGENTI: 2 su 10 non reggevano (dichiarato, non nascosto)
