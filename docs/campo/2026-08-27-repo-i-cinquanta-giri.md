CONTROLLI TRIMESTRALI BILANCIO · GIRO DI REVISIONE INDIPENDENTE
Cinquanta Giri
Non un giro a caccia di bug: un giro a caccia di quello che manca. 50 letture
indipendenti — 10 aree del progetto × 5 lenti nuove, mai usate nel giro precedente
— per rispondere a una domanda sola: cosa renderebbe questo software più
completo, più efficace, più facile, più parlante.
Aree lette 10
Lenti 5
Agenti indipendenti 50
Codice toccato nessuno — solo analisi
Come leggere questo documento. Ogni scheda segue lo stesso formato: Oggi (cosa succede o
non succede ora), Manca (il buco specifico), Proposta (una mossa concreta, non un principio
generico). Nessuna di queste proposte ripete idee già implementate nei due giri precedenti (19
correzioni + 44 idee, PR #97 e #98) — ogni agente aveva l'elenco di cosa esiste già e l'istruzione
esplicita di non riproporlo.
Temi trasversali
Conto Economico
Clienti
Fornitori
Mastrini Fornitori
Banche
Cespiti
Ferie
TFR
Crisi d'impresa
Cruscotto e Registro
Temi trasversali
Pattern comparsi in modo indipendente in tre o più aree — nessun agente sapeva cosa avrebbero trovato
gli altri 49.
1. Segnalato una volta, mai richiuso
Solo i Mastrini Fornitori hanno tre colonne di lavorazione (Stato/Responsabile/Note) che
sopravvivono da un'esecuzione all'altra sulla stessa entità. TFR (dipendenti che non quadrano),
Cespiti (categorie in scostamento), Clienti (risposte di circolarizzazione), Ferie (dipendenti con
costo orario incoerente) non hanno nulla di equivalente: ogni mese si riparte da zero nel
giudicare se un caso è nuovo o già preso in carico.
TFR
Cespiti
Clienti
Ferie
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
1/29
2. Funzioni già scritte, senza porta d'ingresso
archiviaRispostaCircolarizzazione, archiviaRispostaCartolarizzazione,
scaricaContiPerMappatura, mappaStatoPatrimoniale — esistono, spesso testate, ma
nessun menu o cruscotto le richiama: raggiungibili solo da chi apre l'editor Apps Script. Sono
funzionalità finite a metà, non buchi di codice.
Clienti
Fornitori
Crisi d'impresa
3. Il verde che nasconde un dato mai arrivato
Clienti e Fornitori verificano che i dataset BC non siano vuoti prima di dare un esito (altrimenti un
endpoint rotto darebbe un falso 🟢). Il Conto Economico non ha questa guardia. Gli Indici di crisi
non verificano che ogni conto Assets/Liabilities finisca in qualche aggregato: un conto nuovo o
rinumerato sparirebbe in silenzio da un totale, non genererebbe un errore.
Conto Economico
Crisi d'impresa
4. Soglie e mappature senza una casa comune
Le soglie CNDCEC hanno già un default guardato in CONFIG con nota "validato dal revisore". Le
soglie del Conto Economico no. La mappatura conti→banca e conti→aggregato-crisi restano
hardcoded nel codice: lo stesso pattern che ha già risolto la governance delle soglie di crisi non
è stato esteso a queste due mappature, pur condividendo lo stesso rischio (BC rinumera un
conto, nessuno se ne accorge).
Conto Economico
Banche
Crisi d'impresa
5. Un modulo copre un rischio che il suo gemello non copre
Concentrazione clienti esiste, concentrazione fornitori no. Tempificazione pagamenti (Fornitori,
check06) esiste, tempificazione incassi (Clienti) no. Dashboard storica per entità e foglio "Prove"
di attendibilità: il TFR li ha, Ferie/Banche/Mastrini Fornitori solo in parte o per niente. Ogni volta
la domanda "perché il gemello non ce l'ha" non ha una risposta scritta da nessuna parte.
Clienti
Fornitori
Ferie
TFR
Banche
6. Il registro audit parla dialetti diversi da modulo a modulo
Lo stesso processo si chiama "Cartolarizzazione" lato fornitori e "Circolarizzazione" lato clienti.
"Fornitori"/"Mastrini fornitori" e "Fondo TFR"/"Fondi TFR-TFM" restano due moduli distinti nel
registro, tenuti insieme solo da una mappa scritta a mano nel frontend del cruscotto. Il campo
nCasi significa "anomalie", "flag 0/1" o "dimensione del perimetro" a seconda del modulo; la
colonna "Totale (€)" ospita giorni, percentuali o soglie oltre agli euro.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
2/29
Cruscotto
Fornitori
TFR
Crisi d'impresa
Cespiti
7. Il codice tecnico non diventa mai una frase
FUORI_PERIODO, STORNATO_BC, NUMERO_DIVERSO mostrati grezzi invece della frase già
scritta altrove nello stesso modulo; HIGH/MEDIUM/LOW in inglese in mezzo a un report italiano;
CNDCEC/CCII/ISA mai sciolte; numeri di conto senza il nome accanto. Capita, in forme diverse,
in almeno sei delle dieci aree lette.
Mastrini Fornitori
Clienti
Crisi d'impresa
CE
Ferie
TFR
Cruscotto
8. L'ultimo miglio resta sempre un copia-incolla umano
Ferie, TFR e Mastrini Fornitori arrivano tutti a una scrittura contabile pronta, nel formato esatto
del giornale BC — e lì si fermano. Nessuno dei tre la fa arrivare in BC da solo; il gesto finale, per
policy dichiarata, resta umano.
Ferie
TFR
Mastrini Fornitori
9. Nessun test di cut-off o di evento successivo
Il Conto Economico non testa mai se una fattura a cavallo di trimestre è imputata al periodo
giusto. Clienti non verifica se un credito scaduto è stato incassato dopo la data di riferimento. Gli
Indici di crisi ignorano eventi successivi alla chiusura. Il TFR non riscontra che una liquidazione
"a zero" corrisponda a un pagamento reale in banca. Sono varianti dello stesso identico test di
revisione, mai applicato in nessuna delle quattro aree.
CE
Clienti
Crisi d'impresa
TFR
10. Le soglie di legge oltre quelle già coperte restano fuori
Perdita del capitale sociale (artt. 2446/2447 c.c.), test DSCR a 6 mesi, soglie di segnalazione dei
creditori pubblici qualificati (art. 25-novies CCII) per la crisi d'impresa; fido/limite di credito,
stesso soggetto cliente-e-fornitore, fornitore bloccato con saldo ancora aperto per
Clienti/Fornitori. Rischi classici di revisione, non ancora tradotti in un controllo automatico.
Crisi d'impresa
Clienti
Fornitori
11. Decisioni umane prese una volta, scritte solo nella memoria di sessione
La mappatura ferie "approssimativa ma accettata da Luca il 27/07/2026", l'attribuzione dei conti
nominativi TFR caso per caso, le banche con scostamento "noto e già capito" — tutte vivono solo
in SAL.md (il diario narrativo della sessione), non in un punto che il sistema stesso mostra a chi
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
3/29
subentra domani senza aver letto mille righe di changelog.
Ferie
TFR
Banche
12. Nessuna segregazione dei ruoli né chiusura formale del ciclo
Chiunque acceda al cruscotto può segnare qualunque caso "Risolto", e lo può fare chi lo ha
anche eseguito. Stato/Responsabile/Note vengono sovrascritti in place invece che accodati, in
un registro dichiarato append-only per tutto il resto. Non esiste un gesto esplicito e datato
"questo trimestre è chiuso", né una prova che l'evidenza citata nel registro sia rimasta quella
originale.
Cruscotto
Conto Economico
10 proposte
Buco nel processo
Cut-off di competenza a cavallo di trimestre
Oggi: i controlli lavorano solo su saldi aggregati per conto/voce, mai sulle singole registrazioni.
Manca: il test di cut-off che un revisore fa sempre a chiusura — fatture/DDT a cavallo della data imputate
al periodo sbagliato.
Proposta: CE-11 che legge i movimenti di dettaglio nella finestra ±N giorni intorno alla chiusura e segnala
le registrazioni sopra soglia con data documento vicina al confine.
Confronto vs budget/preventivo approvato
Oggi: ogni controllo confronta solo lo stesso trimestre di anno-1 e anno-2, mai un piano interno.
Manca: il confronto consuntivo-vs-budget che un revisore fa sempre, non solo lo storico.
Proposta: foglio CONFIG col budget trimestrale per voce CE e un CE-12 che calcola lo scostamento vs
budget.
Riconciliazione ammortamenti CE ↔ piano cespiti
Oggi: CE-05 guarda solo l'incidenza % su ricavi; il modulo Cespiti calcola la sua quadratura
separatamente — i due non si parlano mai.
Manca: verifica che la quota di ammortamento registrata in CE coincida con quella del piano cespiti.
Proposta: confrontare il totale ammortamenti del report Cespiti già prodotto con B.10a+B.10b del
trimestre CE.
Congruità del carico fiscale (voce 22)
Oggi: le imposte sul reddito sono un costo qualunque nessun controllo dedicato
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
4/29
Oggi: le imposte sul reddito sono un costo qualunque, nessun controllo dedicato.
Manca: verifica di plausibilità dell'aliquota fiscale effettiva rispetto alle aliquote attese.
Proposta: CE-13 che calcola l'aliquota effettiva del trimestre e segnala uno scostamento oltre soglia.
Quadratura incrociata CE ↔ Clienti/Fornitori
Oggi: CE, Clienti e Fornitori girano come sili indipendenti sugli stessi dati BC, senza mai confrontare i
totali fra loro.
Manca: verifica che i ricavi di vendita CE coincidano col fatturato di Clienti, e i costi con i mastrini fornitori
riconciliati.
Proposta: controllo di quadratura fra i due totali dello stesso trimestre, eseguito dopo che entrambi i
moduli hanno prodotto il proprio report.
Parlantezza
Trend ridotto a un simbolo senza etichetta
Oggi: il trend a 3 anni appare solo come "+-"/"≈" colorato; calcolaTrend() genera già una descrizione
leggibile che il report scarta.
Proposta: aggiungere il testo descrittivo (nota cella o colonna) e/o una legenda simboli in testa alla
sezione.
Conti fuori mappatura senza nome
Oggi: CE-01 elenca i conti fuori voce coi soli codici, mentre CE-07/CE-08 già usano "codice — nome".
Proposta: uniformare CE-01 allo stesso formato "codice — nome".
Doppia soglia compressa e ambigua
Oggi: la colonna Soglia mostra "15%/30%" senza dire quale è warning e quale error.
Proposta: scrivere "W 15% · E 30%".
Alert Strategici incoerenti fra loro
Oggi: due categorie di alert chiudono con un'azione suggerita, altre due si fermano al dato nudo.
Proposta: aggiungere la riga "Verificare…" anche a Concentrazione e Ricavi.
Sigle "pp" e "L.B." mai spiegate
Proposta: intestare per esteso "Linea Business" e scrivere almeno una volta "punti percentuali".
Fatica residua dopo il verde
Confronto col trimestre precedente assente
Oggi: ogni esecuzione crea un file isolato in Drive senza riferimento ai report passati.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
5/29
Proposta: recuperare dal registro audit l'URL dell'ultima esecuzione CE e linkarlo in header.
Chiusura silenziosa
Oggi: solo un toast/dialog visibile a chi ha lanciato lo script.
Proposta: email di chiusura con semaforo, risultato d'esercizio e link al report.
Sintesi discorsiva assente
Proposta: paragrafo di sintesi automatico in testa al foglio Analisi Business, pronto da incollare in
mail/verbale.
Nessun export condivisibile fuori Sheets
Proposta: PDF one-page del foglio Controlli generato automaticamente a fine esecuzione.
Risultato d'esercizio da ricopiare a mano
Proposta: scrivere risultato ed EBITDA anche in un foglio di sintesi condiviso fra moduli.
Continuità e sostituibilità
Mapping conti CE senza fonte di verità dichiarata
Proposta: sezione in PROJECT.md/SAL.md su come si aggiorna VOCI_CE, con data, fonte e responsabile.
Linee di business ricostruite invece di lette da BC
Oggi: BC marca già la BU sul campo Global_Dimension_1_Code, scartato subito; e
"Commercializzazione" manca dalle 4 linee elencate contro le 5 documentate.
Proposta: verificare con Luca se Commercializzazione va aggiunta, e documentare la scelta.
"Costi operativi" senza definizione scritta
Proposta: commento esplicito su cosa è dentro/fuori da calcolaTotaleCosti e perché.
Soglie CE senza tracciabilità di validazione
Oggi: le soglie Crisi hanno la nota "validato col revisore"; quelle CE no.
Proposta: stessa annotazione di provenienza per ogni soglia CE in CONFIG.
Soglie di alert "fuori sistema" in AnalisiCE.gs
Oggi: costanti come COSTO_AZZERATO_DELTA_MIN non passano da getSoglia(), uniche nel modulo
a non essere configurabili.
Proposta: spostarle in CONFIG come le altre, o documentare esplicitamente perché restano fisse.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
6/29
Coerenza fra aree gemelle
Dataset BC vuoto non distinto da "tutto a zero"
Oggi: Clienti/Fornitori hanno _verificaDatasetNonVuoto; il CE no — un endpoint rotto darebbe CE-
01 verde (0=0).
Proposta: stessa guardia di non-vuoto sui tre periodi scaricati da scaricaDatiCE.
Un controllo che lancia azzera gli altri nove
Oggi: Clienti/Fornitori isolano ogni controllo (eseguiControlliIsolati); il CE è un push sequenziale
tutto-o-niente.
Proposta: stesso pattern try/catch-per-controllo anche per CE-01..CE-10.
Tre palette di colori diverse per lo stesso semaforo
Proposta: unica palette di sistema condivisa (in Report.gs), riusata da CE/Cespiti/Clienti.
Nomi scheda senza icona di orientamento
Proposta: allineare i tab CE alla convenzione con icona già in uso altrove (es. "📊 Controlli").
Clienti
10 proposte
Buco nel processo
Riscontro delle risposte di circolarizzazione
Oggi: si registra solo l'evento RISPOSTA con nota libera.
Manca: confronto fra saldo confermato dal cliente e saldo contabile, classificazione delle discordanze.
Proposta: aggiungere all'evento RISPOSTA il saldo confermato e calcolare lo scostamento vs BC.
Sollecito per mancata risposta
Manca: nessun controllo guarda se la scadenza di risposta è passata senza evento RISPOSTA.
Proposta: tab/controllo che elenca i clienti oltre scadenza senza risposta.
Fondo svalutazione crediti
Oggi: l'aging dichiara di "supportare la valutazione dei crediti" ma non la calcola.
Proposta: confrontare il fondo svalutazione stanziato in BC con una stima per fascia di rischio sull'aging.
Verifica incassi successi i sui crediti scaduti
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
7/29
Verifica incassi successivi sui crediti scaduti
Manca: il classico subsequent event — chi ha già incassato dopo la data di riferimento.
Proposta: colonna "incassato dopo la data" in check01/aging.
Esposizione oltre il limite di fido
Proposta: confrontare il saldo aperto col limite di credito da anagrafica BC, segnalare chi lo supera.
Parlantezza
Intestazioni di dettaglio grezze
Oggi: colonne "TIPO ANOMALIA" e "SEVERITY" in inglese/codice (DA_APPROFONDIRE, HIGH) in mezzo a
un report italiano.
Proposta: tradurre severity in Alta/Media/Bassa e dare un'etichetta in chiaro.
Semaforo diverso fra Dashboard e Registro per lo stesso esito
Oggi: 2 anomalie sono "verde" in Dashboard ma "rosso" nel registro audit.
Proposta: allineare le soglie o spiegare che rispondono a domande diverse.
Soglie di severity invisibili nel report
Proposta: stampare il criterio usato (es. "HIGH: oltre 90 giorni o 1.000€") come nota sopra ogni tab.
Codici interni al posto di frasi in Circolarizzazione
Oggi: colonna "Metodo Invio" mostra LEGALMAIL_PEC/MANCANTE_CONTATTO grezzi; colonna Note
sempre vuota.
Proposta: tradurre in dicitura piana e usare Note per spiegare cosa manca.
Fasce di aging senza unità di misura
Proposta: rinominare le fasce con l'unità esplicita ("1-30 gg").
Fatica residua dopo il verde
Solleciti circolarizzazione mancanti
Oggi: l'archivio traccia scadenze come lato fornitori, ma senza il sollecito automatico che i fornitori già
hanno.
Proposta: replicare la stessa funzione+trigger già esistente lato fornitori.
Registrare una risposta richiede uscire dal prodotto
Proposta: voce di menu/dialog che chiama archiviaRispostaCircolarizzazione già scritta.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
8/29
Circolarizzazione invisibile dal Cruscotto
Proposta: aggiungerla come area della coda di lavoro, riusando
statoCircolarizzazioneClienti().
Ogni trimestre riparte da foglio bianco sulle anomalie
Proposta: foglio di lavorazione persistente con Stato/Nota per riga di anomalia, riportato per chiave da
un'esecuzione alla successiva.
Clienti ITALIA (PEC) fuori da ogni automazione
Proposta: generare un testo/bozza precompilato anche per loro, da usare come base per l'invio PEC
manuale.
Continuità e sostituibilità
PROJECT.md non copre il modulo Clienti
Oggi: operativo da due mesi con 13 controlli + circolarizzazione + aging + concentrazione, ma zero righe
in PROJECT.md.
Proposta: sezione "Clienti" sul modello di quella Fornitori.
Decisione aperta sepolta in un commento
Oggi: righe senza data che escono in silenzio dai 13 controlli, dichiarato "va deciso" solo nel codice.
Proposta: riportarla come voce esplicita nella sezione decisioni di SAL.md.
Archivi Drive ricreati in silenzio se non trovati per nome
Proposta: loggare/notificare quando un foglio storico viene ricreato da zero invece che trovato.
Soglie CONFIG senza motivazione accanto al valore
Proposta: commento accanto a ogni voce CONFIG che rimanda al motivo validato in
docs/VALIDAZIONE_CLIENTI.md.
Nessun modo per chi non programma di registrare una risposta
Proposta: voce di menu/dialogo analoga a quella già presente per le bozze.
Coerenza fra aree gemelle
Controllo "tempificazione" asimmetrico
Oggi: Fornitori ha check06 Pagamenti Anticipati/Ritardati; Clienti non ha l'equivalente Incassi
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
9/29
Oggi: Fornitori ha check06 Pagamenti Anticipati/Ritardati; Clienti non ha l equivalente Incassi.
Proposta: aggiungere check06 Incassi Anticipati/Ritardati o documentare l'assenza come scelta.
Titolo dashboard con anno hardcoded solo lato Fornitori
Proposta: allineare togliendo l'anno fisso dal titolo Fornitori.
Nome funzione disallineato dal nome visualizzato
Oggi: check02_ValoriNegativi (Fornitori) restituisce "Crediti verso Fornitori"; il gemello Clienti ha
nomi coerenti.
Proposta: rinominare seguendo la convenzione già adottata dal gemello.
Esclusione "saldo zero" applicata a un solo gemello
Oggi: check14_DoppiIncassi esclude saldo≈zero; check14_DoppiPagamenti no.
Proposta: stessa esclusione su entrambi, o motivare la differenza.
Delega a un rappresentante solo lato Fornitori
Proposta: verificare se serve un meccanismo analogo per clienti seguiti da agente/broker.
Fornitori
10 proposte
Buco nel processo
Test di completezza al di là della chiusura
Manca: per i fornitori senza mastrino, nessun test verifica cosa arriva registrato dopo la chiusura con data
documento nel trimestre appena chiuso.
Proposta: controllo che interroga Posted_Purchase_Invoice per Document_Date≤chiusura e
Posting_Date>chiusura, su tutti i fornitori.
Copertura reale della circolarizzazione
Manca: nessun numero riassume quanto del debito totale è stato davvero confermato.
Proposta: indicatore di copertura del campione (saldo con mastrino/risposta ricevuta su totale debiti).
Fornitori bloccati con saldo aperto
Oggi: il campo Blocked è documentato ma non usato in nessun controllo.
Proposta: incrociare fornitori bloccati con partite aperte residue.
Concentrazione/dipendenza fornitori
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
10/29
/
p
Manca: la concentrazione esiste solo lato Clienti.
Proposta: report di concentrazione fornitori per saldo debito e volume acquisti, sul modello clienti.
Soggetti sia cliente sia fornitore
Proposta: incrociare anagrafiche per P.IVA/CF uguale e segnalare saldi aperti su entrambe le posizioni.
Parlantezza
Nome controllo senza criterio in dashboard
Proposta: affiancare al nome controllo la soglia effettiva (es. "inattivo da >12 mesi").
Legenda "LEGALMAIL" promette un invio che il sistema non fa
Proposta: riformulare in "Da inviare manualmente via Legalmail — nessuna bozza generata".
"Richiesta il"/"Risposta il" senza stato
Proposta: colonna "Stato risposta" calcolata (In attesa/Scaduta/Risposto).
Il registro fonde due motivi di scarto diversi
Oggi: "fuori canale o senza contatto" somma il previsto (PEC) col da-correggere (nessun contatto).
Proposta: due esiti separati nel registro.
La lettera dichiara un totale senza il dettaglio
Proposta: includere in lettera l'elenco partite aperte, non solo il totale.
Fatica residua dopo il verde
Bozze PEC Italia assenti
Oggi: le bozze coprono solo GMAIL; i fornitori ITALIA restano righe nude nel report.
Proposta: generare comunque bozze Gmail da spostare poi su Legalmail a mano.
Nessun punto d'ingresso per registrare le risposte
Proposta: menu che elenca i fornitori in attesa e permette di spuntarli.
Nessun sollecito per chi supera la scadenza
Proposta: riga extra nel Dashboard coi fornitori scaduti senza risposta.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
11/29
MANCANTE_CONTATTO si ripete identico ogni trimestre
Proposta: archivio "contatti integrati a mano" letto prima di marcare mancante.
Check03 non spiega mai lo scarto
Proposta: applicare a check03 la stessa euristica già validata sui mastrini (partite/storni che spiegano lo
scarto).
Continuità e sostituibilità
Buco nella numerazione dei controlli (7, 12, 15, 17, 18)
Proposta: commento che elenchi gli ID mancanti e il motivo.
archiviaRispostaCartolarizzazione mai richiamata
Proposta: voce di menu, o documentare esplicitamente che resta manuale da editor.
Flusso PEC Italia senza runbook scritto
Proposta: descrivere in PROJECT.md i passi concreti (chi, dove, quale account).
Soglie sparse nel codice senza motivazione
Proposta: portarle tutte in CONFIG con una riga di motivazione ciascuna in PROJECT.md.
Cartella report cercata per nome, non per Script Property
Proposta: allinearla al pattern Script Property + PROJECT.md già in uso altrove.
Coerenza fra aree gemelle
"Cartolarizzazione" vs "Circolarizzazione"
Oggi: stesso identico processo (conferma saldo, ISA 505), due nomi diversi fra i moduli gemelli —
"cartolarizzazione" è pure tecnicamente scorretto.
Proposta: rinominare verso "Circolarizzazione Fornitori".
Guardia dataset vuoto assente lato Fornitori
Proposta: stessa verifica di Clienti sui fetch di VendorChecks.
Cache di modulo assente lato Fornitori
Oggi: Clienti scarica una volta e riusa; Fornitori rifà una query per ciascuno dei 14 controlli.
Proposta: stessa architettura di cache del lato clienti.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
12/29
p
Tab "Concentrazione" mancante lato Fornitori
Proposta: riusare la stessa funzione generica già scritta per i clienti.
Fix "codice testo" non propagato al gemello Clienti
Oggi: il fix che impedisce a "0001627" di diventare 1627 esiste solo lato Fornitori.
Proposta: stesso setNumberFormat('@') in Circolarizzazione Clienti.
Mastrini Fornitori
10 proposte
Buco nel processo
Stato "Risolto" mai riverificato
Manca: un caso marcato Risolto che ricompare identico alla riconciliazione successiva resta chiuso in
silenzio.
Proposta: riaprire automaticamente se un documento "Risolto" ricompare con lo stesso esito non-
quadra.
Fornitori senza parser invisibili ai solleciti
Proposta: evento "MASTRINO (manuale)" registrabile da menu per chi ha controllato fuori sistema.
Bozza creata non è richiesta inviata
Manca: la scadenza di risposta parte alla preparazione della bozza, non all'invio reale.
Proposta: verificare via Gmail se la bozza è stata inviata e far partire la scadenza da lì.
Nessun riscontro fra "Data al" e documento ricevuto
Proposta: confrontare la data dichiarata nel documento col parametro usato, segnalare (non bloccare) lo
scarto.
Dalla differenza rilevata alla scrittura non c'è ponte
Proposta: foglio/sezione "Da registrare" che isola i casi con azione contabile concreta, come
TfrScrittura.gs.
Parlantezza
Riga di sintesi con zeri a raffica
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
13/29
Proposta: filtrare le categorie a zero, come già fa il registro audit.
"Pagamenti fuori abbinamento" senza verdetto
Proposta: dare un giudizio colorato anche a questa riga.
Sollecito senza l'indirizzo a cui scrivere
Proposta: portare destinatario e lingua nello stato calcolato dei solleciti.
Il registro fonde due motivi di scarto molto diversi
Proposta: esiti separati per "fuori canale PEC" e "senza contatto".
Codice grezzo al posto della frase
Oggi: "SOLO_FORNITORE"/"NUMERO_DIVERSO" mostrati grezzi; la frase già scritta altrove
(_categorieMastrino) non viene riusata.
Proposta: mostrare la frase, tenendo il codice come tooltip.
Fatica residua dopo il verde
Dall'email alla riconciliazione, senza il giro a mano
Proposta: script che precompila (non lancia da sé) la riconciliazione trovando l'allegato dai thread già
tracciati.
I 27+ fornitori senza parser restano ciechi
Proposta: estrazione generica (data+importo+numero) senza layout dedicato, l'umano fa solo
l'abbinamento finale.
Gli effetti in viaggio non si ripresentano da soli
Proposta: ricontrollo automatico alla scadenza dichiarata dell'effetto.
Il follow-up resta un click a riga
Proposta: azione "applica a tutte le righe di questo esito".
La verifica "è il parser giusto?" vive fuori dal cruscotto
Proposta: pulsante "anteprima" nella schermata di upload del cruscotto.
Continuità e sostituibilità
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
14/29
Indice unico fornitori→parser assente
Proposta: tabella di riepilogo (fornitore·file·formato·codice BC·quirk) in testa al parser dispatcher.
Schema del descrittore non verificato
Proposta: whitelist delle chiavi ammesse in descrittoreMastrino.
Collisione di nomi fra parser non intercettata
Proposta: in tests/run.js, far fallire se un nome funzione top-level ricompare fra file.
Nessun campione reale conservato accanto al parser
Proposta: fixture anonimizzate reali per ciascuno dei 14 formati.
Test del parser non individuabile dal file del parser
Proposta: commento incrociato parser↔test.
Coerenza fra aree gemelle
Manca controprova indipendente sul saldo BC
Oggi: TFR/Banche/Ferie confermano il saldo con una seconda fonte BC; i mastrini fornitori no.
Proposta: leggere il saldo fornitore dichiarato da BC e segnalare uno scarto vs somma movimenti.
Manca un foglio "Prove"
Proposta: dichiarare esplicitamente copertura periodo ed esito ricerca incrociata, come il TFR.
Report a un solo foglio contro cinque del TFR
Proposta: foglio "Da correggere" separato dal dettaglio completo.
Manca il carry-forward lato TFR (all'inverso)
Proposta: estendere lo storico TFR con le stesse colonne di follow-up già presenti sui mastrini fornitori.
Manca la diagnostica campi sull'endpoint fornitori
Oggi: il TFR ha uno strumento dedicato per verificare i campi esposti; i mastrini fornitori no, pur
dipendendo da campi non garantiti.
Proposta: generalizzare lo strumento TFR per accettare endpoint/filtro come parametri.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
15/29
Banche
10 proposte
Buco nel processo
Riconciliazione a saldo, non per partite
Manca: quando è rosso, nessun elenco delle partite che spiegano lo scarto.
Proposta: affiancare un elenco dei movimenti BC/reale non ancora abbinati nell'intorno della data.
Conti G/L nuovi/non mappati sfuggono al controllo
Proposta: confrontare i conti letti in BC con le chiavi di mappatura e segnalare quelli non coperti.
Cassa esclusa dal modulo "Banche e Cassa"
Oggi: PROJECT.md nomina "Banche e Cassa" ma il codice copre solo i c/c.
Proposta: verificare con Luca se serve estendere a un conto cassa.
Riconciliazione bancaria nativa di BC non verificata
Proposta: chiedere a Luca se un modulo BC nativo è già in uso, prima di considerarsi l'unico presidio.
Nessun aging delle partite nel conto transitorio
Proposta: controllo di aging sul mastrino dei conti transitori, partite aperte oltre N giorni.
Parlantezza
Alert del menu tace le banche non verificabili
Proposta: aggiungere anche nonVerificate al testo dell'alert.
La guida operativa vive solo nel registro, non nel report
Proposta: scrivere lo stesso testo di _esitoBanca anche come nota sul foglio di riconciliazione.
Lo scarto non dice su quale base è calcolato
Proposta: precisare "(su base c/c)" o "(su base c/c+transitorio)".
Date disallineate senza spiegazione
Proposta: nota in intestazione sul criterio "a pari data".
Il segno dello scostamento non è mai spiegato
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
16/29
g
p
g
Proposta: nota "scostamento = Reale − BC (negativo = BC più alto)".
Fatica residua dopo il verde
Import automatico dei saldi reali
Oggi: digitazione manuale nel foglio SALDI_BANCA (già causa di due incidenti).
Proposta: importare i tracciati elettronici (CBI/CAMT.053/MT940) direttamente in storico.
Partite in transito estratte, non cercate a occhio
Proposta: interrogare i movimenti su c/c e transitorio nell'intorno della data e mostrare le righe
candidate.
Distinguere l'arretrato noto dal nuovo scostamento
Proposta: calcolare la variazione rispetto all'ultima esecuzione, evidenziare solo chi è cambiato.
Età del saldo reale non visibile nella riga
Proposta: aggiungere i giorni di ritardo del saldo reale usato accanto all'esito.
Mappatura conti banca fuori dal codice
Proposta: spostarla su un foglio dedicato, letto a runtime, come già fatto per RAPPRESENTANTI fornitori.
Continuità e sostituibilità
Mappatura conti↔banche solo nel codice
Proposta: pubblicarla anche come tabella con nota su chi la conferma e quando ricontrollarla.
Soglia "sospetto" mai chiusa
Proposta: far confermare a Luca il valore 10.000€ e registrarlo come decisione datata.
Rossi "noti" indistinguibili da rossi nuovi
Proposta: registro vivo per banca (causa, da quando, ultima conferma) richiamato nell'esito.
Guida "cosa fare" assente nel report standalone
Proposta: scrivere la stessa nota diagnostica anche nel foglio di report, non solo nel registro.
Processo a monte (Lavinia) non documentato
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
17/29
Proposta: documentare in PROJECT.md il processo di aggiornamento SALDI_BANCA e un contatto di
riserva.
Coerenza fra aree gemelle
Foglio "Mastrino" assente in Banche
Oggi: Ferie/TFR mostrano i movimenti che compongono il saldo; Banche mostra solo i saldi aggregati.
Proposta: aggiungere un foglio "Mastrino" coi movimenti del periodo sui conti c/c e transitorio.
Testo esplicativo solo nel registro, non nel report aperto
Proposta: scrivere anche nel foglio banche il testo già calcolato per il registro.
Nessun link al documento/riga sorgente del saldo reale
Proposta: riportare la data di registrazione dello snapshot usato.
Età/affidabilità del dato non visibile nel report
Oggi: il TFR ha un foglio "Prove" dedicato; Banche calcola il ritardo altrove ma non lo mostra qui.
Proposta: indicare per riga i giorni di scarto fra data controllo e data saldo reale.
Cespiti
10 proposte
Buco nel processo
Cessioni non riconciliate a conto economico
Proposta: leggere la colonna Cessioni e incrociarla con i conti di plus/minusvalenza a CE.
Completezza delle categorie fra un run e l'altro
Proposta: confrontare l'elenco categorie con quello del run precedente, segnalare categorie scomparse.
Congruità delle quote di ammortamento
Proposta: calcolare la quota implicita per categoria e segnalarla se anomala vs media storica.
Nessun aggancio ad acquisti/fatture del periodo
Proposta: incrociare la variazione di Costo Lordo con le fatture capitalizzate dal mastro fornitori.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
18/29
Assenza di verifica di esistenza fisica
Proposta: almeno una voce "inventario fisico eseguito: sì/no" per le categorie sopra materialità.
Parlantezza
Colonna "Totale (€)" del registro riusata per giorni
Oggi: la freschezza scrive totale: giorni nella colonna intestata "Totale (€)".
Proposta: non confondere un conteggio giorni con un importo nella stessa colonna.
Esito riga non dice quale differenza ha sforato
Proposta: includere nel testo quale campo (VN/Costo/Fondo) ha sforato.
Alert del menu non porta al report appena creato
Proposta: aggiungere l'URL già disponibile all'alert.
Intestazioni "Diff." senza verso esplicito
Proposta: chiarire "Diff. VN (Cespiti − Bilancio)".
"Classe"/"Descrizione" vuote senza spiegazione
Proposta: placeholder esplicito "(non indicata nel report)".
Fatica residua dopo il verde
Nessun innesco automatico dopo l'aggiornamento esterno
Proposta: trigger che confronta la data dell'ultimo file con l'ultima riga registrata e lancia da sé il
controllo.
Scostamenti reali senza notifica proattiva
Oggi: solo la freschezza chiama notificaProblemi; uno scostamento vero resta silenzioso.
Proposta: estendere la notifica anche agli scostamenti.
Nessun aggancio al dettaglio analitico che spiega lo scostamento
Proposta: allegare, se disponibile, solo le righe di dettaglio relative alle categorie in scostamento.
Compensazioni fra classi non segnalate come tali
Proposta: nota automatica quando la somma di due scostamenti è vicina a zero ("possibile riclassifica").
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
19/29
Link al report sorgente non cliccabile
Proposta: sostituire il nome file con un HYPERLINK al file esterno.
Continuità e sostituibilità
Nessun test automatico per il modulo
Proposta: fixture del tab Quadratura (colonne rinominate, celle non numeriche) e test sulle funzioni pure.
Localizzazione e responsabile dello script esterno non documentati
Proposta: sezione in docs/CESPITI.md con link al progetto sorgente e responsabile.
Contratto d'interfaccia sul tab non condiviso con l'esterno
Proposta: tabella delle intestazioni attese, condivisa anche a chi mantiene lo script esterno.
Glossario dei codici Categoria/Classe assente
Proposta: tabella dei codici incontrati in docs/CESPITI.md, aggiornata ad ogni novità.
Titolarità della cartella Drive sorgente non documentata
Proposta: annotare chi possiede/condivide la cartella, non un account personale.
Coerenza fra aree gemelle
Soglia di materialità a due livelli assente
Oggi: Banche distingue lo scarto "sospetto"; Cespiti resta solo binario 🔴/🟢.
Proposta: introdurre una soglia analoga per gli scostamenti materiali.
Valori assoluti Costo Lordo/Fondo assenti dal report
Proposta: riportare anche i valori assoluti, non solo le differenze.
Creazione del file non passa dall'helper condiviso
Proposta: usare creaReportInCartella come già fanno gli altri moduli.
eseguiModulo non avvolge la riconciliazione Banche
Proposta: avvolgerla come già fatto per Cespiti, stessa rete di sicurezza per entrambi.
Granularità degli esiti "non confrontabile"
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
20/29
Granularità degli esiti non confrontabile
Oggi: Banche distingue quattro esiti; Cespiti solo un binario.
Proposta: valutare uno stato "non confrontabile" per singola categoria.
Ferie
10 proposte
Buco nel processo
Nessuna riconciliazione per dipendente, solo per totale
Manca: un errore che sovrastima un dipendente e sottostima un altro si annulla nel totale — rischio che il
TFR copre e Ferie no.
Proposta: segnalarlo esplicitamente come limite dichiarato del controllo.
Turnover dei dipendenti fra un mese e l'altro non tracciato
Proposta: confrontare l'elenco codici/nomi del mese con quello precedente, segnalare chi è
uscito/entrato.
Ore residue individuali mai valutate in assoluto
Proposta: soglia di ore residue oltre la quale segnalare il dipendente (solo evidenza, non blocco).
Variazione del mese non confrontata con lo storico
Proposta: mostrare accanto al delta del mese il delta medio degli ultimi mesi, segnalare scarti anomali.
Nessun incrocio anagrafico con il TFR sullo stesso mese
Proposta: confrontare i due elenchi dipendenti dello stesso mese e segnalare solo le differenze.
Parlantezza
Conti senza nome nel Riepilogo e nella Scrittura
Proposta: riportare il nome conto accanto al codice ovunque.
Differenza sotto soglia senza etichetta
Proposta: scrivere "sotto soglia (non scritto)" invece di "nessuno".
Nota di incoerenza senza i numeri che la giustificano
Proposta: includere i tassi calcolati per voce nella nota.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
21/29
Tooltip cruscotto senza soggetto
Proposta: "2 dipendenti con costo orario incoerente", non solo "2".
Il segno degli importi "utilizzo" non è mai spiegato
Proposta: aggiungere la frase (già nel commento sorgente) sul perché il fondo scende.
Fatica residua dopo il verde
PDF in automatico dalla mail del consulente
Proposta: script che cerca in Gmail i due allegati attesi e lancia il controllo da sé.
Scrittura in bozza via API BC invece del copia-incolla
Proposta: creare la riga di giornale in bozza via OData, lasciando solo il click di registrazione finale.
Diagnosi automatica della voce discordante
Proposta: mostrare il costo orario per voce, non solo il segnale ⚠️.
Sentinella per il mese saltato
Proposta: Routine mensile che avvisa se manca la riga del mese in FONDO_FERIE.
Verifica che la scrittura proposta sia stata poi ribattuta
Proposta: confrontare il movimento reale del mese successivo con la scrittura proposta il mese prima.
Continuità e sostituibilità
Chiusura del ciclo proposta→registrazione non tracciata
Proposta: campo "Registrata in BC" (sì/no, data) nell'archivio mensile.
La mappatura conti è una scelta di Luca non scritta come tale
Proposta: riga esplicita in PROJECT.md su chi può rivederla e quando.
"INAIL fuori scrittura" sospeso senza destinatario né scadenza
Proposta: indicare nella nota a chi va chiesta la decisione.
Voci F01/F02/F03 senza glossario né controllo su voci nuove
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
22/29
g
Proposta: documentare la corrispondenza e avvisare se il prospetto porta voci diverse dalle tre attese.
Riconoscimento PDF dipende da un'intestazione non garantita
Proposta: riga operativa in PROJECT.md sulla causa più probabile se il riconoscimento smette di
funzionare.
Coerenza fra aree gemelle
Diario storico per dipendente e dashboard recidivi assenti
Oggi: il TFR li ha; Ferie calcola la stessa coerenza ma non la archivia mai per nominativo.
Proposta: diario append-only sullo stesso schema del TFR.
Tabella storica mensile e pannello cruscotto assenti per il TFR (all'inverso)
Proposta: tabella FONDO_TFR e stato per il cruscotto, sul modello di Ferie.
Verifica BC invisibile nel report Ferie
Oggi: il TFR mostra sempre un foglio "Prove"; Ferie verifica la doppia lettura BC solo in silenzio.
Proposta: una riga nel Riepilogo che riporta l'esito di quella conferma.
TFR
10 proposte
Buco nel processo
Fondo di Tesoreria INPS non tracciato
Proposta: estrarre la quota C/Tesoreria e confrontarla col conto BC del credito INPS.
Imposta sostitutiva 17% senza riconciliazione col versamento
Proposta: sommare l'imposta del periodo e verificarne il versamento contro il conto Erario dedicato.
Anticipazioni TFR non verificate contro i limiti di legge
Proposta: se isolabili, controllo di soglia sui limiti art. 2120 c.c. (max 70%, 8 anni).
Uscita di cassa della liquidazione non riscontrata
Proposta: per i dipendenti con fondo azzerato, incrociare l'importo con l'uscita banca/cassa dello stesso
periodo.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
23/29
Coerenza dell'organico con una fonte indipendente
Proposta: confrontare l'elenco dipendenti del prospetto con un'anagrafica HR indipendente, se
disponibile.
Parlantezza
Conti BC senza nome del fondo nel Riepilogo
Proposta: comporre l'etichetta come "5500005001 (Caselli)".
Il "non attribuito" del Mastrino non dice cosa fare
Proposta: aggiungere il suggerimento operativo, come nel resto del report.
Celle vuote nel foglio Dipendenti senza spiegazione
Proposta: "n.d. — vedi Esito" al posto della cella vuota.
Icone di esito diverse e non spiegate fra i due controlli TFR
Proposta: legenda in testa a ciascun foglio esito.
Il conteggio "nCasi" confonde informativo e anomalia
Proposta: contare separatamente 🔴/⚠️ e ℹ️.
Fatica residua dopo il verde
Conto nominativo previdenza senza memoria
Proposta: foglio di mappatura dipendente→conto nominativo, popolato una volta e riusato.
"Da decidere" rideciso ogni volta
Proposta: registrare la decisione presa e riapplicarla se la stessa firma si ripresenta identica.
Prospetto caricato a mano ogni mese
Proposta: trigger che intercetta l'allegato via Gmail e lo passa da solo alla pipeline.
Export mastrino secondo file, sempre a mano
Proposta: script schedulato che deposita l'export dove il cruscotto lo legge da solo.
S
i
i i
ll
i
BC
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
24/29
Scrittura sempre copiaincollata in BC
Proposta: valutare estensione dello scope OAuth per creare la riga di giornale, con conferma umana
prima dell'invio.
Continuità e sostituibilità
Whitelist conti nominativi non presidiata
Proposta: confrontare i conti nominativi in BC con l'elenco censito e segnalare i non censiti.
Stesso conto, due nomi diversi, nessun rimando
Proposta: commento incrociato fra le tre costanti che duplicano lo stesso conto.
Le decisioni caso per caso non restano nel sistema
Proposta: campo di annotazione persistente per dipendente ("chiuso: motivo, data").
Il conto condiviso resta un limite eterno
Proposta: annotare in PROJECT.md che esiste una soluzione strutturale (conto BC dedicato) da
sottoporre a chi gestisce il piano dei conti.
La logica di aggancio per nome vive solo nei commenti del sorgente
Proposta: riassumere in PROJECT.md le tre regole di aggancio con rimando al file di dettaglio.
Coerenza fra aree gemelle
Follow-up di lavorazione assente sul dipendente
Oggi: i Mastrini fornitori hanno Stato/Richiesta/Note persistenti; il TFR solo un diario di sola lettura.
Proposta: stesse tre colonne su STORICO_TFR_DIPENDENTI.
Nessun catalogo centralizzato degli stati dipendente
Proposta: tabella stato→frase→cosa fare, come _categorieMastrino.
Riga senza colore nel foglio Dipendenti
Proposta: setBackgrounds sulla colonna Esito, come i mastrini fornitori.
Nessuna riga di andamento nel corpo del report
Proposta: riga "Andamento" nel Riepilogo, come già fatto per i fornitori.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
25/29
Granularità del registro audit diversa senza motivo dichiarato
Proposta: valutare una voce per dipendente ricorrente, o documentare perché la granularità resta
aggregata.
Crisi d'impresa
10 proposte
Buco nel processo
Test DSCR a 6 mesi (art. 3 CCII)
Manca: il test prioritario previsto dalla norma, a cui i 5 indici settoriali sono solo sussidiari.
Proposta: input manuale del budget di cassa a 6 mesi e calcolo del DSCR, motivando il ricorso ai 5 indici
quando non disponibile.
Perdita del capitale sociale (artt. 2446/2447 c.c.)
Proposta: confronto fra patrimonio netto e capitale sociale nominale, trigger normativo autonomo.
Soglie art. 25-novies CCII (creditori pubblici qualificati)
Proposta: confrontare i debiti scaduti per tipologia con le soglie di legge Erario/INPS.
Fattori qualitativi ISA 570 non desumibili dal bilancio
Proposta: checklist qualitativa a compilazione manuale allegata al verdetto quantitativo.
Orizzonte prospettico ed eventi successivi
Proposta: sezione "eventi successivi e orizzonte prospettico" a compilazione manuale.
Parlantezza
Sigle mai sciolte (CNDCEC, CCII, ISA 570)
Proposta: nota che scioglie le sigle e spiega il ruolo del settore.
Indici mostrati come formula, non come concetto
Proposta: intestare col nome descrittivo CNDCEC, formula fra parentesi.
La regola "serve il rosso su tutti e 5" non ripetuta
Proposta: nota sotto la tabella indici che ripete la regola.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
26/29
Il verso della soglia non dice il senso del rischio
Proposta: "(rischio se alto)"/"(rischio se basso)" accanto al valore soglia.
Il verdetto non dice cosa comporta in pratica
Proposta: riga fissa con la conseguenza pratica minima sotto il verdetto rosso.
Fatica residua dopo il verde
Rilancio senza calendario
Proposta: aggiungere Indici crisi alla coda di lavoro del cruscotto con scadenza attesa.
Anno cablato nel codice
Proposta: derivare l'anno di default dalla data corrente.
Mappatura conti solo nel codice
Proposta: scheda CONFIG con fallback al default validato, stesso pattern delle soglie.
Verdetto senza indicazioni operative
Proposta: blocco fisso di "prossimi passi" agganciato all'esito.
Strumenti di mappatura isolati dal flusso
Proposta: esporre scaricaContiPerMappatura come voce di menu.
Continuità e sostituibilità
Copertura non verificata a runtime
Proposta: calcolare un "residuo non classificato" e segnalarlo oltre soglia.
Nessun trigger di revalidazione al cambio piano dei conti
Proposta: confrontare i conti dell'anno corrente con un elenco "conti noti" salvato alla validazione.
La regola per conti nuovi esiste solo come esempio
Proposta: enunciare il criterio generale di classificazione in docs/INDICI_CRISI.md.
Il foglio di mappatura è scollegato dal codice
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
27/29
Proposta: far leggere al calcolo la colonna "Voce" del foglio come mappatura effettiva.
I test coprono le soglie, non la mappatura conti reale
Proposta: test con un conto "orfano" che deve far fallire se resta fuori da ogni aggregato.
Coerenza fra aree gemelle
Copertura dei conti non verificata (vs CE-01)
Oggi: CE-01 segnala i conti fuori voce; Crisi aggrega per prefissi senza verifica di copertura.
Proposta: stesso controllo di copertura anche per gli aggregati crisi.
Nessun dettaglio per conto nel report
Proposta: foglio "Dettaglio conti" per ciascun aggregato, come il CE.
Nessun confronto anno su anno nello stesso report
Proposta: affiancare il valore dell'esercizio precedente per ogni indice.
Nessun feedback di avanzamento durante l'esecuzione
Proposta: stesse chiamate notifica() che il CE già fa ad ogni fase.
Cruscotto e Registro Audit
10 proposte
Buco nel processo
Segregazione fra chi esegue e chi chiude
Manca: il principio dei quattro occhi — nessuno impedisce che chi esegue sia anche chi chiude.
Proposta: registrare chi chiude accanto a chi esegue e segnalare/bloccare quando coincidono.
Le decisioni di follow-up non lasciano traccia
Oggi: Stato/Responsabile/Note sovrascrivono in place un registro dichiarato append-only.
Proposta: accodare ogni cambio come nuova riga di log, mostrando solo l'ultimo stato derivato.
Nessuna chiusura formale del ciclo trimestrale
Proposta: funzione "Chiudi trimestre" che verifica la copertura attesa e scrive un'attestazione datata.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
28/29
Azzeramento senza motivo né restrizione d'uso
Proposta: motivo testuale obbligatorio, azione riservata alla sola fase di build.
Evidenza citata dal registro non immutabile
Proposta: snapshot non modificabile a fine esecuzione e controllo periodico sui link rotti.
Parlantezza
Codici interni nell'esito dei documenti
Proposta: mappatura codice→frase solo lato pagina, senza toccare i dati.
Il numero "casi" è una cifra muta
Proposta: etichetta anche a riga chiusa, nota che il totale somma unità eterogenee.
Il semaforo grigio "Non determinato" sembra un quarto giudizio
Proposta: tooltip che chiarisce che è un fallimento di lettura, non un verdetto.
Sigle non spiegate in testata (ISA 230)
Proposta: tooltip di una riga sul significato pratico.
La gerarchia Area → Modulo → Controllo → Caso mai disegnata
Proposta: tooltip su "Aree" che rende esplicito il contenimento.
Fatica residua dopo il verde
Vidimazione anche dei controlli verdi
Proposta: flag "verificato" selezionabile anche sugli OK, contatore N/tot.
Nota obbligatoria per chiudere un caso critico
Proposta: bloccare "Risolto"/"Non applicabile" su crit/warn con Note vuote.
27/08/26, 22:34
Cinquanta Giri
https://claude.ai/code/artifact/27458051-f580-4b7c-8fea-7a5445e2da5e?open_in_browser=1&via=user_open&org=9bc80406-e755-4c6b-9268-70c73f9b85fa
29/29
