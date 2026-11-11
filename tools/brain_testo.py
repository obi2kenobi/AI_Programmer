"""brain_testo.py — le parole del Brain: normalizzare, togliere il rumore, pesare.

Tutto il Brain (indice, ricerca, verifica delle citazioni) confronta testi per
PAROLE PIENE: minuscole, senza accenti, senza parole vuote, ridotte alla radice
(un taglio a 6 lettere: «fatture»/«fatturato» -> «fattur»). Il taglio è grezzo
ma deterministico e uguale ovunque: indice e domanda parlano la stessa lingua.

I numeri restano interi («1.234,56» -> «1234,56»): la verifica li confronta a parte,
perché un numero sbagliato è il difetto peggiore di una citazione.
"""
import math
import re
import unicodedata
from collections import Counter

RADICE = 6
PAROLA = re.compile(r"[a-z0-9]+(?:[.,][0-9]+)*")
NUMERO = re.compile(r"\d+(?:[.,]\d+)*")
VUOTE = set("""
a ad al alla alle allo agli ai anche ancora che chi ci come con cosa cui da dal dalla
dalle dei del della delle dello degli di dopo e ed era essere fa fra gia gli ha hanno
ho i il in la le lo loro ma me mi molto ne nei nel nella nelle negli no noi o per piu
poi puo quale quali quando quello questa questo queste questi se sei si sia sono su sua
sue suo suoi sul sulla tra tu tutti tutto un una uno va vi
the of and to in is it for on with as by be are this that from or an at not
""".split())
NEGAZIONI = {"non", "mai", "nessun", "nessuna", "nessuno", "senza", "never", "no", "not"}


def piega(testo):
    """Minuscole e senza accenti: «Perché» -> «perche»."""
    t = unicodedata.normalize("NFKD", testo.lower())
    return "".join(c for c in t if not unicodedata.combining(c))


def parole(testo):
    """Le parole piene, ridotte alla radice, nell'ordine in cui compaiono."""
    out = []
    for p in PAROLA.findall(piega(testo)):
        if p in VUOTE or (len(p) < 3 and not p.isdigit()):
            continue
        out.append(p if NUMERO.fullmatch(p) else p[:RADICE])
    return out


def numeri(testo):
    """I numeri del testo, normalizzati (i separatori restano: 1.234 != 1234 per scelta)."""
    return set(NUMERO.findall(testo))


def negati(testo, portata=4):
    """Le radici delle parole piene che seguono una negazione («non», «mai»...) entro `portata` parole.

    Serve a non scambiare un fatto col suo contrario: «non usare clasp» nega «usar» e «clasp».
    Guardare la negazione VICINA alla parola, non nel testo intero, evita il falso allarme
    quando la fonte ha un «non» in un'altra frase.
    """
    out, resta = set(), 0
    for p in PAROLA.findall(piega(testo)):
        if p in NEGAZIONI:
            resta = portata
            continue
        if resta and p not in VUOTE and len(p) >= 3:
            out.add(p if NUMERO.fullmatch(p) else p[:RADICE])
            resta -= 1
    return out


def pesi(testo, quante):
    """Le `quante` parole più frequenti con peso logaritmico (1 + log n): il profilo di un testo.

    Nel profilo (che serve a TROVARE) non entrano le negazioni né i numeri sotto le tre cifre:
    «non», «0», «09» sono ovunque e non distinguono niente. Nella verifica invece contano tutti.
    """
    conta = Counter(p for p in parole(testo)
                    if p not in NEGAZIONI and not (p.isdigit() and len(p) < 3))
    return {p: round(1 + math.log(n), 3) for p, n in conta.most_common(quante)}


def somma_pesi(profili, quante):
    """Unisce i profili dei figli nel profilo del padre (la sintesi delle sintesi, in parole)."""
    tot = Counter()
    for prof in profili:
        tot.update(prof)
    return {p: round(v, 3) for p, v in tot.most_common(quante)}


def punteggio(domanda, profilo):
    """Quanto un profilo parla della domanda: somma dei pesi delle parole in comune."""
    return sum(profilo.get(p, 0.0) for p in set(domanda))
