#!/usr/bin/env python3
"""Controllo canoni leasing con adeguamento Euribor trimestrale arretrato.

Oracolo (7° ciclo, set 1, 2026-08-24). Formula REALE minata dal progetto di
controllo leasing del ciclo passivo di REPO-E (Codice.js,
calcolaImportoPrevistoLeasingTrimestrale + calcolaCapitaleResiduoEInteressi):

1. tassoBase = euriborStipula + spread · tassoCorrente = euriborCorrente +
   spread · deltaTasso = tassoCorrente − tassoBase (punti percentuali).
2. Capitale residuo ad AMMORTAMENTO UNIFORME (semplificazione DICHIARATA nel
   codice sorgente): capitaleInizialeStimato = canoneBase × durataMesi;
   residuo = iniziale × (mesiRimanenti / durataMesi).
3. quotaInteressiMensile = residuo × 2,5% / 12 — TASSO STIMATO dichiarato nel
   sorgente («assume tasso medio 2-3% annuo»): non è il tasso del contratto.
4. adeguamentoMensile = quotaInteressi × deltaTasso / 100;
   adeguamentoTrimestrale = adeguamentoMensile × 3 — TRIMESTRALE e ARRETRATO:
   a ottobre si riceve il canone di ottobre + l'adeguamento del trimestre
   PRECEDENTE (lug-ago-set), regola di dominio scritta nel commento originale.
5. importoPrevisto = canone mensile + adeguamento trimestrale.
6. Euribor corrente ASSENTE → NESSUN adeguamento, importo = canone, con nota
   esplicita «no adeguamento — Euribor mancante»: il dato assente dichiara se
   stesso, non vale zero in silenzio.
7. Se il calcolo del residuo fallisce, il codice reale usa la STIMA quota
   interessi = 30% del canone base — qui riprodotta dietro flag, per fedeltà,
   e dichiarata nell'output come stima.

I limiti sono quelli del codice reale: le stime (2,5%, 30%, ammortamento
uniforme) sono del progetto REPO-E, non formule contrattuali — chi vuole il
piano ammortamento vero deve chiedere il piano alla società di leasing.

Uso: python3 tools/leasing_amministrativo.py contratto.json
  {"canone_base": N, "totale_contratto": N, "spread": N, "euribor_stipula": N,
   "euribor_corrente": N|null, "data_inizio": "YYYY-MM-DD",
   "data_fine": "YYYY-MM-DD", "data_riferimento": "YYYY-MM-DD",
   "usa_stima_30": false}
"""
import json
import sys
from datetime import date


def mesi_tra(d1, d2):
    """Differenza di mesi calendario SENZA aggiustamento del giorno — fedele a
    calcolaMesiTra del codice REPO-E (anni*12 + mesi, il giorno non conta)."""
    return (d2.year - d1.year) * 12 + (d2.month - d1.month)


def capitale_residuo(canone_base, inizio, fine, riferimento):
    """Ammortamento UNIFORME (semplificazione DICHIARATA nel sorgente REPO-E,
    non un piano reale): iniziale stimato = canone×mesi; residuo = quota dei
    mesi rimanenti. La quota interessi usa il 2,5% STIMATO del sorgente: il
    tasso vero sta nel contratto, che qui non c'è.
    """
    durata = mesi_tra(inizio, fine)
    trascorsi = max(0, mesi_tra(inizio, riferimento))
    rimanenti = max(0, durata - trascorsi)
    perc_rimasta = rimanenti / durata if durata > 0 else 0.0
    iniziale_stimato = canone_base * durata
    residuo = iniziale_stimato * perc_rimasta
    quota_interessi_mensile = residuo * 0.025 / 12  # tasso STIMATO 2,5% (dichiarato)
    return {"durata_mesi": durata, "trascorsi": trascorsi, "rimanenti": rimanenti,
            "perc_rimasta": perc_rimasta, "capitale_residuo": residuo,
            "quota_interessi_mensile": quota_interessi_mensile}


def main():
    """Un contratto JSON → importo previsto col canone + adeguamento Euribor
    trimestrale ARRETRATO (regola 4 del docstring: a ottobre arriva l'adeguamento
    del trimestre precedente). Euribor corrente assente = NESSUN adeguamento,
    dichiarato, non zero in silenzio.
    """
    if len(sys.argv) != 2:
        print("uso: leasing_amministrativo.py contratto.json", file=sys.stderr)
        return 1
    with open(sys.argv[1], encoding="utf-8") as f:
        c = json.load(f)
    canone = float(c["canone_base"])
    if canone <= 0:
        print("ERRORE: canone base non valido", file=sys.stderr)
        return 1
    inizio = date.fromisoformat(c["data_inizio"])
    fine = date.fromisoformat(c["data_fine"])
    # giri avversari 2026-08-28 (D7): data_fine < data_inizio produceva mesi negativi
    # accettati in silenzio (durata -12). Un contratto che finisce prima di iniziare
    # è un dato marcio, non un caso limite.
    if fine < inizio:
        print("ERRORE: data_fine precedente a data_inizio", file=sys.stderr)
        return 1
    riferimento = date.fromisoformat(c.get("data_riferimento") or date.today().isoformat())
    spread = float(c["spread"])
    euribor_stipula = float(c["euribor_stipula"])
    euribor_corrente = c.get("euribor_corrente")

    if euribor_corrente is None:
        print(f"Importo previsto: {canone:.2f} EUR")
        print(f" Adeguamento: NESSUNO — Euribor corrente mancante (dato assente dichiarato, non zero in silenzio)")
        print(f" Nota: totale previsto = canone {canone:.2f} senza adeguamento")
        return 0

    r = capitale_residuo(canone, inizio, fine, riferimento)
    if c.get("usa_stima_30"):
        r["quota_interessi_mensile"] = canone * 0.30
        print(" ATTENZIONE: quota interessi = 30% del canone (STIMA di ripiego del codice REPO-E, dichiarata)")
    tasso_base = euribor_stipula + spread
    tasso_corrente = float(euribor_corrente) + spread
    delta = tasso_corrente - tasso_base
    adeguamento_mensile = r["quota_interessi_mensile"] * (delta / 100)
    adeguamento_trimestrale = adeguamento_mensile * 3
    previsto = canone + adeguamento_trimestrale

    print(f"Contratto: {inizio} → {fine} · riferimento {riferimento}")
    print(f" Durata {r['durata_mesi']} mesi · trascorsi {r['trascorsi']} · rimanenti {r['rimanenti']} ({r['perc_rimasta']:.1%})")
    print(f" Capitale residuo stimato: {r['capitale_residuo']:.2f} EUR (ammortamento UNIFORME — semplificazione dichiarata)")
    print(f" Quota interessi mensile: {r['quota_interessi_mensile']:.2f} EUR (tasso 2,5% STIMATO, non contrattuale)")
    print(f"Tassi: base {tasso_base:.3f}% · corrente {tasso_corrente:.3f}% · delta {delta:+.3f} punti")
    print(f"Adeguamento mensile: {adeguamento_mensile:+.2f} EUR · trimestrale ARRETRATO: {adeguamento_trimestrale:+.2f} EUR")
    print(f"Importo previsto: {previsto:.2f} EUR (canone {canone:.2f} + adeguamento {adeguamento_trimestrale:+.2f})")
    print(f"Nota dominio: l'adeguamento del trimestre PRECEDENTE arriva con il canone del trimestre successivo (arretrato).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
