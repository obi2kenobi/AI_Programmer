# Sesto ventaglio — consolidamento (2026-09-24)

Brief: `docs/giri/2026-09-24-sesto/00-BRIEF.md`. Cinque lenti, un giro ciascuna, ognuno in un clone:
- S1: le istruzioni all'operatore;
- S2: il secondo giro;
- S3: i percorsi ostili;
- S4: l'interruzione a metà;
- S5: le cure della notte sotto la lente del Mac.

I rapporti grezzi sono in `grezzi/`, ignorata da git (skill n-giri §2). Dettagli di ogni cura nel SAL, voce 18°,
righe «Sesto ventaglio».

## Esito

- **30 rilievi**, 6 per giro. Sono provati eseguendo, tranne dove il giro ha dichiarato «per lettura»: in S5 le
  forme che solo il Mac esegue (awk, grep e regex di Apple, sandbox-exec, launchctl), in S3 R2 il controllo E-019.
- **Il Mac simulato di S5** è lo strumento nuovo del ventaglio:
  - bash 3.2.57 compilata dal sorgente;
  - sed e seq di Apple compilati da apple-oss-distributions;
  - python 3.9;
  - un PATH senza `timeout` né `setsid`.

  Con quello la suite dell'hub si fermava al 35° file su 183. Dopo le cure di S5 R1 fa 184/184 anche lì. Non è un
  Mac: awk, grep, find, stat, date e ps restano GNU, e il motore regex del sed è glibc.
- **Curati**: 29. Di questi, 3 sono solo in parte, e il resto è dichiarato:
  - S2 R4: il «no» di Luca a una PR non è memoria (D-S2-1);
  - S3 R2: solo il plist del turno e il gancio del garante;
  - S3 R6: i banchi col percorso fra apici dentro `python -c`, `bash -c` o `node -e` restavano, tranne dashboard e
    ai-timeout. Curati dopo il consolidamento (sezione più sotto): ora S3 R6 è intero.

  Ogni cura ha il suo banco rosso prima e il sabotaggio rosso dopo.
- **Esclusi** (domanda di dominio): S5 R3, il censore nella sandbox senza rete. Serve prima la misura sul Mac.
- **Domande nuove in DEBITI**:
  - S2 D-S2-1: la PR di riallineo chiusa senza merge;
  - S3 R2: gli spazi nei percorsi del Mac;
  - S3 R3: i file con lo spazio nei GAS;
  - S4 D2: l'`index.lock` orfano;
  - S5 D1: localhost nella sandbox del censore;
  - S5 D2: il Mac di riferimento.

  La S4 D1 (l'archivio che rifiuta un doppione) si è sciolta nel meccanico: una voce identica già in archivio non si
  riaccoda, e nessuna voce diversa viene rifiutata.
- **Smentite**: una, parziale. S2 R6 diceva che la `storia` di caccia-registro non ha lettori. Invece
  `tools/dashboard.py` la legge per il censimento (è il rilievo R4 R1 del quinto ventaglio).
- **Suite**: 187/187 all'ultima consegna, con cinque banchi nuovi:
  - `tests/test-a-capo-finale.sh`;
  - `tests/test-blocchi-operatore.sh`;
  - `tests/test-grafo-notturno.sh`;
  - `tests/test-installa-citati.sh`;
  - `tests/test-eval-review.sh` (dal merge di main).

## Temi trasversali

1. **Quello che si dà a una persona è codice, e non girava** (S1, S3). Casi:
   - l'issue `[night-verify]` chiedeva di incollare righe che chiudono il terminale;
   - cinque blocchi con commenti in riga non giravano in zsh;
   - la cura del bootstrap aveva un segnaposto che lo strumento sapeva;
   - il rimedio del garante mancava dell'argomento;
   - la skill di consegna insegnava un ramo che nessun giudice vede.

   CLAUDE.md §3 ora ha una guardia (`tests/test-blocchi-operatore.sh`). Il resto dice comandi che girano: un blocco
   incollabile con `printf %q`, owner/repo veri.
2. **La scrittura sul posto e l'aggiunta senza guardare** (S2, S4). Casi:
   - SAL e archivio riscritti sul posto: un kill li lasciava vuoti o raddoppiati;
   - lo stato del registro troncato inventava una crescita del debito;
   - le righe accodate a un file senza a capo si incollavano all'ultima;
   - il segno «fatto oggi» si scriveva prima del lavoro.

   Cura comune: scrivi-e-rinomina, l'a capo prima di accodare, il segno a lavoro finito, il PID nel lock.
3. **Il secondo giro non è un no-op** (S2, S4). Casi:
   - l'onboard lavorava nella copia del turno: lo standard finiva nella PR della notte, oppure diceva «Fatto» su
     una skill mai arrivata;
   - `allinea_hub` toglieva il lavoro anche quando non allineava, e apriva un ramo a ogni ciclo;
   - i conteggi contavano le copie;
   - il presidio vedeva una contesa con sé stessi;
   - la PR già aperta veniva annunciata come nuova.
4. **Il percorso che nessuno aveva provato** (S3, S5). Casi:
   - lo spazio, l'apice, la bash 3.2, il sed del Mac, `setsid` e `timeout` assenti;
   - privacy-check saltava i termini con l'apostrofo, un leak vero con rc 0;
   - la caccia-lente leggeva un errore della shell come uscita dello strumento;
   - il risolutore mandava al modello un sorgente vuoto;
   - la lente della portabilità non si analizzava proprio sulla bash del Mac.

   Ora la portabilità si prova con `bash -n` su ogni script, anche con una bash 3.2 (`BASH_MAC`), e con sette forme
   nuove. La batteria degli avversari gira con un TMPDIR con lo spazio.

## Tassonomia

**Implementata**
- S1:
  - R1 (blocco incollabile nell'issue);
  - R2 (label del bootstrap);
  - R3 (rimedio del garante);
  - R4-R6 (blocchi, ramo `claude/`, citazione del morning-gate), con la guardia nuova.
- S2:
  - R1 (onboard in un clone suo);
  - R2 (a capo finale);
  - R3 (`allinea_hub` decide prima);
  - R4 (rc di `gh pr create`);
  - R5 (bootstrap interrotto);
  - R6 (sal-indice idempotente, conteggi veri, rinnovo del presidio).
- S3:
  - R1 (apostrofo in privacy-check);
  - R2 (plist e garante);
  - R3 (risolutore);
  - R4 (caccia-lente);
  - R5 (giri-avversari e giri-ignoranti);
  - R6 (python e basename negli strumenti, file `S3` del banco).
- S4:
  - R1 (SAL e archivio atomici);
  - R2 (`index.lock` orfano);
  - R3 (onboard);
  - R4 (resto del banco delle mutazioni);
  - R5 (stato del registro);
  - R6 (pass del grafo).
- S5:
  - R1 (tre banchi sul Mac);
  - R2 (heredoc in `$( )` e `bash -n` con la 3.2);
  - R4 (riga d'ambiente);
  - R5 (tre forme nella lente).

**Esclusa** (domanda di dominio)
- S5 R3: il censore nella sandbox senza rete (D1). Prima la misura sul Mac.

**Rinviata**
- S2 R4: la memoria del «no» di Luca (D-S2-1).
- La prova dal vivo sul Mac vero di tutto S5.

**Già coperta**
- Nessuna.

## Dopo il consolidamento: i rinviati di S3 R6

- **La suite intera da un hub con spazio e apice.** Ho misurato un clone dell'hub in `…/hub d'apice spazio`, con un
  `TMPDIR` ostile e ogni banco da solo. Cadevano otto banchi, e uno era muto: `tests/test-verifica-visiva-estrai-testo.sh`
  diceva «0 OK, 0 FAIL» con rc 0. Curati tutti (dettagli nel SAL), e ora il banco muto conta i suoi esiti. La prova
  resta a mano: una riga della notte che la rifaccia costa una seconda suite intera, e il tempo della notte è di Luca.
- **Il pre-commit** si faceva togliere un file dal controllo glifi con un «!x.md» in stage accanto a «x.md» (rc 0, glifo
  passato). La lettura del giro, su «!x.md» da solo, è smentita: il danno c'è solo con la coppia. Ora `:(top,literal)`.
- **Il trattino iniziale**, in sei strumenti: `tests/test-trattino-iniziale.sh`. `gas-gate.sh` proseguiva a giudicare la
  cartella del chiamante.

## Da fare a mano (non potevo)

- `rm -f /CLAUDE.md /claude-satellite.md` nel container (quarto ventaglio, invariato).
- In `/tmp` ci sono circa 160 `mutation-backup.*` orfani. Li ha lasciati `tests/test-mutation-atomico.sh`, che uccide
  il banco di proposito, prima della cura di S4 R4. Sono copie di strumenti dell'hub, senza segreti. Non li ho tolti.

## Anomalie non spiegate

- Durante la suite della consegna `28b88cd`, `docs/bc/README.md` nell'albero vero è stato riscritto col modello di
  prima di `tools/bc_index.py` (ore 21:15:54, commit alle 21:16:30). Il commit ha preso la versione giusta, che era
  già in stage. Rilanciata la suite ad albero pulito, non si è ripetuto. Non ho trovato il banco che scrive lì:
  **non riprodotto**, dichiarato.

## Errori miei in questo ventaglio

- **E-048** (nel REGISTRO, con guardia): un `cp` sopra `.githooks/pre-commit` senza guardarlo (quinto ventaglio,
  scoperto in questo turno di lavoro).
- Il mio aiuto di consegna faceva `git reset` durante un merge, e ha perso lo stato del merge di main. Rifatto.
- Prime stesure prese dai banchi o dai rilevatori prima del commit:
  - un `LOGIN=$(…)` nudo sotto `set -e`;
  - una pipe con `grep -q` (E-002) in `allinea_hub`;
  - un ripiego di `setsid` in una funzione senza `exec`, che rompeva `$!`;
  - un apostrofo in un commento dentro un programma awk fra apici;
  - un banco che cercava «neutralizzato» contro «NEUTRALIZZATI»;
  - un banco del grafo ingannato da `$( )` che aspetta il background;
  - un finto riusato da un caso precedente.
- I giri, dichiarati da loro:
  - S1 ha installato zsh, gh e markdown-it-py nel sistema del container, fuori dalle regole del brief;
  - S4 ha avuto due mutation-tests sovrapposti nel suo clone, fermati per gruppo;
  - S3 ha tolto due volte con `rmdir` una cartella vuota creata fuori dal clone (il difetto di S3 R5).
