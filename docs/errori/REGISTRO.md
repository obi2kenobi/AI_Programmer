# Registro degli errori a regime

> Ogni voce è un errore VERO, fatto e documentato — con la guardia che ora
> spara se torna. Il protocollo sta nella skill `post-mortem`; questa è la
> memoria operativa. Le famiglie R1-R6 sono definite lì. Si appende, non si
> riscrive: anche l'errore imbarazzante resta, perché il prossimo lo rifarebbe.

## E-001 Il canone svuotato da un write anticipato
- Data / sessione: 2026-08-28 (100 giri del ciclo-vivo)
- Famiglia: R1 (assunzione non verificata)
- Sintomo: metodo.md da 314 righe a 9 — e la suite rimasta 103/103 verde.
- Causa prossima: `open(path,'w')` eseguito da Python PRIMA di un NameError
  successivo sulla stessa riga: il file troncato a zero subito, la scrittura
  mai avvenuta; il giro dopo ha riscritto sopra solo l'indice.
- Causa del ragionamento: «prima calcolo la stringa, poi scrivo» — il
  side-effect dell'apertura in scrittura è PRIMA del calcolo, ma a mente era
  dopo. L'ordine mentale del codice non è l'ordine di esecuzione.
- Perché non ci ha fermati: nessun test guardava il CONTENUTO del canone,
  solo l'esistenza. Un file svuotato soddisfa tutti i test di esistenza.
- Guardia: tests/test-canone-integrita.sh — sezioni portanti + soglia 10KB +
  indice che punta a file esistenti.
- Verifica guardia: canone svuotato a mano → rosso (provato in sessione).
- Aggiramento: write atomico (file .tmp + os.replace) nelle modifiche scriptate.

## E-002 I falsi positivi SIGPIPE della lente 2
- Data / sessione: 2026-08-28 (analisi dei 100 giri)
- Famiglia: R2 (verde senza dati) + R5
- Sintomo: il ciclo segnalava 34-39 pattern non citati, con numeri che
  cambiavano fra run identici (34, 36, 39, 5).
- Causa prossima: `echo "$GRANDE" | grep -q "$x"` sotto `set -o pipefail`:
  grep -q esce alla prima corrispondenza, echo prende SIGPIPE (141), la
  pipeline «fallisce» e il pattern CITATO risulta mancante.
- Causa del ragionamento: fiducia nello status della pipeline senza chiedersi
  chi può morire dentro la pipe. La non-deterministicità era l'indizio e
  è rimasta in vista tre run prima che qualcuno la guardasse.
- Perché non ci ha fermati: il finding «34 pattern mancanti» era PLAUSIBILE
  (i gap veri erano 33): un bug che produce quasi-il-vero non si nota.
- Guardia: tools/ciclo-vivo.sh (lente 2 grep -qF diretta sui file) +
  patterns/pipefail-grep-sigpipe.md (la regola portatile).
- Verifica guardia: 3 run consecutivi → stesso numero (fatto in sessione);
  l'attacco avversario C1 (gaming HTML) regge.
- Aggiramento: mai `cmd | grep -q` su cmd costoso sotto pipefail: si greppe
  il file, o si cattura l'output prima.

## E-003 Il test anti-drift che confrontava vuoto con vuoto
- Data / sessione: 2026-08-28 (lenti di architettura)
- Famiglia: R2 (verde senza dati)
- Sintomo: test-opencode-agent-sync verde da giorni mentre gli specchi erano
  driftati davvero (5 agenti su 6).
- Causa prossima: `corpo()` usava due `sed '1,/^---$/d'` concatenate: la prima
  consumava entrambe le recinzioni del frontmatter, la seconda non trovava
  `---` e per semantica sed cancellava fino a EOF. Estrazione sempre vuota,
  `diff vuoto vuoto` sempre verde.
- Causa del ragionamento: il test era stato scritto quando i corpi coincidevano
  DAVVERO: verde per coincidenza, non per verifica. Nessuno ha mai visto il
  test diventare rosso, quindi nessuno sapeva se sapesse.
- Perché non ci ha fermati: è il problema del teorema non testato: un test
  che non ha mai fallito non ha mai detto niente.
- Guardia: tests/test-opencode-agent-sync.sh (non-vuotezza prima del diff,
  conteggio righe) + patterns/confronto-non-vuoto.md (la regola portatile).
- Verifica guardia: corpo driftato iniettato a mano → rosso (provato); righe confrontate
  ora visibili nell'output (89, non più vuoto==vuoto).
- Aggiramento: leggere l'output del test, non solo l'exit code: un "OK"
  senza numeri è sospetto quanto un diff vuoto.

## E-004 L'harness avversario sull'albero sporco
- Data / sessione: 2026-08-28 (giri avversari)
- Famiglia: R3 (precondizione non chiesta)
- Sintomo: due fix della sessione spariti; verdenti a cascata senza senso
  (il deny «assente» mentre il suo test passava 10/10).
- Causa prossima: la batteria di mutazioni ripristinava con `git checkout --`
  su un albero che conteneva lavoro NON COMMITTATO: ogni ripristino
  cancellava i fix appena scritti.
- Causa del ragionamento: il precondition check l'avevo chiesto al sistema
  (gli avversari lo pretendevano) ma non a me stesso che lo stavo usando.
- Perché non ci ha fermati: nessuna guardia d'ingresso sullo stato dell'albero.
- Guardia: tools/mutation-tests.sh e tools/giri-avversari.sh (exit 2 su
  albero sporco) — ha già fermato l'autore stesso, due volte.
- Verifica guardia: file sporco → exit 2 con messaggio (provato; successo
  davvero, due volte, la seconda mentre committavo l'harness indurito).
- Aggiramento: `git stash` prima di attaccare, se il lavoro va tenuto.

## E-005 Le mutazioni leakate (il verdetto sì, lo stato no)
- Data / sessione: 2026-08-28 (giri avversari)
- Famiglia: R6 (effetto collaterale ignorato)
- Sintomo: dopo il run, 10+ file sporchi; le difese successive giudicavano
  un albero wreckato.
- Causa prossima: il restore era alla fine dell'attacco successivo (o mai):
  fra mutazione e ripristino passava un intero attacco, e le difese in mezzo
  valutavano lo stato inquinato.
- Causa del ragionamento: verificavo il verdetto di ogni attacco, mai lo
  stato complessivo fra un attacco e l'altro.
- Perché non ci ha fermati: la batteria usciva con un resoconto sensato:
  il report era pulito, il mondo no.
- Guardia: tools/giri-avversari.sh (`difesa_test` ripristina subito dopo il
  verdetto; trap EXIT con `git checkout -- .`).
- Verifica guardia: post-run `git status --porcelain` vuoto (provato).
- Aggiramento: dopo ogni harness di mutazioni, un `git status` a mani:
  costa un secondo, compra l'albero.

## E-006 La metrica che misurava un'altra cosa (due volte)
- Data / sessione: 2026-08-28 (giri di chiarezza)
- Famiglia: R2 (verde senza dati) + R5
- Sintomo: il censimento di chiarezza dichiarava «nudi» i file .py meglio
  documentati del repo (valorizzazione_magazzino: density 0.01).
- Causa prossima: contava i `#`, non le docstring: nei .py la documentazione
  STA nelle docstring — la metrica misurava lo stile, non la chiarezza.
- Causa del ragionamento: ho scritto la metrica prima di chiedermi «come si
  documenta un .py in QUESTO repo». E l'ho rifatta due volte (la seconda con
  l'header-intent) prima di guardare un file vero per falsificarla.
- Perché non ci ha fermati: produceva un risultato plausibile e ordinabile.
- Guardia: tests/test-chiarezza.sh (conta docstring+commenti; il caso noto
  più documentato deve risultare COMPLETO — la metrica si falsifica su un vero).
- Verifica guardia: valorizzazione risulta COMPLETO nella lente (provato).
- Aggiramento: ogni metrica nuova parte da un caso noto vero e uno falso.

## E-007 L'auto-copertura del probe
- Data / sessione: 2026-08-28 (self-test del banco)
- Famiglia: R4 (autoriferimento)
- Sintomo: il banco 7 dichiarava «presidiato» il file probe scoperto — perché
  il test che lo creava ne conteneva il nome.
- Causa prossima: il test cerca il basename nei test: il basename del probe
  era letterale nel test stesso.
- Causa del ragionamento: il tester e il testato condividevano il nome per
  comodità di scrittura.
- Perché non ci ha fermati: il banco era verde: il verde dell'autoriferimento
  somiglia al verde vero.
- Guardia: tests/test-banco-passaggio.sh (probe a nome runtime `$$`,
  il commento nel test spiega perché il nome letterale mentiva).
- Verifica guardia: probe runtime → banco rosso correttamente (provato).
- Aggiramento: i nomi di prova non si scrivono letterali dove si cerca.

## E-008 L'asserzione che citava un verdetto inesistente
- Data / sessione: 2026-08-28 (test del banco mutazioni)
- Famiglia: R5 (memoria contro realtà)
- Sintomo: test rosso con il banco VERDE: rc=0 e "FAIL run completo non
  pulito (rc=0)".
- Causa prossima: il grep del test cercava "test reagiscono, 0 teatri"; il
  verdetto reale è "test reagiscono alla mutazione, 0 teatri verdi".
- Causa del ragionamento: asserzione scritta A MEMORIA su come suonava
  l'output del tool che avevo scritto io stesso poche ore prima.
- Perché non ci ha fermati: nessuna verifica dell'assert contro l'output.
- Guardia: tests/test-mutation-tests.sh (l'asserzione citava un verdetto
  inesistente: ora la stringa è incollata dall'output reale del banco).
- Verifica guardia: test verde col verdetto reale (provato).
- Aggiramento: nelle asserzioni di stringa, `tail` dell'output vero accanto.

## E-009 Il test fantasma committato
- Data / sessione: 2026-08-28 (test di campo-triage)
- Famiglia: R3 + R6
- Sintomo: un test banale (`PASS=0; [ $PASS -ge 0 ]`) committato al posto di
  quello vero; il banco lo scopre come TEATRO.
- Causa prossima: il test originale non era MAI stato tracciato da git; un
  esperimento lo sovrascrisse; il `git checkout --` di ripristino fallì in
  SILENZIO (non-tracked); la copia di sicurezza in /tmp venne sovrascritta
  dalla seconda versione dell'esperimento stesso.
- Causa del ragionamento: ho creduto al ripristino senza controllarlo; e ho
  riusato lo stesso path di backup per due esperimenti diversi.
- Perché non ci ha fermati: il file esisteva e passava: due verdetti facili.
- Guardia: tools/banco-passaggio.sh (banchi 4 e 7) +
  tests/test-campo-triage.sh (ricostruito in sandbox, teatro-proof).
- Verifica guardia: neutralizzazione → rosso (provato).
- Aggiramento: `git ls-files <file>` prima di credere a un checkout; backup
  con nome unico per esperimento.

## E-010 L'edit incompleto verificato solo sintatticamente
- Data / sessione: 2026-08-28 (fix HOME di install.sh)
- Famiglia: R1 (assunzione non verificata)
- Sintomo: install.sh muore «USER_NAME: unbound variable» dopo il MIO fix.
- Causa prossima: il replace ha tolto la riga che definiva USER_NAME insieme
  al blocco che la usava restava.
- Causa del ragionamento: verificai con `bash -n` (sintassi) invece di
  eseguire: l'unbound variable è run-time, la sintassi non la vede.
- Perché non ci ha fermati: fretta fra due fix; il test vero arrivò subito
  dopo e lo prese — la guardia esisteva, il ragionamento l'aveva saltata.
- Guardia: tests/test-install.sh (esegue l'install vero nella HOME finta:
  l'unbound variable run-time lo prende al primo giro, bash -n mai).
- Verifica guardia: test-install rosso al primo giro dopo l'errore (provato).
- Aggiramento: nessuno: il costo di eseguire è sempre minore del costo di
  credere.

## E-011 Il contratto dichiarato e mai provato
- Data / sessione: 2026-08-28 (mutation-testing dei test)
- Famiglia: R2 (verde senza dati)
- Sintomo: test-backup-config passava col tool neutralizzato; scoperto poi
  che il tool moriva 127 in SILENZIO senza gh.
- Causa prossima: il test si auto-saltava quando gh era presente: il ramo
  «senza gh» non veniva mai esercitato nell'ambiente di chi sviluppava.
- Causa del ragionamento: skip per condizione d'ambiente comodo: la condizione
  era SEMPRE vera dove girava il test.
- Perché non ci ha fermati: tre OK verdi convincono.
- Guardia: tests/test-backup-config.sh (forza il ramo senza gh via PATH,
  niente skip d'ambiente) + tools/backup-config.sh (guardia gh esplicita).
- Verifica guardia: tool neutralizzato → rosso; senza gh → messaggio pulito
  (provati entrambi).
- Aggiramento: ogni skip condizionale va rivoltato: l'ambiente si SIMULA,
  non si aspetta.

## E-012 L'header fossile
- Data / sessione: 2026-08-28 (giri di chiarezza)
- Famiglia: R5 (memoria contro realtà)
- Sintomo: l'header di ciclo-vivo prometteva ciclo A-B-C, memoria in
  stato.json, generazione automatica di test, prioritizzazione: NULLA di
  tutto ciò esisteva nel codice.
- Causa prossima: header scritto al concepimento, mai aggiornato mentre
  l'implementazione divergeva (battito CUORE invece di A-B-C, file piatti
  invece di JSON, coda invece di generazione).
- Causa del ragionamento: la documentazione high-level si scrive una volta e
  si dà per stabile; il codice sotto continua a muoversi.
- Perché non ci ha fermati: nessuna lente confrontava le promesse
  dell'header con ciò che il codice fa.
- Guardia: tests/test-ciclo-vivo.sh (stato.json citabile solo come storia
  mai esistita) + tests/test-chiarezza.sh S1 (intent in testa, verificabile).
- Verifica guardia: header riscritto e presidiato; la verifica di guardia è
  la lente stessa (run verde dopo il fix, rossa se l'header torna a mentire).
- Aggiramento: quando leggi un header per capire, grepba la prima promessa
  concreta contro il codice: se la prima non torna, non fidarti delle altre.

## E-013 I glifi alieni che tornano (terza volta in un giorno)
- Data / sessione: 2026-08-28 (pattern, SAL, e DI NUOVO nel registro stesso)
- Famiglia: R5 (memoria contro realtà) — con ricorrenza
- Sintomo: caratteri CJK dentro parole italiane («alla自身的 pratica»,
  «in阳台», «driftato人工») — prodotti da un agente che scrive italiano.
- Causa prossima: contaminazione del campione di generazione: il modello
  inserisce glifi di un altro script in punti casuali del testo italiano.
- Causa del ragionamento: nessuno: è un difetto di generazione, non di
  giudizio — MA la terza volta nello stesso giorno dice che la guardia va
  resa più larga, non rasa al caso singolo.
- Perché non ci ha fermati: la prima volta è stata trovata a mano dai giri
  ignoranti (S1), le altre due dalla lente stessa. Il punto: SENZA lente,
  tre testi pubblici con glifi alieni sarebbero stati committati.
- Guardia: tools/giri-ignoranti.sh (sonda S1: CJK/cirillico/arabo su tutti
  i tracciati, escluso l'archivio storico).
- Verifica guardia: pianto un glifo → FIND immediato (provato in batteria,
  attacco C6 degli avversari).
- Aggiramento: rilettura umana dei diff per i testi in prosa; la lente per
  tutto il resto.
