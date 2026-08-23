---
name: Commessa notturna
about: Lavoro meccanico per il turno di notte (modello locale) — richiede il design
labels: ["night-shift"]
---

## Design

<!-- OBBLIGATORIO (il turno salta le issue senza questa sezione): link al documento di
     design, riferimento al SAL del progetto, o tre righe di ratio — perché questa
     commessa esiste e da quale analisi nasce. -->

## Forma dei dati (verificata sul codice)

<!-- OBBLIGATORIO per commesse che leggono dati esistenti: la STRUTTURA degli oggetti
     coinvolti (campi, aggregazioni, dove vivono davvero — file:funzione), VERIFICATA
     sul codice da chi scrive la commessa, non assunta dalla documentazione.
     Lezione pagata dall'A/B 2026-08-21: un'assunzione sbagliata qui costa alla notte
     un'ora di palude mentre il giorno se ne accorge leggendo.
     Se il progetto parla con Business Central, applica anche la lente BC della skill
     `audit-commessa` (aggregazione per famiglia ≠ per codice, endpoint con buchi noti,
     CATALOGO_ENDPOINT_BC.md come fonte di verità sui campi). Se un termine di dominio
     (codice articolo, BU, convenzione fornitore) non è ovvio dal codice, cita
     `docs/GRAMMATICA_DOMINIO.md` invece di indovinarlo — se la riga non c'è ancora,
     dillo qui invece di scrivere un'ipotesi come fatto.
     Se la commessa CALCOLA/RICONCILIA una cifra contabile o gestionale reale (margine,
     valorizzazione, scostamento, roll-forward, ecc.), applica la skill
     `controllo-gestione`: la formula va citata come oracolo dal codice esistente (o
     confermata dal proprietario del dominio), mai indovinata — scrivi qui la fonte
     citata. -->

## Territorio

<!-- OBBLIGATORIO: quanto codice bisogna LEGGERE per eseguire (file e loro dimensione).
     Regola dell'11 ore (2026-08-22): la notte non converge sui territori grandi —
     file da centinaia di righe da esplorare = GIORNO. Notturno solo se: file piccoli,
     righe indicate, nessuna esplorazione. Se il territorio è grande, NON scrivere questa
     commessa: passa il lavoro al giorno. -->

## Commessa (contesto precaricato)

<!-- I punti esatti: file, righe, funzioni, regex/pattern già validati, cosa toccare
     e cosa NON toccare. La notte esegue: il contesto arriva già masticato. -->

## Verifica

<!-- Cosa verifica il gate (.night-verify se eseguibili) e cosa resta alla review umana.
     Se la commessa tocca il frontend di una webapp (Index.html/App.html o equivalente),
     valuta se allegare una verifica visiva (skill `verifica-visiva`) prima che la review
     umana sia l'unico controllo sullo schermo — richiede un deploy raggiungibile, non è
     sempre applicabile.
     Se la commessa aggiunge o modifica codice che STAMPA/LOGGA output derivato da config
     di connessione, credenziali o dati di terzi (diagnostica, debug, trascrizioni), valuta
     la lente sicurezza di `dev-critic` (§2bis) PRIMA del merge — nessun passo del gate la
     esegue automaticamente, e i due incidenti reali che l'hanno originata (allowlist
     bucabile, credenziali committate) non sono mai stati trovati da sé. Verificato dal
     vivo (night-shift-pilot, Giro 3 dei test autonomi, 2026-08-21): eseguendo per davvero
     una funzione di diagnostica scritta a commessa, la chiave finiva in chiaro a console
     — la lente la cattura solo se qualcuno la invoca, non da sola. -->
