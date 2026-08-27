# N giri paralleli — il workflow dichiarativo (dal campo REPO-I, 2026-08-27)

Struttura fissa, contenuto per progetto:

1. DIVIDI il progetto in AREE (REPO-I: 15) — nessuna esclusa, o dichiara l esclusione.
2. Per ogni area, LANCIA due letture indipendenti: una a caccia di difetti silenziosi
   (le lenti di patterns/), una a caccia di possibilita non sviluppate (dev-critic:
   chi porta solo difetti ha fatto un terzo). REPO-I: 30 agenti, batch da 10 per limiti
   di concorrenza.
3. SINTESI a posteriori, senza coordinamento in partenza: un tema che ricorre in >=3
   aree INDIPENDENTI e un TEMA TRASVERSALE (REPO-I: 8) — la convergenza indipendente
   e il segnale di qualita che un giro singolo non da.
4. L esito del giro si dichiara (zero bug su superficie ampia = convergenza, in metodo.md).

Ancora: docs/campo/2026-08-27-controlli-trimestrali.md (19/19 findings ALTA
riproducibili con test PRIMA/DOPO, zero regressioni, zero correzioni respinte).
