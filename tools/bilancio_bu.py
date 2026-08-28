#!/usr/bin/env python3
# Uso: python3 bilancio_bu.py < input (vedi docstring per formato)
"""Conto economico per Business Unit dalla contabilità generale (G/L).

Oracolo (7° ciclo, set 1, 2026-08-24). Convenzione REALE minata dal progetto
bilancio periodico di REPO-E (Analisi.js, buildSerieMensile_ / convenzione
dichiarata nel payload):

1. CONVENZIONE DEI SEGNI del G/L: Amount < 0 = RICAVO (entra come −Amount),
   Amount >= 0 = COSTO. «Un segno invertito non dà errore: dà un costo che
   sembra un ricavo» — per questo la convenzione sta in testa all'oracolo,
   non in un commento.
2. Attribuzione BU via dimensione; BU non nota (fuori dall'elenco) → NOBU:
   il non-attribuito è una categoria VISIBILE, non una perdita silenziosa.
3. margine per BU = ricavi diretti − costi diretti; risultato per BU include
   il ribaltamento dei costi indiretti (REPARTO); risultato TOTALE = ricavi −
   costi complessivi (convenzione testuale del progetto reale).
4. QUADRATURA: la somma delle voci del CE riclassificato deve fare il
   risultato totale — «nessun doppio conteggio» (gold test del progetto
   originale). L'oracolo verifica meccanicamente: somma(margini BU) + indiretti
   = risultato totale, tolleranza 0,01 EUR.

COSA NON CALCOLA (dichiarato): la quota di RIBALTAMENTO dei costi indiretti
per BU (regola REPARTO) non è minata — la sua formula specifica non è provata
dal codice letto; l'oracolo produce il margine DIRETTO per BU e il totale, e
dichiara il ribaltamento come punto aperto da chiedere al proprietario (la
lezione dei costi generali della valorizzazione: la formula non si indovina).

Uso: python3 tools/bilancio_bu.py < gl.csv
CSV: conto,posting_date,bu,amount   (amount col segno del G/L)
"""
import csv
import sys


def main():
    righe = list(csv.DictReader(sys.stdin))
    bu_tot = {}
    amounts = []  # righe valide, per la quadratura indipendente sotto
    righe_scartate = 0
    for r in righe:
        bu = (r.get("bu") or "NOBU").strip().upper() or "NOBU"
        amount_raw = (r.get("amount") or "").strip()
        # bug reale (revisione 14 lenti, 2026-08-28): un campo amount vuoto/mancante
        # diventava silenziosamente un costo zero (float(r["amount"] or 0)), senza
        # traccia né conteggio — in contraddizione con la filosofia dichiarata nel resto
        # del file (NOBU visibile, non perso). Una riga con importo mancante/non numerico
        # viene ora SCARTATA e CONTATA, non azzerata in silenzio.
        try:
            amount = float(amount_raw)
            # giri avversari 2026-08-28 (D20): 1e999 produceva margine -inf in silenzio
            import math as _m
            if not _m.isfinite(amount):
                print(f"ERRORE: amount non finito (nan/inf) per BU {r.get('bu', '?')}: rifiutato, non sommato", file=sys.stderr)
                return 1
        except ValueError:
            righe_scartate += 1
            continue
        amounts.append(amount)
        ricavo = -amount if amount < 0 else 0.0
        costo = amount if amount >= 0 else 0.0
        t = bu_tot.setdefault(bu, {"ricavi": 0.0, "costi": 0.0})
        t["ricavi"] += ricavo
        t["costi"] += costo

    tot_r = sum(v["ricavi"] for v in bu_tot.values())
    tot_c = sum(v["costi"] for v in bu_tot.values())
    risultato_totale = round(tot_r - tot_c, 2)

    print("CONVENZIONE G/L: amount < 0 = ricavo (come −amount) · amount >= 0 = costo")
    if righe_scartate:
        print(f"ATTENZIONE: {righe_scartate} riga/e scartata/e per amount vuoto o non numerico (non contate come costo zero)")
    print(f"{'BU':<10} {'ricavi':>12} {'costi':>12} {'margine dir.':>12}")
    for bu in sorted(bu_tot, key=lambda b: -(bu_tot[b]["ricavi"] - bu_tot[b]["costi"])):
        v = bu_tot[bu]
        print(f"{bu:<10} {v['ricavi']:>12.2f} {v['costi']:>12.2f} {v['ricavi'] - v['costi']:>12.2f}")
    print(f"{'TOTALE':<10} {tot_r:>12.2f} {tot_c:>12.2f} {risultato_totale:>12.2f}")

    somma_margini = round(sum(v["ricavi"] - v["costi"] for v in bu_tot.values()), 2)
    # bug reale (revisione 14 lenti, 2026-08-28): il confronto precedente (somma_margini
    # vs risultato_totale) era un falso positivo strutturale — entrambi derivano
    # algebricamente dallo stesso bu_tot popolato dallo stesso loop, quindi matematicamente
    # sempre uguali; un vero doppio conteggio nell'aggregazione per BU avrebbe contaminato
    # entrambi i lati del confronto allo stesso modo e sarebbe comunque risultato "quadrato".
    # Quadratura VERA (pattern oracolo-indipendente): un secondo calcolo, mai passato da
    # bu_tot, direttamente sulla lista piatta delle righe valide — per costruzione il
    # contributo di ogni riga al margine è sempre -amount (ricavo-costo = -amount sia per
    # amount<0 che per amount>=0), quindi il totale indipendente è -sum(amounts).
    risultato_indipendente = round(-sum(amounts), 2)
    if abs(somma_margini - risultato_totale) <= 0.01 and abs(risultato_totale - risultato_indipendente) <= 0.01:
        print(f"QUADRATURA: somma margini BU ({somma_margini:.2f}) = risultato totale = calcolo indipendente sulle righe grezze ({risultato_indipendente:.2f}) — nessun doppio conteggio")
    else:
        print(f"QUADRATURA ROTTA: somma margini {somma_margini:.2f} · totale {risultato_totale:.2f} · calcolo indipendente {risultato_indipendente:.2f} — cercare il doppio conteggio nell'aggregazione per BU")

    if "NOBU" in bu_tot:
        v = bu_tot["NOBU"]
        print(f"NOBU (movimenti non attribuiti a BU): ricavi {v['ricavi']:.2f} · costi {v['costi']:.2f} — visibile, non perso")
    print("APERTO: il ribaltamento dei costi indiretti per BU (regola REPARTO) non è provato dal codice REPO-E letto —")
    print("l'oracolo produce margine DIRETTO; la quota ribaltata va chiesta al proprietario, non indovinata.")
    print("Nota di campo (REPO-G, D48): REPARTO limite osservato — a totRicavi=0 un costo sparisce silenziosamente.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
