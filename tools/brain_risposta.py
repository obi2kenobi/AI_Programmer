"""brain_risposta.py — dalla domanda alla risposta verificata.

Le fasi (le stesse della demo del video, ciascuna loggata):
1. RICERCA      brain_interroga.cerca: discesa nell'albero + riferimenti al volo;
2. BOZZA        con BRAIN_LLM il modello scrive citando [percorso:riga-riga] a ogni frase;
                senza modello la risposta è ESTRATTIVA: le righe migliori, citate una per una;
3. VERIFICA     brain_verifica: ogni frase contro le righe che cita;
4. CORREZIONE   se restano frasi incerte o rotte e c'è un modello: un giro di riscrittura
                con l'elenco dei difetti, poi di nuovo la verifica (BRAIN_GIRI, default 1);
5. RESOCONTO    quello che non passa resta visibile (⚠), mai tolto in silenzio.
"""
import os

import brain_interroga
import brain_modello
import brain_testo
import brain_verifica
from brain_modello import log

GIRI = int(os.environ.get("BRAIN_GIRI", "1"))
TAGLIO = 400
ISTRUZIONI = (
    "Rispondi alla DOMANDA usando i BRANI. Ogni frase che usa un brano termina con la sua "
    "citazione esatta fra parentesi quadre, copiata dall'intestazione del brano, per esempio "
    "[docs/x.md:12-14]: cita le righe più strette che bastano. Non inventare numeri. Se aggiungi "
    "conoscenza generale che non è nei brani, scrivila in una frase SENZA citazione. Se i brani "
    "non bastano, dillo.")


def brani(pezzi):
    """I pezzi trovati come contesto per il modello, ognuno con le righe numerate."""
    out = []
    for p in pezzi:
        righe = p["testo"].split("\n")
        numerate = "\n".join(f"{p['riga_da'] + i}: {r}" for i, r in enumerate(righe))
        out.append(f"### [{p['percorso']}:{p['riga_da']}-{p['riga_a']}]\n{numerate}")
    return "\n\n".join(out)


def estrattiva(pezzi, q, righe_per_pezzo=2):
    """Senza modello: per ogni pezzo le righe che parlano di più della domanda, citate riga per riga."""
    out = []
    for p in pezzi:
        cand = []
        for i, r in enumerate(p["testo"].split("\n")):
            s = len(set(q) & set(brain_testo.parole(r)))
            if s and r.strip() and not r.strip().startswith(("```", "<!--", "---")):
                cand.append((-s, i, r.strip()))
        for _, i, r in sorted(cand)[:righe_per_pezzo]:
            r = r.lstrip("-*# ").strip()
            r = r if len(r) <= TAGLIO else r[:TAGLIO].rsplit(" ", 1)[0] + " …"
            out.append(f"- {r} [{p['percorso']}:{p['riga_da'] + i}]")
    return "\n".join(out) or "I documenti leggibili non contengono righe pertinenti."


def correggi(domanda, contesto, bozza, verdetti):
    """Un giro di riscrittura: il modello riceve le frasi che non passano e il perché."""
    difetti = "\n".join(f"- «{v['frase']}» {' '.join(v['citazioni'])}: {'; '.join(v['motivi'])}"
                        for v in verdetti if v["esito"] in ("incerta", "rotta"))
    log(f"correzione: {difetti.count(chr(10)) + 1} frasi da rivedere")
    return brain_modello.chiedi(
        "scrittore", f"{ISTRUZIONI}\n\nDOMANDA: {domanda}\n\nLa tua BOZZA ha frasi che le righe "
        f"citate non sostengono:\n{difetti}\n\nRiscrivi la risposta intera: correggi la citazione "
        "o la frase, oppure togli la frase.", f"BOZZA:\n{bozza}\n\nBRANI:\n{contesto}")


def rispondi(con, puo, domanda, quanti=6):
    """La risposta verificata: dict con testo, pezzi, verdetti, conta, modo ('modello'|'estrattiva')."""
    log("fase 1/5 ricerca")
    pezzi = brain_interroga.cerca(con, puo, domanda, quanti=quanti)
    contesto = brani(pezzi)
    log(f"fase 2/5 bozza su {len(pezzi)} brani")
    testo = brain_modello.chiedi("scrittore", f"{ISTRUZIONI}\n\nDOMANDA: {domanda}", contesto) if pezzi else None
    modo = "modello" if testo else "estrattiva"
    if not testo:
        log("bozza estrattiva (nessun modello configurato o nessuna risposta)")
        testo = estrattiva(pezzi, brain_testo.parole(domanda))
    log("fase 3/5 verifica delle fonti")
    verdetti, conta = brain_verifica.verifica(con, puo, testo)
    for giro in range(GIRI if modo == "modello" else 0):
        if not (conta["incerte"] or conta["rotte"]):
            break
        log(f"fase 4/5 correzione, giro {giro + 1}/{GIRI}")
        nuovo = correggi(domanda, contesto, testo, verdetti)
        if not nuovo:
            break
        testo = nuovo
        verdetti, conta = brain_verifica.verifica(con, puo, testo)
    log("fase 5/5 resoconto")
    return {"testo": testo, "pezzi": pezzi, "verdetti": verdetti, "conta": conta, "modo": modo}
