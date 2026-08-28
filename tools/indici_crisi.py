#!/usr/bin/env python3
"""Indici della crisi d'impresa (CNDCEC / CCII, D.Lgs 14/2019), settore G46.

Formula reale (oracolo, non inventata): un modulo di analisi indici di crisi (repo
esterno REPO-E, cartella gas-src/, non in questo hub), letto riga per riga sul codice
reale. Le SOGLIE sono quelle pubbliche CNDCEC per il settore ATECO G46 (Commercio
all'ingrosso) — non un dato aziendale, un riferimento regolatorio pubblico. La
mappatura conto-per-conto che produce gli aggregati (oneriFin, ricavi, pn, ecc.) È
invece specifica del piano dei conti dell'azienda e NON è riprodotta qui: questo tool
prende gli aggregati già calcolati come input.

  pct(n, d)       = (n / d) * 100 se d != 0, altrimenti 0
  5 indici        = pct(numeratore, denominatore) confrontato con una soglia settoriale,
                    verso "ge" (allarme se valore >= soglia) o "le" (allarme se <= soglia)
  crisiPresunta   = PN < 0  OPPURE  tutti e 5 gli indici in allarme insieme
                    (PN negativo fa presunzione DA SOLO; quattro su cinque NON bastano)

LIMITE NOTO dell'oracolo (non un difetto di questo tool): con un denominatore a zero,
pct() restituisce 0, e i due indici "ge" non possono mai scattare in quel caso — un
azzeramento per un motivo diverso da "dato assente" (es. una lettura vuota) renderebbe
la presunzione di crisi impossibile invece che incerta. Vale come nota nel risultato,
non come correzione: è così anche nell'oracolo.

Uso: python3 tools/indici_crisi.py < aggregati.json
"""
import json
import sys

SOGLIE_G46 = {
    "oneriFinRicavi": {"soglia": 2.1, "verso": "ge", "nome": "Oneri finanziari / Ricavi"},
    "pnDebiti": {"soglia": 6.3, "verso": "le", "nome": "Patrimonio netto / Debiti totali"},
    "cashFlowAttivo": {"soglia": 0.6, "verso": "le", "nome": "Cash flow / Attivo"},
    "liquidita": {"soglia": 101.4, "verso": "le", "nome": "Liquidità (att. correnti / pass. correnti)"},
    "tribPrevAttivo": {"soglia": 2.9, "verso": "ge", "nome": "Debiti tributari e previdenziali / Attivo"},
}


def pct(n, d):
    return (n / d) * 100 if d else 0


def valuta_indici_crisi(a):
    numeratori_denominatori = {
        "oneriFinRicavi": (a["oneriFin"], a["ricavi"]),
        "pnDebiti": (a["pn"], a["passivoTot"]),
        "cashFlowAttivo": (a["cashFlow"], a["attivo"]),
        "liquidita": (a["attCorrenti"], a["passCorrenti"]),
        "tribPrevAttivo": (a["debTrib"] + a["debPrev"], a["attivo"]),
    }
    indici = []
    for chiave, (n, d) in numeratori_denominatori.items():
        s = SOGLIE_G46[chiave]
        valore = pct(n, d)
        allarme = valore >= s["soglia"] if s["verso"] == "ge" else valore <= s["soglia"]
        indici.append({"chiave": chiave, "nome": s["nome"], "valore": valore,
                        "soglia": s["soglia"], "verso": s["verso"], "allarme": allarme})
    return indici


def crisi_presunta(pn, indici):
    return pn < 0 or all(i["allarme"] for i in indici)


def main():
    try:
        a = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print("uso: indici_crisi.py < bilancio.json (pn, ricavi, patrimonio netto, debiti tributari, perdite esercizi precedenti)", file=sys.stderr)
        return 1
    indici = valuta_indici_crisi(a)
    for i in indici:
        marcatore = "🔴" if i["allarme"] else "🟢"
        print(f"{marcatore} {i['nome']}: {i['valore']:.1f}% (soglia {i['soglia']} {i['verso']})")
    presunta = crisi_presunta(a["pn"], indici)
    print("🔴 CRISI PRESUNTA" if presunta else "🟢 Nessuna presunzione di crisi")


if __name__ == "__main__":
    sys.exit(main())
