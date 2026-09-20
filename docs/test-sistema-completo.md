# Test del sistema COMPLETO — missione per un agente esterno (Fable, primo della lista)

> **Obiettivo**: AI_Programmer funzionante 24/7, in TUTTE le sue parti — non solo
> la notte. Questo documento è la mappa di ogni componente e la missione di test
> end-to-end. Ogni difetto trovato diventa riga nel report (formato:
> `docs/campo/README.md`), con la prova eseguita — il canone diffida dei rilievi
> non riprodotti. Il report FINALE va in `docs/campo/` come i quattro del
> 2026-09-19/20: quelli hanno prodotto 12 difetti hub curati e 26 regole.

## La mappa: le nove parti del sistema

| # | Parte | Dove | Stato dichiarato | Testata davvero? |
|---|---|---|---|---|
| 1 | **Turno notturno** | night-shift/night-shift.sh | 24/7 continuo, 2 repo | sì (catena 100/100) |
| 2 | **Il metodo diurno** | `.claude/skills/gas-sviluppo/`, METHOD.md | il canone | parzialmente (in campo) |
| 3 | **Morning gate** | night-shift/morning-gate.sh | giudizio del mattino | **NO — mai provato end-to-end** |
| 4 | **Sync/onboarding** | tools/sync-repo.sh --standard | installa lo standard, misura drift | parzialmente |
| 5 | **Lenti e banco** | tools/giri-*.sh e tools/banco-passaggio.sh | 17+ sonde, 7 banchi | sì (mutation-tested) |
| 6 | **Guardiani del commit** | tools/pre-commit.sh e i tre hook | la frontiera | parzialmente |
| 7 | **Ciclo issue→PR** | night-shift/risolvi-issue.sh e night-shift/agente.sh | solver→agente | parzialmente |
| 8 | **Dashboard** | tools/dashboard.py | osservazione v4 | sì (unit) |
| 9 | **Il ciclo della memoria** | SAL.md, DEBITI.md, REGISTRO | l'anello che torna | parzialmente |

## La missione: otto test end-to-end (nell'ordine)

### T1 — Il giro completo di una issue (notte)
Apri una issue `night-shift` su una repo di test con un bug piccolo e vero
(es. una funzione che sbaglia un calcolo). Il turno la deve prendere: solver
diretto O agente (con l'azione `edit`). Verifica: PR bozza creata, gate
passato, messaggio con conteggio test. **Esito atteso**: PR entro 2 cicli.
Se muore, la riga di log dice dove (le firme sono distinte).

### T2 — La catena del debito (notte, già provata — rifalla per conferma)
Repo scratch con 3 tubi E-002 → il trasformatore ne salda i riconoscibili,
l'agente dichiara onesto "niente" sugli altri, il censimento scende, il delta
urla. Da `tests/test-catena-viva.sh` come riferimento ma SU UNA REPO REMOTA
VERA (sandbox su GitHub), non solo scratch locale.

### T3 — Il censore su una PR VERA (mai successo)
Crea una PR bozza night/* con un miglioramento piccolo e GIUSTO su una repo
sandbox. Dopo 20 minuti di quarantena il revisore deve: guardie → prove →
verdetto JSON. **APPROVA = merge con certificato**. Poi una SBAGLIATA (es.
una "miglioria" che rompe un test): deve RIGETTARE con motivi. Questo test
non è MAI girato sul vivo: è il buco più grosso.

### T4 — Il morning gate (mai provato end-to-end)
Con una PR aperta e verifiche dichiarate nella repo, lancia
il morning-gate deve produrre il report per-PR con verifiche eseguite,
banco avversariale (comando allowlistato), verdetto, e chiudere nel SAL.
Verifica che il report DICA qualcosa di utile (non solo verde/rosso).

### T5 — L'onboarding completo di una repo nuova
Su una repo sandbox vuota: `tools/sync-repo.sh <repo> --standard` → PR con
CLAUDE.md, skills, hook, `.night-verify` SEGNATO col gate GAS se ha .gs,
`.gitignore` dei residui, gli strumenti citati. Poi mergi la PR e verifica
col `--from-local`: ALLINEATO. Poi misura il drift dopo un tocco all'hub.
**Ogni affermazione di questa lista è stata curata ieri: verifica che siano
VERE tutte insieme, non una per una.**

### T6 — I guardiani del commit (prova che mordono)
Su un clone scratch: commit con glifi alieni → deve rifiutare; CRLF →
rifiutare; citazione `file:riga` inesistente → rifiutare; numero-test
sbagliato nel messaggio → rifiutare. E l'hook clasp: `npx clasp push` →
NEGATO, `npm run push` (con package.json che ci arriva) → NEGATO, grep con
la forma nei DATI → consentito.

### T7 — Il ciclo della memoria
Dopo i test: la SAL riceve la voce del gate, DEBITI.md accumula, il registro
errori accetta una voce nuova con tutti i campi, e
`bash tools/debiti-riapertura.sh` elenca le domande di dominio. L'anello
deve CHIUDERE (il morning gate legge la SAL che il turno ha scritto).

### T8 — Il collasso e la ripresa (resilienza)
- Ammazza Ollama a metà finestra: il watchdog lo rianima al giro dopo.
- Corrompi la work copy (git rotto): il riclono atomico lascia la copia
  viva o la rimpiazza, MAI la cancella senza sostituta.
- Riempi il log a 10k righe: la dashboard resta reattiva.

## Come riportare

Formato `docs/campo/`: cosa provato, cosa retto, cosa ostacolato (con
`file:riga`), proposte numerate al canone. Le proposte che sono difetti
riprodotti vanno per prime. Se trovi che qualcosa di questa mappa è
SBAGLIATO (componente che non esiste, comando che non fa quel che dico),
anche quello è un rilievo — forse il più importante.

## Le regole del gioco

- Il repo hub è in sola lettura per te? I difetti si riportano, non si curano
  (come i quattro report di campo: loro curavano le LORO repo, l'hub lo curiamo noi).
- Ogni affermazione con la prova eseguita allegata. «Verificato eseguendo»
  va dimostrato, non dichiarato.
- I numeri sono bersagli: ricontali (7 su 21 rilievi di REPO-I erano numeri
  sbagliati — il campo insegna).
