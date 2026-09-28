#!/bin/bash
# test-percorso-spazio.sh — domanda 14 di Luca (2026-09-26): «sì, ci sono percorsi con lo spazio sul Mac».
# Il giro S3 (docs/giri/2026-09-24-sesto/grezzi/S3.md, rilievo 2) aveva trovato che da un hub sotto
# «Il mio disco» il turno non partiva e il garante non girava, mentre gli installatori dicevano ✓.
# Le cure c'erano, ma i banchi cercavano il percorso nel TESTO. Qui si installa da una copia
# dell'hub in un percorso con lo spazio, e poi si ESEGUE cio' che e' stato installato:
#   - gli argomenti di ogni plist, come li passerebbe launchd;
#   - il comando del gancio del garante, come lo passerebbe la shell dei ganci;
#   - i comandi in ~/.local/bin.
# Il turno, il digest e il garante nella copia sono sostituiti da finti che dicono «partito»:
# si prova che il percorso arriva intero, non si fa girare la notte.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

HUB="$T/Il mio disco/hub AI"
CASA="$T/casa finta"
echo "Passo 1: copio night-shift, llm, tools e .githooks dell'albero di lavoro in «${HUB}»"
mkdir -p "$HUB" "$CASA/bin" "$CASA/Library/LaunchAgents"
(cd "$HERE" && tar -cf - night-shift llm tools .githooks) | (cd "$HUB" && tar -xf -)
for f in night-shift/night-shift.sh night-shift/morning-digest.sh tools/garante-standard.sh; do
  # MODEL_TAG resta nel finto del turno: install.sh lo legge da li' (night-shift/install.sh:29)
  printf '#!/bin/bash\nMODEL_TAG="finto"\necho "PARTITO %s argomenti=$#"\n' "$f" > "$HUB/$f"; chmod +x "$HUB/$f"
done
printf '#!/bin/bash\nexit 0\n' > "$CASA/bin/launchctl"; chmod +x "$CASA/bin/launchctl"
# caffeinate esiste solo sul Mac: il finto toglie «-i» ed esegue il resto, come fa quello vero
printf '#!/bin/bash\n[ "$1" = "-i" ] && shift\nexec "$@"\n' > "$CASA/bin/caffeinate"; chmod +x "$CASA/bin/caffeinate"

echo "Passo 2: installo turno e garante da quel percorso, con una HOME finta"
OUT=$(HOME="$CASA" PATH="$CASA/bin:/usr/bin:/bin" bash "$HUB/night-shift/install.sh" 2>&1)
grep -q "Fatto" <<<"$OUT" && ok "install.sh da un percorso con lo spazio arriva in fondo" || ko "install.sh: $(tail -2 <<<"$OUT" | tr '\n' ' ')"
OUTG=$(HOME="$CASA" bash "$HUB/tools/install-garante.sh" 2>&1)
grep -q "Garante installato" <<<"$OUTG" && ok "install-garante.sh da un percorso con lo spazio installa" || ko "install-garante.sh: $OUTG"

echo "Passo 3: eseguo gli argomenti di ogni plist che nomina l'hub, come launchd"
NP=0
for PL in "$CASA/Library/LaunchAgents"/*.plist; do
  [ -e "$PL" ] || continue
  NP=$((NP+1))
  N=$(basename "$PL")
  OUTP=$(PATH="$CASA/bin:/usr/bin:/bin" python3 -c '
import plistlib, subprocess, sys, os
a = plistlib.load(open(sys.argv[1], "rb"))["ProgramArguments"]
if a[0] == "/usr/bin/caffeinate":
    a[0] = os.path.join(sys.argv[2], "caffeinate")
r = subprocess.run(a, capture_output=True, text=True)
print(r.stdout + r.stderr, end="")
sys.exit(r.returncode)' "$PL" "$CASA/bin" 2>&1); RC=$?
  [ "$RC" -eq 0 ] && grep -q "^PARTITO " <<<"$OUTP" && ok "$N: il job parte dal percorso con lo spazio ($(head -1 <<<"$OUTP"))" \
    || ko "$N: il job non parte (rc $RC): $(head -2 <<<"$OUTP" | tr '\n' ' ')"
done
[ "$NP" -ge 2 ] && ok "plist generati: $NP" || ko "plist generati: $NP (attesi turno e digest)"

echo "Passo 4: eseguo il comando del gancio del garante, come la shell dei ganci"
CMD=$(jq -r '.hooks.SessionStart[].hooks[] | select(.command | contains("garante")) | .command' "$CASA/.claude/settings.json" 2>/dev/null)
OUTC=$(bash -c "$CMD" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "^PARTITO tools/garante-standard.sh" <<<"$OUTC" && ok "il gancio del garante parte" || ko "il gancio del garante (rc $RC): $CMD — $OUTC"

echo "Passo 5: eseguo i comandi installati in ~/.local/bin"
OUTN=$("$CASA/.local/bin/night-shift" 2>&1)
grep -q "^PARTITO night-shift/night-shift.sh" <<<"$OUTN" && ok "il comando night-shift installato raggiunge il turno" || ko "night-shift installato: $OUTN"
OUTQ=$(env -u ZHIPUAI_API_KEY "$CASA/.local/bin/ask-glm" ping 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -c "non configurata" <<<"$OUTQ" >/dev/null && ok "ask-glm installato gira dal percorso con lo spazio (rc 2: via non configurata)" \
  || ko "ask-glm installato (rc $RC): $(head -1 <<<"$OUTQ")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
