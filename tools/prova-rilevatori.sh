#!/bin/bash
# prova-rilevatori.sh — L'ANTIVIRUS DEI RILEVATORI (2026-09-09, mandate di Luca).
# ⚠ QUESTO TOOL SCRIVE: solo dentro un CLONE di quarantena in /tmp (mai nel repo).
#
# Il principio: un rilevatore che mente non si vede dal verdetto — si vede dal CASO NOTO.
# Ogni sonde che conta viene riprovata contro il suo canarino: si pianta il difetto noto
# in un clone del repo, si lancia la batteria DEL CLONE, e il FIND atteso DEVE arrivare.
# Un rilevatore che non morde il suo canarino e' dichiarato ROTTO — anche se oggi e' verde.
# (Nato dopo tre rilevatori miei colti a mentire in un'ora: cwd sbagliata, '.'+path senza
# slash, tabella cercata dove c'era una lista. Tutti e tre: verdicti plausibili, falsi.)
#
# Uso: bash tools/prova-rilevatori.sh [--veloce]   (--veloce: solo il canarino di ogni sonde)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SB=$(mktemp -d /tmp/prova-rilevatori.XXXXXX)
trap 'rm -rf "$SB"' EXIT
git clone -q --local "$HERE" "$SB/hub" 2>/dev/null || { echo "⛔ clone di quarantena fallito"; exit 2; }
H="$SB/hub"
PASS=0; ROTTI=0

prova() { # prova <nome-sonde> <atteso> <descrizione>
  local sonde="$1" atteso="$2" desc="$3"
  OUT=$(bash "$H/tools/giri-ignoranti.sh" 2>/dev/null)
  if echo "$OUT" | grep -q "FIND $sonde"; then
    echo "✓ $sonde morde il suo canarino ($desc)"; PASS=$((PASS+1))
  else
    echo "⛔ $sonde NON morde il suo canarino ($desc) — RILEVATORE ROTTO, il suo verde non vale"
    ROTTI=$((ROTTI+1))
  fi
}

echo "== quarantena: $H =="

# canarino S15 — numero di testa stantito
sed -i.bak 's/Il conto vive/33 pattern finti. Il conto vive/' "$H/.claude/skills/gas-sviluppo/SKILL.md"
prova S15 "numero dichiarato" "33 pattern iniettato in SKILL.md"
(cd "$H" && git checkout -q -- .claude/skills/gas-sviluppo/SKILL.md 2>/dev/null || true)

# canarino S16 — indice del SAL fermo
printf '\n### 2099-01-01 — canarino\n' >> "$H/SAL.md"
prova S16 "indice SAL fermo" "voce 2099 senza rigenerazione dell'indice"
(cd "$H" && git checkout -q -- SAL.md 2>/dev/null || true)

# canarino S17 — tool muto
python3 - "$H/tools/sal-indice.sh" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
s = re.sub(r'^\s*print\(.*\)$', '', s, flags=re.M)  # ogni print sparito: davvero muto
open(p, 'w').write(s)
PY
prova S17 "tool senza narrazione" "sal-indice privato di TUTTE le print"

# e il caso pulito: nessun canarino piantato -> la batteria deve essere verde.
# ATTENZIONE (colto dal primo giro dell'antivirus stesso): il clone NON contiene i file
# gitignored (repos.conf, repos.key) che i documenti citano — nel clone risulterebbero
# pendenti e la batteria sarebbe rossa A VUOTO. Si portano in quarantena i due file locali.
cp "$HERE/night-shift/repos.conf" "$H/night-shift/repos.conf" 2>/dev/null || true
cp "$HERE/night-shift/repos.key" "$H/night-shift/repos.key" 2>/dev/null || true
# graphify-out/graph.json: generato da graphify, gitignored, citato da SKILL/CLAUDE —
# in quarantena basta che ESISTA (il controllo e' di esistenza, non di contenuto)
mkdir -p "$H/graphify-out" && echo '{}' > "$H/graphify-out/graph.json"
(cd "$H" && git checkout -q -- . 2>/dev/null || true)
OUT=$(bash "$H/tools/giri-ignoranti.sh" 2>/dev/null)
if echo "$OUT" | tail -1 | grep -q "0 finding"; then
  echo "✓ clone pulito: batteria verde (nessun morso a vuoto)"; PASS=$((PASS+1))
else
  echo "⛔ clone pulito MA batteria rossa: morso a vuoto — $(echo "$OUT" | grep FIND | head -2)"; ROTTI=$((ROTTI+1))
fi

echo ""
echo "$PASS canarini tenuti, $ROTTI rilevatori rotti"
[ "$ROTTI" -eq 0 ]
