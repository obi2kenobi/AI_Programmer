#!/usr/bin/env python3
"""Scadenzario clienti/fornitori: classificazione a fasce di scadenza (aging) e totali.

Formula reale (oracolo, non inventata): un modulo di scadenzario clienti/fornitori
(repo esterno REPO-E, cartella gas-src/, non in questo hub) — letto riga per riga sul
codice reale:

  fascia(giorni) = "LUNGO"          se giorni assente
                   "SCADUTO >60"    se giorni < -60
                   "SCADUTO 31-60"  se giorni < -30
                   "SCADUTO <=30"   se giorni < 0
                   "BREVE"          se giorni <= 30
                   "MEDIO"          se giorni <= 90
                   "LUNGO"          altrimenti
  (giorni = giorni residui alla scadenza: negativo = già scaduto da N giorni)

  Convenzione di segno (dal codice reale): l'importo di una riga CLIENTE è preso
  come da BC (positivo = credito da incassare); l'importo di una riga FORNITORE
  fattura/invoice diventa NEGATIVO (-abs), una nota di credito resta POSITIVO
  (+abs) — l'uscita di cassa futura è sempre negativa, l'entrata sempre positiva,
  qualunque sia il tipo di documento originale. Il tipo si confronta senza maiuscole;
  un tipo fornitore fuori elenco rende la riga RIFIUTATA e detta (Luca, 2026-09-26).

  Totali: per ogni fascia, somma degli importi con quel segno; entrate = somma
  importi positivi; uscite = somma importi negativi; saldo = entrate + uscite;
  scaduto_totale = somma delle tre fasce "SCADUTO *".

Uso: python3 tools/scadenzario_aging.py < righe.csv
CSV con colonne: tipo,importo,giorni (giorni vuoto = nessuna data di scadenza)
"""
import csv
import sys

FASCE_SCADUTO = ("SCADUTO >60", "SCADUTO 31-60", "SCADUTO <=30")
FASCE_ORDINE = FASCE_SCADUTO + ("BREVE", "MEDIO", "LUNGO")


def fascia_dettaglio(giorni):
    """Bucket di scaduto (<=30, 31-60, >60) e residuo (breve/medio/lungo):
    la fascia è la domanda di dominio («quanto è vecchio il credito?»), non
    una scelta tecnica — le stesse fasce del progetto REPO-E.
    """
    if giorni is None or giorni == "":
        return "LUNGO"
    g = int(giorni)
    if g < -60:
        return "SCADUTO >60"
    if g < -30:
        return "SCADUTO 31-60"
    if g < 0:
        return "SCADUTO <=30"
    if g <= 30:
        return "BREVE"
    if g <= 90:
        return "MEDIO"
    return "LUNGO"


# (Q22, 2026-09-23): i tipi documento fornitore che la convenzione del docstring nomina. Un tipo fuori elenco (FATTURA
# maiuscolo, Payment, vuoto) prendeva +abs come la nota di credito — cioe' finiva fra le ENTRATE, solo detto.
# (2026-09-26, risposta di Luca alla domanda 1 di docs/giri/2026-09-23-notte/DOMANDE.md): il tipo si confronta senza
# maiuscole («FATTURA» e' una fattura), e un tipo che non e' in elenco non va fra le entrate: la riga si RIFIUTA e
# l'uscita la dice (tipo, quante righe, quanto importo).
TIPI_FORNITORE_NOTI = ("Invoice", "Fattura", "Nota di credito", "Nota credito", "Credit Memo")
TIPI_USCITA = ("invoice", "fattura")


def tipo_noto(doc_type):
    return doc_type.strip().lower() in {t.lower() for t in TIPI_FORNITORE_NOTI}


def importo_fornitore(importo_bc, doc_type):
    is_uscita = doc_type.strip().lower() in TIPI_USCITA
    return -abs(importo_bc) if is_uscita else abs(importo_bc)


def aggrega_totali(righe):
    """Somme per fascia e saldo netto. Le righe fornitore passano da
    importo_fornitore (convenzione uscita di cassa): sommarle col segno
    grezzo di BC metterebbe uscite tra le entrate (bug reale revisione 14
    lenti, fix presidiato dal test).
    """
    tot = {f: 0.0 for f in FASCE_ORDINE}
    entrate = uscite = 0.0
    for r in righe:
        tot[r["fascia"]] += r["importo"]
        if r["importo"] > 0:
            entrate += r["importo"]
        elif r["importo"] < 0:
            uscite += r["importo"]
    scaduto_totale = sum(tot[f] for f in FASCE_SCADUTO)
    return {
        "per_fascia": tot,
        "entrate": entrate,
        "uscite": uscite,
        "saldo": entrate + uscite,
        "scaduto_totale": scaduto_totale,
    }


def main():
    """Scadenzario CSV (giorni,tipo,importo) → aging con fasce e totali.
    Header incompleto o importo non finito: uso/errore esplicito, mai nan
    silenzioso (giri avversari D5/D6).
    """
    # (2026-09-24, quinto ventaglio, R3 R6): un file passato come argomento era ignorato in silenzio, e si
    # calcolava su quello che c'era in stdin
    if len(sys.argv) > 1:
        print(f"uso: scadenzario_aging.py < scadenzario.csv — legge solo stdin: l'argomento {sys.argv[1]!r} non e' letto", file=sys.stderr)
        return 1
    righe = []
    reader = csv.DictReader(sys.stdin)
    # le colonne attese si DICHIARANO prima di usarle: un header sbagliato o mancante
    # deve dire cosa manca, non morire di KeyError nudo (giri ignoranti 2026-08-28:
    # header `a,b` produceva traceback invece di istruzioni)
    mancanti = [c for c in ("giorni", "tipo", "importo") if c not in (reader.fieldnames or [])]
    if mancanti:
        print(f"uso: scadenzario_aging.py < scadenzario.csv — colonne attese: giorni,tipo,importo"
              f" (mancano: {', '.join(mancanti)})", file=sys.stderr)
        return 1
    non_riconosciuti = []
    for r in reader:
        giorni = r["giorni"].strip() if r["giorni"].strip() != "" else None
        tipo = r["tipo"]
        # (2026-09-24, quinto ventaglio, R3 R3): una cella vuota, «1.234,56» o giorni «1.5» erano un traceback
        try:
            importo_bc = float(r["importo"])
            fascia = fascia_dettaglio(giorni)
        except (ValueError, TypeError):
            print(f"ERRORE: riga {reader.line_num}: importo o giorni non numerici (importo={r['importo']!r}, giorni={r['giorni']!r};"
                  f" attesi importo col punto decimale e giorni interi) — nessun verdetto", file=sys.stderr)
            return 1
        # giri avversari 2026-08-28 (D5/D6): nan/inf passavano e producevano totali
        # "+nan€" in silenzio. Un importo non finito è dato marcio: si dichiara.
        import math
        if not math.isfinite(importo_bc):
            print(f"ERRORE: importo non finito (nan/inf) alla riga tipo={r['tipo']}", file=sys.stderr)
            return 1
        # bug reale (revisione 14 lenti, 2026-08-28): importo_fornitore() era definita ma
        # mai chiamata — ogni riga fornitore finiva col segno grezzo di BC (positivo),
        # quindi in "entrate" invece che in "uscite". "tipo" porta sia la controparte
        # (Cliente/Fornitore) sia il tipo documento (es. "Fornitore Fattura"); solo le
        # righe Fornitore applicano la convenzione dell'uscita di cassa.
        # (2026-09-24, quinto ventaglio, R3 R1): anche «fornitore» minuscolo o con uno spazio davanti e' un fornitore
        if tipo.strip().lower().startswith("fornitore"):
            doc_type = tipo.strip()[len("fornitore"):].strip()
            if not tipo_noto(doc_type):
                non_riconosciuti.append((tipo, importo_bc))
                continue
            importo = importo_fornitore(importo_bc, doc_type)
        else:
            importo = importo_bc
        righe.append({
            "tipo": tipo,
            "importo": importo,
            "fascia": fascia,
        })
    if non_riconosciuti:
        tipi = sorted({t for t, _ in non_riconosciuti})
        print(f"ATTENZIONE: {len(non_riconosciuti)} righe fornitore RIFIUTATE, tipo documento non riconosciuto"
              f" ({', '.join(tipi)}; importo {sum(abs(i) for _, i in non_riconosciuti):.2f}): fuori dai totali."
              f" Tipi noti: {', '.join(TIPI_FORNITORE_NOTI)}.", file=sys.stderr)
    # (Q22): con zero righe stampava entrate, uscite e fasce a +0.00€, rc 0
    if not righe:
        print(f"ERRORE: nessuna riga valida nell'input — nessun verdetto (un estratto vuoto e' un'estrazione fallita finche' non si dimostra il contrario; Q22, 2026-09-23)", file=sys.stderr)
        return 1
    r = aggrega_totali(righe)
    print(f"Entrate: {r['entrate']:+.2f}€")
    print(f"Uscite: {r['uscite']:+.2f}€")
    print(f"Saldo netto: {r['saldo']:+.2f}€")
    print(f"Scaduto totale: {r['scaduto_totale']:+.2f}€")
    for f in FASCE_ORDINE:
        print(f"  {f}: {r['per_fascia'][f]:+.2f}€")


if __name__ == "__main__":
    sys.exit(main())
