"""brain_permessi.py — chi può leggere cosa.

Regole per ruolo, con schemi glob sul percorso del documento («contratti/*», «*»).
Una persona può avere più ruoli. Si legge un documento se ALMENO una regola «leggi»
di uno dei suoi ruoli lo copre e NESSUNA regola «nega» dei suoi ruoli lo copre:
il divieto vince sempre (lo stagista con «leggi *» e «nega paghe/*» non vede le paghe).

Due casi dichiarati, mai silenziosi:
- nessuna regola nel database -> tutto leggibile da tutti (Brain personale, detto nel log);
- regole presenti ma persona senza ruoli -> niente leggibile (detto nel log).

Le sintesi delle cartelle mescolano documenti diversi: chi non può leggere TUTTA una
cartella non usa la sua sintesi salvata — la sua vista della cartella si ricompone
al volo dai soli figli che può leggere (brain_interroga), così niente trapela.
"""
import fnmatch

from brain_modello import log


def regole_di(con, utente):
    """Le regole (schema, permesso) dei ruoli della persona; None se il database non ha regole."""
    if not con.execute("SELECT 1 FROM regole LIMIT 1").fetchone():
        return None
    return con.execute(
        "SELECT r.schema, r.permesso FROM regole r JOIN ruoli u ON u.ruolo = r.ruolo "
        "WHERE u.utente = ?", (utente,)).fetchall()


def lettore(con, utente):
    """Una funzione percorso -> bool per questa persona, con il caso dichiarato nel log."""
    regole = regole_di(con, utente)
    if regole is None:
        log(f"nessuna regola di permesso: {utente} legge tutto (Brain senza permessi, dichiarato)")
        return lambda percorso: True
    if not regole:
        log(f"{utente} non ha ruoli con regole: non legge nessun documento (dichiarato)")
        return lambda percorso: False
    leggi = [s for s, p in regole if p == "leggi"]
    nega = [s for s, p in regole if p == "nega"]

    def puo(percorso):
        return (any(fnmatch.fnmatch(percorso, s) for s in leggi)
                and not any(fnmatch.fnmatch(percorso, s) for s in nega))
    return puo


def assegna_ruolo(con, utente, ruolo):
    with con:
        con.execute("INSERT OR IGNORE INTO ruoli VALUES(?,?)", (utente, ruolo))


def aggiungi_regola(con, ruolo, permesso, schema):
    if permesso not in ("leggi", "nega"):
        raise ValueError(f"permesso «{permesso}»: vale solo leggi o nega")
    with con:
        con.execute("INSERT INTO regole(ruolo,schema,permesso) VALUES(?,?,?)", (ruolo, schema, permesso))


def elenco(con):
    """Righe leggibili di ruoli e regole, per il comando `permessi elenca`."""
    out = [f"ruolo {r}: {u}" for u, r in con.execute("SELECT utente, ruolo FROM ruoli ORDER BY ruolo, utente")]
    out += [f"regola {r}: {p} {s}" for r, p, s in
            con.execute("SELECT ruolo, permesso, schema FROM regole ORDER BY ruolo, id")]
    return out or ["(nessun ruolo e nessuna regola: tutti leggono tutto)"]
