#!/usr/bin/env python3
"""Riconciliazione inventario fisico di magazzino.

Formula reale (oracolo, non inventata): il modulo di riconciliazione inventario
di un progetto reale di gestione magazzino (repo esterno REPO-E, cartella
gas-src/, non in questo hub) —
`delta = qtyFisica - qtyBC; deltaValore = delta * costoFinale`.
"Non contato" resta distinto da "contato a zero" (regola di business esplicita
nel codice originale): un articolo non contato non produce un delta numerico,
altrimenti un'assenza di verifica si confonderebbe con una verifica riuscita.

Uso: python3 tools/riconciliazione_magazzino.py < righe.csv
CSV con colonne: codice,qty_bc,costo_finale,qty_fisica,stato
stato = "Non Contato" (qty_fisica vuota) oppure qualsiasi altro valore se contato.
"""
import csv
import sys


def categorizza(righe):
    non_contato, senza_discrepanza, con_rettifica = [], [], []
    for r in righe:
        codice = r["codice"]
        stato = (r.get("stato") or "").strip()
        qty_fisica_raw = (r.get("qty_fisica") or "").strip()
        # bug reale (revisione 14 lenti, 2026-08-28): qty_bc/costo_finale venivano
        # convertiti con float() PRIMA del controllo "non contato" — una riga "Non Contato"
        # con costo_finale vuoto (plausibile: articolo non ancora valorizzato) faceva
        # crashare l'intero script con ValueError, perdendo anche l'output delle righe
        # valide già lette. Il controllo va fatto PRIMA di provare a convertire nulla.
        if stato.lower() == "non contato" or qty_fisica_raw == "":
            non_contato.append({"codice": codice, "delta": "", "delta_valore": ""})
            continue
        qty_bc = float(r["qty_bc"])
        costo_finale = float(r["costo_finale"])
        qty_fisica = float(qty_fisica_raw)
        # giri avversari 2026-08-28: nan/inf nel CSV devono dirsi, non produrre
        # delta "nan" silenziosi nell'output del magazzino
        import math
        if not (math.isfinite(qty_bc) and math.isfinite(costo_finale) and math.isfinite(qty_fisica)):
            print(f"ERRORE: valore non finito (nan/inf) per {codice}: rifiutato", file=sys.stderr)
            return 1
        delta = qty_fisica - qty_bc
        delta_valore = delta * costo_finale
        riga = {"codice": codice, "delta": delta, "delta_valore": delta_valore}
        if delta == 0:
            senza_discrepanza.append(riga)
        else:
            con_rettifica.append(riga)
    con_rettifica.sort(key=lambda r: -abs(r["delta_valore"]))
    return non_contato, senza_discrepanza, con_rettifica


def main():
    righe = list(csv.DictReader(sys.stdin))
    non_contato, senza_discrepanza, con_rettifica = categorizza(righe)
    print(f"Non contati: {len(non_contato)}")
    print(f"Senza discrepanza: {len(senza_discrepanza)}")
    print(f"Con rettifica: {len(con_rettifica)}")
    for r in con_rettifica:
        print(f"  {r['codice']}: delta={r['delta']:+g} deltaValore={r['delta_valore']:+.2f}€")


if __name__ == "__main__":
    main()
