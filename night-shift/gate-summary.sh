#!/bin/bash
# gate-summary.sh — il riepilogo dei dati accumulati dal gate (metrics/gate.csv).
# docs/system.md promette che "le decisioni future le decidono i dati": questo è lo
# strumento che li legge. Per repo: % verifiche ok, % smentite del banco, commesse
# correttive ripetute (area fragile), PR che aspettano l'esito umano da N+ giorni (aging).
#
# Uso: gate-summary.sh [giorni-aging]    (default 1)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CSV="$HERE/../metrics/gate.csv"
AGING="${1:-1}"

[ -f "$CSV" ] || { echo "nessun dato: $CSV inesistente" >&2; exit 1; }

python3 - "$CSV" "$AGING" <<'PY'
import csv, sys
from collections import defaultdict
from datetime import date

csv_path, aging_days = sys.argv[1], int(sys.argv[2])
with open(csv_path, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

if not rows:
    print("Nessun dato nel CSV.")
    sys.exit(0)

oggi = date.today()
stats = defaultdict(lambda: {"righe": 0, "ver_ok": 0, "smentite": 0, "commesse": 0,
                             "merge": 0, "chiusure": 0, "aging_pr": {}, "scarti": 0, "eseguiti": 0})
for r in rows:
    s = stats[r["repo"]]
    s["righe"] += 1
    if r["verifiche"] == "verifiche-ok":
        s["ver_ok"] += 1
    if r["banco"] == "eseguito:smentita":
        s["smentite"] += 1
    if str(r["banco"]).startswith("scartato"):
        s["scarti"] += 1
    if str(r["banco"]).startswith("eseguito"):
        s["eseguiti"] += 1
    esito = (r.get("esito") or "").strip()
    if esito == "commessa":
        s["commesse"] += 1
    elif esito == "merge":
        s["merge"] += 1
    elif esito == "chiusura":
        s["chiusure"] += 1
    else:
        try:
            giorni = (oggi - date.fromisoformat(r["data"])).days
        except ValueError:
            giorni = 0
        if giorni >= aging_days:
            # dedup per PR: conta l'attesa VERA (la riga più vecchia), non ogni run del gate
            chiave = (r["repo"], r["pr"])
            if chiave not in s["aging_pr"] or giorni > s["aging_pr"][chiave][0]:
                s["aging_pr"][chiave] = (giorni, r["data"], r["banco"])

print(f"== Gate summary — {oggi} ({len(rows)} righe, {len(stats)} repo) ==")
for repo, s in sorted(stats.items()):
    pct = lambda n: f"{100*n/s['righe']:.0f}%" if s["righe"] else "—"
    print(f"\n{repo}")
    print(f"  verifiche ok: {s['ver_ok']}/{s['righe']} ({pct(s['ver_ok'])}) · smentite banco: {s['smentite']} ({pct(s['smentite'])})")
    print(f"  esiti umani: {s['merge']} merge · {s['chiusure']} chiusure · {s['commesse']} commesse correttive", end="")
    if s["eseguiti"]:
        print(f" · banco: {s['eseguiti']} eseguiti ({s['scarti']} scartati dall'allowlist = {100*s['scarti']/s['eseguiti']:.0f}% di rigore)", end="")
    if s["commesse"] >= 2:
        print("  ⚠ AREA FRAGILE: commesse correttive ripetute", end="")
    print()
    if s["aging_pr"]:
        print(f"  ⏳ aging (senza esito umano da {aging_days}+ giorni):")
        for (repo, pr), (giorni, data, banco) in sorted(s["aging_pr"].items(), key=lambda kv: -kv[1][0]):
            print(f"     - {pr} da {data} ({giorni}g, ultimo banco {banco})")
PY
