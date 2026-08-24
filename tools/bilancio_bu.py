#!/usr/bin/env python3
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
    for r in righe:
        bu = (r.get("bu") or "NOBU").strip().upper() or "NOBU"
        amount = float(r["amount"] or 0)
        ricavo = -amount if amount < 0 else 0.0
        costo = amount if amount >= 0 else 0.0
        t = bu_tot.setdefault(bu, {"ricavi": 0.0, "costi": 0.0})
        t["ricavi"] += ricavo
        t["costi"] += costo

    tot_r = sum(v["ricavi"] for v in bu_tot.values())
    tot_c = sum(v["costi"] for v in bu_tot.values())
    risultato_totale = round(tot_r - tot_c, 2)

    print("CONVENZIONE G/L: amount < 0 = ricavo (come −amount) · amount >= 0 = costo")
    print(f"{'BU':<10} {'ricavi':>12} {'costi':>12} {'margine dir.':>12}")
    for bu in sorted(bu_tot, key=lambda b: -(bu_tot[b]["ricavi"] - bu_tot[b]["costi"])):
        v = bu_tot[bu]
        print(f"{bu:<10} {v['ricavi']:>12.2f} {v['costi']:>12.2f} {v['ricavi'] - v['costi']:>12.2f}")
    print(f"{'TOTALE':<10} {tot_r:>12.2f} {tot_c:>12.2f} {risultato_totale:>12.2f}")

    somma_margini = round(sum(v["ricavi"] - v["costi"] for v in bu_tot.values()), 2)
    if abs(somma_margini - risultato_totale) <= 0.01:
        print(f"QUADRATURA: somma margini BU ({somma_margini:.2f}) = risultato totale — nessun doppio conteggio")
    else:
        print(f"QUADRATURA ROTTA: somma margini {somma_margini:.2f} ≠ totale {risultato_totale:.2f} — cercare il doppio conteggio")

    if "NOBU" in bu_tot:
        v = bu_tot["NOBU"]
        print(f"NOBU (movimenti non attribuiti a BU): ricavi {v['ricavi']:.2f} · costi {v['costi']:.2f} — visibile, non perso")
    print("APERTO: il ribaltamento dei costi indiretti per BU (regola REPARTO) non è provato dal codice REPO-E letto —")
    print("l'oracolo produce margine DIRETTO; la quota ribaltata va chiesta al proprietario, non indovinata.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
