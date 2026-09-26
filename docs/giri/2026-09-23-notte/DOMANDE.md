# Domande di dominio — la notte dei giri (2026-09-23)

Il giro A4 ha letto gli oracoli contabili (`tools/*.py`) contro le loro promesse. Il meccanico è
curato (SAL, voce 18°, Q22a-c: verdetti sul vuoto, nan, traceback, righe sparite). Restano le
domande che il codice non può chiudere da solo. Quasi tutte hanno la stessa forma: l'oracolo
riproduce un sistema studiato (REPO-E, `gas-src/`), e il comportamento strano **o è fedele al
sorgente** (allora è un difetto del sistema, e diventa un requisito da decidere) **o è un difetto
dell'oracolo** (allora si cura). Solo il sorgente, o Luca, lo dicono.

Per ogni domanda: perché conta · cosa può dire il sistema · cosa solo una persona · la scelta
provvisoria in vigore oggi. Si pongono una alla volta (settimo patto).

## 1. Aging: i tipi documento fornitore fuori elenco vanno fra le entrate?
- **Perché conta.** `tools/scadenzario_aging.py` mette in uscita (-abs) solo `Fattura`/`Invoice`;
  tutto il resto prende +abs, cioè finisce fra le ENTRATE: `FATTURA` maiuscolo, `Payment`, un
  fornitore senza tipo. Riprodotto: `Fornitore FATTURA` 1000, `Fornitore Payment` 300 e
  `Fornitore Fattura` 200 danno entrate +1300 e uscite -200. La sola `FATTURA` maiuscola, se vale
  come `Fattura`, sposta il saldo di 2000 € col segno sbagliato; per `Payment` il segno giusto è
  proprio la domanda.
- **Il sistema.** Il sorgente dello scadenzario di REPO-E dice se il `+abs` di default è suo e se
  il confronto distingue le maiuscole.
- **Una persona.** Quali tipi documento fornitore escono davvero dall'export di BC, e come vanno
  trattati (Payment? Credit Memo in inglese?).
- **Oggi.** Numeri invariati; l'oracolo DICE le righe fuori elenco con un ATTENZIONE (Q22c).

## 2. Rating DSO: l'abbinamento per codice attraversa i clienti?
- **Perché conta.** `tools/rating_dso_clienti.py` abbina un pagamento a una fattura se il codice
  documento è CONTENUTO nella descrizione, senza guardare il cliente: il pagamento di Rossi per
  `25OV-123` si attacca alla fattura di Bianchi `25OV-1234` (Bianchi riceve un DSO di 19 gg,
  Rossi resta non pagato).
- **Il sistema.** `Codice.js` di REPO-E: il docstring dice «che lo contiene» — va letto se il
  sorgente fa la stessa sottostringa.
- **Una persona.** Se i codici possono davvero essere uno il prefisso dell'altro nei dati reali.
- **Oggi.** Invariato.

## 3. Rating DSO: come si arrotonda la metà?
- **Perché conta.** `round()` di Python arrotonda la metà al pari (2,5 → 2), `Math.round` di JS
  la porta su (3). Un DSO medio può differire di un giorno dal sistema studiato.
- **Il sistema.** L'arrotondamento del sorgente.
- **Una persona.** Nessuna, se il sorgente è chiaro.
- **Oggi.** Invariato (arrotondamento di Python).

## 4. Rating DSO: un importo vuoto vale zero?
- **Perché conta.** `float(r["importo"] or 0)`: un importo assente diventa 0. È la famiglia
  «assente non è zero» del canone; ma se il sorgente fa `Number(x) || 0`, l'oracolo è fedele.
- **Il sistema.** Il sorgente. **Una persona.** Se un movimento senza importo può esistere nei dati.
- **Oggi.** Invariato.

## 5. Margine: le BU si confrontano distinguendo le maiuscole?
- **Perché conta.** `tools/margine_documento.py` segnala «⚠️ BU DIVERSA» fra `arrg` e `ARRG`.
- **Il sistema.** Il sorgente del controllo margini. **Una persona.** Se le BU arrivano mai in
  minuscolo dall'export.
- **Oggi.** Invariato. (La normalizzazione del RIFERIMENTO invece è curata: il docstring cita il
  sorgente con `/\s+/g`, Q22c.)

## 6. Roll-forward cespiti: il segno del fondo è un invariante da far rispettare?
- **Perché conta.** Il docstring di `tools/rollforward_cespiti.py` dice «il segno del fondo è un
  invariante di dominio» e che ogni voce che non quadra «viene dichiarata». Il codice non
  controlla nessuna delle due: un export col fondo POSITIVO (convenzione di altri gestionali) dà
  un valore netto di 1600 su un costo storico di 1000, rc 0.
- **Il sistema.** Il registro cespiti del gestionale dice la convenzione di segno dell'export.
- **Una persona.** Cosa fare davanti al fondo positivo: rifiutare (ERRORE), convertire, o
  avvisare. E se aggiungere il riscontro esterno (costo e fondo di chiusura dal registro) che il
  docstring promette.
- **Oggi.** Invariato: nessun controllo di segno (i traceback sono curati, Q22c).

## 7. Accuratezza fatture: gli ordini a importo ≤ 0 sono errori reali?
- **Perché conta.** Dal 2026-08-28 `tools/accuratezza_fatture_acquisto.py` conta fra gli «errori
  reali» anche le fatture su ordini a importo ≤ 0: la formula non è più quella di REPO-E citata
  dal docstring, e su quei dati le due accuratezze divergono.
- **Il sistema.** Il sorgente di REPO-E. **Una persona.** Se la deviazione è voluta: allora si
  dichiara nel docstring come «confine dichiarato», come fa già il rating.
- **Oggi.** Invariato; l'etichetta dell'output ora elenca tutti gli addendi (Q22c).

## 8. Bilancio per BU: c'è un elenco chiuso delle BU, e il segno va per riga o per conto?
- **Perché conta.** Il docstring di `tools/bilancio_bu.py` promette «BU fuori dall'elenco →
  NOBU», ma l'elenco non esiste: un refuso diventa una BU nuova col suo margine. Promette
  «+ indiretti», che il codice non calcola. Dichiara la colonna `conto`, mai letta: il segno si
  decide riga per riga, e lo storno di un costo diventa «ricavo».
- **Il sistema.** `Analisi.js` di REPO-E dice se il segno per riga è suo.
- **Una persona.** L'elenco delle BU (il giro ha trovato ARRG, BIOC, EDIL, IMB in una skill
  esterna al repo: da confermare).
- **Oggi.** Invariato.

## 9. Indici di crisi: da dove vengono le soglie, e cosa vale un denominatore zero?
- **Perché conta.** Il docstring di `tools/indici_crisi.py` dice due cose diverse sulla fonte
  delle soglie (CNDCEC pubbliche, oppure codice di REPO-E). Con aggregati tutti a zero escono tre
  allarmi rossi e il verdetto «nessuna presunzione di crisi», senza avviso. Anche «Debiti
  totali = passivo totale» è ambiguo: il passivo totale include il patrimonio netto.
- **Il sistema.** Il sorgente dice quale aggregato è `passivoTot` e da dove vengono le soglie.
- **Una persona.** Se un indice con denominatore zero deve rendere «NON VALUTABILE» l'intera
  presunzione (è la «nota nel risultato» che il docstring promette e che main non stampa).
- **Oggi.** Invariato.

## 10. Leasing: l'adeguamento si aggiunge a ogni data o solo al mese del trimestre?
- **Perché conta.** La regola 4 del docstring di `tools/leasing_amministrativo.py` dice che
  l'adeguamento arriva «con il canone» del trimestre successivo; il codice lo aggiunge per OGNI
  data di riferimento (novembre: canone 1000 + 2,38). E con `usa_stima_30` l'output stampa ancora
  «tasso 2,5% STIMATO» accanto a una quota che non viene da quel tasso.
- **Il sistema.** Il sorgente dice in che mesi si chiama il calcolo trimestrale.
- **Una persona.** Nessuna, se il sorgente è chiaro.
- **Oggi.** Invariato.

## Risposte di Luca (2026-09-26)

Poste una alla volta in chat, ognuna con le sue opzioni. Corrispondenza con le domande di questo file: 1-7 sono le
domande 1-7; 8 e 9 sono le due meta' della domanda 8 (l'elenco delle BU, il segno per riga o per conto); 10 e' la 9;
11 e' la 10. Le 12-15 sono le altre righe di dominio di `DEBITI.md`: il formato dei numeri (D-R3-2), il leasing oltre
la scadenza (D-R3-3), gli spazi nei percorsi del Mac (S3 R2), i nomi del tenant in `docs/bc/` (V1 R1). Da applicare.

- **1.** scadenzario: maiuscole indifferenti, tipi sconosciuti rifiutati e segnalati
- **2.** DSO abbinamento: solo fatture dello stesso cliente (il confronto per contenuto resta)
- **3.** DSO arrotondamento: al pari, come oggi (nessuna modifica)
- **4.** DSO importo vuoto: vale zero, come oggi (nessuna modifica; scelta di Luca contro il default «assente non e' zero»)
- **5.** margine BU: arrg e ARRG sono la stessa BU (confronto senza maiuscole)
- **6.** cespiti fondo positivo: si converte il segno e un'ATTENZIONE dice quante righe
- **7.** accuratezza ordini <=0: resta errore reale, dichiarato come deviazione voluta da REPO-E
- **8.** bilancio BU: elenco chiuso ARRG, BIOC, EDIL, IMB; il resto va in NOBU, segnalato
- **9.** bilancio BU segno: per riga, come oggi (nessuna modifica)
- **10.** indici crisi un denominatore nullo: nota e verdetto, come oggi (nessuna modifica)
- **11.** leasing adeguamento: a ogni data, come fa il codice; si corregge la documentazione (regola 4)
- **12.** numeri CSV: formato italiano (1.234,56), una funzione di lettura sola li converte per tutti gli oracoli
- **13.** leasing oltre la fine: importo 0 con una NOTA «contratto concluso il ...», il calcolo prosegue
- **14.** percorsi Mac: si', ci sono spazi — un banco che installa e fa girare da un percorso con lo spazio entra nella suite
- **15.** docs/bc/: nomi pubblicabili, esente anche nel controllo notturno (una regola sola)
