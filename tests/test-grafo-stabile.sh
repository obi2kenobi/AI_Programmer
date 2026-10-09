#!/bin/bash
# test-grafo-stabile.sh — il grafo con ordine CANONICO: il rebuild non riscrive
# più il file intero, e GitHub (che non esegue i merge-driver locali) fonde da
# solo due PR che toccano file lontani tra loro.
# Nato da «occhio ai conflitti in pr» (Luca, 2026-10-09): #262/#263 confliggevano
# SOLO lato GitHub — il driver locale (spina punto 3) univa tutto nei cloni, ma
# l'ordine dei nodi non era stabile e ogni commit portava un rewrite completo.
# Contratto ONESTO: il caso comune fonde da solo; il caso peggiore (inserimenti
# sullo stesso ancòra) confligge — fisiologico nei vettori JSON con merge a
# righe — e la cura è UN comando: un lato qualsiasi + la spina rigenera.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SPINA="$HERE/tools/graphify-spina.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$SPINA" && ok "sintassi spina" || { ko "sintassi spina"; exit 1; }
command -v graphify >/dev/null 2>&1 || { echo "SKIP: graphify non installato — banco dichiarato saltato"; exit 0; }

SB=$(mktemp -d /tmp/test-grafo.XXXXXX)
trap 'rm -rf "$SB"' EXIT

# ── fixture: repo con codice, spina viva ─────────────────────────────────────
R="$SB/repo"; mkdir -p "$R"
git -C "$R" init -q -b main
git -C "$R" -c user.name=t -c user.email=t@t commit -qm init --allow-empty
printf 'def funzione_alfa(x):\n    return x + 1\n' > "$R/alfa.py"
printf 'def funzione_beta(y):\n    return y * 2\n' > "$R/beta.py"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm codice
bash "$SPINA" "$R" --stage >/dev/null 2>&1
git -C "$R" -c user.name=t -c user.email=t@t commit -qm grafo -q
[ -s "$R/graphify-out/graph.json" ] && ok "spina: grafo costruito nella fixture" || { ko "spina: grafo costruito nella fixture"; exit 1; }

# ── l'ordine e' canonico: i nodi escono ordinati per id ──────────────────────
if python3 - "$R/graphify-out/graph.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
ids = [str(n.get("id", "")) for n in d.get("nodes", [])]
sys.exit(0 if ids == sorted(ids) else 1)
PY
then ok "canonico: i nodi sono ordinati per id (il diff di un rebuild e' localizzato)"
else ko "canonico: i nodi sono ordinati per id"; fi

# ── determinismo: stesse sorgenti → stessi byte (rebuild due volte) ──────────
H1=$(shasum "$R/graphify-out/graph.json" | cut -d' ' -f1)
bash "$SPINA" "$R" >/dev/null 2>&1
H2=$(shasum "$R/graphify-out/graph.json" | cut -d' ' -f1)
[ "$H1" = "$H2" ] && ok "determinismo: rebuild a sorgenti ferme = stessi byte" || ko "determinismo: rebuild a sorgenti ferme = stessi byte ($H1 vs $H2)"

# ── IL banco del conflitto GitHub, CASO COMUNE: due rami, file lontani ───────
# (GitHub non esegue merge-driver locali: si simula la sua fusione togliendo la
# config). Con l'ordine canonico i diff restano localizzati: inserimenti in
# posizioni DIVERSE si fondono da soli — il caso normale di due PR vere.
git -C "$R" checkout -q -b ramo-a
printf 'def funzione_a1(z):\n    return z - 1\n' > "$R/a1.py"
git -C "$R" add -A && bash "$SPINA" "$R" --stage >/dev/null 2>&1 && git -C "$R" -c user.name=t -c user.email=t@t commit -qm aggiunge-a1 -q
git -C "$R" checkout -q main
git -C "$R" checkout -q -b ramo-b
printf 'def funzione_z9(w):\n    return w / 2\n' > "$R/z9.py"
git -C "$R" add -A && bash "$SPINA" "$R" --stage >/dev/null 2>&1 && git -C "$R" -c user.name=t -c user.email=t@t commit -qm aggiunge-z9 -q
git -C "$R" checkout -q ramo-a
git -C "$R" config --unset merge.graphify.driver 2>/dev/null || true   # niente driver: come GitHub
git -C "$R" config --unset merge.graphify.name 2>/dev/null || true
if git -C "$R" merge --no-edit ramo-b >/dev/null 2>&1; then
  ok "GitHub-simulato (caso comune): due PR con file lontani si FONDONO da sole"
else
  ko "GitHub-simulato (caso comune): due PR con file lontani si FONDONO da sole"
fi
if python3 - "$R/graphify-out/graph.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
ids = [str(n.get("id", "")) for n in d.get("nodes", [])]
sys.exit(0 if ids == sorted(ids) else 1)
PY
then ok "il grafo fuso e' JSON valido e canonico"
else ko "il grafo fuso e' JSON valido e canonico"; fi

# ── CASO PEGGIORE dichiarato: inserimenti sullo STESSO ancore (id adiacenti) ──
git -C "$R" checkout -q main
git -C "$R" checkout -q -b vicino-a
printf 'def v1(z):\n    return z - 1\n' > "$R/m1.py"
git -C "$R" add -A && bash "$SPINA" "$R" --stage >/dev/null 2>&1 && git -C "$R" -c user.name=t -c user.email=t@t commit -qm aggiunge-m1 -q
git -C "$R" checkout -q main
git -C "$R" checkout -q -b vicino-b
printf 'def v2(w):\n    return w / 2\n' > "$R/m2.py"
git -C "$R" add -A && bash "$SPINA" "$R" --stage >/dev/null 2>&1 && git -C "$R" -c user.name=t -c user.email=t@t commit -qm aggiunge-m2 -q
git -C "$R" checkout -q vicino-a
git -C "$R" config --unset merge.graphify.driver 2>/dev/null || true
git -C "$R" config --unset merge.graphify.name 2>/dev/null || true
git -C "$R" merge --no-edit vicino-b >/dev/null 2>&1   # conflitto o no: la cura e' sotto
git -C "$R" checkout --ours graphify-out/graph.json 2>/dev/null || true
bash "$SPINA" "$R" >/dev/null 2>&1
if python3 - "$R/graphify-out/graph.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
ids = [str(n.get("id", "")) for n in d.get("nodes", [])]
files = {str(n.get("source_file", "")) for n in d.get("nodes", [])}
sys.exit(0 if ids == sorted(ids) and "m1.py" in files and "m2.py" in files else 1)
PY
then ok "caso peggiore: un lato + spina = grafo valido, canonico, CON ENTRAMBI i nodi (cura di un comando)"
else ko "caso peggiore: un lato + spina = grafo valido con entrambi i nodi"; fi

# ── config MEZZA registrata (name senza driver) = git FATAL rc=128: la spina ripara ──
git -C "$R" config --unset merge.graphify.driver 2>/dev/null || true
bash "$SPINA" "$R" >/dev/null 2>&1
[ -n "$(git -C "$R" config --get merge.graphify.driver)" ] && ok "spina auto-ripara la config del driver (il fatal rc=128 non resta)" || ko "spina auto-ripara la config del driver"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
