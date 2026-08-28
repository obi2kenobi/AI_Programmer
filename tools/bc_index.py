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


def parse(path):
    """Riduce una riga di censimento endpoint ai campi dell'indice: nome,
    servizi OData, salute. Il censimento è lungo; l'indice è la porta.
    """
    txt = open(path, encoding="utf-8").read()
    name = re.search(r"# Endpoint: `([^`]+)`", txt).group(1)
    n = re.search(r"Campi trovati: (\d+)", txt)
    count = int(n.group(1)) if n else 0
    verified = "✅" if re.search(r"\| ✅ \|", txt) else "☐"
    return name, count, verified


def catalogo_mancanti():
    """I servizi OData del catalogo (2026-08-26, fornitore: Luca) senza file di censimento."""
    cat = os.path.join(os.path.dirname(ENDPOINTS_DIR), "CATALOGO_ENDPOINT_BC.md")
    if not os.path.isfile(cat):
        return None, []
    import re as _re
    text = open(cat, encoding="utf-8").read()
    # bug reale (revisione 14 lenti, 2026-08-28): ogni riga della tabella ha DUE valori fra
    # backtick — il nome visualizzato (con spazi, es. `Job List`) e il nome tecnico/nome
    # file (con underscore, es. `Job_List`) — la regex catturava il PRIMO, cioè quello
    # visualizzato, che non corrisponde mai al nome di un file endpoint reale. Risultato:
    # 22 file censiti con nome tecnico (Job_List, Piano_dei_conti, ecc.) risultavano "non
    # nel catalogo" e il conteggio dei "mancanti" era gonfiato per lo stesso numero di
    # entrate fantasma (nomi con spazio che nessun file avrà mai). Cattura ora il SECONDO
    # gruppo fra backtick (il nome tecnico, verificato: tutte le 258 righe ne hanno
    # esattamente due).
    servizi = set(_re.findall(r"\| (?:Pagina|Query) \| \d+ \| [^|]*\| `[^`]+` \| `([^`]+)`", text))
    esistenti = {os.path.basename(p)[:-3] for p in glob.glob(os.path.join(ENDPOINTS_DIR, "*.md"))}
    return len(servizi), sorted(servizi - esistenti)


def main():
    """Rigenera docs/bc/README.md dall'insieme dei censimenti: l'indice NON si
    edita a mano (la prossima rigenerazione lo cancellerebbe).
    """
    rows = [parse(p) for p in glob.glob(os.path.join(ENDPOINTS_DIR, "*.md"))]
    n_cat, mancanti = catalogo_mancanti()
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
        f"## Avanzamento — {len(rows)} mappati (catalogo completo: `CATALOGO_ENDPOINT_BC.md`, vive in questo hub)",
        f"Anomalie (403/404/vuoti): `CORREZIONI.md`.",
        "",
        "## Salute del censimento",
        f"- Endpoint con almeno un campo verificato: {sum(1 for _, _, v in rows if v == '✅')} su {len(rows)}",
        f"- File con data di aggiornamento: {sum(1 for r in glob.glob(os.path.join(ENDPOINTS_DIR, '*.md')) if 'Ultimo aggiornamento:' in open(r, encoding='utf-8').read())} su {len(rows)} (i senza data sono pre-2026-08-26: un refresh con bc_map li marca)",
        "- Refresh: `python3 tools/bc_map.py <NomeServizio>` rigenera UN endpoint preservando Significato/Verificato compilati",
        "- Su Luca's Mac: `python3 tools/bc_map.py --catalog docs/bc/CATALOGO_ENDPOINT_BC.md` mappa in blocco TUTTI i mancanti (salta i già fatti, credenziali locali)",
        (f"- Catalogo servizi OData: {n_cat} · mancanti al censimento: {len(mancanti)}" if n_cat is not None else "- Catalogo assente (docs/bc/CATALOGO_ENDPOINT_BC.md)"),
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

# Limiti dichiarati: formula minata da REPO-E. Dato assente diverso da zero.
