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
import sys


def normalizza(ref):
    return (ref or "").strip().upper().replace(" ", "").replace("\t", "")


def leggi_csv(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def main():
    if len(sys.argv) not in (3, 4):
        print("uso: margine_documento.py vendite.csv acquisti.csv [note_credito.csv]", file=sys.stderr)
        return 1
    vendite = leggi_csv(sys.argv[1])
    acquisti = leggi_csv(sys.argv[2])
    note_credito = set()
    if len(sys.argv) == 4:
        note_credito = {normalizza(r["rif"]) for r in leggi_csv(sys.argv[3])}

    # primo acquisto per riferimento vince (comportamento del map originale)
    acquisti_map = {}
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
        perc = margine / importo_v if importo_v else 0.0
        totale_ricavi += importo_v
        totale_margine += margine
        avviso = " ⚠️ BU DIVERSA" if (v.get("bu") or "") != (a.get("bu") or "") else ""
        print(f"  {rif}: vendita={importo_v:.2f} acquisto={importo_a:.2f}"
              f" margine={margine:+.2f} ({perc:+.1%} sui ricavi){avviso}")

    perc_tot = totale_margine / totale_ricavi if totale_ricavi else 0.0
    print(f"Totale ricavi accoppiati: {totale_ricavi:.2f} EUR")
    print(f"Totale margine: {totale_margine:+.2f} EUR ({perc_tot:+.1%} sui ricavi)")
    if annullati:
        print(f"Annullati da nota di credito: {len(annullati)} — "
              + ", ".join(f"{x['rif']} ({x['importo']:.2f} EUR esclusi)" for x in annullati))
    if errori:
        print(f"ERRORI accoppiamento (NON sono margine zero): {len(errori)} — "
              + ", ".join(f"{x['rif']}" for x in errori))
    return 0


if __name__ == "__main__":
    sys.exit(main())
