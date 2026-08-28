# Backlog di correzione — Associazione-Energikal (istruzioni per sessione AI)

> Questo file è pensato per essere incollato come messaggio iniziale a una
> nuova sessione AI incaricata di correggere i problemi della revisione.
> Documento di riferimento: ANALISI-REVISIONE-2026-08.md (nel repo Energikal).

## Regole vincolanti

1. Un problema alla volta, in ordine. Non saltare avanti.
2. Se qualcosa non è chiaro, chiedi — non inventare. Le voci [RICHIEDE CONFERMA DOMINIO] attendono risposta di Luca.
3. Input/output attesi prima di scrivere codice (numero atteso dal CSV 2024).
4. Test con dati reali dopo ogni fix su funzione di calcolo.
5. Un commit per ogni voce completata e verificata.
6. Se la funzione da toccare supera le 30-40 righe, spezzarla (solo quella).

## Passo 0 — Bloccante

config.gs conteneva credenziali Azure AD/BC reali (non placeholder) esposte in
git dal 16 febbraio 2026. **Chiedi a Luca: il secret è già stato ruotato in
Azure AD?** Se no, va fatto prima di tutto — non è un'azione che una sessione
di codice può fare da sola. Solo dopo conferma: ripristinare i placeholder
INSERIRE_QUI e committare. Chiedere se serve pulizia history git.

## Backlog ordinato (15 voci critiche/alte)

1. Conti C/G hardcoded non corrispondono al CSV 2024 — [CONFERMA DOMINIO: piano dei conti rinumerato?]
2. Riconciliazione senza verifica importo → falsa quadratura
3. Regressione db-riporto.gs (foglio per posizione, non per nome)
4. Filtro manodopera capacità disallineato — [CONFERMA DOMINIO: criterio ha senso su capacità?]
5. Math.abs() cieco sui saldi C/G
6. Somme non tipizzate (rischio concatenazione stringa)
7. Nessun LockService
8. Nessuna notifica su fallimento pipeline
9. Media Euribor silenziosamente su mesi parziali
10. pct_() nasconde segno negativo
11. Guadagno Lordo su base sbagliata
12. Pubblicità GDO fonte incoerente — [CONFERMA DOMINIO: trimestrale o annuale nel 2024?]
13. Filtro Location asimmetrico vendite vs NC — [CONFERMA DOMINIO]
14. Scritture non idempotenti nei DB
15. Buco silenzioso se pipeline fallisce prima dell'ultimo step

(altre ~20 voci medie/basse nel report completo)
