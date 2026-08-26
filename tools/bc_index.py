#!/usr/bin/env python3
"""Rigenera docs/bc/README.md dall'indice dei file endpoint mappati.

Uso: python3 tools/bc_index.py
Legge docs/bc/endpoints/*.md (nome, n. campi, stato verifica) e riscrive l'indice.
"""
import glob
import os
import re

ENDPOINTS_DIR = "docs/bc/endpoints"
README = "docs/bc/README.md"
TOTAL_CATALOG = 108


def parse(path):
    txt = open(path, encoding="utf-8").read()
    name = re.search(r"# Endpoint: `([^`]+)`", txt).group(1)
    n = re.search(r"Campi trovati: (\d+)", txt)
    count = int(n.group(1)) if n else 0
    verified = "✅" if re.search(r"\| ✅ \|", txt) else "☐"
    return name, count, verified


def main():
    rows = [parse(p) for p in glob.glob(os.path.join(ENDPOINTS_DIR, "*.md"))]
    rows.sort(key=lambda r: -r[1])
    lines = [
        "# Business Central — mappatura endpoint",
        "",
        "Conoscenza viva sugli endpoint OData V4 di BC. Vedi `PROJECT.md` per le regole di processo.",
        "",
        "## Come mappare un endpoint",
        "```",
        "python3 tools/bc_map.py <NomeServizio> [righe_campione]   # singolo",
        "python3 tools/bc_map.py --catalog CATALOGO_ENDPOINT_BC.md  # tutti (salta i già fatti)",
        "python3 tools/bc_index.py                                  # rigenera questo indice",
        "```",
        "Poi: compilare la colonna *Significato* e spuntare *Verificato* dopo il riscontro.",
        "",
        f"## Avanzamento — {len(rows)} mappati (catalogo completo: `CATALOGO_ENDPOINT_BC.md`, vive nel repo cliente)",
        f"Anomalie (403/404/vuoti): `CORREZIONI.md`.",
        "",
        "## Salute del censimento",
        f"- Endpoint con almeno un campo verificato: {sum(1 for _, _, v in rows if v == '✅')} su {len(rows)}",
        f"- File con data di aggiornamento: {sum(1 for r in glob.glob(os.path.join(ENDPOINTS_DIR, '*.md')) if 'Ultimo aggiornamento:' in open(r, encoding='utf-8').read())} su {len(rows)} (i senza data sono pre-2026-08-26: un refresh con bc_map li marca)",
        "- Refresh: `python3 tools/bc_map.py <NomeServizio>` rigenera UN endpoint preservando Significato/Verificato compilati",
        "",
        "| Endpoint | Campi | Verificato |",
        "|---|---|---|",
    ]
    for name, count, verified in rows:
        lines.append(f"| `{name}` | {count} | {verified} |")
    lines.append("")
    with open(README, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"README rigenerato: {len(rows)} endpoint indicizzati.")


if __name__ == "__main__":
    main()
