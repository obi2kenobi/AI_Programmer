# Le 45 domande di DEBITI — risposte delegate (2026-09-25)

Luca, 2026-09-25: «delle 45 domande rispondi a tutte quelle che non hanno bisogno di dominio, rispondi in maniera
logica e sensata con l'idea di risponderne il più possibile».

La numerazione è quella di `bash tools/debiti-riapertura.sh` di oggi. Ogni risposta sceglie una delle strade che la
riga di `DEBITI.md` già prevede, oppure lo dice. Ogni risposta si può ancora rivedere: il codice non è cambiato, e ogni
applicazione sarà un commit a sé, come chiede la riga.

Criteri, in ordine:
1. Il gesto che non si annulla perde: la cancellazione, la pubblicazione, la chiusura in pubblico.
2. Il deterministico vince sul modello, e il dichiarato sul taciuto.
3. Una risposta giusta in tutti e due i mondi batte una che indovina un fatto.
4. A parità, il codice più semplice.

## Esito

- **Risposte: 38.**
- **Restano a Luca: 5.**
  - D1: le dieci domande sugli oracoli contabili.
  - D12: il formato dei numeri negli export.
  - D14: il leasing oltre la scadenza.
  - D20: gli spazi nei percorsi del Mac.
  - D24: i nomi del tenant in `docs/bc/`.

  D1 e D14 chiedono cosa fa il sorgente di REPO-E, che questa sessione non vede. Le altre tre chiedono un fatto che sa
  solo Luca, e una risposta sbagliata corromperebbe dati o pubblicherebbe nomi.
- **In attesa, non da decidere: 2.** D26 (dove sta `node`) e D40 (PCRE nel git del Mac): il primo turno lo scrive nella
  riga d'ambiente.

## Le risposte

| # | Domanda | Risposta | Perché |
|---|---|---|---|
| D2 | I nomi di `repos.key` e `~/.privacy-nomi` sono pubblicabili? | **No**: restano bloccati. | Chi ha scritto quella lista l'ha fatto per tenerli fuori. Una pubblicazione non si annulla (criterio 1). La regola in CLAUDE.md resta una proposta. |
| D3 | I file nuovi di opencode passano da una dichiarazione? | **Si salda con D8.** | Il ramo opencode non gira mai. Tolto il ramo, la domanda non ha più oggetto. |
| D4 | Come si riconosce un'issue di correzione? | **Un'etichetta `correzione`.** | gh la dà in JSON, senza leggere testo libero. Il modello di issue la nomina, e il controllo «GIA' IMPLEMENTATA?» la salta. |
| D5 | `tools/bootstrap-app.sh`: repo pubblica di default? | **Privata** di default, con `--public` esplicito. | I gestionali sono privati. Una repo resa pubblica per sbaglio non si ritira (criterio 1). |
| D6 | privacy-check nei satelliti: forme o anche nomi? | **Solo le forme di segreto.** Senza `repos.key` il satellite non è DEGRADATO. | In una repo privata i nomi dell'azienda sono il contenuto. Un controllo sempre rosso insegna a ignorarlo. |
| D7 | La sentinella del 70% fa rosso? | **No, resta un avviso.** | Il rosso c'è già, ed è il budget `@540` di `.night-verify`. Due rossi per lo stesso tempo sono una regola in due copie (tema del settimo ventaglio). |
| D8 | Il ramo opencode morto, e il watchdog di 240 minuti? | **Via il ramo; il watchdog si mette attorno al risolutore.** | È codice morto (CLAUDE.md §2), e la promessa di CLAUDE.md §7 torna vera senza toccare CLAUDE.md. |
| D9 | Il test generato per un fix, mai eseguito? | **È una bozza**, e il nome e il commento lo dicono. | Non esiste un runner per progetto. Chiamarlo «il test che presidia» è un verde senza dati. Eseguirlo tornerà una domanda quando ci sarà un runner. |
| D10 | Il job `luca.ollama` che nessun installatore crea? | **Il manuale cita `rianima_ollama`, e `tools/system-health.sh` cerca il custode come fa lui.** | Vale da qualunque parte venga il job (criterio 3). |
| D11 | La scopa tocca anche `claude/` e `glm/`? | **No, solo i rami del turno.** | Un ramo del giorno senza PR può essere l'unica copia di un lavoro, e la cancellazione non si annulla (criterio 1). |
| D13 | `tools/indici_crisi.py` con tutti gli aggregati a zero? | **Rifiuto**: ERRORE e rc 1 quando tutti i denominatori sono nulli. | Come gli altri oracoli rifiutano l'estratto vuoto dal Q22. Un bilancio tutto a zero è una lettura vuota, e «nessuna crisi» su nessun dato è un verde falso. |
| D15 | `sync-repo --standard` toglie righe proprie del CLAUDE.md del satellite? | **Si ferma**: con righe proprie la PR non parte, e lo dice. | `tools/onboard-repo.sh` promette che un CLAUDE.md proprio non si sovrascrive. Spostare le righe in PROJECT.md vorrebbe dire decidere al posto del padrone dove vanno. |
| D16 | Le skill dello standard nei satelliti: personalizzabili o dell'hub? | **Dell'hub.** onboard e garante lo dicono; il pre-commit resta com'è. | Il prossimo `sync --standard` riscriverebbe comunque la personalizzazione. Ciò che è locale va in PROJECT.md. |
| D17 | `# NON-VERIFICABILE: <motivo>` vale? | **Sì**: il turno lo legge e lo scrive nel log, senza issue. | Il modello la chiede, e il metodo premia il dichiarato (criterio 2). Un rosso che nessuno può spegnere insegna a ignorare il turno. |
| D18 | Un `.git/index.lock` orfano si toglie da solo? | **Sì**, solo se nessun git lavora su quella cartella e il lock ha più di 60 minuti. `allinea_hub` lo dice. | È la cura che git stesso suggerisce. Le due condizioni insieme escludono un git del giorno che sta scrivendo. |
| D19 | File GAS con lo spazio nel nome? | **Backtick obbligatori nel Territorio** del modello di issue, e il banco del modello lo pretende. | Costa niente, e vale sia che quei file ci siano sia che no (criterio 3). |
| D21 | Una PR di riallineo chiusa senza fondere? | **Si rispetta finché lo standard cambia**: sync salta se una PR chiusa ha lo stesso contenuto. | Il no di una persona è memoria. Uno standard cambiato è una proposta nuova. |
| D22 | localhost nella sandbox del censore? | **Non si apre.** I banchi di rete escono dalle prove dichiarate del censore, e lo si dichiara. | Aprire la rete al codice scritto dal modello riapre la porta che T5#1 ha chiuso contro l'esfiltrazione. |
| D23 | Il Mac di riferimento? | **Stock**: bash 3.2, sed BSD, Homebrew minimo. PROJECT.md lo dice. | Ciò che gira sullo stock gira anche coi GNU. Il contrario no. I banchi di stanotte sono già verdi lì. |
| D25 | Un pass del grafo fallito lascia il segno del giorno? | **No**: il segno solo se ogni pass esce 0, e un fallito si dice nel log. Al più un secondo tentativo per notte. | Un fallito contato come fatto è un silenzio. Il tetto di un tentativo protegge le ore di GPU. |
| D27 | Nella caccia chi decide «sano»? | **Lo strumento**: il suo rc è il pavimento. | Il deterministico vince sul modello (criterio 2). Il provvisorio di stanotte diventa la regola, e si salda. |
| D28 | Un pass del grafo vivo da oltre 24 ore? | **Per ora non si tocca.** Dopo la prima durata misurata, la soglia è il triplo di quella misurata. | Senza una misura ogni numero è indovinato, e uccidere un pass vero butta ore di GPU. |
| D29 | Oltre quanto il report del gate è storia? | **24 ore.** Si resta così e si salda. | Il gate è in pensione, e un report lanciato a mano si legge la mattina dopo. |
| D30 | «Turno incastrato»: l'età del ciclo o il silenzio del log? | **L'età, ma col watchdog**: quando il log dice un'issue in corso, la soglia è 240 minuti più 15 di margine. | Un ⛔ falso insegna a uccidere turni sani. Il watchdog è il limite vero di un'issue. |
| D31 | Export in UTF-8 o in Windows-1252? | **Si prova UTF-8, poi cp1252, e lo si dice.** | Excel in italiano salva il CSV in cp1252. Se gli export sono UTF-8 il ripiego non scatta mai (criterio 3). |
| D32 | Il budget del censore: di calendario o mobile? | **Mobile: le ultime 24 ore.** | Un limite che raddoppia a mezzanotte non limita. |
| D33 | Le mutazioni complete ogni notte? | **Solo al banco di passaggio.** La suite le salta. | Il suo commento dice «non della suite», e rifà circa 107 s di banchi appena eseguiti. |
| D34 | Il budget `@540`? | **Resta 540.** | Senza le mutazioni (D33) la suite scende di circa 140 s, sotto il 55% del budget: 414 s misurati, meno 140. |
| D35 | Il prefisso `notte/`, e la PR del grafo ogni giorno? | **`night/`**, così scopa e giudici li vedono. Il grafo **aggiorna** la PR aperta. | CLAUDE.md §4 dice che un altro prefisso è invisibile a ogni giudice. Una PR al giorno per lo stesso file è rumore. |
| D36 | Il backup su gist e `repos.key`? | **`repos.key` esce dal backup; il gist vecchio si toglie dopo aver verificato il nuovo.** | Chi ha l'URL di un gist segreto lo legge, e la chiave dei nomi è accesso. Il backup di `repos.key` lo custodisce Luca fuori da GitHub. |
| D37 | Il ripiego `mail` del digest? | **Si tiene**, con il messaggio onesto di stanotte. Si salda. | Ora non mente e non svuota la memoria. Senza il ripiego resterebbe un rosso e basta. |
| D38 | privacy-check e la storia di `graphify-out/`? | **Si esclude** `graphify-out/` dalla scansione della storia. | È un file generato, e passa comunque dal cancello delle forme prima del push (V1 R3). |
| D39 | La console del turno non ruota? | **Si ruota** con `rotate_log_if_big`, e `tot` si conta dal file ruotato. | Il pezzo esiste già (CLAUDE.md, la scala del codice minimo, gradino 2). |
| D41 | graphify sul Mac, e la versione di gh? | **pipx con il python 3.12 di Homebrew, e graphify fissato alla versione provata dall'hub.** La spina dice cosa fa quella versione. gh si aggiorna liberamente, e la riga d'ambiente registra quale gira. | pip è rifiutato su tutti e due i python del Mac. Una versione non fissata cambia sotto i banchi. |
| D42 | Il blocco del risolutore tocca più funzioni? | **Diventa una proposta**: oltre una funzione, rc 3. | Un fix che fa più di quanto l'issue chiede non è un fix. Applicarne una parte indovinerebbe quale parte. |
| D43 | Un verdetto del censore fuori vocabolario? | **Al giorno**: rc 2, senza commento né chiusura. | Una chiusura in pubblico per una risposta mal formata non si annulla (criterio 1). Il dubbio non è un no. |
| D44 | L'issue d'allarme a verde, e il no di Luca a una PR? | **Si chiude al verde; un rosso nuovo si commenta. Una PR chiusa su `night/issue-N` ferma l'issue finché qualcuno la riapre.** | Un'issue aperta che dice il falso copre i rossi nuovi. Il no di una persona è memoria (come D21). |
| D45 | Una PR di issue aperta si riscrive? | **No, è intoccabile**: il turno salta l'issue che ha una PR aperta. | Riscriverla sposta il terreno sotto chi la sta leggendo. |

## Due cose viste rispondendo

- D43 nomina anche l'`eval` del comando avversario del banco, fuori dalla sandbox (`night-shift/revisore.sh`, per
  lettura). Non è una domanda: è un debito tecnico da curare col suo banco.
- D26 e D40 non sono decisioni. Si guardano nel log del primo turno dopo il merge, e le loro righe in `DEBITI.md`
  prendono il segno ⏳.
