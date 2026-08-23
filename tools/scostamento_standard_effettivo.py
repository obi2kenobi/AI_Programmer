#!/usr/bin/env python3
"""Scostamento costo standard vs costo effettivo per articolo (controllo di gestione).

Formula reale (oracolo, non inventata): un modulo di controllo di gestione produzione
(repo esterno REPO-E, cartella gas-src/, non in questo hub) — letto riga per riga sul
codice reale, non riassunto a memoria:

  mediaEff  = Σ(costoEffUnitario_i * qtaProdotta_i) / Σ(qtaProdotta_i)   [media pesata]
  scostPerc = ((mediaEff - costoStandard) / costoStandard) * 100  se costoStandard > 0, altrimenti 0
  alert     = costoStandard != 0 AND numOdP >= 2 AND |scostPerc| > soglia (default 10)
  direzione = "sopra" se scostPerc > 0, altrimenti "sotto"
  gravita   = "ALTO" se |scostPerc| > 50, altrimenti "MEDIO"
  trend     = confronto prima metà vs seconda metà degli ordini (ordinati per data):
              variazione = ((media2 - media1) / media1) * 100
              "IN_SALITA" se >5, "IN_DISCESA" se <-5, "STABILE" altrimenti,
              "DATI_INSUFFICIENTI" se meno di 4 ordini o una metà a quantità zero.

Uso: python3 tools/scostamento_standard_effettivo.py < ordini.csv
CSV con colonne (ordinate per data crescente): costo_eff_unitario,qta_prodotta
"""
import csv
import sys


def media_pesata(righe):
    somma_costo = sum(r["costo_eff_unitario"] * r["qta_prodotta"] for r in righe)
    somma_qta = sum(r["qta_prodotta"] for r in righe)
    return somma_costo / somma_qta if somma_qta > 0 else 0


def calcola_scostamento(costo_standard, media_eff):
    if costo_standard <= 0:
        return 0
    return ((media_eff - costo_standard) / costo_standard) * 100


def calcola_trend(righe_ordinate):
    if len(righe_ordinate) < 4:
        return "DATI_INSUFFICIENTI"
    meta = len(righe_ordinate) // 2
    prima, seconda = righe_ordinate[:meta], righe_ordinate[meta:]
    qty1 = sum(r["qta_prodotta"] for r in prima)
    qty2 = sum(r["qta_prodotta"] for r in seconda)
    if qty1 == 0 or qty2 == 0:
        return "DATI_INSUFFICIENTI"
    media1 = media_pesata(prima)
    media2 = media_pesata(seconda)
    variazione = ((media2 - media1) / media1) * 100
    if variazione > 5:
        return "IN_SALITA"
    if variazione < -5:
        return "IN_DISCESA"
    return "STABILE"


def valuta_alert(costo_standard, num_odp, scost_perc, soglia=10):
    if costo_standard == 0 or num_odp < 2 or abs(scost_perc) <= soglia:
        return None
    return {
        "direzione": "sopra" if scost_perc > 0 else "sotto",
        "gravita": "ALTO" if abs(scost_perc) > 50 else "MEDIO",
    }


def main():
    righe = [
        {"costo_eff_unitario": float(r["costo_eff_unitario"]), "qta_prodotta": float(r["qta_prodotta"])}
        for r in csv.DictReader(sys.stdin)
    ]
    costo_standard = float(sys.argv[1]) if len(sys.argv) > 1 else 0
    media_eff = media_pesata(righe)
    scost_perc = calcola_scostamento(costo_standard, media_eff)
    trend = calcola_trend(righe)
    alert = valuta_alert(costo_standard, len(righe), scost_perc)
    print(f"Costo medio effettivo: {media_eff:.2f}")
    print(f"Scostamento: {scost_perc:+.1f}%")
    print(f"Trend: {trend}")
    if alert:
        print(f"ALERT: {alert['gravita']} ({alert['direzione']} soglia)")
    else:
        print("Nessun alert")


if __name__ == "__main__":
    main()
