# Brief dei giri — hub AI_Programmer, notte del 2026-09-23

Un file solo, letto da ogni giro. Il prompt del singolo agente dice soltanto: «area X, le tre lenti,
scrivi in docs/giri/2026-09-23-notte/<X>-<lente>.md — le regole sono nel brief».

## Contesto
- L'hub AI_Programmer: il METODO (regole, skill, agenti, hook, lenti, turno notturno, oracoli)
  che si installa nelle repo di Luca. Mandato: «analisi lenta e approfondita, trova errori,
  incoerenze, collegamenti fatti male, cose illogiche, e aggiusta tutto — affilato, smart,
  operativo; qualità, trucchi, verticali e trasversali».
- NON raggiungibile da questa sessione: il Mac (Ollama, launchd, `gh` autenticato), il GAS vivo,
  Azure. Chi lo richiede si dichiara ⏳, non si inventa.
- Già fatto, da NON riproporre: la revisione in dieci giri (PR #123, SAL 2026-09-23 1°-3°) e i
  debiti di dominio D1-D11 (PR #125, SAL 2026-09-23 4°-17°). Leggi la coda di SAL.md prima.
- Famiglie di difetti già note: E-002 (`… | grep -q` sotto pipefail), «verde senza verdetto»,
  «promessa nel commento, assente nel codice», falsi positivi del cancello clasp, il clone che
  parte dal commit (E-041). La lista: docs/errori/REGISTRO.md.

## Aree (nessuna esclusa)
| # | Area | Ancora |
|---|---|---|
| A1 | Hook e cancelli | `tools/{clasp-block-hook,pattern-reminder-hook,skill-reminder-hook,metodo-reminder-hook,pre-commit,copia-hook,graphify-spina,claude-md-satellite,profilo}.sh`, `.githooks/*`, `.claude/settings.json` |
| A2 | Lenti del metodo | `tools/{ciclo-vivo,giri-ignoranti,giri-avversari,prova-rilevatori,mutation-tests,suite,sal-indice,sal-archivia,debiti-riapertura,cita-verifica,fixture-provenienza,privacy-check,caccia-registro,salda-e002,presidio,polilivello,fork-stato,campo-triage,censimento-contesto}.sh` |
| A3 | Installatori e standard | `tools/{sync-repo,onboard-repo,bootstrap-app,garante-standard,install-garante,backup-config}.sh`, `night-shift/install.sh` |
| A4 | Oracoli contabili | `tools/*.py` |
| A5 | Cuore del turno | `night-shift/night-shift.sh`, `night-shift/lib.sh` |
| A6 | Attori del turno | `night-shift/{revisore,agente,caccia-miglioria,caccia-lente,risolvi-issue,morning-gate,morning-digest,gate-esito,gate-summary}.sh`, `night-shift/sandbox.sb`, `tools/{lente-sicurezza,grafo-semantico}.sh` |
| A7 | Cervelli e servizi | `llm/*`, `tools/{cervello-annota,cervello-domanda,cervello-impara,deploy-ora,prepara-deploy,status-page,system-health,turno-vivo,help,goal-issue,bencina-modelli,test-modelli-notturni,banco-passaggio,gas-gate,py-gate}.sh` |
| A8 | I banchi | `tests/*.sh` (la qualità dei test, non le aree che provano) |
| A9 | Skill e agenti | `.claude/skills/**`, `.claude/agents/*`, specchi `.opencode/**` |
| A10 | Documenti e registri | `README.md`, `METHOD.md`, `PROJECT.md`, `AGENTS.md`, `CLAUDE.md`, `docs/*.md`, `patterns/*.md`, `cervello/*.md`, `profiles/*` |

## Lenti (tre, ortogonali — ogni area le attraversa tutte)
| # | Lente | La domanda | Batteria |
|---|---|---|---|
| L1 | Difetto silenzioso | Cosa fallisce senza dirlo? rc mangiati, fail-open, pipefail/SIGPIPE, `set -e` che uccide senza verdetto, portabilità macOS/BSD (sed -i, grep -P, date, stat, timeout, `\b`), quoting, file temporanei condivisi, race | correttezza |
| L2 | Coerenza | Dove un commento, un documento o un nome promette ciò che il codice non fa? citazioni `file:riga` rotte, percorsi inesistenti, due fonti per la stessa verità, numeri scritti che divergono dal codice | correttezza |
| L3 | Affilatura | Cosa renderebbe l'area più smart e operativa? duplicazioni da derivare, semplificazioni, un trucco che toglie una classe di errori, collegamenti verticali (dall'hook al test al documento) e trasversali (fra aree) che mancano | prodotto |

## Regole di ogni giro
1. Scrivi il tuo file PRIMA di rispondere: se muori dopo, il giro resta.
2. Una lente, un'area: tre file, uno per lente (`A<n>-L<m>.md`). Non guardare le altre aree.
3. Formato per ogni voce: **Oggi** (cosa succede ora, con `file:riga` LETTO davvero) · **Manca**
   (il buco specifico) · **Proposta** (una mossa concreta). Per L1: se puoi, ESEGUI il caso che lo
   prova e scrivi il comando e l'uscita — «provato eseguendo» vale più di «letto».
4. Al massimo 6 finding per lente, in ordine di gravità (alta / media / bassa).
5. Se la lente non trova niente, scrivi «nulla in questa lente» e perché.
6. Nessuna idea «da manuale» senza riscontro nel codice; nessun dato inventato.
7. In testa al file, il modello che ha eseguito il giro.
8. NON modificare nessun file del repo tranne i tuoi tre file in `docs/giri/2026-09-23-notte/`.
   Nessun commit, nessun push, nessuna rete verso il vivo.

## Uscita del consolidamento (dopo i giri)
| Rilievo | Segnalato da N lenti | Verificato eseguendo | Esito (Implementata/Esclusa/Rinviata/Già coperta) |
|---|---|---|---|
