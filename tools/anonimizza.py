#!/usr/bin/env python3
"""anonimizza.py — il anonimizzatore reversibile per il turno (studio rizzo-pii).

Due modalità:
  anonimizza: testo → placeholder ([FULLNAME_1], [CF_1], ...) + dizionario JSON su file
  de-anonimizza: testo con placeholder + dizionario → testo con valori veri

Il dizionario (placeholder → valore) NON passa mai al LLM: vive su disco
locale e viene usato solo dal processo di scrittura.

Uso:
  # anonimizza (il testo pulito va a stdout, il dizionario su file)
  echo "Mario Rossi, CF RSSMRA85M01H501Z" | python3 tools/anonimizza.py --diz diz.json

  # de-anonimizza (il testo vero torna a stdout)
  echo "Ciao [FULLNAME_1]" | python3 tools/anonimizza.py --ripristina --diz diz.json

Se il server rizzo-pii è spento: passthrough dichiarato (stderr), testo invariato.
"""
import json
import os
import sys
import urllib.request

PII_URL = os.environ.get("PII_URL", "http://127.0.0.1:5005")


def chiama_server(testo: str) -> dict | None:
    """Chiama /analyze e ritorna la risposta JSON, o None se il server è spento."""
    try:
        req = urllib.request.Request(
            f"{PII_URL}/analyze",
            data=json.dumps({"text": testo, "include_mapping": True}).encode(),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except Exception:
        return None


def anonimizza(testo: str, diz_path: str) -> str:
    risp = chiama_server(testo)
    if risp is None:
        print("anonimizza: server spento — passthrough (il LLM vedrà i dati veri)", file=sys.stderr)
        return testo
    # dizionario CUMULATIVO: merge, non overwrite (Claude 2026-09-28: se il file A
    # ha [FULLNAME_1]=Mario e il file B ha [FULLNAME_1]=Luigi, il vecchio codice
    # sovrascriveva: il ripristino del file A metteva Luigi — corruzione silenziosa)
    nuovo = risp.get("mapping", {})
    vecchio = {}
    try:
        with open(diz_path) as f:
            vecchio = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    # per ogni placeholder nuovo che collide con uno esistente, rinumera
    for ph, reale in nuovo.items():
        base = ph.rstrip("0123456789]")
        n = 1
        while f"{base}{n}]" in vecchio and vecchio[f"{base}{n}]"] != reale:
            n += 1
        vecchio[f"{base}{n}]"] = reale
    # salva con permessi 600 (non leggibile da altri)
    import os, tempfile
    fd = os.open(diz_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(vecchio, f, ensure_ascii=False, indent=1)
    return risp.get("anonymized_text", testo)


def de_anonimizza(testo: str, diz_path: str) -> str:
    try:
        with open(diz_path) as f:
            mapping = json.load(f)
    except FileNotFoundError:
        print("de-anonimizza: dizionario assente — passthrough", file=sys.stderr)
        return testo
    for ph, reale in mapping.items():
        testo = testo.replace(ph, reale)
    return testo


def main():
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--diz", required=True, help="percorso del dizionario locale")
    p.add_argument("--ripristina", action="store_true", help="de-anonimizza invece di anonimizzare")
    args = p.parse_args()

    testo = sys.stdin.read()
    if args.ripristina:
        risultato = de_anonimizza(testo, args.diz)
    else:
        risultato = anonimizza(testo, args.diz)
    sys.stdout.write(risultato)


if __name__ == "__main__":
    main()
