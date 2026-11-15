"""brain.py — il Brain: la conoscenza dei documenti, indicizzata ad albero e interrogata con le fonti verificate.

Nasce dal confronto con le LLM Wiki «a grafo» (cartella di markdown collegati da un agente):
cinque problemi, cinque risposte — vedi docs/brain.md.

Uso:
  brain.py indicizza <cartella> [--paralleli N] [--estensioni md,txt,pdf] [--forza]
  brain.py chiedi "<domanda>" [--utente U] [--quanti N] [--json]
  brain.py verifica [--utente U] [--json]          (la risposta da verificare su stdin)
  brain.py mappa [--utente U] [--profondita N]     (l'indice: la sintesi delle sintesi)
  brain.py stato
  brain.py permessi ruolo <utente> <ruolo> | regola <ruolo> leggi|nega <schema> | elenca
Opzione comune: --db <file> (altrimenti $BRAIN_DB, poi ~/.brain/brain.db).
La persona: --utente, poi $BRAIN_UTENTE, poi $USER.

Esce: 0 risposta con tutte le parti citate verificate · 2 uso o database assente
      3 almeno una parte citata incerta o rotta · 4 nessuna parte citata (risposta non ancorata)
"""
import argparse
import json
import os
import sys

import brain_db
import brain_ingest
import brain_permessi
import brain_risposta
import brain_verifica
from brain_modello import log


def argomenti(argv):
    """La riga di comando: un sottocomando per verbo, le opzioni di ciascuno (vedi l'uso in testa al file)."""
    ap = argparse.ArgumentParser(prog="brain.py", description="Il Brain: conoscenza ad albero, fonti verificate.")
    ap.add_argument("--db")
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("indicizza")
    s.add_argument("cartella")
    s.add_argument("--paralleli", type=int)
    s.add_argument("--estensioni", default=",".join(brain_ingest.ESTENSIONI))
    s.add_argument("--forza", action="store_true", help="riassume anche gli invariati")
    for nome in ("chiedi", "verifica", "mappa"):
        s = sub.add_parser(nome)
        s.add_argument("--utente")
        s.add_argument("--json", action="store_true")
        if nome == "chiedi":
            s.add_argument("domanda")
            s.add_argument("--quanti", type=int, default=6)
        if nome == "mappa":
            s.add_argument("--profondita", type=int, default=2)
    sub.add_parser("stato")
    s = sub.add_parser("permessi")
    s.add_argument("azione", choices=["ruolo", "regola", "elenca"])
    s.add_argument("valori", nargs="*")
    return ap.parse_args(argv)


def utente(a):
    """Chi chiede: --utente, poi $BRAIN_UTENTE, poi $USER. Dichiarato, non autenticato (docs/brain.md)."""
    return getattr(a, "utente", None) or os.environ.get("BRAIN_UTENTE") or os.environ.get("USER", "anonimo")


def esito(conta):
    """Il codice d'uscita dal conteggio: 3 se qualcosa non passa, 4 se niente è citato, 0 altrimenti."""
    if conta["incerte"] or conta["rotte"]:
        return 3
    return 0 if conta["citate"] else 4


def cmd_indicizza(con, a):
    """Indicizza la cartella (solo il cambiato) e stampa il conteggio del giro."""
    if not os.path.isdir(a.cartella):
        log(f"cartella inesistente: {a.cartella}")
        return 2
    est = tuple(e.strip().lower() for e in a.estensioni.split(",") if e.strip())
    conta = brain_ingest.indicizza(con, a.cartella, est, paralleli=a.paralleli, forza=a.forza)
    print("INDICIZZATO: " + " · ".join(f"{k} {v}" for k, v in conta.items()))
    return 0


def cmd_chiedi(con, a):
    """Risponde alla domanda con i soli documenti leggibili dalla persona, e stampa il resoconto delle fonti."""
    puo = brain_permessi.lettore(con, utente(a))
    r = brain_risposta.rispondi(con, puo, a.domanda, a.quanti)
    if a.json:
        print(json.dumps({k: r[k] for k in ("testo", "modo", "conta", "verdetti")}, ensure_ascii=False, indent=1))
    else:
        print(r["testo"])
        print()
        print(f"(risposta {r['modo']}) " + brain_verifica.rapporto(r["verdetti"], r["conta"]))
    return esito(r["conta"])


def cmd_verifica(con, a):
    """Verifica una risposta scritta altrove (stdin): ogni frase contro le righe che cita."""
    puo = brain_permessi.lettore(con, utente(a))
    verdetti, conta = brain_verifica.verifica(con, puo, sys.stdin.read())
    if a.json:
        print(json.dumps({"conta": conta, "verdetti": verdetti}, ensure_ascii=False, indent=1))
    else:
        print(brain_verifica.rapporto(verdetti, conta))
    return esito(conta)


def cmd_mappa(con, a):
    """La mappa dell'indice: le cartelle fino alla profondità data, solo quelle tutte leggibili."""
    puo = brain_permessi.lettore(con, utente(a))
    docs = [p for (p,) in con.execute("SELECT percorso FROM documenti") if puo(p)]
    for p, liv, n, riass in con.execute(
            "SELECT percorso, livello, n_documenti, riassunto FROM nodi WHERE livello<=? ORDER BY percorso",
            (a.profondita,)):
        visibili = sum(1 for d in docs if p == "." or d.startswith(p + "/"))
        if not visibili:
            continue
        testo = riass if visibili == n else f"(sintesi nascosta: leggi {visibili} documenti su {n})"
        print(f"{'  ' * liv}{p}/ [{visibili}] {testo[:300]}")
    return 0


def cmd_stato(con, a):
    """Una riga: radice del corpus, ultimo giro, quanti documenti, pezzi e cartelle."""
    n_doc, n_pez, n_nod = (con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
                           for t in ("documenti", "pezzi", "nodi"))
    print(f"BRAIN: radice {brain_db.leggi_meta(con, 'radice')} · ultimo giro "
          f"{brain_db.leggi_meta(con, 'ultimo_giro')} · documenti {n_doc} · pezzi {n_pez} · cartelle {n_nod}")
    return 0


def cmd_permessi(con, a):
    """Assegna un ruolo o aggiunge una regola, poi stampa l'elenco completo (ruoli e regole)."""
    v = a.valori
    if a.azione == "ruolo" and len(v) == 2:
        brain_permessi.assegna_ruolo(con, *v)
    elif a.azione == "regola" and len(v) == 3:
        brain_permessi.aggiungi_regola(con, *v)
    elif a.azione != "elenca":
        log("uso: permessi ruolo <utente> <ruolo> | regola <ruolo> leggi|nega <schema> | elenca")
        return 2
    print("\n".join(brain_permessi.elenco(con)))
    return 0


def main(argv):
    """Apre il database (assente = errore d'uso, tranne per indicizza) e lancia il sottocomando."""
    a = argomenti(argv)
    db = brain_db.percorso_db(a.db)
    if a.cmd != "indicizza" and not brain_db.esiste(db):
        log(f"database assente: {db} — prima `brain.py indicizza <cartella>` (assente non è vuoto)")
        return 2
    con = brain_db.apri(db)
    log(f"{a.cmd} su {db}")
    try:
        return globals()[f"cmd_{a.cmd}"](con, a)
    except ValueError as e:
        log(f"errore d'uso: {e}")
        return 2
    finally:
        con.close()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
