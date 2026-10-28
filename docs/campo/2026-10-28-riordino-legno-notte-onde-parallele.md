# 2026-10-28 — riordino-legno: notte di onde in parallelo (R2, copertura listini, nomi legno, rappresentanti, listini L1, contratti, in arrivo)
**Autore**: sessione Claude (coordinatore) per Luca — agenti `sviluppatore-gas`, `curatore-conoscenza`, `general-purpose` in worktree separati sotto /tmp/ap-*

## Cosa ho usato
Agenti in parallelo (fino a 6) con un brief uguale per tutti: worktree da origin/main, disegno con ASSUNTI prima del codice, banco rosso prima, sabotaggi tutti rossi, una PR verso main, versione prenotata per ciascuno (0.94–0.102). Routine oraria (`create_trigger`) per la notte: riprende gli agenti fermati, tiene un diario in scratchpad, non fonde mai. Lente su `gh api` per elencare le PR; `git ls-remote` per sapere se un ramo ha una copia sul remoto.
Voluto e NON c'era: un modo per leggere lo stato di un agente senza aprire il suo transcript (ho usato i worktree e le notifiche); `tools/debiti-riapertura.sh` risponde ma non dice quale agente tiene quale debito.

## Cosa ho improvvisato
1. Le PR impilate sui rami della catena sono state fuse nei rami e NON in main (#176, #179, #180, #181): scoperto solo guardando la base di ogni PR; rimediato con una PR sola da R1 verso main (#182). Regola nuova: ogni PR ha base `main`; il lavoro dipendente si pubblica come ramo e la PR si apre quando la base è in main.
2. Due riavvii del container hanno fermato tutti gli agenti: i worktree in /tmp sono sopravvissuti, i processi no. Ho aggiunto «push del ramo come copia di sicurezza prima di proseguire» ai brief (nessun commit locale è al sicuro da un riavvio).
3. Il limite di spesa (429) ha fermato sei agenti insieme: riprenderli con SendMessage dopo il ripristino funziona e non perde il lavoro (è nei commit); il `send_later` all'ora esatta ha dato «in the past»: controllare l'ora prima.

## Cosa ha retto / ostacolato
Ha retto: il banco scritto prima con il suo `attese eseguite: N/M · fallite: K`, i sabotaggi con il giudice, il controllo delle ancore (4.800 voci), l'obbligo di dichiarare cosa si è dovuto rifare dopo un riavvio. Ha ostacolato: il carico della macchina (load 25–36 con 6 agenti e il giro dei sabotaggi browser da 3 ore); gli script di serie nello scratchpad condiviso con lo stesso nome si sono sovrascritti fra agenti (`bash tools/...` non aiuta: serve un nome per agente); più PR correggono lo stesso banco (`banco-acq-mie-richieste.js`, versione scritta a mano) in modo uguale: i conflitti si vedranno alla fusione.

## Proposta al canone
- Un hook/test che fallisce se un banco contiene una versione `0.X.Y` scritta a mano (almeno 3 PR l'hanno dovuto correggere).
- Regola di processo: nel brief di ogni agente lungo, «nomi di file nello scratchpad con il tuo identificativo» e «push del ramo come prima cosa dopo ogni riavvio».
