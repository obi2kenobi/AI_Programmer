# Settimo ventaglio — giri 41-45 (2026-09-25)

Sei ventagli (in `docs/giri/`: la notte del 23, poi terzo, quarto, quinto e sesto del 24) hanno letto per aree,
per lenti trasversali, il turno, i banchi, le skill, il tempo, i pattern, il primo giorno, i guasti, i contratti
d'uscita, il grafo, i ganci, la memoria, il satellite, gli oracoli, i log, giorno e notte, le istruzioni
all'operatore, il secondo giro, i percorsi ostili, l'interruzione, il Mac. Circa 190 rilievi, curati o dichiarati
(SAL, voce 18°). Questo ventaglio guarda cinque cose nuove.

## Lenti
| # | Lente | La domanda |
|---|---|---|
| V1 | Due giudici, due regole | La stessa regola applicata da più giudici: `tools/suite.sh`, `gate_banchi` ed `esegui_verifica` (`night-shift/lib.sh`), il pre-commit (`tools/pre-commit.sh`), il censore (`night-shift/revisore.sh`), il morning-gate, la caccia. Dove due giudici dicono cose diverse sullo stesso oggetto: una regola copiata che è divergita, liste di esclusioni diverse, soglie diverse, un'allowlist qui e non là. Esempio già curato stanotte: la suite pretendeva «N OK, 0 FAIL», `gate_banchi` no. |
| V2 | Il codice d'uscita lungo la catena | Un rc che si perde fra chi lo produce e chi lo legge: `local x=$(…)` che maschera l'rc, pipe senza `pipefail`, `$( )` dentro una condizione, `|| true` che copre un errore vero, `set -e` che non scatta in una funzione chiamata da `if`. E i codici dichiarati (l'«uso» degli strumenti, i commenti «esce 2 se…») contro quelli veri, e il chiamante che legge 1 dove lo strumento dice 2. |
| V3 | Il calendario | Mezzanotte, UTC e ora locale: `date +%F` calcolato due volte a cavallo della mezzanotte, segni «fatto oggi» e file del giorno, età di 24 o 48 ore calcolate su mtime (BSD e GNU), il cambio dell'ora, gli orari di launchd (ora locale) contro quelli dei Routine e di GitHub (UTC). Un turno che parte alle 23:59 e finisce alle 00:30: in che giorno scrive? |
| V4 | La lingua e la codifica | `LC_ALL=C` contro UTF-8: le lettere accentate e i caratteri «», —, ⛔ in `grep`, `sed`, `awk`, `tr`, `wc -c`/`-m`, `cut -c`; l'ordinamento; la codifica di default di python (3.9 sul Mac, dipende dal locale); i messaggi italiani che un consumatore cerca con una regex; il launchd, che parte senza `LANG`. |
| V5 | Il budget della suite | L'ultima suite ha usato l'83% del budget di `.night-verify` (soglia della sentinella 70%, `tools/suite.sh:61-70`). Quali banchi pesano di più (misura, non stima); gli `sleep` che si possono accorciare senza perdere la prova; il lavoro rifatto (cloni dell'hub in molti banchi, la stessa batteria due volte). **Nessuna proposta può togliere una prova**: solo farla costare meno, o dire che il budget va rivisto (e questa è una domanda per Luca). |

## Regole
- Clone: `git clone -q /home/user/AI_Programmer <scratchpad>/clone-V<n>` e lavora LÌ. Il codice del repo
  vero non si tocca.
- Il rapporto si scrive PRIMA di rispondere, dentro il repo vero ma nella cartella ignorata:
  `/home/user/AI_Programmer/docs/giri/2026-09-25-settimo/grezzi/V<n>.md` (skill n-giri §2). È l'unico file
  che il giro scrive fuori dal clone.
- Ogni rilievo: Oggi (file:riga letti davvero) · Provato eseguendo (comando e uscita vera) · Manca ·
  Proposta. Un rilievo non provato si dichiara «non provato»; «provato per lettura» quando una forma non si
  può eseguire qui (Mac, launchd).
- Tetto 6 rilievi per lente, in ordine di gravità. «Nulla in questa lente» è un esito valido.
- Niente segreti: mai stampare valori di chiavi o token, nemmeno finti presi da file veri.
- Mai `clasp push`/`clasp deploy`. Mai `rm -rf` su una variabile che non hai creato tu con mktemp nello
  stesso script (E-044). Mai `pkill -f` o `kill` su processi che non hai lanciato tu.
- MAI scrivere fuori dal clone e dal rapporto. Se uno strumento sotto prova potrebbe scrivere altrove (in
  `$HOME`, in `/tmp` fisso, alla radice), dagli HOME e TMPDIR dentro il clone. Niente pacchetti installati
  nel sistema (nel sesto ventaglio un giro l'ha fatto).
- Per V3, l'ora si finge (`faketime` se c'è, oppure una `date` finta in testa al PATH, oppure `TZ=`), mai
  cambiando l'orologio del sistema.
- Un sabotaggio di un modulo Python si esegue con `PYTHONPYCACHEPREFIX=$(mktemp -d)` (E-047). Il verdetto
  di un sabotaggio si scrive dopo averne letto l'uscita (E-043).
- Una scelta di dominio (cosa DEVE fare lo strumento) non si decide: si scrive come domanda, con perché
  conta, cosa può dire il sistema, cosa solo una persona.

## Modello
Tutti i giri sullo stesso modello della sessione che orchestra.
