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

## E-014 La trappola pipefail-grep-q che rinasce in ogni test nuovo
- Data / sessione: 2026-08-29 (test-presidio, terza ricorrenza in due giorni)
- Famiglia: R5 (memoria contro realtà) + R2
- Sintomo: il test nuovo falliva proprio quando lo strumento funzionava (la
  CONTESA urlata non vista, il rilascio riuscito dichiarato fallito).
- Causa prossima: `cmd | grep -q X` con cmd multi-riga sotto pipefail: grep -q
  esce al primo match, cmd prende SIGPIPE, la pipeline dà 141 → il ramo `|| ko`
  scatta. Variante inedita scoperta insieme: `grep -c X file | grep -q "^0$"`
  — grep -c esce 1 quando conta ZERO, la pipeline fallisce quando è VERO.
- Causa del ragionamento: so scrivere la pipa prima di ricordare che sotto
  pipefail il verdetto è della pipeline intera, non dell'ultimo comando. È la
  terza volta CHE LA SCRIVO NUOVA sapendola — la conoscenza di un pattern non
  immunizza dal riscriverlo: solo la forma catturata-prima lo fa.
- Perché non ci ha fermati: i test fallivano in direzione «male» plausibile.
- Guardia: tests/test-presidio.sh (la forma catturata-prima, con il commento
  che spiega perché la pipa è vietata) + questa voce come memoria viva. La
  regola portatile: nei test, `OUT=$(cmd || true)` prima di greppare; per i
  conteggi-zero `! grep -q`, mai `grep -c | grep -q`.
- Verifica guardia: test-presidio 9/9 dopo la riscrittura; le celle vecchie
  della suite non usano più `cmd | grep -q` su verdetto.
- Aggiramento: quando serve proprio la pipa: `set +o pipefail` locale al check.

## E-015 Il gate del mattino che crasciava in silenzio sul conf vuoto
- Data / sessione: 2026-08-29 (domanda di Luca: «come è andato il lavoro notturno?»)
- Famiglia: R3 (precondizione non chiesta) + R2
- Sintomo: nessun gate dal 25/8; lanciato a mano: `REPO_LIST[@]: unbound variable`.
- Causa prossima: lista vuota (conf solo commenti) + `"${REPO_LIST[@]}"` sotto
  set -u su bash 3.2 = unbound, non lista vuota.
- Causa del ragionamento: il gate era sempre stato chiamato CON argomenti o da
  conf pieno: il caso vuoto mai provato. Il silenzio di 4 giorni è sembrato
  «niente da giudicare», non «il giudice non partiva».
- Perché non ci ha fermati: il morning-gate logga il proprio completamento:
  l'assenza di log nuova non alertava nessuno.
- Guardia: night-shift/morning-gate.sh (messaggio pulito + exit 1 su lista
  vuota; ${arr[@]+...} per bash 3.2).
- Verifica guardia: lanciato senza args/conf → messaggio e rc=1 (provato);
  tests/test-morning-digest.sh presidia il battito (GIUDICE FERMO se gate non completa).
- Aggiramento: chiamare il gate con le repo esplicite (come fatto fino al 25).

## E-016 Il medesimo report processato due volte in parallelo
- Data / sessione: 2026-08-31 (REPO-G, due sessioni, ~1h di distanza)
- Famiglia: R3 (precondizione non chiesta) + R4
- Sintomo: push rifiutato; il remoto conteneva il report già processato da un'altra sessione.
- Causa prossima: nessuna delle due sessioni ha dichiarato il presidio prima di iniziare.
- Causa del ragionamento: il presidio esiste dalla vigilia ma «processare un report» non
  è stato riconosciuto come LAVORO SU UNA ZONA (sembra lettura, è scrittura).
- Perché non ci ha fermati: la collisione è stata BENIGNA per costruzione (convenzione
  date-slug: stesso report → stesso file → nessuna divergenza) — il danno è stato solo
  lavoro duplicato, e il verde finale ha nascosto lo spreco.
- Guardia: tools/presidio.sh (claim prima di processare) + la regola scritta nella
  skill lavoro-condiviso §1bis: il processing di un report dal campo È un lavoro su zona.
- Verifica guardia: il claim contesa avvisato nelle prove del turno stesso (9/9 test).
- Aggiramento: la convenzione dei nomi rende comunque idempotente l'esito: tenuta.

## E-017 Tre notti perse: il turno incastrato invisibile
- Data / sessione: 2026-08-31 (scoperta alla domanda «come sono andate le ultime notti?»)
- Famiglia: R2 (verde/silenzio senza dati) + R1
- Sintomo: nessun TURNO FINITO dal 28/8; nessun turno avviato il 29 e 30; silenzio totale.
- Causa prossima: opencode in loop di rilettura MAI tornato (~59h, 104h CPU); il job
  vivo ha impedito a launchd di avviare i turni seguenti (niente doppioni).
- Causa del ragionamento: la decisione «nessun limite di tempo» (Luca, 21/8) presupponeva
  «la guardia è la review del mattino» — ma la review non aveva NIENTE da guardare: il
  gate era rotto (E-015) e nessuno strumento mostrava un processo vivo da 59 ore.
- Perché non ci ha fermati: l'assenza di log sembrava coda vuota (stessa famiglia del
  gate muto).
- Guardia: tools/turno-vivo.sh (detector del processo oltre soglia, in system-health;
  non uccide: VISIBILITÀ, la scelta del rimedio resta della review del mattino) +
  DEBITI «il turno senza limite ha bruciato 3 notti» per la decisione del watchdog.
- Verifica guardia: girato oggi: nessun processo attivo → rc 0 (caso sano provato;
  il caso rotto è il documento stesso di oggi: 59h reali).
- Aggiramento: pkill -f "opencode run" (pulizia consolidata), il turno si scioglie.
