#!/usr/bin/env python3
# Uso: python3 rating_dso_clienti.py < input (vedi docstring per formato)
"""Rating clienti: DSO medio per cliente con matching pagamenti↔fatture e factoring.

Oracolo (7° ciclo, set 1, 2026-08-24). Formula REALE minata dal progetto rating
clienti di REPO-E (Codice.js, analizzaRatingClienti):

1. Matching pagamento→fattura, in ordine: (a) per CODICE documento nella
   descrizione del pagamento (pattern tipo 25OV-123456), prima fattura non
   ancora abbinate che lo contiene; (b) in fallback: stesso cliente
   (normalizzato trim/minuscolo/spazi collassati) E data entro 7 giorni E
   importo entro 1 EUR. La cessione a FACTOR pro soluto è un PAGAMENTO alla
   data di cessione (data estratta dalla descrizione, formato ddMMyy).
2. giorni = data pagamento − data fattura; scartati se <0 o >365 (guardia
   contro i falsi abbinate: un pagamento prima della fattura non è velocità,
   è un errore di matching).
3. DSO medio per cliente = somma giorni / fatture pagate, arrotondato.
4. Fatture non pagate contate a parte; pagamenti non abbinate elencati a
   parte (scarto mai silenzioso — nel progetto reale finiscono in un foglio
   "Pagamenti non associati").

CONFINE DICHIARATO (lezione del corpus, qui fatta propria): il codice reale
calcola media=0 quando il cliente non ha NESSUNA fattura pagata — uno zero
che si legge «paga subito» e invece vuol dire «non misurabile». Questo
oracolo stampa quei clienti come DSO «n.d. (solo fatture non pagate)» invece
di 0: la forma del numero dichiara cosa contiene.

Uso: python3 tools/rating_dso_clienti.py < movimenti.csv
CSV: tipo,data_documento,data_registrazione,nr_doc,cliente,descrizione,importo
tipo = "fattura" | "pagamento" | "cessione" (il tipo reale si deduce dalla
colonna tipo documento / descrizione: la cessione contiene 'CessioneFACTOR')
"""
import csv
import re
import sys
from datetime import date

CODICE_RE = re.compile(r"\d{2}(OV|FVI|CORR)-\d+")
CESSIONE_RE = re.compile(r"(?P<cod>\d{2}\w{2}-\d{6}) (?P<gg>\d{2})(?P<mm>\d{2})(?P<aa>\d{2})")


def normalizza(t):
    return re.sub(r"\s+", " ", (t or "").strip().lower())


def main():
    """Movimenti CSV in stdin → DSO medio per cliente. Il matching è quello
    del progetto reale (regola 1-2 del docstring); i clienti senza fatture
    pagate restano «n.d.»: la forma del numero dichiara cosa contiene.
    """
    righe = list(csv.DictReader(sys.stdin))
    fatture, pagamenti = [], []
    for r in righe:
        tipo = (r["tipo"] or "").strip().lower()
        cliente = normalizza(r.get("cliente"))
        importo = float(r["importo"] or 0)
        descrizione = (r.get("descrizione") or "")
        if tipo == "fattura":
            fatture.append({"cliente": cliente, "data": date.fromisoformat(r["data_documento"]),
                            "descrizione": descrizione, "importo": importo, "matched": False})
        elif tipo in ("pagamento", "cessione"):
            d = date.fromisoformat(r["data_documento"])
            if tipo == "cessione":
                m = CESSIONE_RE.search(descrizione)
                if m:
                    d = date(2000 + int(m.group("aa")), int(m.group("mm")), int(m.group("gg")))
            pagamenti.append({"data": d, "cliente": cliente, "descrizione": descrizione, "importo": importo})

    clienti = {}
    non_matchati = []
    for p in pagamenti:
        match = None
        m = CODICE_RE.search(p["descrizione"])
        if m:
            match = next((f for f in fatture if m.group(0) in f["descrizione"] and not f["matched"]), None)
        if match is None:
            match = next((f for f in fatture if not f["matched"]
                          and f["cliente"] == p["cliente"]
                          and abs((p["data"] - f["data"]).days) <= 7
                          and abs(f["importo"] - p["importo"]) < 1), None)
        if match is None:
            non_matchati.append(p)
            continue
        giorni = (p["data"] - match["data"]).days
        if giorni < 0 or giorni > 365:
            # bug reale (revisione 14 lenti, 2026-08-28): un pagamento scartato da questa
            # guardia spariva del tutto — non contato come non-matchato (nonostante il
            # docstring dichiari "scarto mai silenzioso"), né l'importo né il conteggio
            # "Non matchati" lo riflettevano. Ora entra in non_matchati come ogni altro
            # scarto, non solo quelli senza alcun candidato di match.
            non_matchati.append(p)
            continue  # guardia del codice reale contro i falsi matching
        match["matched"] = True
        c = clienti.setdefault(match["cliente"], {"pagate": 0, "somma_giorni": 0, "non_pagate": 0})
        c["pagate"] += 1
        c["somma_giorni"] += giorni
    for f in fatture:
        if not f["matched"]:
            clienti.setdefault(f["cliente"], {"pagate": 0, "somma_giorni": 0, "non_pagate": 0})["non_pagate"] += 1

    print(f"Fatture: {len(fatture)} · Pagamenti/cessioni: {len(pagamenti)} · Non matchati: {len(non_matchati)}")
    print(f"{'cliente':<28} {'pagate':>6} {'DSO medio':>10} {'non pagate':>10}")
    for nome in sorted(clienti, key=lambda n: -(clienti[n]["somma_giorni"] / clienti[n]["pagate"] if clienti[n]["pagate"] else -1)):
        v = clienti[nome]
        if v["pagate"] > 0:
            dso = f"{round(v['somma_giorni'] / v['pagate'])} gg"
        else:
            dso = "n.d."
        print(f"{nome:<28} {v['pagate']:>6} {dso:>10} {v['non_pagate']:>10}")
    clienti_solo_non_pagate = [n for n, v in clienti.items() if v["pagate"] == 0]
    if clienti_solo_non_pagate:
        print(f"NOTA confine: {len(clienti_solo_non_pagate)} cliente/i con DSO 'n.d.' — solo fatture non pagate:")
        print("  nel codice REPO-E questi escono con DSO 0, che si legge 'paga subito' e invece è 'non misurabile'.")
    for p in non_matchati:
        print(f"  NON MATCHATO: {p['data']} {p['importo']:.2f} {p['descrizione'][:50]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
