#!/usr/bin/env python3
"""Valorizzazione di magazzino a costo medio con override a livelli.

Oracolo (6° ciclo, Set 1 giro 3, 2026-08-24). Formula REALE minata dal progetto
di gestione magazzino di REPO-E (repo esterno, cartella gas-src/), non inventata:

1. Costo base per articolo = costo medio dallo snapshot mensile, "primo valore
   non-nullo disponibile per codice" (PhysicalInventory.js, funzione
   _explodeSelectedByLocation: "finalCost per articolo (costo medio): non dipende
   da location, lo prendiamo dallo snapshot mensile prendendo il primo valore
   non-nullo disponibile per codice").
2. Override a livelli, applicati SOPRA il costo base, catena articolo >
   categoria > gruppo (il primo che esiste vince, non si sommano) — forma
   {type: PERCENTUALE|EURO, value: +/-n} dichiarata dal foglio di configurazione
   (ValuationConfig.js: override gruppi/categorie/articoli, log di
   testValuationConfig: "gruppo: PERCENTUALE +5%" / "articolo: EURO +2.00€").
3. Articolo SENZA costo = anomalia critica che "distorce la valorizzazione"
   (SnapshotExporter.js: arancione = Senza costo CRITICO): NON vale zero, NON
   entra nel totale — viene contata e listata.
4. Location escluse (es. depositi terzi) escluse dalla valorizzazione ma
   RIPORTATE separatamente con il loro valore — scarto mai silenzioso
   (pattern patterns/scarto-mai-silenzioso.md; LocationPolicy.js).
5. Giacenza negativa = anomalia "errori di scarico da bonificare": valutata
   (valore negativo, entra nel totale) E flaggata (AIReportAnalysis.js).
6. Costi generali %: la percentuale ESISTE in configurazione (generalCostsPercent)
   ma nel codice REPO-E viene solo CARICATA, mai applicata — nessun consumer
   fuori dal loader (verificato a grep il 2026-08-24). Questo oracolo NON la
   applica e NON la indovina: la riporta come "punto di applicazione non provato
   — chiedere al proprietario del dominio prima di applicarla" (regola
   controllo-gestione: una formula di business non si indovina mai).

Uso: python3 tools/valorizzazione_magazzino.py config.json < righe.csv
CSV con colonne: codice,gruppo,categoria,location,qty,costo_medio
(costo_medio può essere vuoto su alcune righe: vince il primo non-vuoto per codice)
config.json: {"override_gruppi": {...}, "override_categorie": {...},
"override_articoli": {...}, "costi_generali_percent": N, "location_escluse": [...]}
Ogni override: {"type": "PERCENTUALE"|"EURO", "value": numero con segno}
"""
import csv
import json
import sys


def costo_base_per_codice(righe):
    """Primo costo medio non-nullo per codice, attraversando le location."""
    costi = {}
    for r in righe:
        codice = r["codice"].strip()
        if codice in costi:
            continue
        raw = (r.get("costo_medio") or "").strip()
        if raw != "":
            try:
                costi[codice] = float(raw)
            except ValueError:
                print(f"ATTENZIONE: costo_medio non numerico per {codice}: '{raw}' — ignorato", file=sys.stderr)
    return costi


def applica_override(costo, override):
    """PERCENTUALE: costo*(1+v/100) · EURO: costo+v. override None → costo invariato."""
    if not override:
        return costo
    tipo = str(override.get("type", "")).upper()
    valore = float(override.get("value", 0))
    if tipo == "PERCENTUALE":
        return costo * (1 + valore / 100.0)
    if tipo == "EURO":
        return costo + valore
    raise ValueError(f"tipo override sconosciuto: {override!r} (attesi PERCENTUALE|EURO)")


def risolvi_costo(codice, gruppo, categoria, costo_base, cfg):
    """Catena articolo > categoria > gruppo: il primo override esistente vince."""
    for tabella, chiave in (
        ("override_articoli", codice),
        ("override_categorie", categoria),
        ("override_gruppi", gruppo),
    ):
        override = (cfg.get(tabella) or {}).get(chiave)
        if override:
            return applica_override(costo_base, override), f"{tabella}:{chiave}"
    return costo_base, "costo_base"


def valorizza(righe, cfg):
    costi_base = costo_base_per_codice(righe)
    escluse = set(cfg.get("location_escluse") or [])
    totale = 0.0
    anomalie_senza_costo, anomalie_negative, righe_escluse = [], [], []
    dettaglio = []
    for r in righe:
        codice = r["codice"].strip()
        gruppo = (r.get("gruppo") or "").strip()
        categoria = (r.get("categoria") or "").strip()
        location = (r.get("location") or "PRINCIPALE").strip()
        qty = float(r["qty"])
        if location in escluse:
            base = costi_base.get(codice)
            valore_escluso = round(qty * base, 2) if base is not None else None
            righe_escluse.append({"codice": codice, "location": location,
                                  "valore_non_valorizzato": valore_escluso})
            continue
        if codice not in costi_base:
            anomalie_senza_costo.append(codice)
            continue
        costo, fonte = risolvi_costo(codice, gruppo, categoria, costi_base[codice], cfg)
        valore = round(qty * costo, 2)
        totale += valore
        riga = {"codice": codice, "qty": qty, "costo_risolto": round(costo, 6),
                "fonte_costo": fonte, "valore": valore}
        if qty < 0:
            anomalie_negative.append(riga)
        dettaglio.append(riga)
    dettaglio.sort(key=lambda x: -x["valore"])
    return totale, dettaglio, anomalie_senza_costo, anomalie_negative, righe_escluse


def main():
    if len(sys.argv) != 2:
        print("uso: valorizzazione_magazzino.py config.json < righe.csv", file=sys.stderr)
        return 1
    with open(sys.argv[1], encoding="utf-8") as f:
        cfg = json.load(f)
    righe = list(csv.DictReader(sys.stdin))
    totale, dettaglio, senza_costo, negative, escluse = valorizza(righe, cfg)

    print(f"Righe lette: {len(righe)}")
    print(f"Valore totale (solo location considerate): {totale:.2f} EUR")
    print(f" Articoli valorizzati: {len(dettaglio)}")
    for r in dettaglio:
        print(f"  {r['codice']}: qty={r['qty']:+g} costo={r['costo_risolto']:.4f}"
              f" ({r['fonte_costo']}) valore={r['valore']:+.2f} EUR")
    if senza_costo:
        print(f" ANOMALIA senza costo (non valutati, NON valgono zero): {len(senza_costo)} — {', '.join(sorted(set(senza_costo)))}")
    if negative:
        pezzi = sum(r["qty"] for r in negative)
        print(f" ANOMALIA giacenza negativa: {len(negative)} righe, {pezzi:+g} pz (valutate e flaggate)")
    if escluse:
        parti = []
        for e in escluse:
            v = e["valore_non_valorizzato"]
            v_txt = f"{v:.2f} EUR" if v is not None else "senza costo (non valorizzabile)"
            parti.append(f"{e['codice']}@{e['location']} (valore non valorizzato: {v_txt})")
        print(f" Location escluse dalla valorizzazione: {len(escluse)} righe — {', '.join(parti)}")
    gc = cfg.get("costi_generali_percent") or 0
    if gc:
        print(f" costi_generali_percent={gc}% configurato ma NON applicato: punto di applicazione")
        print(f" non provato nel codice REPO-E (caricato in config, nessun consumer) —")
        print(f" chiedere al proprietario del dominio prima di applicarlo sopra il totale o sul costo unitario.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
