# Quarto ventaglio — giri 26-30 (2026-09-24)

Tre ventagli (docs/giri/2026-09-23-notte/, docs/giri/2026-09-24-terzo/) hanno letto per aree, per lenti
trasversali, e mettendo alla prova il turno, i banchi, le skill, il tempo e i pattern. Circa 100 rilievi,
curati o dichiarati, dettaglio nel SAL (voce 18°). Questo ventaglio guarda cinque cose che nessuno ha
ancora provato: chi arriva per la prima volta, i guasti delle dipendenze, i contratti d'uscita, il grafo
come strumento di navigazione, i ganci di sicurezza visti da un avversario.

## Lenti
| # | Lente | La domanda |
|---|---|---|
| Q1 | Il primo giorno | Chi arriva (persona o agente) segue README.md, AGENTS.md e docs/MANUALE-OPERATIVO.md alla lettera, in una HOME vuota e in un clone fresco: install, help, i primi comandi che i documenti prescrivono. Dove si rompe, dove un documento dice un comando o un esito che non c'è? |
| Q2 | Il guasto | Una dipendenza alla volta si guasta (gh che fallisce, rete giù, jq o python3 assenti, disco in sola lettura, remote che rifiuta il push, Ollama muto) sotto gli strumenti principali (night-shift/*.sh, tools/sync-repo.sh, tools/bootstrap-app.sh, tools/suite.sh, llm/*.sh). Lo strumento lo dice (sesto patto) o resta muto, o peggio verde? |
| Q3 | I contratti d'uscita | Ogni tools/*.sh, llm/*.sh e night-shift/*.sh che dichiara nell'intestazione i suoi codici d'uscita («Esce:», «Exit», «rc») o un «Uso:»: con argomenti sbagliati, input vuoto, cartella inesistente fa quello che dichiara? I chiamanti leggono i codici giusti? |
| Q4 | Il grafo come navigazione | CLAUDE.md §7 dice: prima di sfogliare, `graphify query`. Dieci domande tipiche di un agente (dov'è il lock del turno, chi usa ai_timeout, dove si decide il budget, dove si maschera un segreto, ...): il grafo risponde, con riferimenti file:L giusti? È fresco rispetto al codice? Dove manda fuori strada? |
| Q5 | I ganci come avversario | tools/clasp-block-hook.sh, tools/pre-commit.sh, tools/privacy-check.sh, tools/lente-sicurezza.sh, l'allowlist di night-shift/lib.sh: si cercano le forme che li aggirano (clasp via npx, via bash -c, con un percorso, con virgolette, in un heredoc, in una sostituzione; un segreto spezzato su due righe; un file rinominato). Il blocco tiene? |

## Regole
- Clone: `git clone -q /home/user/AI_Programmer <scratchpad>/clone-Q<n>` e lavora LÌ. Il codice del repo
  vero non si tocca.
- Il rapporto si scrive PRIMA di rispondere, dentro il repo vero ma in una cartella ignorata da git:
  `/home/user/AI_Programmer/docs/giri/2026-09-24-quarto/grezzi/Q<n>.md` (skill n-giri §2, lezione E-044).
  È l'unico file che il giro scrive fuori dal clone.
- Ogni rilievo: Oggi (file:riga letti davvero) · Provato eseguendo (comando e uscita vera) · Manca ·
  Proposta. Un rilievo non provato si dichiara «non provato».
- Tetto 6 rilievi per lente, in ordine di gravità. «Nulla in questa lente» è un esito valido.
- Niente segreti: mai stampare valori di chiavi o token, nemmeno finti presi da file veri.
- Mai `clasp push`/`clasp deploy`. Mai `rm -rf` su una variabile che non hai creato tu con mktemp nello
  stesso script (E-044). Mai `pkill -f` con un'espressione che compare nella tua stessa riga di comando:
  si uccide per PID (il giro V1 si è ucciso la shell così).
- Un sabotaggio di un modulo Python si esegue con `PYTHONPYCACHEPREFIX=$(mktemp -d)` (E-047).
- Il verdetto di un sabotaggio si scrive dopo averne letto l'uscita (E-043).
