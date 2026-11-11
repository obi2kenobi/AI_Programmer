"""brain_riassunto.py — i riassunti a più livelli: documento, cartella, mappa.

Livello 1 (documento): titolo, intestazioni, prima frase utile, profilo di parole.
Livello 2..n (cartella): la sintesi delle sintesi dei figli — conteggio, titoli, temi.
Radice («.»): la mappa del corpus.

Ogni livello dipende SOLO dai suoi figli: due documenti si riassumono in parallelo
senza aspettarsi (il primo problema delle LLM Wiki: l'indicizzazione sequenziale
nasceva dal grafo, dove ogni pagina deve conoscere le altre per collegarle).

Con BRAIN_LLM configurato il testo del riassunto lo scrive il modello; il profilo di
parole (quello che serve alla ricerca) resta sempre deterministico.
"""
import re

import brain_modello
import brain_testo

TITOLO = re.compile(r"^\s*#{1,6}\s+(.+?)\s*#*\s*$")
RIGHE_PEZZO = 40
PAROLE_DOC = 60
PAROLE_PEZZO = 30
PAROLE_NODO = 120
CARATTERI_CONTESTO = 12000


def pezzi(righe):
    """Il testo a pezzi: un pezzo per sezione (intestazione markdown), al massimo RIGHE_PEZZO righe.

    Ogni pezzo porta le sue righe vere (1-based, estremi inclusi): è ciò che si cita.
    """
    out, inizio, intest = [], 0, ""
    for i, r in enumerate(righe):
        m = TITOLO.match(r)
        if (m and i > inizio) or i - inizio >= RIGHE_PEZZO:
            out.append(_pezzo(righe, inizio, i, intest))
            inizio = i
        if m:
            intest = m.group(1)
    if inizio < len(righe):
        out.append(_pezzo(righe, inizio, len(righe), intest))
    return [p for p in out if p["testo"].strip()]


def _pezzo(righe, da, a, intest):
    testo = "\n".join(righe[da:a])
    return {"riga_da": da + 1, "riga_a": a, "intestazione": intest, "testo": testo,
            "profilo": brain_testo.pesi(intest + "\n" + testo, PAROLE_PEZZO)}


def documento(percorso, testo):
    """Il livello 1 di un documento: titolo, riassunto, profilo, pezzi."""
    righe = testo.splitlines()
    intest = [m.group(1) for m in map(TITOLO.match, righe) if m]
    titolo = intest[0] if intest else percorso.rsplit("/", 1)[-1]
    riass = _riassunto_modello(percorso, testo) or _riassunto_estrattivo(titolo, intest, righe)
    return {"titolo": titolo, "riassunto": riass, "righe": len(righe),
            "profilo": brain_testo.pesi(titolo + "\n" + titolo + "\n" + testo, PAROLE_DOC),
            "pezzi": pezzi(righe)}


def _riassunto_estrattivo(titolo, intest, righe):
    """Senza modello: titolo, le prime intestazioni, la prima frase che non è un titolo."""
    frase = next((r.strip() for r in righe if r.strip() and not TITOLO.match(r)
                  and not r.strip().startswith(("---", "<!--", "```"))), "")
    sezioni = "; ".join(intest[1:9])
    return f"{titolo}. {frase[:300]}" + (f" — sezioni: {sezioni}" if sezioni else "")


def _riassunto_modello(percorso, testo):
    """Il riassunto scritto dal modello (BRAIN_LLM), o None se non c'è o non risponde."""
    if not brain_modello.comando("scrittore"):
        return None
    return brain_modello.chiedi(
        "scrittore", f"Riassumi in 3-5 frasi il documento {percorso}: di cosa parla, quali "
        "decisioni, regole o numeri contiene. Solo il riassunto, nessun preambolo.",
        testo[:CARATTERI_CONTESTO])


def cartella(percorso, figli):
    """Il livello di una cartella dai riassunti dei figli: [{'nome','titolo','riassunto','profilo','n'}]."""
    n = sum(f["n"] for f in figli)
    prof = brain_testo.somma_pesi([f["profilo"] for f in figli], PAROLE_NODO)
    temi = ", ".join(list(prof)[:12])
    titoli = "; ".join(f["titolo"] or f["nome"] for f in figli[:15])
    riass = _sintesi_modello(percorso, figli) or (
        f"{percorso}: {n} documenti. Temi: {temi}. Contiene: {titoli}"
        + (" …" if len(figli) > 15 else ""))
    return {"riassunto": riass, "profilo": prof, "n": n}


def _sintesi_modello(percorso, figli):
    """La sintesi della cartella scritta dal modello dai riassunti dei figli, o None."""
    if not brain_modello.comando("scrittore"):
        return None
    elenco = "\n".join(f"- {f['nome']}: {f['riassunto']}" for f in figli)
    return brain_modello.chiedi(
        "scrittore", f"Questi sono i riassunti del contenuto di {percorso}. Scrivi la sintesi "
        "della cartella in 3-6 frasi: temi, documenti chiave, a chi serve.",
        elenco[:CARATTERI_CONTESTO])
