#!/usr/bin/env python3
"""Margine per documento: accoppiamento vendita↔acquisto per riferimento.

Oracolo (6° ciclo, Set 1 giro 4, 2026-08-24). Formula REALE minata dal progetto
controllo margini di REPO-E (repo esterno, cartella gas-src/, Codice.js intorno
alla riga 639):

1. Accoppiamento per RIFERIMENTO normalizzato: trim + maiuscolo + spazi rimossi
   (`ref.toString().trim().toUpperCase().replace(/\\s+/g, '')`) — la stessa
   normalizzazione qui, chiavi vendite/acquisti confrontabili.
2. margine = importo_vendita − importo_acquisto (a livello di documento accoppiato).
3. perc = margine / importo_vendita — percentuale SUI RICAVI (margine), non sul
   costo (sarebbe ricarico): le due si confondono solo finché non le si scrive.
4. Vendita SENZA acquisto e SENZA nota di credito = ERRORE (conteggiata a parte),
   NON margine zero: un documento non accoppiato non è un margine mancante,
   è un accoppiamento mancante (nel codice REPO-E finisce in `errori`).
5. Riferimento presente nelle NOTE DI CREDITO = vendita "Annullato da nota di
   credito": esclusa dal margine, riportata a parte (scarto mai silenzioso).
6. BU vendita ≠ BU acquisto = ⚠️ BU DIVERSA: margine calcolato lo stesso, ma
   flaggato — è un segnale di contabilità per BU sbagliata, non un errore di calcolo.
7. Margine NEGATIVO possibile e ammesso: vendere sotto costo è un dato, non un
   bug del tool (nessun clamp, nessun valore assoluto).

Limiti dichiarati (comportamento del codice originale, mantenuto e documentato):
un acquisto può essere accoppiato a più vendite con lo stesso riferimento (il map
non consuma gli acquisti); di più acquisti con lo stesso riferimento vince il
primo incontrato.

Uso: python3 tools/margine_documento.py vendite.csv acquisti.csv [note_credito.csv]
vendite.csv:    rif,data,bu,ubicazione,importo
acquisti.csv:   rif,data,bu,fornitore,importo
note_credito.csv: rif (una per riga, con intestazione)
"""
import csv
import math
import re
import sys


def normalizza(ref):
    # (Q22, 2026-09-23): toglieva solo spazio e tab; il sorgente citato qui sopra usa /\s+/g, che
    # toglie anche NBSP e gli altri spazi Unicode — un rif esportato con NBSP non si accoppiava.
    # In Python 3 \s su str copre gli stessi spazi Unicode.
    return re.sub(r"\s+", "", (ref or "").strip().upper())


def leggi_csv(path, colonne=()):
    """(giro 21, 2026-09-20 — D32): file inesistente o colonna mancante = traceback nudo.
    Si dichiara cosa manca e si esce 1, come scadenzario_aging."""
    try:
        with open(path, encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            mancanti = [c for c in colonne if c not in (reader.fieldnames or [])]
            if mancanti:
                print(f"uso: margine_documento.py — in {path} mancano le colonne: {', '.join(mancanti)}", file=sys.stderr)
                sys.exit(1)
            return list(reader)
    except OSError as e:
        print(f"uso: margine_documento.py vendite.csv acquisti.csv [note_credito.csv] — {e}", file=sys.stderr)
        sys.exit(1)


def main():
    """Accoppia vendite↔acquisti per riferimento documento, calcola margine
    per documento e percentuale SUI RICAVI (non ricarico). Le regole 1-7 del
    docstring vivono qui: vendite senza acquisto = errore dichiarato, note
    credito a parte, BU diverse = avviso non scarto.
    """
    if len(sys.argv) not in (3, 4):
        print("uso: margine_documento.py vendite.csv acquisti.csv [note_credito.csv]", file=sys.stderr)
        return 1
    vendite = leggi_csv(sys.argv[1], ("importo",))
    acquisti = leggi_csv(sys.argv[2], ("importo",))
    # (Q22): con zero vendite stampava «Totale margine +0.00 EUR (+0.0%)»
    if not vendite:
        print(f"ERRORE: nessuna riga valida nell'input — nessun verdetto (un estratto vuoto e' un'estrazione fallita finche' non si dimostra il contrario; Q22, 2026-09-23)", file=sys.stderr)
        return 1
    note_credito = set()
    if len(sys.argv) == 4:
        # (Q22): un rif vuoto (anche solo " ") entrava come "" e annullava ogni vendita senza rif
        note_credito = {normalizza(r["rif"]) for r in leggi_csv(sys.argv[3], ("rif",))} - {""}

    # primo acquisto per riferimento vince (comportamento del map originale)
    acquisti_map = {}
    # (2026-09-24, quinto ventaglio, R3 R2): un importo nan/inf dava «Totale margine: +nan EUR», rc 0
    marci = [r.get("rif") or "(senza rif)" for r in vendite + acquisti if not math.isfinite(float(r["importo"]))]
    if marci:
        print(f"ERRORE: importi non finiti (nan/inf) per {', '.join(marci[:5])} — nessun verdetto", file=sys.stderr)
        return 1
    for a in acquisti:
        rif = normalizza(a.get("rif"))
        if rif and rif not in acquisti_map:
            acquisti_map[rif] = a

    totale_ricavi = 0.0
    totale_margine = 0.0
    errori, annullati = [], []
    print(f"Vendite lette: {len(vendite)} · Acquisti letti: {len(acquisti)} · "
          f"Riferimenti nota di credito: {len(note_credito)}")
    for v in vendite:
        rif = normalizza(v.get("rif"))
        importo_v = float(v["importo"])
        if rif in note_credito:
            annullati.append({"rif": rif, "importo": importo_v})
            continue
        a = acquisti_map.get(rif)
        if a is None:
            errori.append({"rif": rif or "(senza rif)", "importo": importo_v})
            continue
        importo_a = float(a["importo"])
        margine = importo_v - importo_a
        # bug reale (revisione 14 lenti, 2026-08-28): con vendita a importo 0 la percentuale
        # era forzata a 0.0 — l'euro del margine resta corretto, ma "+0.0%" si legge come
        # "margine nullo", fuorviante proprio quando (vendita 0, acquisto pieno) il margine
        # in euro è negativo: la percentuale sui ricavi non è definita a denominatore nullo.
        perc = margine / importo_v if importo_v else None
        totale_ricavi += importo_v
        totale_margine += margine
        avviso = " ⚠️ BU DIVERSA" if (v.get("bu") or "") != (a.get("bu") or "") else ""
        perc_txt = f"{perc:+.1%}" if perc is not None else "n.d. (vendita a zero)"
        print(f"  {rif}: vendita={importo_v:.2f} acquisto={importo_a:.2f}"
              f" margine={margine:+.2f} ({perc_txt} sui ricavi){avviso}")

    # (Q22): la cura del 2026-08-28 per la riga (percentuale n.d. a ricavi nulli) non era arrivata
    # al totale: «-100.00 EUR (+0.0% sui ricavi)»
    perc_tot_txt = f"{totale_margine / totale_ricavi:+.1%}" if totale_ricavi else "n.d. (ricavi a zero)"
    print(f"Totale ricavi accoppiati: {totale_ricavi:.2f} EUR")
    print(f"Totale margine: {totale_margine:+.2f} EUR ({perc_tot_txt} sui ricavi)")
    if annullati:
        print(f"Annullati da nota di credito: {len(annullati)} — "
              + ", ".join(f"{x['rif']} ({x['importo']:.2f} EUR esclusi)" for x in annullati))
    if errori:
        print(f"ERRORI accoppiamento (NON sono margine zero): {len(errori)} — "
              + ", ".join(f"{x['rif']}" for x in errori))
    return 0


if __name__ == "__main__":
    sys.exit(main())
