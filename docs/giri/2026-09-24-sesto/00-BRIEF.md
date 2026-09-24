# Sesto ventaglio — giri 36-40 (2026-09-24)

Cinque ventagli (docs/giri/2026-09-23-notte/, 2026-09-24-terzo/, -quarto/, -quinto/) hanno letto per aree, per
lenti trasversali, il turno, i banchi, le skill, il tempo, i pattern, il primo giorno, i guasti, i contratti
d'uscita, il grafo, i ganci, la memoria, il satellite, gli oracoli, i consumatori dei log, giorno e notte:
circa 160 rilievi, curati o dichiarati (SAL, voce 18°). Questo ventaglio guarda cinque cose nuove.

## Lenti
| # | Lente | La domanda |
|---|---|---|
| S1 | Le istruzioni all'operatore | CLAUDE.md §3 «What you hand to a human to run is code»: ogni blocco di comandi che il repo dà a una persona (docs/MANUALE-OPERATIVO.md, README, night-shift/README.md, PROJECT.md, le uscite degli strumenti che dicono «lancia X», i corpi delle issue e delle PR che il turno scrive, le skill) gira davvero, incollato in zsh senza `interactive_comments`? Commenti in riga, percorsi che non esistono, opzioni sbagliate, uscite attese dichiarate senza la fonte `file:riga`. |
| S2 | Il secondo giro | Ogni strumento che scrive, lanciato DUE volte di fila sulla stessa cartella (installa-citati, copia-hook, sal-indice, onboard/sync su un satellite finto, bootstrap-app, garante-standard, debiti-riapertura, caccia-registro, graphify-spina, allinea_hub): il secondo giro è un no-op? Righe duplicate, file riscritti a vuoto, commit vuoti, contatori che raddoppiano, un «fatto» detto due volte. |
| S3 | I percorsi ostili | Una cartella di lavoro con uno spazio, una lettera accentata, un apice o un trattino iniziale nel percorso (e un file con lo spazio nel nome): gli strumenti del turno, della suite e dell'installazione reggono? Variabili senza virgolette, `for f in $(…)`, `xargs` senza `-0`, `find | while read` senza `IFS=`/`-r`, python che spezza su spazi. |
| S4 | L'interruzione a metà | Uno strumento che scrive, ucciso a metà (SIGTERM, poi SIGKILL) nel punto peggiore: cosa resta? File scritti a metà invece che atomici (scrivi-e-rinomina), lock lasciati presi, cartelle temporanee fuori da un `trap`, un indice git con metà del lavoro in stage, un ramo creato senza commit. E al giro dopo: si riprende da solo o resta bloccato? |
| S5 | Le cure della notte sotto la lente del Mac | Il diff di stanotte (`git diff origin/main...HEAD`, circa 190 commit, provati solo su Linux) letto come lo eseguirebbe il Mac: bash 3.2 (niente `declare -A`, `mapfile`, `${x,,}`, `wait -n`, `local -n`), BSD (`sed -i ''`, `grep -P`, `date -d`, `stat -c`, `readlink -f`, `find -printf`, `timeout`, `xargs -r`), il python3 di sistema (versione minima, `match`, f-string annidate), `ps`/`pkill` BSD. Solo ciò che il diff di stanotte ha AGGIUNTO: il resto l'ha già letto T3. |

## Regole
- Clone: `git clone -q /home/user/AI_Programmer <scratchpad>/clone-S<n>` e lavora LÌ. Il codice del repo
  vero non si tocca.
- Il rapporto si scrive PRIMA di rispondere, dentro il repo vero ma nella cartella ignorata:
  `/home/user/AI_Programmer/docs/giri/2026-09-24-sesto/grezzi/S<n>.md` (skill n-giri §2). È l'unico file
  che il giro scrive fuori dal clone.
- Ogni rilievo: Oggi (file:riga letti davvero) · Provato eseguendo (comando e uscita vera) · Manca ·
  Proposta. Un rilievo non provato si dichiara «non provato». S5 può dichiarare «provato per lettura» quando
  una forma non si può eseguire qui (bash 3.2, BSD): lo scrive così.
- Tetto 6 rilievi per lente, in ordine di gravità. «Nulla in questa lente» è un esito valido.
- Niente segreti: mai stampare valori di chiavi o token, nemmeno finti presi da file veri.
- Mai `clasp push`/`clasp deploy`. Mai `rm -rf` su una variabile che non hai creato tu con mktemp nello
  stesso script (E-044). Mai `pkill -f` o `kill` su processi che non hai lanciato tu: in S4 uccidi solo i PID
  che hai avviato, per numero.
- MAI scrivere fuori dal clone e dal rapporto: niente TMPDIR inesistenti, niente strumenti lanciati su
  percorsi assoluti che non sono tuoi. Se uno strumento sotto prova potrebbe scrivere altrove (in `$HOME`, in
  `/tmp` fisso, alla radice), dagli HOME e TMPDIR dentro il clone.
- Un sabotaggio di un modulo Python si esegue con `PYTHONPYCACHEPREFIX=$(mktemp -d)` (E-047). Il verdetto
  di un sabotaggio si scrive dopo averne letto l'uscita (E-043).
- Una scelta di dominio (cosa DEVE fare lo strumento) non si decide: si scrive come domanda, con perché
  conta, cosa può dire il sistema, cosa solo una persona.

## Modello
Tutti i giri sullo stesso modello della sessione che orchestra.
