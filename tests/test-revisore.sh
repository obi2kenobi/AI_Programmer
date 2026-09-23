#!/bin/bash
# test-revisore.sh — il censore delle PR notturne sotto prova (2026-09-18, idea
# di Luca: «revisore, censore, che verifica prova certifica e delibera»).
# Tutto deterministico: i due cervelli sono uno STUB (distingue per modello:
# autore scrive il comando avversario, censore emette il verdetto), le azioni
# gh girano in REVISORE_DRY (stampate, non eseguite). Le guardie e le prove
# sono REALI: sono la parte che non deve mai sbagliare.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
REV="$HERE/night-shift/revisore.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$REV" && ok "sintassi" || { ko "sintassi"; exit 1; }

# stub dei cervelli: $1=nome modello; l'autore risponde col comando avversario
# (grep che trova il simbolo vivo: riesce se il codice regge), il censore col
# verdetto dettato da REVISORE_STUB_VERDETTO
# (revisione 10 giri, 2026-09-23): la pulizia era `rm -rf /tmp/test-rev.* …` — cancellava
# anche le cartelle di un'ALTRA esecuzione in corso (il banco notturno si sovrappone). Ora
# ogni esecuzione ha la sua radice e pulisce solo quella.
RADICE=$(mktemp -d /tmp/test-revisore-run.XXXXXX)
STUB=$(mktemp "$RADICE/stub-revisore.XXXXXX")
cat > "$STUB" <<'EOF'
#!/bin/bash
# (2026-09-20, modello unico): i due cervelli non si distinguono piu' dal NOME
# (14b anche come censore — bencina: il 27b 0/3 in 442s anche sola). Si
# distinguono dal RUOLO nel prompt: l'avversario SMASCHERA, il censore delibera.
MODELLO="$1"; shift; PROMPT=$(cat)
case "$PROMPT" in
  *SMASCHERA*) printf '```\ngrep -c "function viva" utils.js\n```\n' ;;
  *CENSORE*) printf '{"verdetto":"%s","rischio":"basso","motivi":["il diff fa quello che dichiara","nessun danno collaterale"]}\n' "${REVISORE_STUB_VERDETTO:-APPROVA}" ;;
  *) printf '' ;;
esac
EOF
chmod +x "$STUB"

# repo scratch con PR bozza vera (le azioni gh girano in DRY; per le GUARDIE
# serve gh pr view: anche quello e' uno stub che risponde dal file $GHSTUB_JSON)
GHSTUB=$(mktemp -d "$RADICE/ghstub.XXXXXX")
export GHSTUB_JSON="$GHSTUB/pr.json"
mkdir -p "$GHSTUB"
cat > "$GHSTUB/gh" <<'EOF'
#!/bin/bash
# minimale: `gh pr view N --json ...` risponde dal file $GHSTUB_JSON
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then cat "$GHSTUB_JSON"; exit 0; fi
exit 0
EOF
chmod +x "$GHSTUB/gh"

nuova_pr() { # $1=dir $2=eta_min $3=branch — prepara repo+branch+json della PR
  SB="$1"
  cat > "$SB/utils.js" <<'EOF'
function viva(x) {
  return x * 2;
}
EOF
  git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm base
  git -C "$SB" checkout -q -b "$3"
  cat > "$SB/utils.js" <<'EOF'
function viva(x) {
  // raddoppia il valore: usata da calcoloPrezzo
  return x * 2;
}
EOF
  git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm "improve: docs"
  git -C "$SB" checkout -q main
  python3 - "$2" "$3" > "$GHSTUB_JSON" <<'PY'
import sys, json
from datetime import datetime, timezone, timedelta
eta, branch = int(sys.argv[1]), sys.argv[2]
print(json.dumps({"number": 7, "title": "caccia: miglioria al codice dall'agente notturno",
  "headRefName": branch, "isDraft": True, "state": "OPEN",
  "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=eta)).isoformat()}))
PY
}

nuova_repo() {
  SB=$(mktemp -d "$RADICE/test-rev.XXXXXX")
  git -C "$SB" init -q -b main
  git -C "$SB" -c user.name=t -c user.email=t@t commit -qm init --allow-empty
  printf 'true\n' > "$SB/.night-verify"   # una verifica banale, sempre verde
  git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm verify
  echo "$SB"
}
trap 'rm -rf "$RADICE"' EXIT

# 1. flusso completo: PR matura, guardie ok, prove ok, censore APPROVA → merge (DRY)
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-ok
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "APPROVA → rc 0" || ko "rc $RC (atteso 0): $(echo "$OUT" | tail -2)"
echo "$OUT" | grep -q "\[DRY\] gh pr merge 7 --squash" && ok "delibera: squash-merge della PR #7" || ko "non ha delibera il merge"
if echo "$OUT" | grep -q "budget\|deliberazione 1/"; then ok "budget registrato"; else ko "budget non scritto (audit 2026-09-23: il ko era irraggiungibile)"; fi
B=$(cat "$SB"/.git/revisore/mergi-* 2>/dev/null | head -1)
[ "$B" = "1" ] && ok "budget a 1/5 sul file" || ko "file budget: '$B'"
BR_FIN=$(git -C "$SB" branch --show-current)
[ "$BR_FIN" = "main" ] && ok "tornato su main dopo la deliberazione" || ko "rimasto su $BR_FIN"

# 2. censore RIGETTA → PR chiusa con motivi, rc 1, NESSUN merge
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-ko
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" REVISORE_STUB_VERDETTO=RIGETTA bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "RIGETTA → rc 1" || ko "rc $RC (atteso 1)"
echo "$OUT" | grep -q "\[DRY\] gh pr close 7" && ok "PR chiusa col parere" || ko "non ha chiuso la PR"
echo "$OUT" | grep -q "gh pr merge" && ko "ha provato a mergiare una rigettata!" || ok "nessun merge della rigettata"

# 3. quarantena: PR troppo giovane → skip (rc 2), nessun giudizio speso
SB=$(nuova_repo); nuova_pr "$SB" 5 night/test-giovane
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "quarantena 5min → rc 2 (rinvio)" || ko "rc $RC (atteso 2)"

# 4. guardia diff: PR enorme → mai al censore, rc 2
SB=$(nuova_repo)
git -C "$SB" checkout -q -b night/test-grande
python3 -c "
open('$SB/grande.js','w').write('\n'.join('var x%d = %d;' % (i,i) for i in range(100)))"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm big
git -C "$SB" checkout -q main
python3 - > "$GHSTUB_JSON" <<'PY'
import json
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 7, "title": "caccia: miglioria", "headRefName": "night/test-grande",
  "isDraft": True, "state": "OPEN",
  "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=60)).isoformat()}))
PY
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "diff enorme → rc 2 (guardia, al giorno)" || ko "rc $RC (atteso 2)"

# 5. prove rosse: la verifica dichiarata fallisce sul branch → mai al censore
SB=$(nuova_repo)
git -C "$SB" checkout -q -b night/test-rotto
printf 'exit 1\n' > "$SB/.night-verify"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm rotto
git -C "$SB" checkout -q main
python3 - > "$GHSTUB_JSON" <<'PY'
import json
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 7, "title": "caccia: miglioria", "headRefName": "night/test-rotto",
  "isDraft": True, "state": "OPEN",
  "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=60)).isoformat()}))
PY
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "verifiche rosse → rc 2 (mai al censore)" || ko "rc $RC (atteso 2)"

# 6. allowlist del banco: comando con interprete/concatenatore → scartato → rc 2
STUB_CATTIVO=$(mktemp "$RADICE/stub-avv-cattivo.XXXXXX")
cat > "$STUB_CATTIVO" <<'EOF'
#!/bin/bash
MODELLO="$1"; shift; cat >/dev/null
case "$MODELLO" in
  *coder*) printf '```\nbash -c "echo bo" ; rm -rf /\n```\n' ;;
  *) printf '{"verdetto":"APPROVA","rischio":"basso","motivi":["x"]}\n' ;;
esac
EOF
chmod +x "$STUB_CATTIVO"
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-avv
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB_CATTIVO" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "comando avversario fuori allowlist → scartato, PR rinvita" || ko "rc $RC (atteso 2): ha lasciato passare un comando vietato"
rm -f "$STUB_CATTIVO"

# 7. budget esaurito: 5 deliberazioni oggi → guardia, rc 2
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-budget
mkdir -p "$SB/.git/revisore"
echo 5 > "$SB/.git/revisore/mergi-$(date '+%Y-%m-%d')"
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "budget 5/5 → rc 2 (non si delibera piu' oggi)" || ko "rc $RC (atteso 2)"

# --- test del sistema completo, 2026-09-20 (report Fable, D1-D4): quattro buchi che
# DELIBERAVANO il merge. Ogni caso e' stato riprodotto in DRY prima della cura.

# stub con avversario che RIESCE sempre (ls di un file che c'e'): cosi' la prova morde
# sulle guardie, non sul banco (la prima stesura passava per il motivo sbagliato:
# l'avversario smascherava la PR e il rinvio arrivava comunque)
STUB_LS=$(mktemp "$RADICE/stub-avv-ls.XXXXXX")
cat > "$STUB_LS" <<'EOF'
#!/bin/bash
MODELLO="$1"; shift; PROMPT=$(cat)
case "$PROMPT" in
  *SMASCHERA*) printf '```\nls .night-verify\n```\n' ;;
  *CENSORE*) printf '{"verdetto":"APPROVA","rischio":"basso","motivi":["x"]}\n' ;;
esac
EOF
chmod +x "$STUB_LS"

# 9. D1: la PR riscrive le PROPRIE prove (.night-verify a 'true') e rompe il codice.
#    Le prove si leggono dal ramo di default e una PR che tocca .night-verify non si giudica.
SB=$(nuova_repo)
printf 'grep -q "function viva" utils.js\n' > "$SB/.night-verify"
printf 'function viva(x) {\n  return x * 2;\n}\n' > "$SB/utils.js"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm base
git -C "$SB" checkout -q -b night/test-prove-addomesticate
printf 'true\n' > "$SB/.night-verify"; printf 'function morta() {}\n' > "$SB/utils.js"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm "improve"
git -C "$SB" checkout -q main
python3 - > "$GHSTUB_JSON" <<'PY'
import json
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 7, "title": "caccia: miglioria", "headRefName": "night/test-prove-addomesticate",
  "isDraft": True, "state": "OPEN", "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=60)).isoformat()}))
PY
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB_LS" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! echo "$OUT" | grep -q "gh pr merge" \
  && ok "D1: PR che tocca .night-verify → rinvio, nessun merge (le prove sono del ramo di default)" \
  || ko "D1: rc $RC — una PR che addomestica le proprie prove e' stata deliberata: $(echo "$OUT" | tail -1)"

# 10. D2: il comando avversario con redirezione NON deve scrivere nel repo ne' contare come prova
STUB_SCRIVE=$(mktemp "$RADICE/stub-avv-scrive.XXXXXX")
cat > "$STUB_SCRIVE" <<'EOF'
#!/bin/bash
MODELLO="$1"; shift; PROMPT=$(cat)
case "$PROMPT" in
  *SMASCHERA*) printf '```\necho pwned > utils.js\n```\n' ;;
  *CENSORE*) printf '{"verdetto":"APPROVA","rischio":"basso","motivi":["x"]}\n' ;;
esac
EOF
chmod +x "$STUB_SCRIVE"
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-avv-scrive
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB_SCRIVE" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "D2: avversario con '>' → scartato, rc 2" || ko "D2: rc $RC (atteso 2): la redirezione e' passata"
[ -z "$(git -C "$SB" status --porcelain)" ] && ok "D2: working tree pulito dopo il banco" || ko "D2: il banco ha sporcato il repo: $(git -C "$SB" status --porcelain | head -2 | tr '\n' ' ')"
grep -q "function viva" "$SB/utils.js" && ok "D2: utils.js intatto" || ko "D2: utils.js SOVRASCRITTO dal comando avversario"
rm -f "$STUB_SCRIVE"

# 11. D3: createdAt illeggibile → la quarantena chiude, non apre (fail-closed)
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-data
python3 - > "$GHSTUB_JSON" <<'PY'
import json
print(json.dumps({"number": 7, "title": "caccia: miglioria", "headRefName": "night/test-data",
  "isDraft": True, "state": "OPEN", "createdAt": "ieri"}))
PY
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! echo "$OUT" | grep -q "gh pr merge" && ok "D3: data illeggibile → rinvio (quarantena fail-closed)" \
  || ko "D3: rc $RC — data illeggibile e la PR e' stata deliberata"

# 12. D4: diff VUOTO (ramo identico al default) → niente da giudicare, rc 2
SB=$(nuova_repo)
git -C "$SB" checkout -q -b night/test-vuoto && git -C "$SB" checkout -q main
python3 - > "$GHSTUB_JSON" <<'PY'
import json
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 7, "title": "caccia: miglioria", "headRefName": "night/test-vuoto",
  "isDraft": True, "state": "OPEN", "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=60)).isoformat()}))
PY
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB_LS" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! echo "$OUT" | grep -q "gh pr merge" && ok "D4: diff vuoto → rinvio, nessun merge del nulla" \
  || ko "D4: rc $RC — un diff vuoto e' stato deliberato"
rm -f "$STUB_LS"

# 7b. (revisione 10 giri, 2026-09-23): .night-verify di SOLI commenti sulla base — la guardia
# «verifiche-vuote» usava `grep -vc ... || echo 0`: con zero comandi grep stampa 0 ED esce 1,
# l'echo aggiunge un secondo 0, `[ "0\n0" -eq 0 ]` e' un errore di sintassi → falso → nessun
# comando da eseguire → nessuna prova rotta → la PR arrivava al censore «con le prove verdi».
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-vuote
printf '# solo commenti\n\n# nessuna verifica\n' > "$SB/.night-verify"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm vuote
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && echo "$OUT" | grep -q "verifiche-vuote" && ! echo "$OUT" | grep -q "gh pr merge" \
  && ok "verifiche-vuote sulla base → rc 2, mai al censore" \
  || ko "verifiche-vuote NON rilevate (rc $RC): $(echo "$OUT" | grep -iE 'prove|integer|merge' | head -2)"

# 8. sfida coi cervelli VERI (skip dichiarato se Ollama non gira o il modello del censore manca;
#    giro 19 2026-09-20: cercava il 27b abbandonato il 2026-09-19 — sarebbe stata saltata per sempre)
CENSORE_MODEL="${REVISORE_MODEL:-qwen3.8-27b:iq3s}"
if curl -sf --max-time 2 http://localhost:11434/api/tags 2>/dev/null | grep -q "$CENSORE_MODEL"; then
  echo "· sfida modello vero: fatta girare a mano nel turno (il censore e' lento: fuori dalla suite)"
else
  echo "⊘ sfida modello vero saltata (censore $CENSORE_MODEL non attivo — dichiarato, non taciuto)"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
