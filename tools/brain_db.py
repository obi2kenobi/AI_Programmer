"""brain_db.py — la memoria del Brain: un database relazionale, non file sparsi.

Perché un database e non cartelle di markdown (il quinto problema delle LLM Wiki):
- i PERMESSI sono una query (chi legge cosa), non una sovrastruttura sul file system;
- più persone lo usano INSIEME: modalità WAL, chi legge non blocca chi indicizza e
  ogni documento entra in una transazione sua, quindi chi interroga vede sempre uno
  stato coerente (o il documento vecchio, o il nuovo, mai mezzo);
- scala: il conto dei documenti non cambia la forma, cambia solo il numero di righe.

Le tabelle:
  meta(chiave, valore)                    la radice del corpus, la data dell'ultimo giro
  documenti(percorso, cartella, ...)      un documento = livello 1 (riassunto + profilo)
  pezzi(percorso, riga_da, riga_a, ...)   il testo, a pezzi con le righe vere (per citare)
  nodi(percorso, livello, padre, ...)     cartelle = livelli 2..n, radice «.» = la mappa
  ruoli(utente, ruolo)                    chi è chi
  regole(ruolo, schema, permesso, ordine) cosa vede ciascun ruolo (nega vince su leggi)
"""
import json
import os
import sqlite3

SCHEMA = """
CREATE TABLE IF NOT EXISTS meta(chiave TEXT PRIMARY KEY, valore TEXT);
CREATE TABLE IF NOT EXISTS documenti(
  percorso TEXT PRIMARY KEY, cartella TEXT NOT NULL, impronta TEXT NOT NULL,
  righe INTEGER NOT NULL, titolo TEXT, riassunto TEXT, profilo TEXT NOT NULL,
  aggiornato TEXT NOT NULL);
CREATE INDEX IF NOT EXISTS documenti_cartella ON documenti(cartella);
CREATE TABLE IF NOT EXISTS pezzi(
  id INTEGER PRIMARY KEY, percorso TEXT NOT NULL, riga_da INTEGER NOT NULL,
  riga_a INTEGER NOT NULL, intestazione TEXT, testo TEXT NOT NULL, profilo TEXT NOT NULL);
CREATE INDEX IF NOT EXISTS pezzi_percorso ON pezzi(percorso);
CREATE TABLE IF NOT EXISTS nodi(
  percorso TEXT PRIMARY KEY, livello INTEGER NOT NULL, padre TEXT,
  riassunto TEXT, profilo TEXT NOT NULL, n_documenti INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS ruoli(utente TEXT NOT NULL, ruolo TEXT NOT NULL,
  PRIMARY KEY(utente, ruolo));
CREATE TABLE IF NOT EXISTS regole(id INTEGER PRIMARY KEY, ruolo TEXT NOT NULL,
  schema TEXT NOT NULL, permesso TEXT NOT NULL CHECK(permesso IN ('leggi','nega')));
"""


def percorso_db(argomento=None):
    """Dove vive il database: --db, poi $BRAIN_DB, poi ~/.brain/brain.db (mai nel repo)."""
    if argomento:
        return argomento
    return os.environ.get("BRAIN_DB") or os.path.expanduser("~/.brain/brain.db")


def apri(percorso):
    """Apre (e crea se serve) il database in modalità WAL, pronto per lettori e scrittori insieme."""
    os.makedirs(os.path.dirname(os.path.abspath(percorso)), exist_ok=True)
    con = sqlite3.connect(percorso, timeout=30)
    con.execute("PRAGMA journal_mode=WAL")
    con.execute("PRAGMA busy_timeout=30000")
    con.executescript(SCHEMA)
    return con


def esiste(percorso):
    """Il database c'è già? (chiedere a un Brain mai indicizzato è un errore d'uso, non un vuoto)."""
    return os.path.isfile(percorso)


def leggi_meta(con, chiave):
    riga = con.execute("SELECT valore FROM meta WHERE chiave=?", (chiave,)).fetchone()
    return riga[0] if riga else None


def scrivi_meta(con, chiave, valore):
    con.execute("INSERT OR REPLACE INTO meta VALUES(?,?)", (chiave, valore))


def profilo(testo_json):
    """Il profilo salvato (JSON) -> dizionario parola: peso."""
    return json.loads(testo_json) if testo_json else {}
