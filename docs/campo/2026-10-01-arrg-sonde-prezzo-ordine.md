# 2026-10-01 — ARRG: sonde S12–S15 sul prezzo dell'ordine
**Autore**: sessione Claude (con Luca) — repo Registrazione_Fatture_Acquisto, PR #260–#263

## Cosa ho usato
Banco `tools/test_fase2.mjs` (test rosso prima, poi codice, sabotaggi con elenco esatto), lente `coerenza_gas.mjs`, gate `gate_copre_i_banchi.mjs`; sonde di sola lettura con `apriProduzioneInLettura_`. Non c'era: graphify (assente nell'hook di avvio, navigazione a grep).

## Cosa ho improvvisato
Un errore mio di lettura in chat (ordine 909 «21.481,20 €» al posto di 1.507,98 €, costo per pezzo moltiplicato per i pezzi della fattura): annotato in §42.34, senza una guardia nel REGISTRO perché non è codice. Ho anche azzerato per sbaglio il ramo di una PR aperta (#263) con `checkout -B` da un `origin/main` non aggiornato: rimediato rifacendo il ramo dal remoto.

## Cosa ha retto / ostacolato
Ha retto: sonda prima della regola (S13 ha mostrato che l'area si guarda sulle righe, non sulla testata; S14 che il costo è per pezzo e la quantità in m³). Ha ostacolato: `git fetch` dopo il `checkout -B`, invece di prima, e una PR mergiata a ogni passo (rami da rifare ogni volta).

## Proposta al canone
Nei calcoli ricavati a mano da un log: scrivere accanto al numero «ricavato, non letto» e rileggere l'importo dall'ordine prima di citarlo (errore della sessione). Rifare il ramo da `origin/main` solo DOPO il fetch (una riga nel flusso PR).
