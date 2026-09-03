# Indice dei codici repo (REPO-A, REPO-B, …)

Regola CLAUDE.md "Public repo, private work": questo hub è pubblico, i nomi reali di
repo private vivono SOLO in `night-shift/repos.key` (locale, gitignored). I codici
anonimi (REPO-A, REPO-B, …) sono invece sparsi in oltre 15 file (skill, SAL.md,
docs/system.md, pattern) SENZA un indice che dica cosa rappresenta ciascuno — chi legge
il hub per la prima volta non ha modo di sapere se "REPO-A" citato in un file è lo
stesso "REPO-A" citato in un altro, e una sessione futura che sceglie un nuovo codice
rischia di riusare per errore una lettera già in uso per un repo diverso (rischio
verificato dal vivo: 4° ciclo, set 1, prima di assegnare REPO-E ho dovuto verificare che
non collidesse con nessun codice esistente).

Questo file NON contiene nomi reali — solo il RUOLO di ciascun codice, ricostruito da
citazioni già pubbliche nel repo (nessuna informazione nuova). La mappatura codice→nome
reale resta solo in `night-shift/repos.key`.

| Codice | Ruolo (senza nome) | Dove citato per la prima volta |
|---|---|---|
| REPO-A | Repo pilota del turno notturno — tre notti di test veri (2026-08-18/21) che hanno prodotto il metodo in `night-shift/README.md`. Issue #363: il modello locale non converge sui giudizi. Ha una cartella `gas-src/` dichiarata "cartella specchio/sola lettura" — regola fondativa del sistema | `night-shift/README.md` |
| REPO-B | Origine della skill `audit-commessa` — primo giro reale (2026-08-21): 3 commesse su 4 avevano difetti di forma-dati, trovati eseguendo non leggendo (issue #11, dettaglio HTTP 501 in `SAL.md:235-236` di quel repo) | `.claude/skills/audit-commessa/SKILL.md` |
| REPO-C | Origine della skill `dev-critic` — l'onboarding vero di un progetto esistente ha rivelato un percorso cloud non documentato, drift di CLAUDE.md, e credenziali committate: nessuno di questi gap era visibile dalla sola lettura | `.claude/skills/dev-critic/SKILL.md` |
| REPO-D | Repo del ciclo "5 giri" (mandato: tutto da un solo operatore in loop) e del ciclo 2 successivo, incentrato sulla progettazione | `SAL.md`, voci del 2026-08-22 |
| REPO-E | Sistema-Gestione-Magazzino GAS+BC (dashboard + inventario + rettifiche; oracoli: riconciliazione magazzino, valorizzazione magazzino, indici di crisi, scadenzario aging, scostamento standard-effettivo, roll-forward cespiti) | 2026-09-03: routine controlli → bloccante 10.000€ (spazio letto come zero), 10 difetti chiusi, 11 dichiarati, redesign UI (5.292→5.279 righe, 105 colori → token), gate 173→227 attese, 8 regole al canone | docs/campo/2026-09-03-repo-e-chiusura-ciclo-redesign.md |
| REPO-F | Progetto GAS/BC reale con una dashboard web (`Dashboard.html`) e un flusso di consegne — caso di campo del 2026-08-24: bug reale (una funzione di backfill mai attivata da un trigger) trovato per indagine diretta, non da una skill invocata | `SAL.md`, voce del 2026-08-24 |
| REPO-G | repo del bilancio periodico (CE per BU, SP, quadrature) | attiva, MAI onboardata (decisione aperta invariata, DEBITI 2026-08-24); revisione robustezza+grafica 2026-08-31: 16 lenti, 12 batch, PR #37 mergiata, confermata funzionante dal cliente | docs/campo/2026-08-31-repo-g-robustezza-grafica-16-lenti.md |
| REPO-H | repo cespiti GAS+BC standalone (FA Ledger + G/L da BC, report mensile) | prima segnalazione 2026-08-27: 13 rilievi, 12 fix, banco Node 19/19 | docs/campo/2026-08-27-revisione-cespiti-gas-bc.md |
| REPO-I | controlli trimestrali di bilancio GAS+BC (97 file) | 3° giro 2026-09-01: 10 agenti correttezza pura → 16 bug (tema trasversale: "Open" letto come oggi in 4 aree; 1 area pulita) + 2 questioni delegate e CHIUSE; PR #102+#103; poi PRIMO DEPLOY DAL VIVO: 2 asserzioni vere solo negli stub (il reale più permissivo del previsto → riga di test nel registro di produzione ISA 230) — 6 proposte al canone | docs/campo/2026-09-01-repo-i-giro-correttezza-16-bug.md |
| REPO-J | Gestione-ordini-REPO-J (ordini EDI fornitori, GAS+BC) | 2ª revisione 2026-08-31 su main post-deploy: 95 agenti (55 ricerca × 6 lenti + 35 verifica avversariale + 5 idee) → 29 bug confermati (6 ALTI: OData injection, TRIGGER_HOUR=0, CSV formula injection, numeroOrdine non escaped, quantità senza arrotondamento, undefined nella mail) + 3 confutati + 99 NON VERIFICATI dichiarati (tetto capacità) + 20 idee robustezza | docs/campo/2026-08-31-repo-j-revisione-100-agenti.md |
| REPO-K | Dashboard web GAS+BC per gestione ordini multi-categoria (foglio "aperti" e foglio storico paralleli, sync automatico) — già citato informalmente come "dossier SD" in `.claude/skills/gas-sviluppo/references/famiglie-difetti.md` e in `SAL.md` (voce 2026-08-28) prima che questo codice esistesse | dossier 86 rilievi + 25 idee (2026-08-28), TUTTI implementati in sessione continua; 2ª sessione 2026-08-31 (5 bug per lente + tooltip + 4 feature, PR mergiata, clasp in produzione); 3ª sessione 2026-09-01: 3 giri extra onesti (i rilievi calano ciclo dopo ciclo, dichiarato) — `clasp push` ≠ PRODUZIONE scoperto e verificato col fetch mirato, promosso a pattern (`patterns/clasp-push-non-e-produzione.md`) | docs/campo/2026-08-28-repo-k-dal-dossier-a-tutti-i-fix.md, docs/campo/2026-08-31-repo-k-robustezza-grafica-nuove-feature.md, docs/campo/2026-09-01-repo-k-terza-sessione-3-giri-extra-deploy.md |
| REPO-L | Unicredit_Factoring (cessione fatture, GAS+BC, file fixed-width TXT per banca) | audit 30 agenti 2026-08-28: 54 rilievi, 9 confermati, 45 NON VERIFICATI, 0 smentiti · SECRET in git history (da ruotare) | docs/campo/2026-08-28-unicredit-factoring-30-agenti.md |
| REPO-M | Associazione-Energikal (bilancino trimestrale, GAS+BC) | sessione estesa completa 2026-08-31/09-01 (PR #55-#59 TUTTE mergiate): Fasi 1-5 (piano 39 voci, R1-R7, grafica, F1-F14, deploy) + FASE 6 V1-V26 (26 fix: 4 bug REALI — V5 override parziale, V11 protocolli consumati per report fallito, V15 race sui fogli DB alla prima esecuzione, V16 riga verificabile controllava colonne sbagliate; + token 401 con ritento, paginazione protetta, Python 3 fix con output identico verificato). Deploy clasp live con TUTTO incluso. ROTAZIONE SECRET AZURE ANCORA APERTA. Report: docs/campo/2026-09-01-repo-m-sessione-estesa-fase6.md | docs/campo/2026-08-31-repo-m-chiusura-sessione-estesa.md |
| REPO-N | gestionale parrocchie (Flask+SQLite, privato) | 50 passate 2026-08-28: 13 difetti banco, 10 commit, scadenze 10/10 | docs/campo/2026-08-28-parrocchie-fase1.md |
| REPO-Q | parco GAS produzione/costi diretti (8 progetti: 5 nostri + 3 cloni di riferimento) | 2026-09-02/03: AUDIT COMPLETO col metodo (9 agenti censimento → 4 correttori in worktree → composizione → consegna): 41 fatte + 7 parziali + 13 bloccate + 3 misura + 6 cloni + 3 decisioni + 2 dichiarate = 75; 575/575 attese, 31 banchi verdi; 86 commit; 13 diff-bloccati pronti con domanda; 22 domande di dominio. Il LIMITE più grande: parità tutta livello 1 (zero staging). G00: SyntaxError letterale da scrub (restituito da cross-reference). Il GARANTE oggi chiude il buco 6.1 (installazione) | docs/campo/2026-09-03-repo-q-audit-completo-procedura.md |
| REPO-V | Gestionale di magazzino di sede GAS (nuovo, nato il 2026-09-03: nessun codice applicativo, requisiti in brainstorming). Prima repo portata a standard NON con `sync-repo.sh --standard` ma a mano, da una sessione cloud senza `gh` — percorso che ha fatto emergere i due buchi sul cancello del deploy (SAL 2026-09-03 (8)) | `SAL.md`, voce del 2026-09-03 (8) |

## Come usarlo

- **Prima di citare un repo esterno in un file versionato**: controlla questa tabella —
  se il repo ha già un codice, riusalo; se è un repo nuovo, aggiungi una riga qui E
  registra la mappatura reale in `night-shift/repos.key` (locale, sulla macchina di
  chi possiede il repos.key — questa sessione non può scriverci).
- **Se un codice qui elencato non corrisponde più a quanto scritto altrove** (un file
  citato è stato spostato, un dettaglio è cambiato): è una discrepanza reale, aggiorna
  questa riga E il file di origine, non solo uno dei due.
## REPO-CR — Centrale_Rischi (repo PUBBLICA di Luca, citabile per nome nei path)
Codice per il repo pubblico github.com/obi2kenobi/Centrale_Rischi (adempimento Banca
d'Italia, GAS). Usato come banco di prova del metodo 2026-08-29. Il prefisso REPO-CR
nei pattern dichiara l'ancora ESTERNA all'hub senza anonimizzare una repo pubblica.
| REPO-O | gestionale parrocchie (PRIVATA, frazu2003-lab): schema v7, 26 difetti al banco, 5 suite verdi (89 controlli); onboarding PR #1 2026-08-29 | adozione standard in corso | docs/campo/2026-08-29-repo-o-standard-adoption.md |
| REPO-P | rendiconto parrocchie (nuovo, non ancora su GitHub): passi 0-2 provati, fermo al 3 di proposito (mancano estratti veri) | attesa materiali | docs/campo/2026-08-29-repo-o-standard-adoption.md |
| REPO-Q | Repo produzione/costi diretti GAS+BC, 8 sotto-progetti Apps Script indipendenti — MAI onboardato | 2026-09-01: audit tutto-repo (6 agenti sola lettura) → 53 rilievi veri (non i 200 richiesti); Tier1 8/8+2 in esecuzione (incl. funzione corrotta dallo scrub di un secret — scoperta leggendo per intero, non col grep); Tier2 17/17, Tier3 12/20, Tier4 3/8; PR mergiata; 3 idee extra dopo AskUserQuestion | docs/campo/2026-09-01-repo-q-audit-tutto-il-repo-53-voci.md |
| REPO-S | monorepo TypeScript privato: configuratore prodotto su misura + back-office multi-tenant (motore geometrico, cascata prezzi, Postgres/Prisma, React) — **primo bersaglio TypeScript** del metodo, NON-GAS (il precedente non-GAS e REPO-N, Python) | 2026-09-03: standard `.claude/` adottato, caccia errori 7 corsie parallele in sola lettura -> 87 reperti (3 P0) + 38 bandiere di dominio, 14 correzioni con banco; agenti GAS 0/6 utilizzabili, metodo e patterns 100% applicabili; 6 proposte al canone | docs/campo/2026-09-03-repo-s-caccia-errori-monorepo-typescript.md |
| REPO-R | progetto onboardato GAS+Sheets (ingestione file gestionale) | 2026-09-02/03: /design-doc→/goal→banco 27→avversariale→PR mergiata. 4 proposte al canone: vm realm nel banco, avversariale che paga, tolleranza derivata, quale-sistema-lo-produce | docs/campo/2026-09-03-repo-r-quattro-proposte-canone.md |
| REPO-T | codice citato in repo senza riga d'indice (da assegnare: vedere repos.key) | da censire | — |
| REPO-X | codice citato in repo senza riga d'indice (da assegnare: vedere repos.key) | da censire | — |
| REPO-Z | codice citato in repo senza riga d'indice (da assegnare: vedere repos.key) | da censire | — |
| REPO-W | fatture estere GAS+BC (registrazione via API BC) | 2026-09-03: fase 2 chiusa (204), 41/41 test, 15 cicli log→analisi→commit. Installazione AI_Programmer PARZIALE (post-mortem e registro errori assenti). **Secondo tempo**: due misure (0,2% contro 51,3%) ribaltano una richiesta già inviata a un fornitore esterno — 8 ore non acquistate. 5 regole al canone in tutto: identità prima di configurare, sonda che distingue zero da domanda sbagliata, mai `&&` dopo una pipe, `$select` condiviso come interfaccia, nessun impegno esterno con verifica aperta | docs/campo/2026-09-03-repo-w-fatture-estere-fase2.md + docs/campo/2026-09-03-repo-w-misure-ribaltano-richiesta.md |
