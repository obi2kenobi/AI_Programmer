#!/usr/bin/env python3
"""Corregge i TIPI dei campi del censimento usando $metadata (schema vero, non campioni).

2026-08-26: la verifica del censimento ha trovato 901 campi importo/quantità
tipizzati 'int' solo perché il campione era 0 — inferire il tipo da poche righe
è debole dove lo zero è un valore legittimo. OData V4 pubblica lo schema vero
in <base>/ODataV4/$metadata: questo tool lo scarica (stesse credenziali di
bc_map), mappa EntitySet→EntityType→Property/Type, e corregge la colonna
Tipo di ogni file endpoint con il tipo di schema (Edm.Decimal→float ecc.),
PRESERVANDO Significato/Verificato (stesso merge di bc_map).
Stampa il conto delle correzioni per file; esce 1 se il metadata non è raggiungibile.
"""
import glob
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

import importlib.util
spec = importlib.util.spec_from_file_location("bcm", os.path.join(os.path.dirname(__file__), "bc_map.py"))
bcm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bcm)

EDM = {"Edm.Decimal": "float", "Edm.Double": "float", "Edm.Single": "float",
       "Edm.Int16": "int", "Edm.Int32": "int", "Edm.Int64": "int",
       "Edm.String": "string", "Edm.Boolean": "bool", "Edm.Guid": "guid",
       "Edm.Date": "date", "Edm.DateTimeOffset": "datetime"}


def main():
    """Scarica $metadata (schema VERO, non campioni), mappa EntitySet→
    EntityType→Property/Type e corregge la colonna Tipo dei censimenti con
        merge che PRESERVA Significato/Verificato (stesso contratto di bc_map).
    Credenziali irraggiungibili: morte loud, non traceback nudo.
    """
    raw = open(bcm.CRED_FILE, encoding="utf-8", errors="ignore").read()
    c = {k: bcm.cred(k, raw) for k in ("client_id", "client_secret", "scope", "token_url", "base_url")}
    token = bcm.get_token(c)
    # $metadata sta a livello tenant, PRIMA della Company(...): base_url la porta nelle credenziali
    base = c["base_url"].split("/Company(")[0].rstrip("/") + "/$metadata"
    req = urllib.request.Request(base, headers={"Authorization": f"Bearer {token}"})
    xml = urllib.request.urlopen(req, timeout=120).read()
    root = ET.fromstring(xml)
    ns = {"edmx": "http://docs.oasis-open.org/odata/ns/edmx",
          "edm": "http://docs.oasis-open.org/odata/ns/edm"}
    # EntitySet Name -> EntityType Name (senza namespace)
    set2type = {}
    for es in root.iter("{http://docs.oasis-open.org/odata/ns/edm}EntitySet"):
        set2type[es.get("Name")] = es.get("EntityType").split(".")[-1]
    # EntityType Name -> {Property: tipo-stdio}
    type2props = {}
    for et in root.iter("{http://docs.oasis-open.org/odata/ns/edm}EntityType"):
        type2props[et.get("Name")] = {p.get("Name"): EDM.get(p.get("Type"), p.get("Type"))
                                      for p in et.iter("{http://docs.oasis-open.org/odata/ns/edm}Property")}
    n_file = n_cor = 0
    for path in sorted(glob.glob("docs/bc/endpoints/*.md")):
        nome = os.path.basename(path)[:-3]
        et = set2type.get(nome)
        props = type2props.get(et) if et else None
        if not props:
            continue
        righe = open(path, encoding="utf-8").read().split("\n")
        cambiati = 0
        for i, r in enumerate(righe):
            m = re.match(r"(\| `[^`]+` \| )(\w+) \|", r)
            if not m:
                continue
            campo = r.split("`")[1]
            vero = props.get(campo)
            if vero and vero != m.group(2):
                righe[i] = r.replace(f"| {m.group(2)} |", f"| {vero} |", 1)
                cambiati += 1
        if cambiati:
            open(path, "w", encoding="utf-8").write("\n".join(righe))
            n_file += 1
            n_cor += cambiati
            print(f"  {nome}: {cambiati} tipi corretti dallo schema")
    print(f"TOTALE: {n_cor} tipi corretti in {n_file} file (sorgente: $metadata, non campioni)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# Limiti dichiarati: formula minata da REPO-E. Dato assente diverso da zero.
