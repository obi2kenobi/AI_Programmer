#!/usr/bin/env python3
"""Mappa i campi di un endpoint OData V4 di Business Central.

Uso: python3 tools/bc_map.py <NomeServizio> [top]

Legge le credenziali OAuth2 da 'credenziali BC.rtf' a runtime (mai hard-coded),
ottiene un token client_credentials, interroga l'endpoint e genera/aggiorna
docs/bc/endpoints/<NomeServizio>.md con l'elenco completo dei campi.
"""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

CRED_FILE = "credenziali BC.rtf"
OUT_DIR = "docs/bc/endpoints"


def cred(key, raw):
    m = re.search(r'"%s"\s*:\s*"([^"]+)"' % re.escape(key), raw)
    if not m:
        sys.exit(f"Chiave mancante nelle credenziali: {key}")
    return m.group(1)


def get_token(c):
    data = urllib.parse.urlencode({
        "grant_type": "client_credentials",
        "client_id": c["client_id"],
        "client_secret": c["client_secret"],
        "scope": c["scope"],
    }).encode()
    req = urllib.request.Request(c["token_url"], data=data)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)["access_token"]


def fetch(base_url, endpoint, token, top):
    url = f"{base_url}/{urllib.parse.quote(endpoint)}?$top={top}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
    })
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r).get("value", [])


def infer_type(v):
    if v is None:
        return "null"
    return {bool: "bool", int: "int", float: "float", str: "string"}.get(type(v), type(v).__name__)


def collect_fields(rows):
    """Unione ordinata dei campi su tutte le righe campione, con tipo e valore esempio."""
    fields = {}
    for row in rows:
        for k, v in row.items():
            if k not in fields:
                fields[k] = {"type": infer_type(v), "sample": v}
            elif fields[k]["sample"] in (None, "") and v not in (None, ""):
                fields[k] = {"type": infer_type(v), "sample": v}
    return fields


def leggi_curati(path):
    """Le colonne compilate a mano (Significato, Verificato) del file esistente,
    per campo: un refresh che le cancellasse renderebbe il censimento
    non-aggiornabile (nessuno ricompilerebbe 88 file per aggiornarne la forma)."""
    curati = {}
    try:
        for riga in open(path, encoding="utf-8"):
            parti = riga.strip().strip("|").split("|")
            if len(parti) >= 5 and parti[0].strip().startswith("`"):
                nome = parti[0].strip().strip("`")
                curati[nome] = (parti[3].strip(), parti[4].strip())
    except OSError:
        pass
    return curati


def write_md(endpoint, base_url, rows, fields):
    import datetime
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, f"{endpoint}.md")
    curati = leggi_curati(path)
    oggi = datetime.date.today().isoformat()
    lines = [
        f"# Endpoint: `{endpoint}`",
        "",
        f"- URL: `{base_url}/{endpoint}`",
        f"- Righe campione lette: {len(rows)}",
        f"- Campi trovati: {len(fields)}",
        f"- Ultimo aggiornamento: {oggi} (merge: le colonne compilate a mano sono preservate)",
        "",
        "> Stato: **mappato** (da verificare con riscontro: interfaccia BC / gestionale / totali noti).",
        "",
        "| Campo | Tipo | Esempio | Significato | Verificato |",
        "|---|---|---|---|---|",
    ]
    for name, info in fields.items():
        sample = str(info["sample"]).replace("|", "\\|")
        if len(sample) > 40:
            sample = sample[:37] + "..."
        sig, ver = curati.get(name, ("", "☐"))
        if not ver:
            ver = "☐"
        lines.append(f"| `{name}` | {info['type']} | {sample} | {sig} | {ver} |")
    lines.append("")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path


def parse_catalog(path):
    """Estrae i nomi servizio dal catalogo: tabella §3 (`| Pagina|Query | id | `Nome` |`)."""
    text = open(path, encoding="utf-8").read()
    # due formati: export "Servizi Web" 2026-08-26 (| Pagina | id | nome | `Servizio` | ...)
    # e il vecchio formato del repo cliente (| Pagina|Query | id | `Nome` |)
    names = re.findall(r"\| (?:Pagina|Query) \| \d+ \| [^|]*\| `([^`]+)`", text)
    names += re.findall(r"\| (?:Pagina|Query)\| \d+ \| `([^`]+)`", text)
    seen, out = set(), []
    for n in names:
        if n not in seen:
            seen.add(n)
            out.append(n)
    return out


def map_one(c, token, endpoint, top):
    """Mappa un endpoint. Ritorna la stringa di esito."""
    try:
        rows = fetch(c["base_url"], endpoint, token, top)
    except urllib.error.HTTPError as e:
        return f"{endpoint}: ERRORE HTTP {e.code} {e.reason}"
    except Exception as e:
        return f"{endpoint}: ERRORE {type(e).__name__}: {e}"
    if not rows:
        return f"{endpoint}: nessuna riga restituita"
    fields = collect_fields(rows)
    write_md(endpoint, c["base_url"], rows, fields)
    return f"{endpoint}: OK {len(fields)} campi"


def main():
    if len(sys.argv) < 2:
        sys.exit("Uso: python3 tools/bc_map.py <NomeServizio> [top] | --catalog <catalogo.md>")

    raw = open(CRED_FILE, encoding="utf-8", errors="ignore").read()
    c = {k: cred(k, raw) for k in
         ("client_id", "client_secret", "scope", "token_url", "base_url")}
    token = get_token(c)

    if sys.argv[1] == "--catalog":
        endpoints = parse_catalog(sys.argv[2])
        ok = skip = err = 0
        for ep in endpoints:
            if os.path.exists(os.path.join(OUT_DIR, f"{ep}.md")):
                skip += 1
                continue
            res = map_one(c, token, ep, "3")
            print(res)
            if ": OK " in res:
                ok += 1
            else:
                err += 1
        print(f"\nTotale: {len(endpoints)} nel catalogo · {ok} mappati ora · {skip} già presenti · {err} anomalie")
        return

    endpoint = sys.argv[1]
    top = sys.argv[2] if len(sys.argv) > 2 else "3"
    print(map_one(c, token, endpoint, top))


if __name__ == "__main__":
    main()
