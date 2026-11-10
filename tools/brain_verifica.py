"""brain_verifica.py — il controllo delle fonti: la citazione dice davvero quello che si afferma?

Una citazione che esiste ma non sostiene l'affermazione è peggio di nessuna citazione:
dà fiducia a un'invenzione. Per ogni frase della risposta:

1. senza citazione            -> «generale»: conoscenza generale, NON dai tuoi documenti;
2. citazione rotta            -> documento sconosciuto, non leggibile per te, o righe oltre la fine;
3. PRIMO GIUDICE (deterministico, istantaneo): copertura delle parole piene della frase
   nelle righe citate, con due denti — un NUMERO della frase assente dalle righe citate
   abbassa la fiducia a 0.2 (e nessun modello può salvarla), una NEGAZIONE presente da
   una parte sola la dimezza. Fiducia >= soglia -> «verificata»;
4. sotto soglia -> SECONDO GIUDICE (un modello, BRAIN_GIUDICE): risponde SI o NO;
   SI -> «verificata dal giudice», altrimenti -> «incerta» (⚠, col perché).

Onestà sul primo giudice: è lessicale, non un classificatore addestrato; la soglia
(BRAIN_SOGLIA, default 0.6) NON è calibrata su dati etichettati — è una domanda aperta.
Il suo valore è essere veloce, deterministico e severo sui numeri.
"""
import os
import re

import brain_modello
import brain_testo

CITAZIONE = re.compile(r"\[([^\[\]\s:]+\.[A-Za-z0-9]+):(\d+)(?:-(\d+))?\]")
FINE_FRASE = re.compile(r"(?<=[.!?\]])\s+(?=[A-ZÀ-Ý«\"(*-])")
SOGLIA = float(os.environ.get("BRAIN_SOGLIA", "0.6"))
NUMERO_ASSENTE = 0.2


def frasi(risposta):
    """Le unità da verificare: ogni riga, divisa in frasi; titoli e righe vuote esclusi.

    Una citazione a fine paragrafo copre le frasi SENZA citazione che la precedono nella
    stessa riga (lo stile «cito a fine paragrafo»): si verificano insieme contro le righe
    citate. Le frasi dopo l'ultima citazione della riga restano senza fonte: «generale».
    """
    out = []
    for riga in risposta.splitlines():
        riga = riga.strip()
        if not riga or riga.startswith("#"):
            continue
        attesa = []
        for f in FINE_FRASE.split(riga):
            if not brain_testo.parole(CITAZIONE.sub("", f)):
                continue
            attesa.append(f)
            if CITAZIONE.search(f):
                out.append(" ".join(attesa))
                attesa = []
        out += attesa
    return out


def righe_citate(con, puo, percorso, da, a):
    """Il testo delle righe da..a del documento, o (None, perché) se la citazione è rotta."""
    riga = con.execute("SELECT righe FROM documenti WHERE percorso=?", (percorso,)).fetchone()
    if riga is None or not puo(percorso):
        # un solo messaggio per i due casi: dire «esiste ma non puoi» rivelerebbe che esiste
        return None, "documento sconosciuto o non leggibile per te"
    if da < 1 or a < da or a > riga[0]:
        return None, f"righe {da}-{a} fuori dal documento ({riga[0]} righe)"
    testo = {}
    for inizio, corpo in con.execute(
            "SELECT riga_da, testo FROM pezzi WHERE percorso=? AND riga_a>=? AND riga_da<=?",
            (percorso, da, a)):
        for i, r in enumerate(corpo.split("\n")):
            testo[inizio + i] = r
    return "\n".join(testo.get(n, "") for n in range(da, a + 1)), None


def fiducia(frase, fonte):
    """Il primo giudice: (fiducia 0..1, motivi[]). Deterministico."""
    pf = {p for p in brain_testo.parole(frase) if not p[0].isdigit()}
    pv = set(brain_testo.parole(fonte))
    conf = len(pf & pv) / len(pf) if pf else 1.0
    motivi = [f"copertura {conf:.2f}"]
    mancano = brain_testo.numeri(frase) - brain_testo.numeri(fonte)
    if mancano:
        conf = min(conf, NUMERO_ASSENTE)
        motivi.append("numeri assenti dalle righe citate: " + ", ".join(sorted(mancano)))
    nf, nv = brain_testo.negati(frase), brain_testo.negati(fonte)
    rovesciate = ((nf & pv) - nv) | ((nv & pf) - nf)
    if rovesciate:
        conf /= 2
        motivi.append("negata da una parte sola: " + ", ".join(sorted(rovesciate)))
    return round(conf, 2), motivi


def giudice(frase, fonte):
    """Il secondo giudice (modello): True se dice SI, False se NO, None se non c'è o non risponde."""
    r = brain_modello.chiedi(
        "giudice", "Rispondi solo SI o NO. Il TESTO sostiene esattamente l'AFFERMAZIONE "
        "(stessi fatti, stessi numeri, stesso verso)?", f"AFFERMAZIONE: {frase}\n\nTESTO:\n{fonte}")
    if r is None:
        return None
    return brain_testo.piega(r).strip().split()[0].strip(".,!") in ("si", "yes")


def giudica_frase(con, puo, frase):
    """Il verdetto di una frase: dict con esito, citazioni, fiducia, motivi."""
    cit = CITAZIONE.findall(frase)
    pulita = CITAZIONE.sub("", frase).strip()
    if not cit:
        return {"frase": pulita, "esito": "generale", "citazioni": [], "fiducia": None, "motivi": []}
    fonti, citazioni = [], []
    for percorso, da, a in cit:
        da, a = int(da), int(a or da)
        citazioni.append(f"{percorso}:{da}" + (f"-{a}" if a != da else ""))
        testo, rotta = righe_citate(con, puo, percorso, da, a)
        if rotta:
            return {"frase": pulita, "esito": "rotta", "citazioni": citazioni, "fiducia": 0.0,
                    "motivi": [f"{percorso}:{da}: {rotta}"]}
        fonti.append(testo)
    return _decidi(pulita, "\n".join(fonti), citazioni)


def _decidi(frase, fonte, citazioni):
    """Primo giudice; sotto soglia il secondo, ma mai per un numero assente (il deterministico vince)."""
    conf, motivi = fiducia(frase, fonte)
    esito = "verificata"
    if conf < SOGLIA:
        voto = None if any(m.startswith("numeri assenti") for m in motivi) else giudice(frase, fonte)
        esito = "verificata dal giudice" if voto else "incerta"
        motivi.append({True: "il giudice dice SI", False: "il giudice dice NO",
                       None: "sotto soglia, nessun giudice utile"}[voto])
    return {"frase": frase, "esito": esito, "citazioni": citazioni, "fiducia": conf, "motivi": motivi}


def verifica(con, puo, risposta):
    """Tutti i verdetti della risposta e il riepilogo {'citate','verificate','incerte','rotte','generali'}."""
    verdetti = [giudica_frase(con, puo, f) for f in frasi(risposta)]
    conta = {"citate": 0, "verificate": 0, "incerte": 0, "rotte": 0, "generali": 0}
    for v in verdetti:
        if v["esito"] == "generale":
            conta["generali"] += 1
            continue
        conta["citate"] += 1
        chiave = {"rotta": "rotte", "incerta": "incerte"}.get(v["esito"], "verificate")
        conta[chiave] += 1
    return verdetti, conta


def rapporto(verdetti, conta):
    """Il resoconto leggibile: una riga di verdetto, poi le frasi che non passano e le generali."""
    out = [f"VERIFICA FONTI: parti citate e verificate {conta['verificate']}/{conta['citate']}"
           f" · incerte {conta['incerte']} · rotte {conta['rotte']}"
           f" · conoscenza generale {conta['generali']}"]
    simboli = {"incerta": "⚠", "rotta": "⛔", "generale": "[generale]"}
    for v in verdetti:
        if v["esito"] in simboli:
            dove = " ".join(v["citazioni"])
            perche = "; ".join(v["motivi"]) or "non dai tuoi documenti"
            out.append(f"  {simboli[v['esito']]} «{v['frase'][:160]}» {dove} — {perche}")
    return "\n".join(out)
