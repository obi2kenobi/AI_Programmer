"""brain_modello.py — il ponte (facoltativo) verso un modello linguistico.

Il Brain funziona SENZA modello: riassunti estrattivi, risposte estrattive, verifica
deterministica (concetto-vaccino: deterministico prima di intelligente). Un modello
si aggiunge dichiarandolo con una variabile d'ambiente che nomina un comando col
contratto di llm/ (prompt come argomento, contesto su stdin, risposta su stdout):

  BRAIN_LLM      scrive: riassunti dei documenti e delle cartelle, risposte, correzioni
  BRAIN_GIUDICE  giudica: la seconda istanza che ricontrolla le citazioni incerte
                 (se manca, si usa BRAIN_LLM; se mancano entrambi, l'incerta resta ⚠)

Esempio: BRAIN_LLM=llm/ask-qwen.sh (locale) · BRAIN_GIUDICE=llm/ask-opus.sh (cloud,
mascherato). Ogni chiamata fallita si dice nel log e torna None: chi chiama ripiega.
"""
import os
import shlex
import subprocess
import sys
import time

TEMPO = int(os.environ.get("BRAIN_TEMPO_MODELLO", "300"))


def log(msg):
    print(f"[brain {time.strftime('%H:%M:%S')}] {msg}", file=sys.stderr, flush=True)


def comando(ruolo):
    """Il comando configurato per un ruolo ('scrittore' o 'giudice'), o None."""
    if ruolo == "giudice":
        return os.environ.get("BRAIN_GIUDICE") or os.environ.get("BRAIN_LLM")
    return os.environ.get("BRAIN_LLM")


def chiedi(ruolo, prompt, contesto=""):
    """Una domanda al modello del ruolo: la risposta pulita, o None (detto nel log) se non c'è."""
    cmd = comando(ruolo)
    if not cmd:
        return None
    try:
        r = subprocess.run(shlex.split(cmd) + [prompt], input=contesto, capture_output=True,
                           text=True, timeout=TEMPO)
    except (OSError, subprocess.TimeoutExpired) as e:
        log(f"modello {ruolo} ({cmd}) non risponde: {e.__class__.__name__} — si ripiega")
        return None
    if r.returncode != 0 or not r.stdout.strip():
        log(f"modello {ruolo} ({cmd}) rc {r.returncode}, risposta vuota o errore — si ripiega")
        return None
    return r.stdout.strip()
