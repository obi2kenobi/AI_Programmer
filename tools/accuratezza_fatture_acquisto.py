#!/usr/bin/env python3
"""Accuratezza fatture di acquisto: matching fattura↔ordine e accuratezza complessiva.

Oracolo (6° ciclo, Set 1 giro 5, 2026-08-24). Formula REALE minata dal progetto
controllo accuratezza fatture di acquisto di REPO-E (cartella gas-src/):

1. Matching fattura→ordine per numero d'ordine. Esiti per fattura:
   matching valido · senza ordine · ordine inesistente · discrepanza importo.
2. SOLO l'OVER-INVOICING è discrepanza (Elaborazione.js ~415, commento del
   codice originale): eccedenza = importoFattura − importoOrdine, percentuale
   = eccedenza/importoOrdine × 100, discrepanza se % > SOGLIA_DISCREPANZA (5).
   Una fattura INFERIORE all'ordine è fatturazione parziale/a tranche e NON è
   una discrepanza — nel codice REPO-E questo era un falso positivo corretto a
   mano: la lezione è dentro l'oracolo, non nel README.
3. Fatture senza ordine da fornitore WHITELIST = legittime (canoni, abbonamenti):
   NON sono errori. Le altre = anomale (Elaborazione.js calcolaStatisticheFinali).
4. erroriReali = fattureAnomaleSenzaOrdine + fattureOrdineInesistente +
   discrepanzeImporti.
5. percentualeAccuratezza = (totaleFatture − erroriReali) / totaleFatture × 100;
   margineErrore = erroriReali / totaleFatture × 100; obiettivo raggiunto se
   margineErrore < obiettivoMargineErrorePct (0.1% di default, Config.js).

Uso: python3 tools/accuratezza_fatture_acquisto.py config.json fatture.csv ordini.csv
fatture.csv: nr,fornitore,ordine_nr,importo  (ordine_nr vuoto = senza ordine)
ordini.csv:  nr,importo
config.json: {"soglia_discrepanza_pct": 5, "obiettivo_margine_errore_pct": 0.1,
              "whitelist_fornitori": ["..."]}
"""
import csv
import json
import sys


def leggi_csv(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def main():
    """Fatture vs ordini → accuratezza (T−E)/T. Solo l'OVER-invoicing è
    discrepanza (regola 1 del docstring); la whitelist legittima il
    senza-ordine; l'obiettivo dichiarato in config decide il verdetto.
    """
    if len(sys.argv) != 4:
        print("uso: accuratezza_fatture_acquisto.py config.json fatture.csv ordini.csv", file=sys.stderr)
        return 1
    with open(sys.argv[1], encoding="utf-8") as f:
        cfg = json.load(f)
    soglia = float(cfg.get("soglia_discrepanza_pct", 5))
    obiettivo_pct = float(cfg.get("obiettivo_margine_errore_pct", 0.1))
    whitelist = set(cfg.get("whitelist_fornitori") or [])

    fatture = leggi_csv(sys.argv[2])
    ordini = {r["nr"].strip(): float(r["importo"]) for r in leggi_csv(sys.argv[3])}

    validi, discrepanze, inesistenti = [], [], []
    legittime_senza_ordine, anomale_senza_ordine = [], []
    ordine_importo_non_valido = []
    for f in fatture:
        nr = f["nr"]
        fornitore = (f.get("fornitore") or "").strip()
        onr = (f.get("ordine_nr") or "").strip()
        importo = float(f["importo"])
        if onr == "":
            (legittime_senza_ordine if fornitore in whitelist else anomale_senza_ordine).append(nr)
            continue
        if onr not in ordini:
            inesistenti.append({"fattura": nr, "ordine": onr})
            continue
        importo_ordine = ordini[onr]
        # bug reale (revisione 14 lenti, 2026-08-28): un ordine con importo <= 0 (dato
        # anomalo a monte, plausibile: es. ordine registrato a 0€ per errore) forzava pct
        # a 0.0 e la fattura passava "valida" a prescindere dall'importo fatturato — una
        # fattura di 5000€ contro un ordine da 0€ passava inosservata invece di essere
        # segnalata come caso limite/dato anomalo. Categoria a sé, non silenziosamente
        # "valida": la percentuale di over-invoicing non è nemmeno definita a denominatore
        # nullo, non ha senso dichiarare "nessuna discrepanza" su un calcolo che non regge.
        if importo_ordine <= 0:
            ordine_importo_non_valido.append({"fattura": nr, "ordine": onr, "importo_ordine": importo_ordine, "importo_fattura": importo})
            continue
        eccedenza = importo - importo_ordine
        pct = eccedenza / importo_ordine * 100
        if pct > soglia:
            discrepanze.append({"fattura": nr, "ordine": onr, "eccedenza": eccedenza, "pct": pct})
        else:
            validi.append(nr)  # include fatturazione parziale: NON è discrepanza

    totale = len(fatture)
    errori_reali = len(anomale_senza_ordine) + len(inesistenti) + len(discrepanze) + len(ordine_importo_non_valido)
    accuratezza = (totale - errori_reali) / totale * 100 if totale else 0.0
    margine_errore = errori_reali / totale * 100 if totale else 0.0

    print(f"Fatture totali: {totale}")
    print(f" Matching validi (incl. fatturazione parziale): {len(validi)}")
    print(f" Senza ordine — legittime (whitelist): {len(legittime_senza_ordine)}"
          + (f" — {', '.join(legittime_senza_ordine)}" if legittime_senza_ordine else ""))
    print(f" Senza ordine — anomale: {len(anomale_senza_ordine)}"
          + (f" — {', '.join(anomale_senza_ordine)}" if anomale_senza_ordine else ""))
    print(f" Ordine inesistente: {len(inesistenti)}"
          + (f" — {', '.join(x['fattura'] + '→' + x['ordine'] for x in inesistenti)}" if inesistenti else ""))
    oinv_desc = [f"{x['fattura']}→{x['ordine']} (fattura {x['importo_fattura']:.2f}€ vs ordine {x['importo_ordine']:.2f}€)" for x in ordine_importo_non_valido]
    print(f" Ordine con importo <= 0 (dato anomalo, percentuale non definita): {len(ordine_importo_non_valido)}"
          + (f" — {', '.join(oinv_desc)}" if oinv_desc else ""))
    print(f" Discrepanze over-invoicing (>{soglia:g}%): {len(discrepanze)}")
    for d in discrepanze:
        print(f"  {d['fattura']}→{d['ordine']}: fattura oltre ordine di {d['eccedenza']:+.2f} EUR ({d['pct']:+.1f}%)")
    print(f"Errori reali: {errori_reali} (anomale + inesistenti + discrepanze)")
    print(f"Accuratezza: {accuratezza:.1f}% · Margine di errore: {margine_errore:.1f}%")
    esito = "RAGGIUNTO" if margine_errore < obiettivo_pct else "NON raggiunto"
    print(f"Obiettivo (margine < {obiettivo_pct:g}%): {esito}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# Limiti dichiarati: formula minata da REPO-E. Dato assente diverso da zero.
