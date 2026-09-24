# Secondo ventaglio — giri 11-20 (notte del 2026-09-23/24)

Il primo ventaglio (00-BRIEF.md) ha letto per AREE × tre lenti. Dopo le cure Q1-Q32 (SAL, voce 18°),
questo ventaglio legge per LENTI TRASVERSALI: ogni lente attraversa tutto l'hub e cerca una classe
di errore che le aree da sole non vedono. Stesse regole del primo brief, più una: ogni giro lavora
in un CLONE nello scratchpad, mai nel repo vero.

## Lenti trasversali
| # | Lente | La domanda |
|---|---|---|
| T1 | Il satellite appena nato | Installa lo standard in una repo vuota (bootstrap in un clone, gh finto) e USA il metodo da lì: ogni hook, ogni lente, ogni comando che il CLAUDE.md dei satelliti promette gira davvero nel satellite, o presuppone l'hub? |
| T2 | Stato condiviso e concorrenza | Percorsi fissi in /tmp, file di stato in ~ o in .git, lock, contatori: cosa si pesta quando girano due sessioni, due turni, due banchi insieme? Cosa resta sporco dopo un SIGKILL? |
| T3 | Mac contro Linux | Il turno gira sul Mac (bash 3.2, BSD sed/grep/date/stat, niente timeout): quali righe funzionano solo su GNU/Linux, dove i banchi girano? |
| T4 | Documenti contro codice | README, METHOD, docs/system.md, night-shift/README, docs/MANUALE-OPERATIVO, docs/benvenuto: cosa dicono che il codice non fa più dopo stanotte (e prima)? |
| T5 | Segreti e accessi | Ogni via per cui una credenziale o un accesso può finire in argv, log, output, commit, PR pubblica, prompt a un modello |
| T6 | La coda piccola | Verificare (ESEGUENDO, in un clone) le voci piccole rimaste: vedi sotto |

### T6 — le voci piccole da verificare, una per una
1. il censore misura la quarantena dalla creazione della PR, non dall'ultimo push;
2. `night-shift/caccia-lente.sh` legge LENTE_CERCA e non lo usa;
3. `tools/copia-hook.sh` mette `.mirror-boundaries` nel .gitignore dei residui;
4. `tools/metodo-reminder-hook.sh` sullo Stop forza la continuazione della sessione;
5. il contatore del SAL (promemoria dopo N edit) è condiviso fra sessioni;
6. `tools/onboard-repo.sh` usa `\b` in una regex (non portabile su BSD grep);
7. `tools/install-garante.sh` stampa ✅ anche quando jq fallisce;
8. descrizioni delle skill troppo lunghe (oltre il limite del frontmatter?).

## Regole
- Clone: `git clone -q /home/user/AI_Programmer <scratchpad>/clone-T<n>` e lavora LÌ. Mai scrivere
  in /home/user/AI_Programmer.
- Ogni rilievo: Oggi (file:riga letti davvero) · Provato eseguendo (comando e uscita vera) · Manca ·
  Proposta. Un rilievo non provato si dichiara «non provato», non si presenta come fatto.
- Tetto 6 rilievi per lente, in ordine di gravità. «Nulla in questa lente» è un esito valido.
- Scrivi il file PRIMA di rispondere: `<scratchpad>/giri2/T<n>.md`.
- Niente segreti: mai stampare valori di chiavi o token, nemmeno finti presi da file veri.
