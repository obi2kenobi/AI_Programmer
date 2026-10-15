# 2026-10-15 — note-credito-bozza-e-varianti
**Autore**: sessione Claude (con Luca)

## Cosa ho usato
- Registrazione_Fatture_Acquisto: un worktree per PR, banco rosso prima del codice, sabotaggi, `tools/gate.sh`. Sei PR dal 14/10 sera: #392 lista Noritec vuota, #393 `sondaCodiceServizi`, #394 testo della bozza, #395 `sondaNote2026`, #396 `sondaConfrontoBozza`, #397 testo della bozza corretto, #398 `provaVariantiNotaSandbox` (armata, solo sandbox).
- Le sonde in sola lettura hanno sostituito le ipotesi: `sondaCodiceServizi` (nessun codice), `sondaNote2026` (113 note, nessun codice servizi, nemmeno sulle 8 DIVPREBIOC dell'ufficio), `sondaConfrontoBozza` (bozza contro 26FAU-000755: serie, ubicazione, dimensione di riga).

## Cosa ho improvvisato
- Ho affermato per due PR (#394, messaggio a Maurizio) che serviva «il codice tipo transazione servizi»: era l'errore di BC preso alla lettera, non un fatto. I dati l'hanno smentito e ho corretto il testo in #397. Errore mio, non del sistema.
- `sondaCodiceServizi` taceva sulle righe d'ordine quando erano zero (nessuna riga stampata, nessun «nessuna riga»): l'ho segnalato a Luca, non l'ho ancora corretto (silenzio contro il sesto patto).
- La correzione che rende registrabili le note NON è scritta: la regola «ubicazione della fattura (SD)» è una decisione di Luca (§42) protetta dai test, e l'ufficio usa PRINCIPALE. Ho preparato una prova in sandbox per scegliere con un esito di BC invece di rovesciare la decisione su un'ipotesi.

## Cosa ha retto / ostacolato
- Ha retto: il gate ha fermato tre commit giusti per motivi giusti (àncore dei sabotaggi non uniche su tutti i `.gs`, `Q()` ambigua, lista dei sabotaggi sbagliata); il confronto bozza/registrata ha trovato un difetto vero indipendente dal codice (dimensione BIOC assente sulla riga).
- Ostacolato: ogni sonda nuova costa ancora cinque punti di registrazione a mano (`.night-verify`, README, elenco file di `test_fase2`, eccezioni delle lenti, e per le prove armate `FUNZIONI_ARMABILI` + `test_terzo_giro_g8.mjs`); il gate dura ~10 minuti ogni giro. Un'àncora di sabotaggio troppo corta (es. `var token = bcToken_();`) è presente in molte sonde e fa cadere tutte le attese: serve l'àncora lunga, e il banco lo dice solo dopo.

## Proposta al canone
- Un solo elenco per le sonde e le prove armate da cui derivare i punti da aggiornare (già proposta il 14/10, ora a sette punti).
- Una regola nei banchi delle sonde: ogni elenco stampato dichiara anche «zero righe», non solo gli errori (famiglia assente≠zero, applicata a una sonda mia).
- Prima di dare a una persona un'istruzione per completare un documento a mano, citare il dato che la sostiene (qui: la differenza campo per campo), non solo il messaggio d'errore del sistema.
