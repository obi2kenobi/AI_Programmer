# Report dal campo — Centrale_Rischi: cruscotto v2, giro di prova su 10 mesi, giri di miglioramento (2 sessioni, 31/08–01/09)

Due sessioni di fila sul progetto cruscotto Centrale Rischi: la prima ha consegnato il
cruscotto v2 (4 moduli) e il giro di prova su 10 prospetti reali; la seconda ha preso
in produzione quello che la prima aveva messo online — con l'utente che ha trovato a
mano tre difetti che tutti i banchi verdi non vedevano. Report scritto come chiede il
metodo: cosa è consegnato, come è uscito dai difetti, cosa il processo ha dimostrato.

## Cosa è stato consegnato (con la prova)

- **Cruscotto v2** (4 moduli, un PR ognuno): indice dei prospetti (protocollo PEC →
  nome canonico, mesi, righe, sconfinamenti, stato coda, link PDF Drive); statistiche
  per mese con ordine cronologico; riepilogo mensile stampabile per mese; stato
  aggiornamento in sola lettura. Ogni aggregazione ha il suo banco (vincolo #1).
- **Ingestione dei prospetti dalla PEC**: `GmailApp` nel Workspace cerca i prospetti
  per oggetto, salva i PDF su Drive e li etichetta col protocollo PEC ("CR-1337410-26")
  — che coincide col "Prot. N°" stampato nel PDF: il nome canonico deriva dal
  documento, non da un'etichetta battuta a mano. Coda di elaborazione con
  `avviaProssimoCR` (una voce alla volta, persiste solo dopo un avvio riuscito,
  retry deterministico al fallimento).
- **Giro di prova eseguito**: 10 prospetti reali (consegne mensili), pipeline a ripresa
  ~15 min l'uno, coda visibile nell'indice pubblico.
- **10 giri di miglioramento** in una sessione: 59→67 attese verdi, ognuna citata nel
  log (`loops/2026-09-01-giri-miglioramento.md` nel progetto).
- **Deploy via clasp su richiesta esplicita dell'utente** (push + redeploy della
  deployment esistente con `-i`), con verifica dal vivo nel browser.

## I difetti usciti in produzione (e chi li ha trovati)

1. **Sheets converte "ottobre 2025" in data** al momento della scrittura → le viste
   che raggruppano sul testo si rompono. Trovato dall'utente su screenshot. Fix su
   tre livelli: formato testo alla colonna, normalizzazione alla lettura (Date →
   "mese anno" con mappa italiana, locale-indipendente), correzione una-tantum.
2. **Pagine guida con tabelle d'esempio ingerite come dati**: i prospetti incorporano
   la guida di lettura con tabelle finte (banche "UNO/DUE/QUATTRO", "sig. Rossi") che
   hanno la stessa forma delle tabelle vere. Prima lettura mia sbagliata ("dati
   storici"), corretta dall'utente ("sono dati test nelle istruzioni"), verificata
   poi sul testo del PDF ("rappresenta così le informazioni…"). Filtro deterministico
   prima della chiamata LLM: `FILIALE DI` + `Intestatario:` sulle pagine vere,
   12/12 vs 10/10 sul documento reale, ~40 chiamate risparmiate a documento.
3. **Il PDF stampato era troncato**: 9 colonne non stavano in A4 e il browser
   tagliava le colonne dei soldi. Letto il PDF dell'utente con estrazione testo per
   confermare (2 pagine, solo intermediario+categoria). Fix: riepilogo essenziale a
   6 colonne, a-capo, @page A4.
4. **Click sui mesi → pagina bianca**: link relativi nel sandbox GAS risolvono
   contro googleusercontent, e il redirect interno **doppio-codifica** i parametri
   (dipende dal percorso: click vs URL diretto). Fix: URL assoluto dal server +
   decodifica in doGet finché si stabilizza.
5. **`ePaginaDati_` case-sensitive su "Intestatario"**: un OCR in maiuscolo avrebbe
   scartato in massa le pagine dati vere. Giro di miglioramento n.1.
6. **Il redeploy clasp ha perso la config "App web"** della deployment: l'URL /exec
   dava errore Drive. Causa: la config viveva solo nella deployment creata dall'UI.
   Fix alla radice: sezione `webapp` nel manifest (nel repo), così ogni deploy futuro
   la conserva. Nota: aggiornare il manifest remoto richiede `clasp push --force`.

## Cosa il processo ha dimostrato

1. **I banchi verdi non vedono i difetti del canale di presentazione**: quaranta
   attese verdi e il PDF usciva troncato, perché nessun banco testava il browser e
   la stampa. Il gap non è colmabile in CI: la verifica-visiva e il "stampalo e
   guardalo" sono canali di verifica a parte, non cerimonia.
2. **L'utente ha trovato a mano i difetti che l'automazione non vedeva** (coerzione
   date, pagine esempio, PDF troncato) e una volta su tre aveva già dato la risposta
   giusta prima di me ("sono dati test nelle istruzioni"): il dominio vince, sempre.
3. **Il metodo regge anche quando sbaglio a leggere il dominio** — purché la
   correzione venga VERIFICATA sul documento invece che discussa a parole: la
   sequenza "ipotesi sbagliata → correzione utente → prova sul testo del PDF" ha
   chiuso la discussione in un attimo.
4. **Due tracce di sviluppo in parallelo sulla stessa repo** (sessione locale +
   sessione cloud): il sync costante (fetch prima di ogni tocco) ha evitato le
   collisioni; DEBITI.md condiviso come memoria comune ha funzionato.

## Proposte al canone

1. **Pattern "manifest webapp nel repo"**: ogni progetto GAS con Web App deve avere
   la sezione `webapp` in `appsscript.json` dal primo giorno — il redeploy clasp
   senza di essa distrugge l'entry point. Da aggiungere a `gas-sviluppo`/README GAS.
2. **Pattern "link assoluti + decodifica robusta"** nelle Web App GAS: i link con
   query param relativi si rompono nel sandbox, e i parametri arrivano a volte
   doppiamente codificati (redirect interno). Da pattern, con la decodifica
   finché-stabilizza come inciso standard nei `doGet`.
3. **Formattazione presentazione esplicita, mai `toLocaleString`**: dipende
   dall'ICU dell'ambiente (verificato: i negativi in Node senza separatore) —
   il banco non è un oracolo se la formula cambia risultato tra banco e runtime.
4. **"Il cruscotto risponde a una domanda"**: prima di disegnare una dashboard,
   scrivere la domanda dell'utente in testa al design-doc e testare ogni pannello
   contro di essa — il muro di 348 righe passava tutti i vincoli e non serviva
   a nessuna domanda.
5. **Stampa = vincolo di larghezza**: ogni vista stampabile dichiara le colonne che
   stanno in A4 (o la @page landscape) NEL design-doc, non a CSS finito.

## Stato e prossimi passi

Issue #18 aperta (si chiude con la verifica col parser deterministico mese per
mese); coda quasi completa; prossime commesse dichiarate: parser-oracolo
(quantificare le righe perse — 3 già individuate su maggio), Config Banche per le
statistiche per banca normalizzate, foglio di fiducia (percentuali e via l'avviso),
restrizione accessi della deployment prima di qualunque uso verso terzi.
