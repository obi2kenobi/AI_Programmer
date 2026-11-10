# Il Brain — la conoscenza dei documenti, ad albero, con le fonti verificate

> `tools/brain.py` e i suoi moduli `tools/brain_*.py`. Banco: `tests/test-brain.sh`.
> Nato il 2026-11-10 da un video sulle «LLM Wiki» (il second brain di Karpathy: un agente legge
> una cartella di documenti e la compila in pagine markdown collegate a grafo) e sui loro cinque
> problemi. Qui le cinque risposte, ciascuna col punto del codice che la porta.

Non sostituisce `cervello/`: quello resta la memoria **curata a mano** (decisioni, concetti,
famiglie, una nota per cosa). Il Brain indicizza **tutto** il corpus, cervello compreso, e
risponde con le righe esatte da cui ha preso ogni affermazione.

## I cinque problemi, le cinque risposte

| # | Problema della LLM Wiki a grafo | Risposta del Brain | Dove |
|---|---|---|---|
| 1 | Indicizzazione lenta e sequenziale: ogni pagina deve conoscere le altre per collegarle | Riassunti a livelli (documento → cartella → mappa). Ogni documento è indipendente: si riassumono in parallelo | `brain_ingest.riassumi_tutti`, `brain_riassunto` |
| 2 | Fonti citate ma mai controllate | Ogni frase si confronta con le righe che cita: primo giudice deterministico, secondo giudice modello sotto soglia, ⚠ se nessuno la salva | `brain_verifica` |
| 3 | Pensata per una persona: ognuno ricompila la sua wiki | Un database per tutti, in modalità WAL: chi interroga non blocca chi indicizza, ogni documento entra in una transazione sua | `brain_db.apri`, `brain_ingest.scrivi_documento` |
| 4 | Oltre 200-300 documenti il grafo esplode (ingestion e «healing») | Albero, non grafo: cambiare un documento rifà solo i suoi antenati. Il collegamento fra documenti si scopre **al volo**, alla domanda | `brain_ingest.ricostruisci_cartelle`, `brain_interroga.riferimenti` |
| 5 | Niente permessi: i markdown stanno sul file system | Ruoli e regole nel database (`nega` vince su `leggi`); una cartella letta in parte non usa la sua sintesi salvata | `brain_permessi`, `brain_interroga.Vista` |

In più, come nella demo: le frasi **senza** citazione escono marcate `[generale]` — conoscenza
generale, non dai tuoi documenti — così si sa da dove viene ogni cosa.

## Uso

```bash
python3 tools/brain.py indicizza .
```

```bash
python3 tools/brain.py chiedi "perché clasp push è vietato e come si fa il deploy"
```

```bash
printf '%s\n' "La bencina si misura prima di sedersi [cervello/concetto-bencina.md:4]." | python3 tools/brain.py verifica
```

```bash
python3 tools/brain.py mappa --profondita 1
```

Permessi (senza nessuna regola tutti leggono tutto, e il log lo dice):

```bash
python3 tools/brain.py permessi regola stagista leggi '*'
```

```bash
python3 tools/brain.py permessi regola stagista nega 'paghe/*'
```

```bash
python3 tools/brain.py permessi ruolo mario stagista
```

Il database sta in `~/.brain/brain.db` (mai nel repo); `--db` o `BRAIN_DB` lo spostano.
La persona è `--utente`, poi `BRAIN_UTENTE`, poi `$USER`.
Uscite di `chiedi`/`verifica`: 0 tutte le parti citate verificate · 2 uso o database assente ·
3 almeno una parte incerta o rotta · 4 nessuna parte citata (risposta non ancorata).

## Le fasi di una domanda (ognuna nel log)

1. **ricerca** — discesa a fascio dalla mappa: a ogni livello i figli più pertinenti
   (`ampiezza` 4), poi i pezzi di testo dei documenti scelti, poi un salto sui documenti che
   quei pezzi nominano (un percorso di file `.md`/`.txt`/`.pdf` o un `[[wikilink]]`). Se la discesa non trova niente,
   scansione piatta, dichiarata.
2. **bozza** — con `BRAIN_LLM` la scrive il modello citando `[percorso:riga-riga]`; senza
   modello è **estrattiva**: le righe migliori, citate una per una.
3. **verifica** — ogni frase contro le righe che cita.
4. **correzione** — se restano frasi incerte e c'è un modello: un giro di riscrittura con
   l'elenco dei difetti, poi di nuovo la verifica (`BRAIN_GIRI`, default 1).
5. **resoconto** — `VERIFICA FONTI: parti citate e verificate k/n · incerte · rotte · generale`.

## I due giudici della verifica

- **Primo (deterministico, istantaneo):** copertura delle parole piene della frase nelle righe
  citate. Due denti: un **numero** della frase che non c'è nelle righe citate porta la fiducia a
  0.2 e **nessun modello può salvarla**; una parola **negata** da una parte sola («non stoccare»
  contro «stoccare») la dimezza. Fiducia ≥ `BRAIN_SOGLIA` (0.6) → verificata.
- **Secondo (modello, `BRAIN_GIUDICE` o in mancanza `BRAIN_LLM`):** solo sotto soglia, risponde
  SI o NO. Senza giudice la frase resta ⚠ «sotto soglia, nessun giudice utile».

## Con un modello

Il contratto è quello di `llm/` (prompt come argomento, contesto su stdin, risposta su stdout):

```bash
BRAIN_LLM=llm/ask-qwen.sh BRAIN_GIUDICE=llm/ask-opus.sh python3 tools/brain.py chiedi "..."
```

Con `BRAIN_LLM` anche i riassunti di documenti e cartelle li scrive il modello (al giro di
indicizzazione: `--forza` per rifare quelli già fatti senza modello). Ogni chiamata fallita è
detta nel log e si ripiega sul deterministico.

## Misurato (2026-11-10, in questa sessione)

- Hub intero senza modello: 498 documenti (i .md di cartelle nascoste esclusi), 2376 pezzi,
  23 cartelle, **1,3 s** il primo giro; il secondo giro: 498 invariati, 0 cartelle rifatte.
- Domande sull'hub: 0,05–0,09 s ciascuna, risposta estrattiva verificata.
- Banco `tests/test-brain.sh`: 29/29. Sabotaggi dichiarati (ciascun dente neutralizzato, il banco
  arrossisce): numero assente 4 rossi, `nega` ignorato 3, incrementale spento 2, negazione 1,
  sintesi parziale che trapela 1.

## Limiti dichiarati e domande aperte

1. **La soglia non è calibrata.** Il video parla di modelli di decisione con confidenza
   calibrata; il primo giudice qui è lessicale e la soglia 0.6 è una scelta, non una misura.
   Calibrarla vuole un insieme di frasi etichettate (vera/falsa rispetto alla fonte): chi lo fa?
2. **L'identità non è autenticata.** `--utente` lo dichiara chi chiama: i permessi filtrano,
   ma su una macchina condivisa non proteggono da chi si dichiara un altro. Una protezione vera
   vuole un servizio che autentica (un server, anche MCP) davanti al database.
3. **La ricerca è lessicale.** Radici di 6 lettere, niente sinonimi: «quale modello usa il turno»
   trova il diario prima di `cervello/decisione-modello-unico.md`. Un modello che guida la
   discesa (sceglie i figli leggendo le sintesi) è la strada naturale, non ancora fatta.
4. **I PDF passano da `pdftotext`:** un PDF scansionato (senza testo) è saltato e detto nel log,
   non indicizzato vuoto. L'OCR non c'è.
5. **Il server MCP del video non c'è:** oggi il Brain si usa da riga di comando.
