# METHOD.md — il metodo in una pagina

> Il sistema ha molte stanze; questa è la porta. Ogni elemento rimanda alla sua fonte
> di verità. Ultima revisione: 2026-08-23 (4° ciclo, set 1 "agenti/sistema contabile",
> giro 1/10).

## Il ciclo

```
/brainstorming ⇄ /design-doc → territorio piccolo: /goal | max N
                              → territorio grande: commessa → /audit-commesse → notte
                                → gate → review di Luca
(design-doc torna a brainstorming se nessuna opzione è buona — 5° ciclo, set 2 giro 7)
```

| Fase | Comando/strumento | Fonte di verità |
|---|---|---|
| Brainstorming (socratico) | `/brainstorming` | `.claude/skills/brainstorming/SKILL.md` (set 2 2026-08-22: prima citato senza esistere) |
| Design (opzioni confrontate su criteri espliciti, NON implementa) | `/design-doc` | `.claude/skills/design-doc/SKILL.md` (set 2 2026-08-22: prima citato senza esistere; 4° ciclo set 2 2026-08-23: criteri dichiarati prima delle opzioni + tabella opzioni×criteri, non più solo trade-off narrativo) |
| Controllo di gestione (formula ancorata a un oracolo reale, non inventata) — quando la commessa è un calcolo contabile/gestionale, non una decisione software | `/controllo-gestione` (via provata); `.claude/agents/` esiste come documentazione dei tre ruoli ma NON è invocabile dal tool Agent in questa sessione (verificato dal vivo, set 1 giro 8) | `.claude/skills/controllo-gestione/SKILL.md` (4° ciclo, set 1, giro 1); `.claude/agents/` (5° ciclo, set 1, giro 1-3 — limite in docs/system.md §"Limiti dichiarati" #6) |
| Commessa (issue `night-shift` con Design+Territorio+Forma dei dati) | template | `.github/ISSUE_TEMPLATE/` |
| Audit serale (verifica le assunzioni sul codice) | `/audit-commesse` | idem |
| Notte (turno 23:00, multi-repo, ponytail) | `night-shift/night-shift.sh` | `night-shift/README.md` |
| Gate del mattino (3 controlli + banco sandboxed) | `night-shift/morning-gate.sh` | idem |
| Registro esiti (notte) | `night-shift/gate-esito.sh`, `night-shift/gate-summary.sh` | `metrics/gate.csv` |
| Registro chiamate (giorno) | `llm/usage-summary.sh` | `~/.ai-programmer-usage.log` (4° ciclo, set 3, giro 5, 2026-08-23: il log esisteva dal ciclo precedente, il riepilogo no) |
| Loop diurni con verifica | `/goal ... \| max N` | `.claude/skills/goal/SKILL.md` (set 2 2026-08-22: prima citato senza esistere; 5° ciclo, set 2 giro 3, 2026-08-23: primo loop reale eseguito, `loops/` non più vuota) |

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
