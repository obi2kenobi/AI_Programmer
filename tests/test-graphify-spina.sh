#!/bin/bash
# test-graphify-spina.sh — graphify e' la SPINA DORSALE dell'hub e di ogni repo installata
# (decisione di Luca, D1 2026-09-23: «il graphify deve essere il teletrasporto per trovare tutti
# i dati, e quando installi ai_programmer in un repo graphify deve essere la spina dorsale anche
# del nuovo repo»; scelte: grafo VERSIONATO col merge-driver di graphify, semantica LA NOTTE con
# Ollama).
#
# Prima: graphify-out/ era gitignored (ogni clone partiva senza grafo), la skill viveva solo in
# .opencode (Claude Code non la vedeva) e nessuno dei quattro installatori portava il grafo.
# Ora: tools/graphify-spina.sh e' un hook SessionStart — viaggia da solo con copia-hook --elenco
# in sync-repo, onboard-repo, bootstrap-app e garante-standard — e il pre-commit lo rilancia
# con --stage, cosi' la copia versionata segue ogni commit.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
SPINA="$HERE/tools/graphify-spina.sh"
g() { git -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null "$@"; }

# 1. il grafo dell'hub e' versionato, con le sue regole nella sua cartella
git -C "$HERE" ls-files --error-unmatch graphify-out/graph.json >/dev/null 2>&1 \
  && ok "graphify-out/graph.json e' tracciato in git" || ko "graphify-out/graph.json non e' tracciato"
grep -qx 'graph.json merge=graphify linguist-generated=true' "$HERE/graphify-out/.gitattributes" 2>/dev/null \
  && ok "graphify-out/.gitattributes: merge=graphify (unione dei grafi) e diff compresso nelle PR" \
  || ko "graphify-out/.gitattributes assente o senza merge=graphify"
# (2026-09-24, quinto ventaglio, R5 R4): il driver vive in .git/config, e lo registra la spina alla SessionStart.
# Un clone nuovo o il merge dal bottone di GitHub non lo conoscono: graph.json va in conflitto (provato dal giro
# senza driver: rc 1). La PR notturna del grafo prometteva «il merge unisce i grafi» senza dire dove.
grep -c 'non dal bottone' "$HERE/tools/grafo-semantico.sh" >/dev/null && ok "R5 R4: la PR del grafo dice dove il merge unisce davvero i grafi" \
  || ko "R5 R4: la PR del grafo promette l'unione senza dire che vale solo dove la spina ha registrato il driver"
git -C "$HERE" check-ignore -q graphify-out/cache/x && git -C "$HERE" check-ignore -q graphify-out/graph.html \
  && ! git -C "$HERE" check-ignore -q graphify-out/graph.json \
  && ok "cache e graph.html restano locali, graph.json no" || ko "regole di ignore del grafo sbagliate"

# 2. la skill vive anche dove Claude Code la vede — nella SUA variante (2026-09-24, V3#2: qui si pretendeva
# l'identita' con lo specchio OpenCode, che dispatcha con @agent; il confronto per variante e' in
# tests/test-opencode-skills-sync.sh)
[ -f "$HERE/.claude/skills/graphify/SKILL.md" ] && ! grep -c '@agent Chunk' "$HERE/.claude/skills/graphify/SKILL.md" >/dev/null \
  && diff -rq "$HERE/.opencode/skills/graphify/references" "$HERE/.claude/skills/graphify/references" >/dev/null 2>&1 \
  && ok ".claude/skills/graphify c'e', nella variante per Claude, coi references dello specchio" || ko "skill graphify assente in .claude/skills, o nella variante OpenCode"

# 3. la spina viaggia: e' un hook dichiarato, quindi copia-hook --elenco la porta ovunque
bash "$HERE/tools/copia-hook.sh" --elenco | grep -xc 'tools/graphify-spina.sh' >/dev/null \
  && ok "graphify-spina.sh e' nell'elenco degli hook (lo copiano i quattro installatori)" \
  || ko "graphify-spina.sh non e' un hook dichiarato: non raggiunge le repo installate"
grep -q 'graphify-spina.sh" .*--stage' "$HERE/tools/pre-commit.sh" \
  && ok "il pre-commit rilancia la spina con --stage" || ko "il pre-commit non aggiorna il grafo versionato"

# 4. senza graphify: esce 0 e lo DICHIARA (mai bloccare, mai tacere)
mkdir -p "$T/nog" && g -C "$T/nog" init -q
OUT=$(cd "$T/nog" && PATH=/usr/bin:/bin bash "$SPINA" "$T/nog" 2>&1); RC=$?
[ $RC -eq 0 ] && grep -q "DEGRADATO" <<<"$OUT" \
  && ok "graphify assente: esce 0 e dichiara DEGRADATO" || ko "graphify assente: rc=$RC, uscita '$OUT'"

# 5-7. con graphify: costruisce, registra il merge-driver, mette in stage, e il merge UNISCE
if command -v graphify >/dev/null 2>&1; then
  R="$T/r"; mkdir -p "$R" && g -C "$R" init -q -b main
  printf 'def base():\n    pass\n' > "$R/a.py" && g -C "$R" add a.py && g -C "$R" commit -qm init
  OUT=$(bash "$SPINA" "$R" --stage 2>&1)
  [ -s "$R/graphify-out/graph.json" ] && g -C "$R" diff --cached --name-only | grep -xc 'graphify-out/graph.json' >/dev/null \
    && ok "spina --stage: grafo costruito e messo in stage" || ko "spina --stage non ha costruito/staged il grafo: $OUT"
  g -C "$R" config --get merge.graphify.driver | grep -c 'merge-driver %O %A %B' >/dev/null \
    && ok "merge-driver di graphify registrato nella config della repo" || ko "merge-driver non registrato"
  g -C "$R" diff --cached --name-only | grep -xc 'graphify-out/cache/stat-index.json' >/dev/null \
    && ko "la cache del grafo e' finita in stage" || ok "la cache resta fuori dallo stage"
  g -C "$R" commit -qm grafo
  g -C "$R" checkout -q -b ramo
  printf 'def solo_ramo():\n    pass\n' > "$R/b.py" && g -C "$R" add b.py && bash "$SPINA" "$R" --stage >/dev/null 2>&1 && g -C "$R" commit -qm ramo
  g -C "$R" checkout -q main
  printf 'def solo_main():\n    pass\n' > "$R/c.py" && g -C "$R" add c.py && bash "$SPINA" "$R" --stage >/dev/null 2>&1 && g -C "$R" commit -qm main
  g -C "$R" merge -q --no-edit ramo >/dev/null 2>&1
  N=$(grep -cE '"label": "solo_(ramo|main)\(\)"' "$R/graphify-out/graph.json" 2>/dev/null); N=${N:-0}
  [ -z "$(g -C "$R" diff --name-only --diff-filter=U)" ] && [ "$N" -eq 2 ] \
    && ok "merge di due rami: nessun conflitto, il grafo contiene i nodi di entrambi" \
    || ko "merge del grafo: conflitti o nodi persi ($N nodi su 2)"
else
  echo "SALTO 5-7: graphify non installato qui (pip install graphifyy) — dichiarato, non verde"
fi

# 8. la notte: una volta al giorno, in background, lo strumento semantico con Ollama
NS="$HERE/night-shift/night-shift.sh"
grep -q 'grafo-semantico.sh' "$NS" && grep -q '\.grafo-\$(date +%F)' "$NS" \
  && ok "il turno lancia grafo-semantico.sh una volta al giorno" || ko "il turno non lancia la semantica del grafo"
grep -q -- '--backend ollama' "$HERE/tools/grafo-semantico.sh" 2>/dev/null && grep -q -- '--max-concurrency 1' "$HERE/tools/grafo-semantico.sh" \
  && ok "grafo-semantico: backend ollama, una richiesta alla volta" || ko "grafo-semantico non usa ollama a concorrenza 1"

# 9. grafo-semantico con doppi: grafo cambiato -> ramo night/, commit, PR bozza; invariato -> niente
B="$T/origin.git"; W="$T/w"; S="$T/stub"; mkdir -p "$S" "$W"
g init -q --bare -b main "$B"; g clone -q "$B" "$T/seed" 2>/dev/null
mkdir -p "$T/seed/graphify-out" && echo '{"nodes":[]}' > "$T/seed/graphify-out/graph.json"
g -C "$T/seed" add . && g -C "$T/seed" commit -qm seed && g -C "$T/seed" push -q origin main 2>/dev/null
cat > "$S/gh" <<EOF
#!/bin/bash
[ "\$1 \$2" = "repo clone" ] && exec git clone -q "$B" "\$4"
[ "\$1 \$2" = "pr create" ] && { echo "\$*" >> "$T/pr.log"; echo https://example.invalid/pr/1; exit 0; }
exit 1
EOF
cat > "$S/graphify" <<EOF
#!/bin/bash
echo "\$*" >> "$T/graphify.log"
[ "\$1" = "extract" ] && echo "\${GRAFO_FINTO:-{\"nodes\":[]}}" > graphify-out/graph.json
exit 0
EOF
chmod +x "$S/gh" "$S/graphify"
GS() { PATH="$S:$PATH" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
  MODELLO=modello-prova bash "$HERE/tools/grafo-semantico.sh" own/repo "$W" 2>&1; }
OUT=$(GRAFO_FINTO='{"nodes":[{"id":"semantico"}]}' GS); RC=$?
[ $RC -eq 0 ] && grep -q -- '--draft' "$T/pr.log" 2>/dev/null && g -C "$B" branch --list 'night/grafo-*' | grep -c night/grafo- >/dev/null \
  && ok "grafo cambiato: ramo night/grafo-* spinto e PR in bozza" || ko "grafo cambiato ma niente ramo/PR (rc=$RC): $OUT"
grep -q -- '--model modello-prova' "$T/graphify.log" 2>/dev/null \
  && ok "il modello e' quello del turno (MODELLO)" || ko "il modello del turno non arriva a graphify"
# il giorno fonde la PR (main = il ramo notte), la notte dopo il grafo e' lo stesso: niente PR
NB=$(g -C "$B" branch --list 'night/grafo-*' | tr -d ' *')
rm -f "$T/pr.log"; g -C "$B" update-ref refs/heads/main "refs/heads/$NB" && g -C "$B" branch -D "$NB" >/dev/null 2>&1
OUT=$(GRAFO_FINTO='{"nodes":[{"id":"semantico"}]}' GS); RC=$?
[ $RC -eq 0 ] && [ ! -f "$T/pr.log" ] && grep -q "invariato" <<<"$OUT" \
  && ok "grafo invariato: nessuna PR, e lo dice" || ko "grafo invariato ma PR aperta o silenzio (rc=$RC): $OUT"

# 10. (2026-09-24, quarto ventaglio, Q4): il grafo non vede le chiamate dentro "$(f …)", <(f) e trap '…' —
# `graphify affected lente_pr` (la lente di sicurezza D2, chiamata due volte dal turno) risponde «No affected
# nodes found», e chi applica «no dead code» la toglierebbe. Le regole che l'agente legge (AGENTS.md) e la
# riga che la spina stampa a ogni avvio dicono il limite e la forma giusta per «chi usa X».
A=$(cat "$HERE/AGENTS.md")
grep -c 'graphify affected' <<<"$A" >/dev/null && grep -c 'grep -rn' <<<"$A" >/dev/null \
  && ok "AGENTS.md insegna affected per «chi usa X» e la conferma con grep (siti invisibili al grafo)" \
  || ko "AGENTS.md non dice il limite del grafo sui chiamanti"
grep -c 'affected' "$SPINA" >/dev/null && ok "la riga d'avvio della spina nomina affected e il limite" \
  || ko "la spina all'avvio insegna solo query"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
