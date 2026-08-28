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
| REPO-E | Repo esterno con progetti Google Apps Script reali (cartella `gas-src/`, coincidenza di nome con REPO-A — repo diverso, confermato da Luca) — oracolo per la skill `controllo-gestione` (4° ciclo, set 1, 2026-08-23; 5° ciclo, set 1 giro 4, 2026-08-23): scostamento standard/effettivo, riconciliazione magazzino, roll-forward cespiti, indici di crisi, scadenzario aging clienti/fornitori | `.claude/skills/controllo-gestione/SKILL.md` |
| REPO-F | Progetto GAS/BC reale con una dashboard web (`Dashboard.html`) e un flusso di consegne — caso di campo del 2026-08-24: bug reale (una funzione di backfill mai attivata da un trigger) trovato per indagine diretta, non da una skill invocata | `SAL.md`, voce del 2026-08-24 |
| REPO-G | repo del bilancio periodico (CE per BU, SP, quadrature) | attiva, MAI onboardata — onboarding o esclusione = decisione aperta (DEBITI 2026-08-24); bonificata nei file 2026-08-24, storia git da purgare o accettare (DEBITI) |
| REPO-H | repo cespiti GAS+BC standalone (FA Ledger + G/L da BC, report mensile) | prima segnalazione 2026-08-27: 13 rilievi, 12 fix, banco Node 19/19 | docs/campo/2026-08-27-revisione-cespiti-gas-bc.md |
| REPO-I | controlli trimestrali di bilancio GAS+BC (97 file, ~850 asserzioni preesistenti) | ciclo 2026-08-27: 30 agenti, 19 findings ALTA corretti, 915/915 test, PR #97 — report docs/campo/2026-08-27-controlli-trimestrali.md | docs/campo/2026-08-27-controlli-trimestrali.md |
| REPO-J | Gestione-ordini-Bricoman (ordini EDI fornitori, GAS+BC, 12 file) | audit 50 agenti 2026-08-28: 153 rilievi, 13 confermati, 2 smentiti | docs/campo/2026-08-28-bricoman-50-agenti.md |
| REPO-K | Dashboard web GAS+BC per gestione ordini multi-categoria (foglio "aperti" e foglio storico paralleli, sync automatico) — già citato informalmente come "dossier SD" in `famiglie-difetti.md` e in `SAL.md` (voce 2026-08-28) prima che questo codice esistesse | dossier 86 rilievi/25 idee (`docs/campo/2026-08-28-sd-dashboard-dossier.md`), tutti implementati in sessione continua — report `docs/campo/2026-08-28-repo-k-dal-dossier-a-tutti-i-fix.md` |
| REPO-J | Gestione-ordini-Bricoman (ordini EDI fornitori, GAS+BC, 12 file) | audit 50 agenti 2026-08-28: 153 rilievi, 13 confermati, 2 smentiti (`docs/campo/2026-08-28-bricoman-50-agenti.md`) — 25 fix applicati in sessione continua, verificati con node prima di ogni commit | docs/campo/2026-08-28-bricoman-dal-audit-ai-fix.md |
| REPO-K | dashboard web GAS+BC per gestione ordini multi-categoria (SD) | dossier 86 rilievi + 25 idee, TUTTI implementati in sessione continua 2026-08-28 | docs/campo/2026-08-28-repo-k-dal-dossier-a-tutti-i-fix.md |
| REPO-L | Unicredit_Factoring (cessione fatture, GAS+BC, file fixed-width TXT per banca) | audit 30 agenti 2026-08-28: 54 rilievi, 9 confermati, 45 NON VERIFICATI, 0 smentiti · SECRET in git history (da ruotare) | docs/campo/2026-08-28-unicredit-factoring-30-agenti.md |
| REPO-M | Associazione-Energikal (bilancino trimestrale, GAS+BC, 27 file .gs) | revisione 15+20 rilievi 2026-08-28: CRITICA credenziali Azure in git history + conto C/G non corrispondente CSV + backlog completo | docs/campo/2026-08-28-energikal-analisi-revisione.md |
| REPO-N | gestionale parrocchie (Flask+SQLite, privato) | 50 passate 2026-08-28: 13 difetti banco, 10 commit, scadenze 10/10 | docs/campo/2026-08-28-parrocchie-fase1.md |

## Come usarlo

- **Prima di citare un repo esterno in un file versionato**: controlla questa tabella —
  se il repo ha già un codice, riusalo; se è un repo nuovo, aggiungi una riga qui E
  registra la mappatura reale in `night-shift/repos.key` (locale, sulla macchina di
  chi possiede il repos.key — questa sessione non può scriverci).
- **Se un codice qui elencato non corrisponde più a quanto scritto altrove** (un file
  citato è stato spostato, un dettaglio è cambiato): è una discrepanza reale, aggiorna
  questa riga E il file di origine, non solo uno dei due.
