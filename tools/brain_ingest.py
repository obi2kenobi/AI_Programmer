"""brain_ingest.py — l'indicizzazione: parallela, incrementale, senza «healing» globale.

Il giro, ogni passo loggato:
1. censisce i file del corpus e ne calcola l'impronta (sha256 del contenuto);
2. confronta col database: nuovi, cambiati, spariti, invariati (gli invariati non si toccano);
3. riassume i nuovi/cambiati IN PARALLELO (ogni documento è indipendente dagli altri);
4. scrive ogni documento nella SUA transazione (chi interroga intanto vede uno stato coerente);
5. ricostruisce SOLO le cartelle sporche, dal basso verso la radice.

Togliere o cambiare un documento costa i suoi antenati, non il grafo intero: è il punto
in cui le LLM Wiki a grafo si inceppano oltre i 200-300 documenti.
"""
import fnmatch
import hashlib
import json
import os
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor

import brain_db
import brain_riassunto
from brain_modello import log

ESTENSIONI = ("md", "txt", "pdf")
ESCLUSI = (".*", "node_modules", "__pycache__", "graphify-out")


def censisci(radice, estensioni, esclusi):
    """I file del corpus come {percorso relativo: percorso assoluto}, cartelle escluse saltate."""
    trovati = {}
    for cur, dirs, files in os.walk(radice):
        dirs[:] = sorted(d for d in dirs if not any(fnmatch.fnmatch(d, e) for e in esclusi))
        for f in sorted(files):
            if f.rsplit(".", 1)[-1].lower() in estensioni:
                ass = os.path.join(cur, f)
                trovati[os.path.relpath(ass, radice).replace(os.sep, "/")] = ass
    return trovati


def leggi(assoluto):
    """Il testo di un file; i PDF passano da pdftotext. None (detto) se illeggibile."""
    if assoluto.lower().endswith(".pdf"):
        if not shutil.which("pdftotext"):
            log(f"SALTO {assoluto}: pdftotext assente (il PDF non è letto, non è vuoto)")
            return None
        r = subprocess.run(["pdftotext", "-layout", assoluto, "-"], capture_output=True, text=True)
        if r.returncode != 0 or not r.stdout.strip():
            log(f"SALTO {assoluto}: PDF illeggibile o senza testo (scansione? serve l'OCR, che qui non c'è)")
            return None
        return r.stdout
    with open(assoluto, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def impronta(testo):
    return hashlib.sha256(testo.encode("utf-8")).hexdigest()


def cartella_di(percorso):
    return percorso.rsplit("/", 1)[0] if "/" in percorso else "."


def antenati(cartella):
    """Le cartelle da `cartella` fino alla radice «.», inclusa."""
    out = []
    while cartella != ".":
        out.append(cartella)
        cartella = cartella_di(cartella)
    return out + ["."]


def confronta(con, file, forza):
    """Divide il censimento: (da_fare {percorso: (testo, impronta)}, spariti [percorsi], invariati n)."""
    noti = dict(con.execute("SELECT percorso, impronta FROM documenti"))
    da_fare, invariati = {}, 0
    for rel, ass in file.items():
        testo = leggi(ass)
        if testo is None:
            continue
        imp = impronta(testo)
        if not forza and noti.get(rel) == imp:
            invariati += 1
        else:
            da_fare[rel] = (testo, imp)
    return da_fare, sorted(set(noti) - set(file)), invariati


def riassumi_tutti(da_fare, paralleli):
    """Il livello 1 di ogni documento, in parallelo: {percorso: documento}."""
    def uno(rel):
        return rel, brain_riassunto.documento(rel, da_fare[rel][0])
    with ThreadPoolExecutor(max_workers=paralleli) as pool:
        return dict(pool.map(uno, sorted(da_fare)))


def scrivi_documento(con, rel, imp, doc):
    """Un documento e i suoi pezzi, in UNA transazione: chi legge vede il vecchio o il nuovo."""
    with con:
        con.execute("DELETE FROM pezzi WHERE percorso=?", (rel,))
        con.execute("INSERT OR REPLACE INTO documenti VALUES(?,?,?,?,?,?,?,?)",
                    (rel, cartella_di(rel), imp, doc["righe"], doc["titolo"], doc["riassunto"],
                     json.dumps(doc["profilo"]), time.strftime("%Y-%m-%dT%H:%M:%S")))
        con.executemany(
            "INSERT INTO pezzi(percorso,riga_da,riga_a,intestazione,testo,profilo) VALUES(?,?,?,?,?,?)",
            [(rel, p["riga_da"], p["riga_a"], p["intestazione"], p["testo"],
              json.dumps(p["profilo"])) for p in doc["pezzi"]])


def togli_documento(con, rel):
    with con:
        con.execute("DELETE FROM pezzi WHERE percorso=?", (rel,))
        con.execute("DELETE FROM documenti WHERE percorso=?", (rel,))


def figli_di(con, cartella):
    """I figli di una cartella (documenti e sottocartelle) nella forma che vuole brain_riassunto.cartella."""
    docs = [{"nome": p.rsplit("/", 1)[-1], "titolo": t, "riassunto": r,
             "profilo": brain_db.profilo(pr), "n": 1}
            for p, t, r, pr in con.execute(
                "SELECT percorso,titolo,riassunto,profilo FROM documenti WHERE cartella=? "
                "ORDER BY percorso", (cartella,))]
    sotto = [{"nome": p.rsplit("/", 1)[-1] + "/", "titolo": "", "riassunto": r,
              "profilo": brain_db.profilo(pr), "n": n}
             for p, r, pr, n in con.execute(
                 "SELECT percorso,riassunto,profilo,n_documenti FROM nodi WHERE padre=? "
                 "ORDER BY percorso", (cartella,))]
    return docs + sotto


def ricostruisci_cartelle(con, sporche):
    """Le cartelle sporche dal basso verso l'alto: la sintesi delle sintesi, solo dove serve."""
    for c in sorted(sporche, key=lambda x: (-x.count("/") - (x != "."), x)):
        figli = figli_di(con, c)
        with con:
            if not figli:
                con.execute("DELETE FROM nodi WHERE percorso=?", (c,))
                continue
            sint = brain_riassunto.cartella(c, figli)
            livello = 0 if c == "." else c.count("/") + 1
            con.execute("INSERT OR REPLACE INTO nodi VALUES(?,?,?,?,?,?)",
                        (c, livello, None if c == "." else cartella_di(c), sint["riassunto"],
                         json.dumps(sint["profilo"]), sint["n"]))


def indicizza(con, radice, estensioni=ESTENSIONI, esclusi=ESCLUSI, paralleli=None, forza=False):
    """Il giro completo. Ritorna il conteggio {'nuovi_o_cambiati','spariti','invariati','cartelle'}."""
    paralleli = paralleli or min(8, os.cpu_count() or 2)
    log(f"censisco {radice} (estensioni {','.join(estensioni)}, esclusi {','.join(esclusi)})")
    file = censisci(radice, estensioni, esclusi)
    da_fare, spariti, invariati = confronta(con, file, forza)
    log(f"{len(file)} file: {len(da_fare)} da riassumere, {len(spariti)} spariti, {invariati} invariati")
    log(f"riassumo in parallelo ({paralleli} alla volta)")
    fatti = riassumi_tutti(da_fare, paralleli)
    for rel, doc in fatti.items():
        scrivi_documento(con, rel, da_fare[rel][1], doc)
    for rel in spariti:
        togli_documento(con, rel)
        log(f"tolto {rel} (non c'è più nel corpus)")
    sporche = {a for rel in list(fatti) + spariti for a in antenati(cartella_di(rel))}
    log(f"ricostruisco {len(sporche)} cartelle sporche (le altre restano com'erano)")
    ricostruisci_cartelle(con, sporche)
    with con:
        brain_db.scrivi_meta(con, "radice", os.path.abspath(radice))
        brain_db.scrivi_meta(con, "ultimo_giro", time.strftime("%Y-%m-%dT%H:%M:%S"))
    return {"nuovi_o_cambiati": len(fatti), "spariti": len(spariti), "invariati": invariati,
            "cartelle": len(sporche)}
