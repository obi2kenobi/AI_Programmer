"""numero.py — la lettura unica dei numeri negli export CSV, per tutti gli oracoli.

Domanda 12, risposta di Luca (2026-09-26): gli export arrivano in formato italiano
(1.234,56), e una funzione sola li converte per tutti. Prima ogni oracolo chiamava
float() da sé, e «1.234,56» era un ERRORE in quattro oracoli e una riga scartata nel
bilancio per BU.

Le regole, in ordine:
1. Con la virgola il numero è italiano: i punti sono migliaia, la virgola è il
   decimale. «1.234,56» -> 1234.56. Punti fuori posto («1.23,4») sono un errore.
2. Senza virgola, cifre a gruppi di tre dopo un punto sono migliaia:
   «1.234» -> 1234, «1.234.567» -> 1234567. È l'ambiguità che la risposta di Luca
   scioglie: un «1.500» inteso come uno e mezzo diventa millecinquecento.
   Un gruppo iniziale «0» non è migliaia («0.500» resta 0.5).
3. Tutto il resto va a float(): «1234.56», «-0.5», «100». Anche nan e inf passano,
   e restano ai controlli di finitezza che ogni oracolo già fa.
Il vuoto e ogni altra forma sono ValueError: ciascun oracolo decide cosa fare del
vuoto (il rating lo conta zero, domanda 4) e dice l'errore col numero di riga.
"""
import re

ITALIANO = re.compile(r"-?(\d{1,3}(\.\d{3})+|\d+),\d+")
MIGLIAIA = re.compile(r"-?[1-9]\d{0,2}(\.\d{3})+")


def leggi_numero(testo):
    """Il testo di una cella -> float. ValueError se non è un numero riconosciuto."""
    t = (testo or "").strip()
    if "," in t:
        if not ITALIANO.fullmatch(t):
            raise ValueError(f"numero italiano malformato: {testo!r}")
        return float(t.replace(".", "").replace(",", "."))
    if MIGLIAIA.fullmatch(t):
        return float(t.replace(".", ""))
    return float(t)
