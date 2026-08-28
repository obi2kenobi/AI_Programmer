# AI_Programmer — Report lavori del 28/08/2026 su gestionale-parrocchie

**Target:** `frazu2003-lab/gestionale-parrocchie` (Flask+SQLite, archivio amministrativo di
parrocchie, dati personali reali, repo privato)
**Regime:** sessione diurna unica, ZCode/GLM, su clone locale. Nessuna notte, nessun gate:
il banco avversariale ha fatto da gate.
**Consegna:** 21 commit su `main` (da `3c03981` a `4b3dd24`), tutti verificati su archivio
di prova isolato; la cartella dati vera non e' mai stata toccata (non esiste su questa macchina).

---

## 1. I numeri del giorno

| Metrica | Valore |
|---|---|
| Committate in main | **22** (9 correzioni, 4 documenti vivi, 3 nuove funzioni, 1 privacy, 5 SAL/DEBITI) |
| Giri di revisione/verifica eseguiti | **159**: 50 di revisione a lenti + 77 controlli automatizzati in 5 suite + 30 giri di analisi CRM |
| Difetti catalogati | ~60 (revisione) + 15 trovati nei giri successivi |
| Difetti DIMOSTRATI al banco (eseguiti, non letti) | 13 + 3 (30 giri) + 6 (caccia) + 1 (P0 privacy) |
| Difetti corretti e consegnati | **26** |
| Suite di collaudo lasciate al progetto | **5, tutte verdi**: persone 13/13, caccia 20/20, 30 giri 30/30, incroci 16/16, scadenze 10/10 |
| Migrazione schema | v6 → **v7** (anagrafica persone, nessuna riga toccata) |
| Pagine app | da 19 a **22** (+ Persone, + sezione Scadenzario in Strumenti) |

## 2. Le commesse della giornata, in ordine

1. **Revisione a 50 passate + banco avversariale.** Lettura integrale (~7.000 righe),
   4 subagenti a lenti, 13 difetti dimostrati eseguendo. Nove correzioni, un tema per commit.
2. **Correzioni**: `--prova` propagato a tutti gli strumenti (lavorare in prova agiva
   sull'archivio vero); IBAN troncato dall'estrazione; «None» precompilato nei form;
   modifiche fantasma int/testo; guardia Host/anti-CSRF; rilevatore backup; copertura
   senza crash; intestatario conto storicizzato; controllo versione schema all'avvio;
   conteggi e parsing onesti (`numero()`, «NON SO», buchi solo attivi).
3. **M10 passo 1 — Generatore dello scadenzario** (`genera_scadenze.py`, +2 pulsanti):
   proponi/conferma, rinnovi con finestra di disdetta per ogni rinnovo, ISTAT, rate non
   mensili, polizze, verifiche. Idempotente; chiusure DIcHIARATE nel foglio (colonna
   CHIUDERE), mai sovrascritture. Un difetto di design (catene che si chiudevano fra loro)
   trovato dal collaudo e corretto prima del commit.
4. **30 giri su archivio popolato** (casi limite: archiviati, cessati, canoni di ogni
   periodicità, documenti mancanti, doppioni): 30/30 dopo 3 correzioni (Documenti in prova
   guardava la cartella vera; `ripristina.py` scambiava `--prova` per il nome della copia;
   `esporta.py` senza modalità prova).
5. **Giri degli incroci**: spazzata SQL di ogni FK + collegamenti polimorfi (38 tabelle) e
   14 navigazioni bidirezionali: 16/16. Trovata e corretta la colonna «Riguarda» degli atti
   canonici (l'oggetto collegato esisteva in DB e non si vedeva da nessuna parte).
6. **Caccia spietata — 20 giri, lenti nuove** (soldi, iniezioni, doppi clic, dati sporchi,
   percorsi, XSS, date al limite): 20/20 dopo 6 correzioni (arrotondamento a mezzo sopra in
   `euro()`, ricerca senza accenti, dedup IBAN + riprova sulla gara dei codici, numeri a
   parole segnalati e non fatali, importi testuali conteggiati, percorso che esce dalla
   cartella dati rifiutato — commonpath normalizza i «..» da solo: prima guardia inefficace).
7. **30 giri di analisi CRM parrocchiale**: censimento ancorato a gestionali reali (UNIO/CEI,
   Sipa.NET, Deru, Genesis, ParishSOFT/Pushpay), sei domini tipici, mappatura sul progetto,
   **16 proposte prioritarizzate (P0–P16)** con vincoli charter; le 9 idee dell'utente
   integrate una per una (sacramenti, benedizioni+SMS/WhatsApp, anagrafica telematica,
   manutenzioni a progetto con Gantt, sorveglianza consumi, estratti conto, circolari,
   social, certificati PEC) con principio fisso: **il programma prepara, l'umano invia**.
8. **P0 — Scheda Persona (M13)**: schema v7 (contatti su `conduttori`, zero migrazioni di
   dati), elenco cercabile, scheda con cronologia automatica (contratti, utenze intestate,
   annotazioni), nuovo/modifica con registro e dedup CF, link bidirezionali coi contratti,
   voce «Persone» nel menu. 13/13 al banco + regressione completa delle altre suite.

## 3. I difetti per famiglia (il corpus conferma e si estende)

- **Normalizzazione/tipi** (famiglia `Number('')=0`): int/testo = modifiche fantasma;
  `1000.50` → ×100; importi testuali che svuotano totali; numeri a parole («sei») che
  crashano; `120.0` vs `'120'` risolto con normalizzazione Decimal/mezzo-su.
- **«Non letto» vs «vuoto»**: sentinella `0000-00-00`, `letta=True` su PDF vuoti,
  canoni senza periodicità, adempimenti senza scadenza — ogni volta il vuoto va SEGNALE,
  non riempito.
- **Guardiano cieco dove dichiara di vedere**: controllo riservatezza senza lista;
  rilevatore backup spento da una cartella; pagina Documenti in prova che guardava la
  cartella vera (tutto «mancante»); **export che avevano i nomi delle persone
  `riservato`** (trovato dal banco di P0).
- **Risorse/concorrenza**: gara sui codici → 500 + archivio bloccato (connessione non
  chiusa in errore); file spostati prima del commit (debito, dichiarato).
- **Confini**: attraversamento di percorso via DB (commonpath normalizza i «..»: la guardia
  va provata col caso reale); Host non verificato (CSRF/DNS rebinding).

## 4. Le lezioni di metodo di oggi

1. **«Esegui, non leggere» e' stato il discrimine di ogni fase**: ~60 sospetti da lettura,
   23 difetti promossi come dimostrati, 1 falso positivo smentito dal banco. Il verdetto
   «fatto» e' arrivato solo dal ribaltamento del banco.
2. **Il banco e' diventato la memoria eseguibile del progetto**: le 5 suite (persone,
   caccia, 30 giri, incroci, scadenze) sono di fatto il `.night-verify` del target, pronte
   per il ciclo notturno dell'hub.
3. **Le fixture degradano con i rilanci**: due suite ha fatto finta di rompersi perche'
   lo stato del database di prova portava la storia dei giri precedenti. Regola nuova:
   ogni giro resa autonoma, con reset dichiarato della propria fixture.
4. **Le guardie vanno provate col caso reale, non col caso pulito**: `commonpath`
   normalizza i «..» (prima guardia inefficace), `openpyxl` tratta «=» come formula
   (verificato: qui no, ma ora c'e' il test che lo presidia), `--prova` scambiato per il
   nome di una copia.
5. **Il clone shallow falsifica l'audit**: 1 commit visto contro 41 reali; l'ambiente del
   censimento (depth/remote/branch) va dichiarato nei giudizi sulla storia git.
6. **Charter come insieme di decisioni vive**: 9 idee utente mappate senza scrivere codice,
   16 proposte con dentro/fuori/decisione; il principio «prepara, l'umano invia» tiene
   insieme benedizioni, circolari, PEC e social senza violare §10.

## 5. Consegna e artefatti

- Repo: `main` a `4b3dd24`. App demo in prova avviata (fascia rossa, dati finti marcati).
- Artefatti nella cartella della revisione: banco avversariale + esiti, 30 giri + esiti,
  incroci + esiti, caccia + esiti, collaudo persone + esiti, report fase 1, proposta CRM
  completa (P0–P16 + le 9 idee dell'utente).
- **Aperto (decisioni dell'utente/proprietario):** rilancio di banco e controllo
  riservatezza dalla macchina con `.riservato.txt` prima dell'uso su dati veri; nomi nella
  storia git (41 commit) e localita' in DA-VERIFICARE.md; preavvisi dello scadenzario da
  confermare voce per voce; le 5 proposte che attendono decisione di charter (offerte,
  catechesi come dominio, rendiconti/budget, OCR, catalogazione spese).
- **Prossimo passo consigliato:** P1 dettaglio contratto (piccola, chiude il grafo) oppure
  I2 benedizioni (la prima delle idee utente, ora sbloccata da P0).
