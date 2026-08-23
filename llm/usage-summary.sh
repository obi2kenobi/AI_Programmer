#!/bin/bash
# usage-summary.sh — il riepilogo dei dati accumulati da _usage.sh (~/.ai-programmer-usage.log).
# Gap reale (4° ciclo, set 3 "flusso delle idee", 2026-08-23): il log esiste dal Set 1
# del ciclo precedente (giro 10, "nessuna traccia dei cervelli di giorno") ma nulla lo
# leggeva — i dati entravano e non uscivano mai come insight, la stessa asimmetria che
# quel giro aveva chiuso per metà (scrittura sì, lettura no). Stesso pattern di
# gate-summary.sh per metrics/gate.csv, applicato qui al log dei cervelli di giorno.
#
# Uso: usage-summary.sh [percorso-log]    (default $HOME/.ai-programmer-usage.log)
set -euo pipefail

LOG="${1:-${ASK_USAGE_LOG:-$HOME/.ai-programmer-usage.log}}"

[ -f "$LOG" ] || { echo "nessun dato: $LOG inesistente" >&2; exit 1; }

python3 - "$LOG" <<'PY'
import re, sys
from collections import defaultdict

log_path = sys.argv[1]
riga_re = re.compile(r'^\S+ (\S+) rc=(-?\d+) dur=(\d+)s prompt_chars=(\d+)$')

stats = defaultdict(lambda: {"chiamate": 0, "successi": 0, "dur_tot": 0})
scartate = 0
with open(log_path, encoding="utf-8") as f:
    for riga in f:
        riga = riga.strip()
        if not riga:
            continue
        m = riga_re.match(riga)
        if not m:
            scartate += 1
            continue
        brain, rc, dur, _ = m.groups()
        s = stats[brain]
        s["chiamate"] += 1
        s["dur_tot"] += int(dur)
        if rc == "0":
            s["successi"] += 1

if not stats:
    print("Nessuna riga valida nel log.")
    sys.exit(0)

print(f"{'Cervello':<12} {'Chiamate':>9} {'Successi':>9} {'% successo':>11} {'Durata media':>13}")
for brain in sorted(stats):
    s = stats[brain]
    pct = (s["successi"] / s["chiamate"]) * 100
    media = s["dur_tot"] / s["chiamate"]
    print(f"{brain:<12} {s['chiamate']:>9} {s['successi']:>9} {pct:>10.1f}% {media:>11.1f}s")

if scartate:
    print(f"\n{scartate} riga/e nel log non riconosciute (formato inatteso) — ignorate, non hanno fatto fallire il riepilogo.")
PY
