Audit AI_Programmer
·
parco GAS · 8 progetti
·
2026-09-02 / 03
La procedura del giro, dall'inizio alla fine
Le fasi, le decisioni e chi le ha prese, i numeri rimisurati, e la lista dei buchi dichiarati.

Questo documento esiste per far trovare i buchi. Non racconta i risultati — quelli stanno in esito-finale.md: racconta come ci siamo arrivati, cosa ho deciso io senza chiedere, e cosa non è stato fatto. È lì che si nascondono le cose da aggiungere o correggere.

Verdetto del parco · branch dei fix · bbec87a
$ banchi/tutti.sh
=== SINTASSI ===
  sintassi: 151 blocchi controllati · 0 rotti

=== VERDETTO DEL PARCO ===
  banchi: 31 verdi · 0 rossi · 0 muti
  attese eseguite: 575/575 · fallite: 0
exit=0
Il verdetto è la riga canonica, non il codice di uscita: un banco che non stampa attese eseguite: N/M · fallite: K vale muto, cioè rotto. Sul branch delle funzionalità: 34 verdi · 616/616 · 158 blocchi.
86
commit sui fix
41
voci fatte
13
bloccate da una domanda
22
domande di dominio
0
voci perse
Il punto di partenza

0
La richiesta, e le tre decisioni
Chiesto: usare il metodo AI_Programmer, girare tutti gli agenti su tutto il codice, trovare falle · errori · inesattezze · problemi, diagnosticarli, fare un piano; in parallelo cercare funzionalità nuove mai pensate e progettarle; poi portare in fondo entrambi i piani senza fermarsi, preparando i comandi clasp e i push sui progetti giusti.

Le tre decisioni le hai prese tu
Domanda	Scelta
Su quali progetti posso correggere?	Solo i 5 nostri — webapp-produzione, webapp-bom, webapp, webapp-banner-produzione, gas/. I 3 cloni di riferimento restano a sola diagnosi.
Come consegno?	Due PR separate, fix e funzionalità.
Quanto spingo sulle funzionalità?	Implemento le tecniche, porto a design-doc quelle di dominio.
Le decisioni che ho preso io — da confermare o smentire
La classificazione T (tecnica, si implementa) contro D (dominio, si progetta) è mia, voce per voce. Se una voce è nel posto sbagliato, il lavoro fatto è sbagliato di conseguenza — vedi §6.7.
T6 non l'ho fatta deliberatamente: un gate di quota ha bisogno di una soglia, e la soglia esce dalla misura di T1. Una guardia tarata a caso taglia notti che finivano bene.
Dove la correzione «ovvia» cambiava un numero gestionale, non ho corretto: ho preparato il diff e l'ho messo in diff-bloccati/ con la domanda accanto. Sono 7 diff.
clasp non l'ho mai eseguito. È un cancello umano: credenziale unica condivisa, produzione senza staging e senza rollback.
Non ho toccato appsscript.json di webapp-produzione né i wrapper LogLib: sono della PR #1, aperta.
Le regole applicate

1
Il metodo, e cosa ho preso da esso
Quattro verbi in ordine: ANALIZZA → TESTA → CORREGGE → PROGETTA. E tre prodotti obbligatori, non uno: difetti · migliorie · funzionalità — «chi porta solo difetti ha fatto un terzo». Ecco perché funzionalita.md esiste e non è un contentino.

Le regole che hanno cambiato il risultato, non solo la forma:

«Esegui, non dedurre.» Un difetto si dichiara solo se l'ho fatto cadere su un banco eseguito. Le voci solo lette sono marcate come tali nel registro.
Il banco si scrive PRIMA della correzione, in due gruppi: PARITÀ (il comportamento vecchio che deve restare) e CORREZIONE (quello nuovo). La riga finale ha M dichiarato a mano: se le eseguite non tornano col dichiarato il banco è rosso anche se nessuna attesa è caduta. Questo contatore ha scoperto 4 banchi che si erano silenziosamente rimpiccioliti.
Due sabotaggi per correzione, dichiarando quante e quali attese devono cadere. Un sabotaggio che non morde è un falso verde — ed è successo, §6.8.
«Una deviazione si APRE, non si aggiusta.» Sulla paginazione BC avevo predetto 2 attese cadute e ne sono cadute 0. Non ho ritoccato il sabotaggio: ho riscritto la diagnosi, e l'elemento portante è risultato un altro — non chiedere $top, non il $skip.
I livelli di parità. 1 = logica pura eseguita sugli stessi casi. 2 = golden run su staging. 3 = diff ragionato, parità non provata. ⛔ In questa repo la parità è tutta di livello 1: non esiste nessuna copia di staging di nessuno degli 8 progetti. È il limite più grande del giro, §6.2.
Un'assenza si dichiara col comando che l'ha cercata. Corollario imparato sul campo e finito nel registro: un comando che cerca un nome che non esiste torna zero e si legge come «assente». Mi ha fatto scrivere «zero consumatori» su D5, che invece era costruita.
In ordine — ogni fase dipende dalla precedente

2
Le fasi
F0
Ricognizione e taratura del rilevatore
Prima di censire, ho verificato lo strumento. Il detector meccanico sbagliava in 7 modi documentati: falsi positivi su nomi che esistono, endpoint chiamati con nome diverso, file con byte NUL che grep salta in silenzio. Da qui la regola: ogni file letto in UTF-8 con python3, mai con grep cieco.

Perché conta
Un censimento fatto con uno strumento non tarato produce un elenco che sembra completo. La taratura è il motivo per cui mi fido dei numeri delle fasi dopo.
F1
Censimento, 9 agenti
Nove agenti indipendenti sugli 8 progetti, ognuno con perimetro dichiarato; output integrale in report/. Due agenti hanno trovato la stessa cosa senza sapersi — la freschezza dei fogli-ponte: dove due agenti convergono, la voce è più solida.

Un caso da leggere
Due agenti si contraddicevano sulla paginazione BC. Ho letto io il sorgente e avevano ragione entrambi a metà: il report 07 consigliava di «copiare 20 righe da webapp-bom», e quelle 20 righe contenevano il bug — skip che si incrementa anche dopo aver seguito un @odata.nextLink: 3000 righe in BC diventavano 5000, 2000 duplicate. Riordinato il lavoro: prima si corregge webapp-bom, poi si porta.
F2
Consolidamento
Dedup delle voci dei 9 report, ognuna con file:riga e la lettera A/B/C/D/E che dice come l'ho stabilita. Poi tre documenti che separano ciò che posso fare da ciò che non posso: domande-dominio.md (con i ⚠️ dove la correzione ovvia è dannosa), misure-sul-vivo.md (V1–V9, ~45 min, nessuna scrive), piano-intervento.md (10 lotti con le dipendenze e il criterio di fine).

⚠️ Il censimento si è aggiornato in corsa
Dopo il censimento ho trovato altre 6 voci (G00, X01–X05), correggendo mentre lavoravo. Stanno in una sezione a parte, non mescolate: un censimento che si riscrive per sembrare completo non è un censimento.
F3
Correzione, 4 correttori in worktree isolati
Un correttore per progetto, ognuno in un git worktree proprio, ognuno col ciclo completo: banco → correzione → sabotaggi → commit.

Il difetto più grave, corretto a mano
G00: in EmailCicliCapireparto.gs c'era
var righeT5406 = ***RIMOSSO-2026-08-21***(ordiniSet);
— letteralmente un SyntaxError in 3 punti, e in Apps Script un SyntaxError uccide tutto il progetto, non solo il file. Il nome vero non era recuperabile da git (il passaggio di redazione ha riscritto la storia): ricostruito da RigheOdPCache.gs:5-7, che elenca i tre chiamanti dello stesso T5406, più il suffisso …Capireparto_ del file. Verificato libero.
F4
Composizione — la fase che quasi nessuno fa
Il canone dice: la compatibilità fra due consegne è una relazione, nessuna delle due può dichiararla da sola. Va provata sull'albero composto. Ed è servito.

X05
In gas/, un correttore aveva giustamente lasciato intatti 5 file che ereditavano callBc/scaricaTutti/getAccessToken; l'altro aveva giustamente privatizzato quelle funzioni nel file ospite. Ognuno corretto. Composti: ReferenceError. Allineati 14 call-site, e le 14 collisioni nuove che ne sono nate (4 con firme divergenti) chiuse con la convenzione del correttore stesso. Collisioni 14 → 0.
F5
Funzionalità
7 di Classe T implementate, 7 di Classe D a design-doc con zero codice. La regola che ha tenuto fuori le idee da manuale: verifica prima di costruire — e verificalo con un test, non a occhio.

Ha pagato 3 volte su 7
D5 era già costruita (mancava solo un consumatore in produzione: il numero viveva in un console.log); D2 era calcolata due volte in due file con due definizioni; D6 aveva una diagnostica dedicata che guardava nel posto sbagliato. Nessuna scartata: sono diventate più piccole e più precise.
F6
Consegna
Due PR. comandi-clasp.md prepara i comandi, ma il PASSO 0 non è un push: è un clasp pull in una cartella scratch fuori dalla repo, per diffare quello che c'è davvero online contro git. Poi clasp push -f progetto per progetto, dal meno al più rischioso, con verifica in mezzo. La regola del SAL è rispettata — «clasp pull non si usa: la fonte di verità è git»: qui non è la fonte, è la misura di quanto online e git hanno divergato.

F7
Presidio
.night-verify contiene una riga: banchi/tutti.sh. Non un elenco di banchi, perché un elenco a mano dimentica il banco scritto domani — che è esattamente il difetto che questo audit ha censito: il documento che invecchia contro il comando che si rilancia.

La mappa

3
Dove sta cosa
docs/audit-ai-programmer-2026-09-02/
├── README.md              indice · fotografia · TARATURA del rilevatore · copertura
├── registro-difetti.md    47 runtime in perimetro + 6 cloni + 7 processo + 5 nuove = 65 righe
├── domande-dominio.md     19 domande, coi ⚠️ dove correggere fa danno
├── misure-sul-vivo.md     V1..V9 — solo il tuo Mac può eseguirle, nessuna scrive
├── piano-intervento.md    10 lotti, dipendenze, criterio di fine
├── comandi-clasp.md       PASSO 0 = pull+diff, poi push dal meno rischioso
├── funzionalita.md        7 T + 7 D con gli stati
├── esito-finale.md        l'esito voce per voce, una riga ciascuna
├── procedura.md           ← questo documento
├── design/     (8)        i design-doc di Classe D, zero codice
├── report/     (9)        il censimento integrale dei 9 agenti
├── diff-bloccati/ (7)     i diff pronti che aspettano una risposta
└── banchi/   (109)        le prove CONGELATE, con le uscite vere

banchi/        (46 file)   la suite VIVA, che si rilancia
├── tutti.sh               scopre i banchi dal filesystem, legge la riga canonica
├── sintassi.sh            node --check su ogni .gs/.js + ogni <script> inline
└── lib/estrai.js          estrae la funzione VERA dal sorgente + il contatore M
La differenza fra le due cartelle banchi/ conta. Quella sotto docs/ è la prova storica: non si rilancia, documenta cosa ho misurato quel giorno. Quella in radice è la suite che gira ogni notte. Un correttore aveva messo il suo banco sotto docs/ — non sarebbe mai più girato. Spostato.

Misurati coi comandi, non a memoria

4
I numeri
Esito	Voci	Cosa vuol dire
✅ fatte	41	correzione applicata, banco verde, sabotaggi mordono
◐ fatte in parte	7	il resto è dichiarato nella voce stessa
⛔ bloccate da una domanda di dominio	13	diff pronto in diff-bloccati/, non applicato
📏 bloccate da una misura sul vivo	3	serve BC vivo o i fogli veri
🔒 fuori perimetro per decisione	6	cloni: diagnosi consegnata, nessuna correzione
👤 richiedono una decisione, non un fix	3	fra cui la soglia di T6
❌ non fatte in perimetro, dichiarate	2	dette apposta perché non fossero invisibili
perse	0	ID unici, zero duplicati, i due elenchi combaciano
⚠️ Le tre intestazioni non contano la stessa cosa — ed è un difetto del mio lavoro. «47 voci» nel registro sono i difetti di runtime in perimetro (14 gravi + 21 medi + 12 minori); «52» in esito-finale.md sono quei 47 più le 5 nuove; ma le righe delle due tabelle sono 65 e 66, perché comprendono anche le 6 voci dei cloni, le 7 di processo e X05. Nessuna voce è persa, ma il numero in copertina non è il numero delle righe. Dettaglio e rimedio in §6.10.
Il passaggio di mano

5
Cosa resta, e su chi
#	Cosa	Perché non posso io
1	PASSO 0: clasp pull in scratch + diff contro git	credenziale Google tua, e va vista la divergenza prima di sovrascrivere
2	clasp push -f progetto per progetto	produzione senza staging né rollback: è un cancello umano
3	V1–V9, ~45 minuti	serve BC vivo e i fogli veri; nessuna misura scrive
4	22 domande di dominio — 19 in domande-dominio.md + Q-D5/Q-D6/Q-D7; ne bloccano 13 voci	sbloccano i 7 diff in diff-bloccati/. Il dominio è tuo, non mio
5	3 decisioni, fra cui la soglia di T6	una soglia inventata è peggio di nessuna soglia
Le tre domande che sbloccano più lavoro
Q-C6 — quale delle due letture del bottom-up è giusta. Da lì escono i +18.622 € comunicati al consulente BC, e il 357,1× di divergenza che il banco di T4 misura ma non giudica.
Q-C4 — la base della percentuale di manodopera: il triangolo confronta mele con pere.
Q4 — perché su 5 delle 10 casette più prodotte il consumo manca fino al 99%. Ripartire un dato che non c'è è una regola applicata al nulla: per questo D7 è tornata a brainstorming.
La sezione per cui il documento esiste

6
I buchi
Dieci voci. La striscia a sinistra dice quanto pesa; il cartellino dice a chi tocca chiuderla.

6.1
Il metodo non è installato in questa repo
.claude/skills, .claude/agents, .claude/settings.json, .opencode, night-shift/, tools/ — tutti assenti. tools/sync-repo.sh <owner/repo> --standard non è mai stato eseguito: il metodo l'ho portato dentro a mano, leggendolo dall'hub, invece di trovarlo già in posto. Il canone è netto: «se manca un pezzo, manca il metodo.»

Conseguenza pratica: la prossima sessione non trova gli agenti, le skill e il gate del mattino — ricomincia a mano come ho fatto io. Il .gitignore è già predisposto (ignora solo .claude/worktrees/, non .claude/ intera). È il primo buco da chiudere.

Decisione tua
6.2
Zero esecuzione dal vivo → tutta la parità è di livello 1
Nessuno degli 8 progetti ha una copia di staging. Ogni banco gira in node, con gli adattatori (BC, Sheets, Cache, Lock) finti. Vuol dire: ho provato che la logica non cambia sugli stessi casi; non ho provato che il comportamento su Apps Script vero, con BC vero, non cambia.

Le forme che nessun banco può cogliere: i 6 minuti di runtime, i 6 MB per fetch, la formattazione fantasma, l'ordine di caricamento reale dei file.

Limite strutturale
6.3
Copertura di lettura incompleta, e il pezzo che manca è il più importante
webapp-produzione 26 file su 44 · i cloni 27 su 93. E il buco peggiore: EsplosioneBOM.gs e SyncBOM.gs non sono stati letti a fondo — ed è da lì che escono i costi unitari della colonna DB-distinta, cioè la fondazione del bottom-up. Hanno un lotto nel piano; non è stato eseguito.

Lavoro da fare
6.4
Le cause a monte restano in piedi
Diversi difetti che falsificano i costi hanno la causa dentro i 3 cloni, fuori perimetro per tua decisione. Li ho diagnosticati e non toccati. Il lato webapp-bom è difeso (T7), ma la difesa misura il problema, non lo elimina: la colonna aggiornato va messa nel produttore, e il produttore è un clone.

Decisione tua
6.5
Il rischio dichiarato che ho lasciato dentro
In webapp-bom/backend/BcApi.gs, togliendo il $top la dimensione di una risposta la decide il server, contro il limite di 6 MB per fetch. Nessun chiamante passava $top (verificato), quindi il comportamento voluto non cambia. Ma se una pagina fosse enorme, la forma corretta non è rimettere il $top — rimetterebbe il difetto: è l'header Prefer: odata.maxpagesize=N. Va provato dal vivo prima di metterlo, ed è in lista misure, non fatto.

Misura sul vivo
6.6
L3b — la superficie dei trigger è ancora aperta
16 dei 17 bersagli di trigger sono globali, cioè endpoint google.script.run di fatto. Non li ho privatizzati: il trigger memorizza il nome, e rinominare senza reinstallare uccide in silenzio il giro notturno. Serve la procedura di reinstallazione, che è un'azione sull'ambiente vivo.

Ambiente vivo
6.7
Cose che non ho fatto, e vanno dette
Nessuna verifica visiva. Nessuna delle webapp è stata guardata renderizzata: le correzioni di igiene web sono provate sul comportamento, non sull'aspetto. — Nessuna misura di prestazione: non so quanto durano i giri notturni oggi, quindi non so se le correzioni li hanno allungati. — PR #1 e PR #2 non sono coordinate su appsscript.json/LogLib: ho evitato il conflitto non toccando quei file, ma l'ordine di merge conta e nessuno l'ha deciso. — T6 non fatta per scelta; T4 fatta solo nella parte tecnica.

E la classificazione T/D è mia. Il canone avverte che «una voce di Classe T che nasconde una scelta di dominio va classificata D: la classificazione sbagliata è il difetto più costoso del giro». Le due su cui sono meno sicuro: T4 — il bottom-up unico: la parte tecnica è T, ma quale lettura sia giusta è dominio puro — e T5 — alzare il cancello di schema da 4 a 13 è tecnico, ma cosa fare degli orfani è una decisione gestionale.

Decisione tua
6.8
Errori miei, dichiarati perché il modo di sbagliare è riutilizzabile
Ho letto l'exit code di tail invece di quello dello script, due volte (pipe); rimisurato senza pipe, annotato nei commit. — Il mio primo runner leggeva la prima riga canonica, non l'ultima: un banco misurava 3/3 dove diceva 13/13 — «8/8 diventato 6/6 in silenzio» dentro il guardiano. — sabotaggi.sh puntava a un percorso vecchio: il cp non trovava niente, i sabotaggi non sabotavano, lo script usciva senza verdetti. Un sabotaggio che non morde è un falso verde. — Un banco fissava la funzione ospite alla riga 123; aggiungendo il contatore di T1 la funzione si è spostata e il banco è morto muto: sostituito con una ricerca per nome. — Aggiungere quel contatore ha fatto diventare rossi 4 banchi: risolto con un try/catch che avvisa, in produzione, sul principio che l'osservabilità non deve poter rompere ciò che osserva.

Già corretti
6.9
Due correttori sono morti sul rate limit
Il correttore di webapp-bom (dopo 15 commit, col banco N01 non committato) e quello di gas/ (a metà di una correzione del banco) sono caduti su un 429 di sessione. Ho finito io i due lavori invece di aspettare. Se qualcosa in quei due perimetri sembra fuori stile, è perché ha due mani.

Chiuso, con la nota
6.10
La contabilità delle voci è tenuta in tre modi diversi
Verificato coi comandi mentre scrivevo questo documento: registro-difetti.md ha 65 righe-voce e in copertina dice «47»; esito-finale.md ha 66 righe-voce e in copertina dice «52». I due numeri di copertina sono difendibili (47 = gravi+medi+minori in perimetro; 52 = 47 + le 5 nuove) ma non sono il conteggio delle righe, e la tabella di riepilogo somma 75 su una base dichiarata di 52 — 72 anche scontando le 3 voci dichiarate sovrapposte.

Nessuna voce è persa: gli ID sono unici e i due elenchi combaciano. Ma il criterio di fine del piano è un'uguaglianza aritmetica (voci = fatte + bloccate + non fatte), e un'uguaglianza su una base ambigua non si può verificare. Da chiudere: una sola base dichiarata, e i totali ricalcolati da lì.

Lavoro da fare
Tutto qui dentro è rieseguibile

7
Come rilanciare le verifiche
banchi/tutti.sh        # 31 banchi + sintassi: il verdetto del parco
banchi/sintassi.sh     # solo node --check su .gs/.js e <script> inline
python3 analisi/mappa_endpoint_bc.py   # rigenera docs/mappa-endpoint-bc.md dal codice
Il verdetto è la riga canonica, non il codice di uscita: un banco che non stampa attese eseguite: N/M · fallite: K va contato muto, cioè rotto. Un codice di uscita non è un verdetto.

Come leggerlo, se devi dirmi cosa manca

Tre punti dove una tua parola cambia il lavoro più che altrove
§6.1
Installo il metodo, o lo lascio a mano?
tools/sync-repo.sh <owner/repo> --standard non è mai girato. Finché non gira, ogni sessione ricomincia da zero.
§6.7
T4 e T5 sono classificate bene, o sono di dominio?
Se sono D, la parte che ho implementato va rivista: la classificazione sbagliata è il difetto più costoso del giro.
§5
Delle 22 domande, quali rispondi ora e quali «non adesso»?
Un «non adesso» è una risposta legittima e chiude la voce. Il silenzio la lascia aperta per sempre.
docs/audit-ai-programmer-2026-09-02/procedura.md
·
branch claude/ai-programmer-analysis-2w63mk
·
PR #2 (fix) · PR #3 (funzionalità, impilata)
·
nessun clasp eseguito da qui