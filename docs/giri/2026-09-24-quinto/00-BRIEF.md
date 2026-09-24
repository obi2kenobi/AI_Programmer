# Quinto ventaglio — giri 31-35 (2026-09-24)

Quattro ventagli (docs/giri/2026-09-23-notte/, 2026-09-24-terzo/, 2026-09-24-quarto/) hanno letto per
aree, per lenti trasversali, mettendo alla prova il turno, i banchi, le skill, il tempo, i pattern, il primo
giorno, i guasti, i contratti d'uscita, il grafo e i ganci: circa 130 rilievi, curati o dichiarati (SAL,
voce 18°). Questo ventaglio guarda cinque cose nuove.

## Lenti
| # | Lente | La domanda |
|---|---|---|
| R1 | La memoria del sistema | SAL.md (e il suo indice), DEBITI.md, docs/errori/REGISTRO.md, cervello/, docs/campo/: voci che si contraddicono, debiti saldati nel codice ma aperti sulla carta (o il contrario), rimandi a file o righe che non esistono più, indici che non corrispondono. `tools/debiti-riapertura.sh` e `tools/sal-indice.sh` dicono il vero? |
| R2 | Il satellite end-to-end | Una repo satellite finta (locale, bare come remoto, gh finto): `tools/onboard-repo.sh`, `tools/sync-repo.sh --standard`, `tools/bootstrap-app.sh`. Lo standard arriva intero E funziona nel satellite: gli hook scattano davvero (clasp-block, pre-commit), la suite del satellite gira, `tools/garante-standard.sh` dice il vero? |
| R3 | Gli oracoli come strumenti | Ogni `tools/*.py` di calcolo (indici, riconciliazione, scostamento, rollforward, aging, DSO…): input degeneri (vuoto, zero, negativo, NaN, stringa, colonna mancante, file enorme), CLI, codici d'uscita, arrotondamenti, messaggi. Solo il MECCANICO: una scelta di dominio (segno, soglia, formula) si scrive come domanda, mai si decide. |
| R4 | I consumatori dei log | Chi legge il log del turno, metrics/gate.csv, i report (tools/dashboard.py, status-page, morning-digest, docs/eventi.md, caccia-registro): ogni firma che cercano esiste ancora nel codice che scrive? Stanotte sono cambiate e nate molte righe di log (LENTE MUTA, coda ILLEGGIBILE, MANCA …, sentinella, rianima_ollama): chi le conta, chi le perde, chi conta ancora firme morte? |
| R5 | Giorno e notte sulla stessa repo | Il turno (self-pull, reset, rami night/, lock) e una sessione di giorno sullo stesso hub o satellite: cosa succede se la sessione ha modifiche non committate, un ramo omonimo, un commit non pushato, un merge del grafo (driver graphify), un SAL con merge union? Si perde lavoro? Il turno lo dice? |

## Regole
- Clone: `git clone -q /home/user/AI_Programmer <scratchpad>/clone-R<n>` e lavora LÌ. Il codice del repo
  vero non si tocca.
- Il rapporto si scrive PRIMA di rispondere, dentro il repo vero ma nella cartella ignorata:
  `/home/user/AI_Programmer/docs/giri/2026-09-24-quinto/grezzi/R<n>.md` (skill n-giri §2). È l'unico file
  che il giro scrive fuori dal clone.
- Ogni rilievo: Oggi (file:riga letti davvero) · Provato eseguendo (comando e uscita vera) · Manca ·
  Proposta. Un rilievo non provato si dichiara «non provato».
- Tetto 6 rilievi per lente, in ordine di gravità. «Nulla in questa lente» è un esito valido.
- Niente segreti: mai stampare valori di chiavi o token, nemmeno finti presi da file veri.
- Mai `clasp push`/`clasp deploy`. Mai `rm -rf` su una variabile che non hai creato tu con mktemp nello
  stesso script (E-044). Mai `pkill -f` con un'espressione che compare nella tua riga di comando.
- MAI scrivere fuori dal clone e dal rapporto: niente TMPDIR inesistenti, niente strumenti lanciati da root
  su percorsi assoluti che non sono tuoi (nel quarto ventaglio un giro ha lasciato `/CLAUDE.md` nel
  container, e non si è potuto togliere). Se uno strumento sotto prova potrebbe scrivere altrove, dagli un
  TMPDIR dentro il clone.
- Un sabotaggio di un modulo Python si esegue con `PYTHONPYCACHEPREFIX=$(mktemp -d)` (E-047). Il verdetto
  di un sabotaggio si scrive dopo averne letto l'uscita (E-043).
