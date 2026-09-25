# Ottavo ventaglio — giri 46-50 (2026-09-25)

Sette ventagli (in `docs/giri/`) hanno letto per aree e per lenti trasversali: circa 220 rilievi, curati o dichiarati
(SAL, voce 18°). Questo ventaglio guarda cinque cose nuove.

## Lenti
| # | Lente | La domanda |
|---|---|---|
| O1 | Il modello come avversario | Tutto ciò che un cervello restituisce (`night-shift/risolvi-issue.sh`, `night-shift/agente.sh`, `night-shift/caccia-miglioria.sh`, `night-shift/caccia-lente.sh`, `tools/cervello-impara.sh`, il censore, la lente sicurezza) è testo non fidato. Cosa succede se risponde con JSON rotto, un file enorme, un percorso `../`, un nome di funzione con metacaratteri, un blocco di codice che contiene altro codice, istruzioni scritte dentro il corpo di un'issue che finiscono nel prompt e poi in un comando? Dove un'uscita del modello arriva a `eval`, a `bash -c`, a un percorso di scrittura, a un commit, a un commento pubblico? |
| O2 | GitHub come avversario | `gh` risponde con liste troncate (il `--limit` di default è 30), errori a metà, rate limit, JSON con campi mancanti, titoli e rami con caratteri ostili (apici, `$( )`, a capo, emoji). Chi legge quelle liste le prende per complete? Un titolo di issue o un nome di ramo arriva mai a una shell? Un errore di `gh` si legge mai come «niente»? |
| O3 | La crescita | Lo stesso hub fra un anno: log, `SAL.md`, `SAL-ARCHIVIO.md`, il REGISTRO, `graphify-out/graph.json`, `metrics/*.csv`, il cervello, le code. Chi rilegge un file intero a ogni ciclo, chi non ruota, chi ha un tetto nascosto (un `head -N` che taglia i dati nuovi, un `tail` che ne perde di vecchi), chi diventa lento in modo quadratico. Misura con file gonfiati artificialmente nel clone, non stimare. |
| O4 | Le versioni degli strumenti | Le versioni vere del Mac e di Linux: git (Apple git 2.39 sul Mac; `--show-current` da 2.22, `branch --format`, `-c` e i pathspec magici), jq (1.6 contro 1.7: `ltrimstr`, `--arg` e i numeri, `@sh`), python3 (3.9 di sistema: niente `match`, `str.removeprefix` da 3.9, `zoneinfo`), gh (i campi di `--json`), curl, graphify. Quali forme usate stanotte e prima richiedono una versione che il Mac di serie non ha? Prova con le versioni che puoi installare nel clone o per lettura della documentazione, e dichiaralo. |
| O5 | Le azioni verso l'esterno, ripetute | Ogni azione che esce dalla macchina (issue, commento, PR, label, ramo remoto, mail, notifica, file fuori dal repo) fatta due volte, o a ogni ciclo, o dopo un fallimento a metà. È idempotente? Si accumula (dieci issue uguali, cento rami, la stessa mail ogni mattina)? Si ritira quando la causa sparisce? Il secondo ventaglio l'ha guardato in locale (S2): qui si guarda verso GitHub e la posta. |

## Regole
- Clone: `git clone -q /home/user/AI_Programmer <scratchpad>/clone-O<n>` e lavora LÌ. Il codice del repo vero non
  si tocca.
- Il rapporto si scrive PRIMA di rispondere, dentro il repo vero ma nella cartella ignorata:
  `/home/user/AI_Programmer/docs/giri/2026-09-25-ottavo/grezzi/O<n>.md` (skill n-giri §2). È l'unico file che il giro
  scrive fuori dal clone.
- Ogni rilievo: Oggi (file:riga letti davvero) · Provato eseguendo (comando e uscita vera) · Manca · Proposta. Un
  rilievo non provato si dichiara «non provato»; «provato per lettura» quando una forma non si può eseguire qui.
- Tetto 6 rilievi per lente, in ordine di gravità. «Nulla in questa lente» è un esito valido.
- Niente segreti: mai stampare valori di chiavi o token, nemmeno finti presi da file veri.
- Mai `clasp push`/`clasp deploy`. Mai `rm -rf` su una variabile che non hai creato tu con mktemp nello stesso
  script (E-044). Mai `pkill -f` o `kill` su processi che non hai lanciato tu; un albero di processi si uccide con
  STOP al padre, poi i figli, poi il padre (E-049).
- **Niente rete verso GitHub o altri servizi**: `gh` e i cervelli si fingono con stub nel clone. Nessuna issue,
  commento, PR o mail vera.
- MAI scrivere fuori dal clone e dal rapporto: HOME e TMPDIR dentro il clone. Niente pacchetti installati nel sistema
  (per O4, versioni diverse solo dentro il clone, per esempio in un venv o in una cartella `bin` del clone).
- Un sabotaggio di un modulo Python si esegue con `PYTHONPYCACHEPREFIX=$(mktemp -d)` (E-047). Il verdetto di un
  sabotaggio si scrive dopo averne letto l'uscita (E-043).
- Una scelta di dominio (cosa DEVE fare lo strumento) non si decide: si scrive come domanda, con perché conta, cosa
  può dire il sistema, cosa solo una persona.

## Modello
Tutti i giri sullo stesso modello della sessione che orchestra.
