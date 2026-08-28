#!/usr/bin/env python3
"""Scadenzario clienti/fornitori: classificazione a fasce di scadenza (aging) e totali.

Formula reale (oracolo, non inventata): un modulo di scadenzario clienti/fornitori
(repo esterno REPO-E, cartella gas-src/, non in questo hub) — letto riga per riga sul
codice reale:

  fascia(giorni) = "LUNGO"          se giorni assente
                   "SCADUTO >60"    se giorni < -60
                   "SCADUTO 31-60"  se giorni < -30
                   "SCADUTO <=30"   se giorni < 0
                   "BREVE"          se giorni <= 30
                   "MEDIO"          se giorni <= 90
                   "LUNGO"          altrimenti
  (giorni = giorni residui alla scadenza: negativo = già scaduto da N giorni)

  Convenzione di segno (dal codice reale): l'importo di una riga CLIENTE è preso
  come da BC (positivo = credito da incassare); l'importo di una riga FORNITORE
  fattura/invoice diventa NEGATIVO (-abs), una nota di credito resta POSITIVO
  (+abs) — l'uscita di cassa futura è sempre negativa, l'entrata sempre positiva,
  qualunque sia il tipo di documento originale.

  Totali: per ogni fascia, somma degli importi con quel segno; entrate = somma
  importi positivi; uscite = somma importi negativi; saldo = entrate + uscite;
  scaduto_totale = somma delle tre fasce "SCADUTO *".

Uso: python3 tools/scadenzario_aging.py < righe.csv
CSV con colonne: tipo,importo,giorni (giorni vuoto = nessuna data di scadenza)
"""
import csv
import sys

FASCE_SCADUTO = ("SCADUTO >60", "SCADUTO 31-60", "SCADUTO <=30")
FASCE_ORDINE = FASCE_SCADUTO + ("BREVE", "MEDIO", "LUNGO")


def fascia_dettaglio(giorni):
    if giorni is None or giorni == "":
        return "LUNGO"
    g = int(giorni)
    if g < -60:
        return "SCADUTO >60"
    if g < -30:
        return "SCADUTO 31-60"
    if g < 0:
        return "SCADUTO <=30"
    if g <= 30:
        return "BREVE"
    if g <= 90:
        return "MEDIO"
    return "LUNGO"


def importo_fornitore(importo_bc, doc_type):
    is_uscita = doc_type in ("Invoice", "Fattura")
    return -abs(importo_bc) if is_uscita else abs(importo_bc)


def aggrega_totali(righe):
    tot = {f: 0.0 for f in FASCE_ORDINE}
    entrate = uscite = 0.0
    for r in righe:
        tot[r["fascia"]] += r["importo"]
        if r["importo"] > 0:
            entrate += r["importo"]
        elif r["importo"] < 0:
            uscite += r["importo"]
    scaduto_totale = sum(tot[f] for f in FASCE_SCADUTO)
    return {
        "per_fascia": tot,
        "entrate": entrate,
        "uscite": uscite,
        "saldo": entrate + uscite,
        "scaduto_totale": scaduto_totale,
    }


def main():
    righe = []
    for r in csv.DictReader(sys.stdin):
        giorni = r["giorni"].strip() if r["giorni"].strip() != "" else None
        tipo = r["tipo"]
        importo_bc = float(r["importo"])
        # bug reale (revisione 14 lenti, 2026-08-28): importo_fornitore() era definita ma
        # mai chiamata — ogni riga fornitore finiva col segno grezzo di BC (positivo),
        # quindi in "entrate" invece che in "uscite". "tipo" porta sia la controparte
        # (Cliente/Fornitore) sia il tipo documento (es. "Fornitore Fattura"); solo le
        # righe Fornitore applicano la convenzione dell'uscita di cassa.
        if tipo.startswith("Fornitore"):
            doc_type = tipo[len("Fornitore"):].strip()
            importo = importo_fornitore(importo_bc, doc_type)
        else:
            importo = importo_bc
        righe.append({
            "tipo": tipo,
            "importo": importo,
            "fascia": fascia_dettaglio(giorni),
        })
    r = aggrega_totali(righe)
    print(f"Entrate: {r['entrate']:+.2f}€")
    print(f"Uscite: {r['uscite']:+.2f}€")
    print(f"Saldo netto: {r['saldo']:+.2f}€")
    print(f"Scaduto totale: {r['scaduto_totale']:+.2f}€")
    for f in FASCE_ORDINE:
        print(f"  {f}: {r['per_fascia'][f]:+.2f}€")


if __name__ == "__main__":
    main()
