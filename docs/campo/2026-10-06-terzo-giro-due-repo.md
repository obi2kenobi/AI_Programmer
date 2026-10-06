# 2026-10-06 — terzo giro di lettura e correzione su due repo
**Autore**: sessione Claude (Sonnet 5.5) per Luca — Magazzino_Treviso e Registrazione_Fatture_Acquisto

## Esito
Quaranta giri di lettura chiusi (20 per repo) e due PR di correzione aperte, una per repo, verificate da me a sorgente fermo: Treviso `cancello: 115 comandi · 3451 attese · fallite: 0` verde pieno con tutti i banchi browser eseguiti; Registrazione `gate: 33 comandi, tutti verdi`. Il contratto condiviso non è stato toccato (una cura lo richiede: contratto v4, consegna sincronizzata nei due repo).

## Cosa ho usato
Agenti `revisore-gas` (40 giri di lettura, 20 per repo, area × lente, rapporti scritti prima di rispondere in cartelle gitignorate) e `sviluppatore-gas` (correzioni a gruppi, una consegna alla volta per worktree). Il cancello e il gate li ho rilanciati io a sorgente fermo a ogni consegna. Mi sarebbe servito un analizzatore di variabili libere nel cancello: non c'era, e l'ha scritto un agente di lettura (acorn + eslint-scope).

## Cosa ho improvvisato
- **Base rossa prima del lavoro**: l'adozione dello standard (#203) ha reso rosso il cancello di Treviso su `main` (3 test sui hook non riconoscevano la forma dello standard). L'ho curata per prima, come primo commit del ramo di Treviso, dichiarando `test-errori.sh` fuori dal cancello col motivo (registro a sette campi, append-only) e aprendo un debito.
- **Un errore mio, senza danno**: una catena `cd && rsync && ... ; cp` ha eseguito un comando di prova nel worktree vero perché `rsync` non c'era; il `cp` è fallito per «stesso file» e la mutazione non è partita. La prova dei sabotaggi va fatta in una copia creata con `cp -r` e verificata prima di mutare.
- **Domande di dominio in un file**: 60 circa, raccolte man mano in un file della sessione, da porre una per volta al mattino; ogni correzione che dipendeva da una scelta di Luca ha preso la via fail-closed e ha lasciato la domanda numerata nel file delle domande di ciascun repo.

## Cosa ha retto / ostacolato
- **Ha retto:** i rapporti scritti prima di rispondere; la verifica indipendente dello stesso difetto da più giri (il `token` indefinito di `Ponte.gs:5191` è stato trovato da 6 giri con arnesi diversi); il banco che esegue il punto di chiamata invece della funzione pura.
- **Ostacolato:** i banchi verdi hanno nascosto difetti veri perché provavano regex sul sorgente, stub al posto della shim di produzione, o pratiche passate a mano; 87 delle 252 funzioni globali di Treviso non erano eseguite da nessun banco.

## Proposta al canone
1. Ogni cura va chiusa col collegamento fino al punto di chiamata (endpoint, pagina, shim di produzione), con un banco che lo esegue: le cure del 4 ottobre stavano nel modulo e non arrivavano alla pagina (`da_guardare`, `token`, bottone senza metodo nella shim).
2. Una lente che nasce rossa sul codice di oggi si consegna insieme alla cura che la rende verde, e dice DEGRADATO (mai rosso, mai verde pieno) se manca lo strumento.
3. Il cancello deve contare le funzioni mai eseguite da nessun banco, con un elenco dichiarato che può solo scendere.
4. Una PR di adozione dello standard si verifica con il cancello sullo stato combinato prima del merge (già proposta il 5 ottobre).
