# METHOD.md — il metodo in una pagina

> Il sistema ha molte stanze; questa è la porta. Ogni elemento rimanda alla sua fonte
> di verità. Ultima revisione: 2026-08-23 (4° ciclo, set 1 "agenti/sistema contabile",
> giro 1/10).

## Il ciclo

```
/selezione-contesto → /brainstorming ⇄ /design-doc → territorio piccolo: /goal | max N
                                               → territorio grande: commessa → /audit-commesse → notte
                                                 → gate → review di Luca
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
| Controllo di gestione (formula ancorata a un oracolo reale, non inventata) — quando la commessa è un calcolo contabile/gestionale, non una decisione software | `/controllo-gestione`, o delega a un subagent (`contabilita-analitica`/`costruttore-calcoli-gestionali`/`revisore-calcoli-critici` più, dal 6° ciclo, `censitore-forma-dati` e `sviluppatore-gas`) — invocabilità dipende da un refresh del roster degli agenti, non garantita nella sessione/turno in cui i file vengono scritti (set 1 giro 8, poi confermata funzionante) | `.claude/skills/controllo-gestione/SKILL.md`; `.claude/agents/` (5 agenti — nota in docs/system.md §"Limiti dichiarati" #6); la copertura per dominio: `docs/mappa-dominio-gas-src.md` (6° ciclo, set 1: 8 oracoli Python minati da REPO-E) |
| Commessa (issue `night-shift` con Design+Territorio+Forma dei dati) | template | `.github/ISSUE_TEMPLATE/` |
| Audit serale (verifica le assunzioni sul codice) | `/audit-commesse` | idem |
| Notte (turno 23:00, multi-repo, ponytail) | `night-shift/night-shift.sh` | `night-shift/README.md` |
| Gate del mattino (3 controlli + banco sandboxed) | `night-shift/morning-gate.sh` | idem |
| Registro esiti (notte) | `night-shift/gate-esito.sh`, `night-shift/gate-summary.sh` | `metrics/gate.csv` |
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

Un solo comando porta tutto: `tools/sync-repo.sh <owner/repo> --standard`
(apre la PR). `tools/sync-repo.sh <owner/repo>` senza flag verifica e riporta
il drift. Lo standard NON è dichiarato dai documenti soltanto: se manca un
pezzo, manca il metodo.

## Le regole che contano (le altre stanno nelle fonti)

1. **Esegui, non leggere** — ogni affermazione porta il comando che la dimostra
2. **Design dichiarato** — da dove nasce la commessa (SAL/analisi), prima del lavoro
3. **Territorio dichiarato** — quanto codice serve leggere; grande = giorno
4. **Forma dei dati verificata** — le assunzioni si controllano sul codice
5. **Privacy come presidio** — repo pubblica: nomi mai, codici sempre (`tools/privacy-check.sh` fallisce il gate su una perdita; `night-shift/repos-index.md` registra il ruolo di ogni codice senza nomi reali)
6. **Il guardiano si prova quando deve fallire** — un check si testa col caso noto-difettoso
7. **L'aspettativa si deriva** — l'aritmetica del test si conta a mano, non a memoria
8. **Il giorno non tocca il workdir della notte** — passa dall'API

## I pattern

`patterns/` — 23+ trucchi ancorati al codice che li usa (l'ancora muore, la voce muore).

## La mappa completa

`docs/system.md` (architettura e limiti dichiarati) · `docs/test-processo-2026-08-21.md`
(dove il processo fallisce) · `SAL.md` (diario con indice, "cosa funziona coi numeri" vive
per ora nelle sue voci datate) · `DEBITI.md` (i "poi" che non devono diventare "mai").

<!-- CORREZIONE (set 2 "capacità di progettare", giro 4/10, 2026-08-22): questa riga citava
`docs/stato-2026-08-22.md` come parte della mappa — il file non esiste mai stato scritto,
verificato con una ricerca sul repo. La riga in SAL.md ("Stato completo del progetto:
docs/stato-2026-08-22.md") molto probabilmente si riferiva al repo onboardato di cui parlava
quella voce (issue #12), non al hub — ma qui, nella mappa DEL HUB, era una citazione senza
presidio. Rimossa; se un report numerico del hub servirà davvero, va scritto con dati veri
al momento, non promesso qui in anticipo. -->
