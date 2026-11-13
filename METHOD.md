# METHOD.md — il metodo in una pagina

> Il sistema ha molte stanze; questa è la porta. Ogni elemento rimanda alla sua fonte
> di verità. Ultima revisione: 2026-09-23 (revisione in dieci giri: regola 5 riscritta sulla
> decisione privacy del giorno — il testo era spezzato a metà di un nome di file —, conteggio
> dei pattern). La precedente: 2026-08-28 (revisione 14 lenti).

## Il ciclo

```
/selezione-contesto → /brainstorming ⇄ /design-doc → territorio piccolo: /goal | max N
                                               → territorio grande: commessa → /audit-commessa → notte
                                                 → censore (PR `caccia:`) → digest del mattino → review di Luca
TASK DA UNA SESSIONE (terza corsia, 7° ciclo 2026-08-24 — dal report sul campo):
  chiarito in 1-2 domande, un file, verificabile qui e ora → si fa e basta, col metodo
  (leggere prima, chiedere invece di indovinare, banco/prima della dichiarazione di fine,
  SAL se c'è una scoperta) ma SENZA pipeline: la cerimonia senza rigore in più è spreco.
(design-doc torna a brainstorming se nessuna opzione è buona — 5° ciclo, set 2 giro 7)
```

| Fase | Comando/strumento | Fonte di verità |
|---|---|---|
| Selezione del contesto (pacchetto limitato di fonti, budget ed esclusioni dichiarate) | `/selezione-contesto` | `.claude/skills/selezione-contesto/SKILL.md` (6° ciclo, set 2, 2026-08-24) |
| Brainstorming (socratico + divergenza: riformulazioni del problema prima di convergere) | `/brainstorming` | `.claude/skills/brainstorming/SKILL.md` (set 2 2026-08-22: prima citato senza esistere; 6° ciclo set 2: divergenza + contesto preventivo) |
| Design (vincoli di squalifica PRIMA, poi opzioni confrontate su criteri espliciti, effetti di secondo ordine, spike se un criterio è ignoto — NON implementa) | `/design-doc` | `.claude/skills/design-doc/SKILL.md` (6° ciclo set 2: squalifiche/secondo-ordine/spike) |
| GAS sviluppo/revisione generici (canone del parco REPO-E: quattro verbi, famiglie misurate, parità) | `gas-sviluppo` + agenti `sviluppatore-gas`/`revisore-gas` | `.claude/skills/gas-sviluppo/` (6° ciclo, addendum: il parco come corpus) |
| Controllo di gestione (formula ancorata a un oracolo reale, non inventata) — quando la commessa è un calcolo contabile/gestionale, non una decisione software | `/controllo-gestione`, o delega a un subagent (`contabilita-analitica`/`costruttore-calcoli-gestionali`/`revisore-calcoli-critici` più, dal 6° ciclo, `censitore-forma-dati` e `sviluppatore-gas`) — invocabilità dipende da un refresh del roster degli agenti, non garantita nella sessione/turno in cui i file vengono scritti (set 1 giro 8, poi confermata funzionante) | `.claude/skills/controllo-gestione/SKILL.md`; `.claude/agents/` (6 agenti, incluso `revisore-gas` — bug reale corretto: revisione 14 lenti, 2026-08-28, il conteggio era rimasto a 5); la copertura per dominio: `docs/mappa-dominio-gas-src.md` (6° ciclo, set 1: 8 oracoli Python minati da REPO-E) |
| Commessa (issue `night-shift` con Design+Territorio+Forma dei dati) | template | `.github/ISSUE_TEMPLATE/` |
| Audit serale (verifica le assunzioni sul codice) | `/audit-commessa` | idem |
| Notte (turno 23:00, multi-repo, ponytail) | `night-shift/night-shift.sh` | `night-shift/README.md` |
| Censore nel ciclo (guardie + prove sul branch + delibera, solo PR `caccia:`) | `night-shift/revisore.sh` | idem |
| Digest del mattino (email alle 7:30: lezioni, sospesi, resoconto) | `night-shift/morning-digest.sh` | idem |
| Gate del mattino — **in pensione dal 2026-09-23**, invocabile a mano (3 controlli + banco sandboxed) | `night-shift/morning-gate.sh` | idem (`cervello/decisione-dominio-2026-09-23.md`) |
| Registro esiti del gate — **storico**: lo scriveva il gate del mattino (in pensione); ultima riga 2026-08-21 | `night-shift/gate-esito.sh`, `night-shift/gate-summary.sh` | `metrics/gate.csv` |
| Registro chiamate (giorno) | `llm/usage-summary.sh` | `~/.ai-programmer-usage.log` (4° ciclo, set 3, giro 5, 2026-08-23: il log esisteva dal ciclo precedente, il riepilogo no) |
| Loop diurni con verifica | `/goal ... \| max N` | `.claude/skills/goal/SKILL.md` (set 2 2026-08-22: prima citato senza esistere; 5° ciclo, set 2 giro 3, 2026-08-23: primo loop reale eseguito, `loops/` non più vuota) |

## Lo standard (2026-08-26 — «non un'opzione»)

Il metodo non si invoca: si TROVA già in opera. Una repo che lavora col metodo
AI_Programmer ha, fisicamente:

1. **CLAUDE.md dell'hub** (regole caricate automaticamente a ogni sessione);
2. **`.claude/skills/` + `.claude/agents/`** (e gli specchi `.opencode/agent/`
   per la notte);
3. **`.claude/settings.json` con gli HOOK** — la parte che non dipende dalla
   memoria della sessione: SessionStart inietta il metodo all'apertura,
   UserPromptSubmit lo ri-inietta a ogni prompt (il problema era «invocato
   all'inizio e poi dimenticato»: ora non serve invocarlo);
4. **`.night-verify`** dichiarato.
5. **gli strumenti che il CLAUDE.md cita** — il settimo patto (`tools/debiti-riapertura.sh`), lo
   scheletro di `DEBITI.md` e del REGISTRO, i guardiani del commit (`.githooks/`,
   `tools/pre-commit.sh`), il formato del report di campo. Una lista sola,
   `tools/installa-citati.sh`, per sync-repo, bootstrap-app e onboard-repo.

Un solo comando porta tutto: `tools/sync-repo.sh <owner/repo> --standard`
(apre la PR). `tools/sync-repo.sh <owner/repo>` senza flag verifica e riporta
il drift. Lo standard NON è dichiarato dai documenti soltanto: se manca un
pezzo, manca il metodo.

## Le regole che contano (le altre stanno nelle fonti)

1. **Esegui, non leggere** — ogni affermazione porta il comando che la dimostra
2. **Design dichiarato** — da dove nasce la commessa (SAL/analisi), prima del lavoro
3. **Territorio dichiarato** — quanto codice serve leggere; grande = giorno
4. **Forma dei dati verificata** — le assunzioni si controllano sul codice
5. **Privacy come presidio** — repo pubblica: i nomi possono comparire, l'ACCESSO mai (segreti,
   credenziali, token, push di produzione — CLAUDE.md §«Public repo, private work», dal 2026-09-23;
   prima valeva «nomi mai, codici sempre»). `tools/privacy-check.sh` fallisce il gate su una
   perdita; `night-shift/repos-index.md` resta come storia dei codici anonimi ritirati
6. **Il guardiano si prova quando deve fallire** — un check si testa col caso noto-difettoso
7. **L'aspettativa si deriva** — l'aritmetica del test si conta a mano, non a memoria
8. **Il giorno non tocca il workdir della notte** — passa dall'API

## I pattern

`patterns/` — i trucchi ancorati al codice che li usa (l'ancora muore, la voce muore); il numero non si scrive qui, si conta: `ls patterns/*.md | grep -v README | wc -l` (65 al 2026-09-23 — era «23+» da agosto).

## La mappa completa

`docs/system.md` (architettura e limiti dichiarati) · `docs/test-processo-2026-08-21.md`
(dove il processo fallisce) · `SAL.md` (diario con indice, "cosa funziona coi numeri" vive
per ora nelle sue voci datate) · `DEBITI.md` (i "poi" che non devono diventare "mai").

<!-- CORREZIONE (set 2 "capacità di progettare", giro 4/10, 2026-08-22): questa riga citava
voce SAL del 2026-08-22 come parte della mappa — il file non esiste mai stato scritto,
verificato con una ricerca sul repo. La riga in SAL.md ("Stato completo del progetto:
docs/stato-2026-08-22.md") molto probabilmente si riferiva al repo onboardato di cui parlava
quella voce (issue #12), non al hub — ma qui, nella mappa DEL HUB, era una citazione senza
presidio. Rimossa; se un report numerico del hub servirà davvero, va scritto con dati veri
al momento, non promesso qui in anticipo. -->

## Revisione 15 lenti — le regole nate dalla maratona 12-13/11/2026

Quattro regole nuove, tutte da incidenti veri (due rimbotti a un agente di
livello campione, un banco rosso colpevole del proprio test):

1. **Le note non sono il diff** (incidente: diff dichiarava rimosso un loop
   che teneva, con costante orfana → ReferenceError). La prova di ogni
   "rimosso/aggiunto" si QUOTA dal diff (le righe '-'), e dopo l'applicazione
   si lancia `tools/verifica-diff.sh <file> --assenti X --presenti Y`.
   La fine si dichiara solo a guardia verde.
2. **Allineamento per costruzione**: mai mappare risposte a record per indice
   su un sottoinsieme filtrato (urls[i]↔batch[i] disallinea al primo scarto
   → il dedup scartava i DDT sbagliati). Pattern obbligato: `items[]` con
   `{url, rec}` e ritorno per `items[i].rec`.
3. **La CONFIG non si hardcoda**: nome header/valore che vive in CONFIG.*
   si referenzia da lì (grep su CONFIG prima di ogni stringa fissa).
4. **Il banco può mentire quanto il diff**: un rosso va letto PRIMA di
   correggere il codice — nella maratona il banco era buggy due volte su
   tre (aspettativa autocontraddittoria, fallback dimenticato). Verificare
   il verificatore è parte del verificare.

E una promozione: il **ciclo diurno eredita i cancelli della notte** —
apertura con caccia-miglioria in miniatura (il backlog nasce dai fatti),
budget per richiesta (richiesta ibernata = si dichiara, non si aspetta),
chiusura con caccia-lente sul diff del giorno + digest tre righe
(fatto/sospeso/lezione) nel diario dei lavori. L'esame d'ingresso per i
cervelli: `docs/esame-modello.md`.

## Revisione 16 lenti — le regole del turno autonomo (13/11 sera)

5. **Le priorità del mandato si leggono IN ORDINE**: il fallback scatta solo
   DOPO aver verificato che il primario non c'è (incidente: rapporto UX
   esistente ignorato, tre ore di recency bias sul territorio familiare).
6. **L'header non è una lettura**: scagionare "da commento d'intestazione"
   si dichiara come assunzione (Main.gs: 56 funzioni, header letto, resto no).
7. **Rami di esecuzione mutuamente esclusivi** (già dimostrata col catch):
   prima di giudicare un ramo, chiedersi cosa è già successo negli altri.
8. **Documentazione viva** (v. docs/documentazione-viva.md): nessun diff
   senza la sua riga di documento; la doc si verifica come il codice;
   il documento generato firma la propria fonte.

E il cambio d'epoca: da oggi il sistema gira con la testa in API — il mini
del 30/11 non è un inizio ma un TRASLOCO del cervello da remoto a locale
(profiles/mini.sh, esame della quant al giorno-1). Si lavora già da mini.


## Revisione 17 lenti — il METABOLISMO (13/11 sera, decisione di Luca)
Il sistema si auto-migliora dalle proprie sessioni di codice:
9. A FINE SESSIONE ogni lezione/incidente/recidiva e' CANDIDATO di regola:
   su ramo auto/regola-<data> dell'harness — METHOD +1 datato, recidiva(2a)
   -> riga in .night-verify, buco ripetuto -> proposta di tool. PR aperta.
10. IL MERGE E' DI LUCA, SEMPRE: l'agente scrive le proprie regole su un
   ramo; il cancello umano non si delega (volpe e pollaio).
11. LA PROMOZIONE ESIGE LA RECIDIVA CONTATA O LA PROVA: niente regole
   d'umore, solo sangue versato (la liturgia dell'hub).
12. LA CODA DELLE DECISIONI: quando un blocco e' umano ([FIRMA], dati,
   segreti), non basta dichiararlo — si ISCRIVE a DECISIONI-DOVUTE.md
   (cosa/chI/perche'/cosa blocca). Il digest del mattino la ripresenta
   finche' Luca non la chiude. Il collaboratore vero non esegue soltanto:
   TIEDE IL CONTAPIOGGI con l'umano.


## Revisione 18 lenti — AUTONOMIA DI PASSO vs DIREZIONE (13/11 sera)
13. DIREZIONE = umano, PASSO = agente. L'umano decide LA META (mandato,
    priorità, approvazione diff). Tra una meta e l'altra l'agente CAMMINA
    DA SOLO: se il passo segue logicamente dal mandato approvato (stesso
    pattern, stessa area, stessa natura), si esegue e si DICHIARA dopo.
    Il "Procedo?" è per i bivi di direzione (cambio area, approccio nuovo,
    toccare production, regola [FIRMA]) — non per ogni passo del sentiero.
    REGOLA PRATICA: se alla mia domanda "procedo?" la risposta scontata
    e' "si, ovviamente" — NON CHIEDERE. Vai, e dichiaralo nel digest.
