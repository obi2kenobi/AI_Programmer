# La mappa del dominio — cosa sa sviluppare il sistema, e cosa no

> 6° ciclo, Set 1 giro 1 (2026-08-24). Censimento della cartella `gas-src/` di REPO-E
> (repo esterno pubblico, regola "Public repo, private work": qui nessun nome di
> cliente o progetto, solo categorie e conteggi). Metodo: classificazione per nome
> e ispezione dei file di una decina di progetti rappresentativi per categoria,
> eseguita, non stimata. Numeri: 91 progetti, 998 file, tutti Google Apps Script
> (`appsscript.json` in 91/91; 31/91 hanno frontend HTML; 56/91 parlano con
> Business Central; solo 6/91 hanno un `Test.js`).

## Perché questa mappa esiste

Il Set 1 del 5° ciclo aveva censito "~10 calcoli di controllo di gestione" e costruito
il metodo `/controllo-gestione` + il trio di agenti. Ma una domanda restava senza
risposta meccanica: **copriamo TUTTI i domini in cui il gruppo lavora davvero, o solo
quelli da cui sono nati i primi cinque oracoli?** Questa mappa è la risposta verificata:
per ogni categoria di progetto reale, lo stato della copertura (oracolo in `tools/`,
agente in `.claude/agents/`, o VUOTO con piano).

## Il censimento (91 progetti → 12 categorie)

| Categoria | Progetti | Oracolo in `tools/` | Agente | Stato |
|---|---|---|---|---|
| Ciclo attivo (ordini clienti, portali, sconti, conferme carico, credito) | ~20 | `margine_documento.py` | trio calcoli + `sviluppatore-gas` | PARZIALE: margine per documento sì (giro 4); i flussi ordini/sconti/portali restano da coprire |
| Ciclo passivo (fatture acquisto, DTE, leasing, controllo fornitori) | ~10 | `accuratezza_fatture_acquisto.py`, `leasing_amministrativo.py` | trio calcoli + `sviluppatore-gas` | PARZIALE: accuratezza e leasing sì; DTE resta |
| Magazzino e logistica (inventario, valorizzazione, CMR, riordino, BOM) | ~10 | `riconciliazione_magazzino.py`, `valorizzazione_magazzino.py` | trio calcoli + `sviluppatore-gas` | **COPERTO** per i calcoli (riconciliazione + valorizzazione con override, giro 3); i flussi CMR/BOM restano |
| Controllo di gestione, margini, vendite, rating, dashboard produzione | ~12 | `scostamento_standard_effettivo.py` | trio calcoli | PARZIALE: scostamento sì, **margine per documento** e budget no |
| Bilancio e contabilità generale (bilancio periodico, registri, intrastat, factoring) | ~6 | `indici_crisi.py`, `bilancio_bu.py` | trio calcoli | PARZIALE: indici e CE per BU (convenzione segni G/L) sì; ribaltamento REPARTO dichiarato APERTO; intrastat resta |
| Crediti e debiti (scadenzario, aging, rating clienti, factoring) | ~3 | `scadenzario_aging.py`, `rating_dso_clienti.py` | trio calcoli | **COPERTO** |
| Cespiti | ~1 | `rollforward_cespiti.py` | trio calcoli | **COPERTO** |
| Produzione industriale (costi diretti, manutenzione) | ~3 | `scostamento_standard_effettivo.py` | trio calcoli | PARZIALE |
| HR e collaboratori (presenze, valutazioni, controlli automatici) | ~6 | — | — | VUOTO (calcolo puro scarso: per lo più flussi, non formule critiche) |
| Post-vendita e cassa (scontrini, catalogazione, mobile) | ~4 | — | — | VUOTO (idem: flussi) |
| Integrazioni/BI/middleware (BC hub, database SD, BI agent, e-commerce) | ~10 | — | — | VUOTO come FORMULE (l'integrazione è il contesto, non il calcolo) |
| Energia/ambiente e varie (fotovoltaico, EUTR, PEFC) | ~7 | — | — | VUOTO (monitoraggio, non calcolo contabile) |

Legge che emerge dai numeri: **i due domini più popolati (ciclo attivo ~20 progetti,
ciclo passivo ~10) sono gli unici grandi senza NESSUN oracolo** — i cinque oracoli
esistenti coprono i domini da cui sono nati, non i domini più grandi. E la
valorizzazione di magazzino — il calcolo con più righe di codice reale di tutta la
cartella (il progetto magazzino di REPO-E porta `ValuationConfig.js` con override
gruppi/categorie/articoli e percentuali di costi generali, inventario fisico oltre
3.000 righe) — non ha oracolo.

## I pattern trasversali — e dove sta oggi il canone completo

I sei pattern elencati qui sotto (nati col censimento del giro 1) erano la
versione povera: dal giro di correzione di rotta (2026-08-24, stesso ciclo) il
canone completo vive nella skill `gas-sviluppo`
(`.claude/skills/gas-sviluppo/`), che porta nell'hub il corpus MISURATO della
skill gas-agent di REPO-E: il metodo dei quattro verbi, le famiglie di difetti
con le popolazioni, la consegna con prova di parità, le domande dei domini.
Quella skill è la fonte; questi sei restano come sintesi storica del perché
il censimento era necessario.

1. **Business Central è la fonte dati dominante** (56/91 progetti): pattern client
   dedicato (`BCConnector`/`BcClient`) con paginazione, retry e cache — mai chiamate
   sparse nel codice di calcolo.
2. **CacheService sopra PropertiesService per la configurazione** (limite 9KB vs
   100KB — correzione documentata nel codice REPO-E stesso dopo un incidente reale).
3. **Configurazione a livelli di override** (gruppo → categoria → articolo) con
   percentuali di costi generali: la stessa forma del ValuationConfig, riusata.
4. **WebApp con `doGet` + dashboard HTML** in 31/91 progetti: il frontend è parte
   del deliverable, non un extra.
5. **`LockService`/concurrency gestiti esplicitamente** dove più trigger toccano
   gli stessi fogli.
6. **Test quasi assenti** (6/91): la verifica è quasi sempre "review visiva di Luca"
   — esattamente il gap che `verifica-visiva` e il gate già presidiano altrove.

## Piano del Set 1 (eseguito, 6° ciclo)

- Giro 2 ✅: agente **`censitore-forma-dati`** — il censimento della forma dei dati
  (endpoint BC, schema fogli, campi) è il passo #1 di `/controllo-gestione` e il
  pattern "forma-dei-dati-verificata", ma restava manuale.
- Giri 3-5 ✅: oracoli per i tre VUOTO/parziali a maggior densità di calcolo:
  **valorizzazione magazzino** (costo medio + override + costi generali),
  **margine per documento** (ciclo attivo), **accuratezza fatture acquisto**
  (ciclo passivo) — tutti minati dal codice reale di REPO-E, con aritmetica
  derivata a mano nel test.
- Giro 6-7 ✅: agente **`sviluppatore-gas`** (costruisce progetti Apps Script nello
  stile REPO-E: sei pattern sopra, censimento prima, oracolo prima) e armonizzazione
  dei ruoli del trio esistente.
- Giri 8-10 ✅: propagazione (glob, mai liste), mappa/docs aggiornati, riepilogo.

## Manutenzione

Questa mappa è una fotografia con data. Se `gas-src/` cresce (nuove categorie), il
censimento va rifatto e la colonna "Stato" riletta — non è un documento che si
aggiorna da sé. Il test `tests/test-mappa-dominio-gas-src.sh` presidia la forma
(ogni categoria dichiara uno stato esplicito, gli oracoli citati esistono davvero),
non la verità del censimento.

Residui dichiarati (aggiornati al 7° ciclo, set 1): i costi generali % della
valorizzazione restano NON applicati (formula non provata); il ribaltamento
REPARTO del bilancio per BU resta APERTO (formula non provata); leasing e
rating DSO ora hanno oracolo (con le stime 2,5%/30% del codice REPO-E dichiarate
dentro); DTE e i flussi ordini/portali restano da coprire. NUOVO dal 7° ciclo:
`tools/gas_qualita.py` porta le famiglie misurate a rilevatore meccanico —
censimento aid, non verdetto, con la domanda discriminante per famiglia.
