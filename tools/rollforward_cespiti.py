#!/usr/bin/env python3
"""Roll-forward annuale dei cespiti (costo storico, fondo, valore netto) per categoria.

Formula reale (oracolo, non inventata): un modulo di quadratura/roll-forward cespiti
(repo esterno REPO-E, cartella gas-src/, non in questo hub), letto riga per riga sul
codice reale:

  clOpen       = openCosto + openRival + openSval
  clAcq        = yearCosto
  clRivalSval  = yearRival + yearSval
  clCess       = Σ(costo + rival + sval) sui cespiti dismessi nell'anno (isDisposed
                 e yearCessioni != 0) della categoria
  clClose      = clOpen + clAcq + clRivalSval - clCess

  fondoOpen    = openFondo               [il fondo è convenzionalmente negativo]
  fondoAmm     = yearFondo               [l'ammortamento dell'anno, negativo]
  fondoCess    = Σ(-fondo) sui cespiti dismessi nell'anno della categoria
  fondoClose   = fondoOpen + fondoAmm + fondoCess

  vnOpen       = clOpen + fondoOpen      [valore netto = costo storico + fondo]
  vnClose      = clClose + fondoClose

Il segno del fondo è un invariante di dominio (lente dev-critic §2ter: un segno
sbagliato qui produce un roll-forward che quadra solo per caso su dati piccoli e
diverge silenziosamente su dati reali).

Uso: python3 tools/rollforward_cespiti.py < categoria.json
"""
import json
import sys


def calcola_roll_forward(fa, cespiti_categoria):
    disposti = [
        c for c in cespiti_categoria
        if c.get("isDisposed") and c.get("yearCessioni", 0) != 0
    ]
    cl_cess = sum(c["costo"] + c["rival"] + c["sval"] for c in disposti)
    fondo_cess = sum(-c["fondo"] for c in disposti)

    cl_open = fa["openCosto"] + fa["openRival"] + fa["openSval"]
    cl_acq = fa["yearCosto"]
    cl_rival_sval = fa["yearRival"] + fa["yearSval"]
    cl_close = cl_open + cl_acq + cl_rival_sval - cl_cess

    fondo_open = fa["openFondo"]
    fondo_amm = fa["yearFondo"]
    fondo_close = fondo_open + fondo_amm + fondo_cess

    vn_open = cl_open + fondo_open
    vn_close = cl_close + fondo_close

    return {
        "clOpen": cl_open, "clAcq": cl_acq, "clRivalSval": cl_rival_sval,
        "clCess": cl_cess, "clClose": cl_close,
        "fondoOpen": fondo_open, "fondoAmm": fondo_amm, "fondoCess": fondo_cess,
        "fondoClose": fondo_close,
        "vnOpen": vn_open, "vnClose": vn_close,
    }


def main():
    dati = json.load(sys.stdin)
    r = calcola_roll_forward(dati["categoria"], dati["cespiti"])
    for chiave, valore in r.items():
        print(f"{chiave}: {valore:.2f}")


if __name__ == "__main__":
    main()
