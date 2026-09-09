# 2026-09-10 — Magazzino_Treviso: i giri di miglioramento e le scoperte della settimana

**Autore**: sessione `glm/treviso-giri-miglioramento` (ZCode/GLM) su Magazzino_Treviso, il
progetto Apps Script del magazzino. Mandato di Luca: «far fare 5-6 giri di miglioramento e
correzione ora che abbiamo le idee chiare, e fare un report con tutte le scoperte e gli
errori ad AI_Programmer». Il report copre la sessione intera, non solo i giri di stasera:
la settimana ha curato #239-#247 (endpoint separati, la cella-data, il filtro della coda,
l'attribuzione visibile, il fornitore dal documento, la sonda OCR, la cascata col modello).

## Cosa ho usato

- **Il cancello a ogni giro** (50 comandi · 1093 attese). Stasera ha preso **due errori miei
  di forma nel registro dei debiti** al primo passaggio dopo la scrittura — celle di stato
  col grassetto malformato (`**CHIUSO il 2026-09-10**`): lo strumento che le legge non le
  riconosceva come stato. Il cancello ha trasformato un registro che mentiva per incidente
  in uno che dice 36 aperte, vere.
- **Banco prima, rosso visto, cura, sabotaggio dichiarato col verdetto del banco** — su ogni
  giro. Il sabotaggio di stasera (resa nuda dei codici rimessa al suo posto) è stato rosso
  col valore atteso nel messaggio, non col grep.
- **Il banco browser con la fotografia** (`FOTO=`): i due difetti visivi della schermata
  vengono da una foto del vivo alle 00:20. Uno dei due era un artefatto del copia-incolla:
  l'attesa che presidia l'impilamento passa già, e NON ho toccato il CSS. Guardare la foto
  ha evitato una cura inutile.
- **La lente delle ancore** (test-ancore-banchi.sh) come banco dei banchi.
- **`docs/campo/`, `DEBITI.md`, `SAL.md`** a ogni giro, in sola aggiunta.
- **Ciò che ho voluto usare e non c'era**: niente di nuovo stasera. Il vivo resta
  irraggiungibile (clasp vietato all'agente per scelta) e questo resta il limite
  strutturale: il magazziniere non ha ancora confermato un camion, quindi il primo giro
  end-to-end della conferma è ancora tutto da misurare.

## Cosa ho improvvisato

- **La cascata a gradini dichiarati** (#246, su ordine perentorio di Luca: «se non riconosce
  il documento usi Mistral, faccia il modello, e poi testi se il modello funzioni — e vada
  avanti finché non trova tutto»). Tre gradini — parser sul testo appiattito, modello Mistral
  con `document_annotation_format` e schema JSON, ripiego Drive — e OGNI gradino dichiara
  `letto_da` nel record. La risposta del modello SI TESTA: i fatti obbligatori mancanti
  respingono l'intera risposta col motivo che li nomina. Il secondo morso è arrivato dal
  vivo a mezzanotte: l'appiattimento faceva passare il riconoscimento ma il destinatario
  restava illeggibile — la cascata ora sale al gradino successivo anche quando manca un
  FATTO, non solo quando manca il documento. «Finché non trova tutto», l'altra metà
  dell'ordine, era la parte che il primo giro non aveva ascoltato.
- **La sonda come ponte banco-vivo** (#245): `sondaOcrDocumento` restituisce il testo VERO
  di entrambi i motori col verdetto di riconoscimento. È il canale per cui una misura del
  vivo diventa fixture: quando il banco è verde e il vivo no, la risposta è un probe
  esterno, non un'altra deduzione.

## Cosa ha retto / ostacolato

**Ha retto:**

- **«La misura di un sabotaggio è il verdetto del banco»**: stasera il rosso del sabotaggio
  portava il valore esatto («1:» atteso vs «1 pacchetto» ottenuto). Nei giri della settimana
  ha preso anche sabotaggi nulli (che non rimuovevano il difetto) e mezze cure (il reduce
  che concatenava oggetti: `pezzi: "0[object Object][object Object]"` — il mezzo-fatto
  VISTO nel valore).
- **«Il registro si legge con uno strumento»**: la lente della forma ha pagato due volte
  stasera, su righe scritte male DA ME nelle ore precedenti. Un presidio che ti prende
  mentre sbagli tu è l'unico che conta.
- **Il divieto di deploy all'agente**: ogni `clasp push` è gesto di Luca, e il flusso
  «push + NUOVA VERSIONE dalla UI» è documentato nel libretto. Le due volte che il vivo
  «non cambiava» la causa era la versione, non il push.

**Ha ostacolato:**

- **`google.script.run` rifiuta i payload con oggetti Date** (#240) e lo dice SOLO al
  failure handler client, mentre il log server dice «Completata». Guasto invisibile dal
  lato da cui si guarda di solito. Cura: serializzare a ISO al confine. Famiglia da
  dichiarare per ogni progetto Apps Script.
- **Il bash 3.2 di macOS in locale UTF-8** legge il primo byte di `»` come parte del nome
  della variabile: `$T»` con `set -u` uccide lo script con «unbound variable». L'ho
  riprodotto in tre righe. Cura: `${T}`. Ma il punto è un altro: **la lezione esisteva già
  in un altro file dello stesso progetto** (tre graffe in test-clasp-block-hook.sh) e non si
  era propagata a quello nuovo.
- **I miei gesti sbagliati della settimana, tutti registrati in SAL**: `git checkout` che
  cancellava lavoro non committato; heredoc python con `find()` non verificati che hanno
  corrotto due file (shebang distrutto) fino al ripristino + regola delle ancore
  `count==1`; apostrofi nudi nelle stringhe JS delle attese (tre volte: la lezione è
  accenti veri, è/perché/tracciabilità); attese inserite due volte dentro la funzione
  verdetto sbagliata fino all'ancora univoca. Il canone li prende quasi tutti («verifica il
  bersaglio prima di sostituirlo»); gli apostrofi nessuno li presidia se non la memoria.

## Proposta al canone

Tre patto-candidati e una forma:

1. **«Dopo il merge, il ramo è morto»**: mai pushare lavoro nuovo su un ramo la cui PR è
   stata mergiata — il commit #243 è rimasto settimane fuori dal vivo esattamente così, e
   nessun cancello locale può vederlo (il danno è fra repo e repo, non nel codice). Il
   presidio è una riga nel flusso: il lavoro nuovo parte da un ramo NUOVO dal main, e se
   trovi commit tuoi su un ramo mergiato, li porti con un merge esplicito dichiarato.
2. **«`${VAR}` davanti a un carattere multibyte, sempre»** (bash): il 3.2 di macOS con
   `set -u` legge `»` come parte del nome. Ma la proposta vera è la forma generale che
   questo caso rivela: **una lezione vissuta in un file non si propaga da sola** — se resta
   sepolta nel punto dove è stata imparata, il file nuovo la riscrive come bug. Le lezioni
   di shell vanno come REGOLA nel patto, non come graffa nel file che è capitato.
3. **«Ogni gesto sul registro passa dal cancello SUBITO»**: il registro dei debiti è un
   banco anche lui. Le sue lenti (forma delle righe, vocabolario degli stati, il numero
   esatto delle voci storiche) prendono la riga scritta male solo se il cancello gira DOPO
   la scrittura, non «al prossimo giro». Stasera: due celle malformate e tre cure mai
   registrate, tutte prese/corrette in un solo cancello.
4. **La forma del cambio-lettore** (da #245/#246, come conferma di E-018): quando cambia
   chi legge, cambia la FORMA di ciò che si legge. La risposta non è «un parser più
   robusto» ma una **cascata a gradini dichiarati**, dove ogni gradino dichiara chi ha
   letto (`letto_da`), le risposte del modello si TESTANO sui fatti obbligatori prima di
   essere credute, e il ripiego è dichiarato nel record. Il gradino che tace è il gradino
   che mente.

**E una non-proposta, dichiarata**: il guasto «Date nel payload» (#240) e «/exec serve
l'ultima versione non l'ultimo push» sono specifiche di piattaforma, non del metodo: stanno
nel libretto del progetto (docs/deploy-e-prova.md) e nei suoi DEBITI, non nel canone.
