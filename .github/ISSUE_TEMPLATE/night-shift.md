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
     dillo qui invece di scrivere un'ipotesi come fatto. -->

## Commessa (contesto precaricato)

<!-- I punti esatti: file, righe, funzioni, regex/pattern già validati, cosa toccare
     e cosa NON toccare. La notte esegue: il contesto arriva già masticato. -->

## Verifica

<!-- Cosa verifica il gate (.night-verify se eseguibili) e cosa resta alla review umana.
     Se la commessa tocca il frontend di una webapp (Index.html/App.html o equivalente),
     valuta se allegare una verifica visiva (skill `verifica-visiva`) prima che la review
     umana sia l'unico controllo sullo schermo — richiede un deploy raggiungibile, non è
     sempre applicabile. -->
