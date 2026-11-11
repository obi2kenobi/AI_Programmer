"""brain_interroga.py — la ricerca: si scende l'albero, il grafo si fa al volo.

Il Brain non compila un grafo all'indicizzazione (costoso, sequenziale, fragile):
1. DISCESA: dalla mappa (radice) si sceglie a ogni livello il fascio dei figli più
   pertinenti (cartelle e documenti), e si scende solo lì;
2. PEZZI: nei documenti scelti si cercano i pezzi di testo che rispondono;
3. RIFERIMENTI AL VOLO: se un pezzo scelto nomina un altro documento (un percorso
   «docs/x.md», un «[[wikilink]]»), si salta lì e se ne prende il pezzo migliore —
   il collegamento si scopre quando serve, non si mantiene per sempre.

Il costo si sposta dall'indicizzazione alla domanda: la domanda è un po' più lenta,
l'indice resta parallelo e incrementale. Se la discesa non trova niente (il profilo
delle cartelle è troncato: è il prezzo dell'albero), si ripiega sulla scansione piatta
dei documenti, detto nel log.

I permessi entrano a ogni livello: si vedono solo documenti leggibili; una cartella
leggibile solo in parte non usa la sua sintesi salvata ma una ricomposta dai figli visibili.
"""
import math
import re
from collections import defaultdict

import brain_db
import brain_ingest
import brain_testo
from brain_modello import log

RIFERIMENTO = re.compile(r"([A-Za-z0-9_./-]+\.(?:md|txt|pdf))|\[\[([^\]|#]+)")


class Vista:
    """Il corpus come lo vede UNA persona: documenti leggibili e conteggi per cartella."""

    def __init__(self, con, puo):
        """Carica una volta per domanda: documenti leggibili, quanti leggibili per cartella, i figli di ognuna."""
        self.con = con
        self.docs = {p: c for p, c in con.execute("SELECT percorso, cartella FROM documenti") if puo(p)}
        self.leggibili = defaultdict(int)
        for c in self.docs.values():
            for a in brain_ingest.antenati(c):
                self.leggibili[a] += 1
        self.nodi = {p: (n, padre) for p, n, padre in
                     con.execute("SELECT percorso, n_documenti, padre FROM nodi")}
        self.sotto = defaultdict(list)
        for p, (_, padre) in sorted(self.nodi.items()):
            if self.leggibili.get(p):
                self.sotto[padre].append(("cartella", p))
        for p, c in sorted(self.docs.items()):
            self.sotto[c].append(("documento", p))
        self._profili = {}

    def figli(self, cartella):
        """(tipo, percorso) dei figli visibili: sottocartelle con almeno un leggibile, documenti leggibili."""
        return self.sotto.get(cartella, [])

    def profilo(self, tipo, percorso):
        """Il profilo di parole visibile: salvato se tutto leggibile, ricomposto se no."""
        chiave = (tipo, percorso)
        if chiave not in self._profili:
            self._profili[chiave] = self._calcola(tipo, percorso)
        return self._profili[chiave]

    def _calcola(self, tipo, percorso):
        """Documento: il suo profilo. Cartella tutta leggibile: quello salvato. Altrimenti: dai figli visibili."""
        if tipo == "documento":
            return brain_db.profilo(self.con.execute(
                "SELECT profilo FROM documenti WHERE percorso=?", (percorso,)).fetchone()[0])
        if self.leggibili.get(percorso) == self.nodi[percorso][0]:
            return brain_db.profilo(self.con.execute(
                "SELECT profilo FROM nodi WHERE percorso=?", (percorso,)).fetchone()[0])
        return brain_testo.somma_pesi([self.profilo(t, p) for t, p in self.figli(percorso)], 120)


def discesa(vista, q, ampiezza):
    """La discesa a fascio: a ogni livello i migliori `ampiezza` figli; ritorna i documenti toccati."""
    frontiera, scelti = ["."], []
    while frontiera:
        cand = []
        for c in frontiera:
            for tipo, p in vista.figli(c):
                n = vista.leggibili.get(p, 1) if tipo == "cartella" else 1
                s = brain_testo.punteggio(q, vista.profilo(tipo, p)) / math.sqrt(n)
                if s > 0:
                    cand.append((s, tipo, p))
        cand.sort(reverse=True)
        top = cand[:ampiezza]
        scelti += [p for _, t, p in top if t == "documento"]
        frontiera = [p for _, t, p in top if t == "cartella"]
        log(f"discesa: {len(cand)} candidati, scelgo {[p for _, _, p in top]}")
    return scelti


def pezzi_di(con, percorsi, q, via=None):
    """I pezzi dei documenti dati col loro punteggio per la domanda (solo quelli con punteggio > 0;
    per un documento raggiunto da riferimento, `via`, vale anche zero: il legame è la pertinenza)."""
    out = []
    for p in percorsi:
        for da, a, intest, testo, prof in con.execute(
                "SELECT riga_da, riga_a, intestazione, testo, profilo FROM pezzi WHERE percorso=?", (p,)):
            s = brain_testo.punteggio(q, brain_db.profilo(prof))
            if s > 0 or via:
                out.append({"percorso": p, "riga_da": da, "riga_a": a, "intestazione": intest,
                            "testo": testo, "punteggio": round(s, 3), "via": via})
    return sorted(out, key=lambda x: (-x["punteggio"], x["percorso"], x["riga_da"]))


def riferimenti(vista, pezzo):
    """I documenti leggibili nominati dentro un pezzo (percorsi o [[wikilink]]), escluso se stesso."""
    nomi = {(m.group(1) or m.group(2) + ".md").strip().lstrip("./") for m in RIFERIMENTO.finditer(pezzo["testo"])}
    trovati = set()
    for nome in nomi:
        esatti = [p for p in vista.docs if p == nome or p.endswith("/" + nome)]
        if len(esatti) == 1 and esatti[0] != pezzo["percorso"]:
            trovati.add(esatti[0])
    return sorted(trovati)


def cerca(con, puo, domanda, quanti=6, ampiezza=4, salti=3):
    """La ricerca completa: discesa, pezzi, riferimenti al volo (un salto), scansione piatta di riserva."""
    q = brain_testo.parole(domanda)
    if not q:
        log("la domanda non ha parole piene: niente da cercare")
        return []
    vista = Vista(con, puo)
    log(f"cerco {q} fra {len(vista.docs)} documenti leggibili")
    trovati = pezzi_di(con, discesa(vista, q, ampiezza), q)
    if not trovati:
        log("la discesa non ha trovato pezzi: ripiego sulla scansione piatta (dichiarato)")
        trovati = pezzi_di(con, sorted(vista.docs), q)
    scelti = trovati[:quanti]
    gia = {p["percorso"] for p in scelti}
    for pz in list(scelti):
        for rif in [r for r in riferimenti(vista, pz) if r not in gia][:salti]:
            extra = pezzi_di(con, [rif], q, via=pz["percorso"])[:1]
            if extra:
                log(f"riferimento al volo: {pz['percorso']} -> {rif}")
                scelti += extra
                gia.add(rif)
    return scelti
