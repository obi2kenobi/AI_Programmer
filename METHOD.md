# METHOD.md — il metodo in una pagina

> Il sistema ha molte stanze; questa è la porta. Ogni elemento rimanda alla sua fonte
> di verità. Ultima revisione: 2026-08-23 (4° ciclo, set 1 "agenti/sistema contabile",
> giro 1/10).

## Il ciclo

```
/brainstorming → /design-doc → commessa → /audit-commesse → notte → gate → review di Luca
```

| Fase | Comando/strumento | Fonte di verità |
|---|---|---|
| Brainstorming (socratico) | `/brainstorming` | `.claude/skills/brainstorming/SKILL.md` (set 2 2026-08-22: prima citato senza esistere) |
| Design (opzioni+trade-off, NON implementa) | `/design-doc` | `.claude/skills/design-doc/SKILL.md` (set 2 2026-08-22: prima citato senza esistere) |
| Controllo di gestione (formula ancorata a un oracolo reale, non inventata) — quando la commessa è un calcolo contabile/gestionale, non una decisione software | `/controllo-gestione` | `.claude/skills/controllo-gestione/SKILL.md` (4° ciclo, set 1, giro 1, 2026-08-23) |
| Commessa (issue `night-shift` con Design+Territorio+Forma dei dati) | template | `.github/ISSUE_TEMPLATE/` |
| Audit serale (verifica le assunzioni sul codice) | `/audit-commesse` | idem |
| Notte (turno 23:00, multi-repo, ponytail) | `night-shift/night-shift.sh` | `night-shift/README.md` |
| Gate del mattino (3 controlli + banco sandboxed) | `night-shift/morning-gate.sh` | idem |
| Registro esiti | `gate-esito.sh`, `gate-summary.sh` | `metrics/gate.csv` |
| Loop diurni con verifica | `/goal ... \| max N` | `.claude/skills/goal/SKILL.md` (set 2 2026-08-22: prima citato senza esistere, `loops/` era vuota) |

## Le regole che contano (le altre stanno nelle fonti)

1. **Esegui, non leggere** — ogni affermazione porta il comando che la dimostra
2. **Design dichiarato** — da dove nasce la commessa (SAL/analisi), prima del lavoro
3. **Territorio dichiarato** — quanto codice serve leggere; grande = giorno
4. **Forma dei dati verificata** — le assunzioni si controllano sul codice
5. **Privacy come presidio** — repo pubblica: nomi mai, codici sempre (`privacy-check.sh` fallisce il gate su una perdita)
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
