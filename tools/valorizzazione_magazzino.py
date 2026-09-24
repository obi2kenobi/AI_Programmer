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
import math
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
            # (Q22, 2026-09-23): «nan»/«inf» passavano da float() e davano «nan EUR» con rc 0 —
            # un costo non finito e' non numerico come «abc»: ignorato e dichiarato (senza costo)
            try:
                v = float(raw)
                if not math.isfinite(v):
                    raise ValueError("non finito")
                costi[codice] = v
            except ValueError:
                print(f"ATTENZIONE: costo_medio non numerico per {codice}: '{raw}' — ignorato", file=sys.stderr)
    return costi


def applica_override(costo, override):
    """PERCENTUALE: costo*(1+v/100) · EURO: costo+v. override None → costo invariato."""
    if not override:
        return costo
    # (2026-09-24, quinto ventaglio, R3 R4): un override stringa («EURO+2») era un AttributeError
    if not isinstance(override, dict):
        raise ValueError(f"override non e' un oggetto {{type, value}}: {override!r}")
    tipo = str(override.get("type", "")).upper()
    # (Q22): un override SENZA value valeva 0 in silenzio — la riga risultava «valorizzata con
    # override» senza che nessuno l'avesse deciso. Assente non e' zero: si dichiara.
    if "value" not in override:
        raise ValueError(f"override senza value: {override!r}")
    try:
        valore = float(override["value"])
    except (TypeError, ValueError):
        raise ValueError(f"override con value non numerico: {override!r}")
    if not math.isfinite(valore):
        raise ValueError(f"override con value non finito: {override!r}")
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
    """Il cuore dell'oracolo: per riga — location esclusa? riportata a parte.
    Senza costo? anomalia, NON zero. Altrimenti costo risolto (catena
    override), valore=qty×costo; le negative entrano nel totale ESDO
    flaggate (regole 3-5 del docstring).
    """
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
        # (Q22): qty vuota = traceback, qty «nan» = «valore +nan EUR». Senza quantita' non si valuta.
        try:
            qty = float(r["qty"])
        except (TypeError, ValueError):
            raise ValueError(f"qty non numerica per {codice}: {r['qty']!r}")
        if not math.isfinite(qty):
            raise ValueError(f"qty non finita per {codice}: {r['qty']!r}")
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
    """Report: totale SOLO delle location considerate, dettaglio ordinato per
    valore, anomalie nominate, escluse col loro valore, costi generali
    dichiarati-non-applicati (regola 6: il punto di applicazione non è
    provato, si chiede al proprietario del dominio).
    """
    if len(sys.argv) != 2:
        print("uso: valorizzazione_magazzino.py config.json < righe.csv", file=sys.stderr)
        return 1
    # (giro 21, 2026-09-20 — D32): config inesistente o colonne sbagliate = traceback nudo.
    # Stesso gesto di scadenzario_aging: si dice cosa manca.
    try:
        with open(sys.argv[1], encoding="utf-8") as f:
            cfg = json.load(f)
    except (OSError, ValueError) as e:
        print(f"uso: valorizzazione_magazzino.py config.json < righe.csv — config non leggibile: {e}", file=sys.stderr)
        return 1
    # (2026-09-24, quinto ventaglio, R3 R4): una config lista, o una tabella di override lista, erano un traceback
    if not isinstance(cfg, dict):
        print("uso: valorizzazione_magazzino.py — la config deve essere un oggetto JSON {...}", file=sys.stderr)
        return 1
    tabelle_storte = [t for t in ("override_gruppi", "override_categorie", "override_articoli") if not isinstance(cfg.get(t) or {}, dict)]
    if tabelle_storte:
        print(f"uso: valorizzazione_magazzino.py — {', '.join(tabelle_storte)} deve essere un oggetto {{codice: override}}", file=sys.stderr)
        return 1
    reader = csv.DictReader(sys.stdin)
    mancanti = [c for c in ("codice", "qty") if c not in (reader.fieldnames or [])]
    if mancanti:
        print(f"uso: valorizzazione_magazzino.py config.json < righe.csv — colonne mancanti: {', '.join(mancanti)}", file=sys.stderr)
        return 1
    righe = list(reader)
    # (Q22): con zero righe stampava «Valore totale 0.00 EUR», rc 0
    if not righe:
        print(f"ERRORE: nessuna riga valida nell'input — nessun verdetto (un estratto vuoto e' un'estrazione fallita finche' non si dimostra il contrario; Q22, 2026-09-23)", file=sys.stderr)
        return 1
    try:
        totale, dettaglio, senza_costo, negative, escluse = valorizza(righe, cfg)
    except ValueError as e:
        print(f"ERRORE: {e} — nessuna valorizzazione (Q22: prima era un traceback o un valore inventato)", file=sys.stderr)
        return 1

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
