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
  *"LENTE SICUREZZA"*) printf '{"sicuro":%s,"rilievi":["stub: la lente dice cosi"]}\n' "${REVISORE_STUB_LENTE:-true}" ;;
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
# (2026-09-23, giro A6): come il gh vero, la PR porta il suo commit (headRefOid) — se il caso non lo
# fissa, e' la punta del ramo nominato nel repo corrente
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then
  jq --arg o "$(git rev-parse -q --verify "$(jq -r .headRefName "$GHSTUB_JSON")" 2>/dev/null)" 'if has("headRefOid") then . else . + {headRefOid:$o} end' "$GHSTUB_JSON"; exit 0
fi
if [ "$1" = "issue" ] && [ "$2" = "view" ]; then printf '{"title":"Titolo della issue %s","body":"Documenta il raddoppio."}\n' "$3"; exit 0; fi
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
grep -q "\[DRY\] gh pr merge 7 --squash" <<<"$OUT" && ok "delibera: squash-merge della PR #7" || ko "non ha delibera il merge"
if grep -q "budget\|deliberazione 1/" <<<"$OUT"; then ok "budget registrato"; else ko "budget non scritto (audit 2026-09-23: il ko era irraggiungibile)"; fi
B=$(cat "$SB"/.git/revisore/mergi-* 2>/dev/null | head -1)
[ "$B" = "1" ] && ok "budget a 1/5 sul file" || ko "file budget: '$B'"
BR_FIN=$(git -C "$SB" branch --show-current)
[ "$BR_FIN" = "main" ] && ok "tornato su main dopo la deliberazione" || ko "rimasto su $BR_FIN"

# 2. censore RIGETTA → PR chiusa con motivi, rc 1, NESSUN merge
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-ko
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" REVISORE_STUB_VERDETTO=RIGETTA bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "RIGETTA → rc 1" || ko "rc $RC (atteso 1)"
grep -q "\[DRY\] gh pr close 7" <<<"$OUT" && ok "PR chiusa col parere" || ko "non ha chiuso la PR"
grep -q "gh pr merge" <<<"$OUT" && ko "ha provato a mergiare una rigettata!" || ok "nessun merge della rigettata"

# 2bis. (D2, 2026-09-23) la lente sicurezza trova un rilievo → rc 2 al giorno, NESSUN merge
#       anche col censore pronto ad APPROVARE (un segreto fuso resta nella storia)
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-lente
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" REVISORE_STUB_LENTE=false bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! grep -q "gh pr merge" <<<"$OUT" && grep -q "LENTE SICUREZZA: RILIEVI" <<<"$OUT" \
  && ok "lente sicurezza con rilievi → rc 2, nessun merge" || ko "lente con rilievi: rc $RC — $(echo "$OUT" | tail -1)"

# 2ter. (2026-09-23, giro A6) si giudica il commit DELLA PR, non il ramo locale con lo stesso nome,
#       e la fusione e' legata a quel commit (--match-head-commit): nessuna PR fusa senza giudizio
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-punta
C2=$(git -C "$SB" rev-parse night/test-punta)
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
grep -q "gh pr merge 7 --squash --delete-branch --match-head-commit $C2" <<<"$OUT" \
  && ok "la fusione e' legata al commit giudicato (--match-head-commit)" || ko "fusione non legata al commit giudicato: $(echo "$OUT" | grep 'gh pr merge')"
# il ramo locale e' rimasto INDIETRO (c1) mentre la PR punta a un commit piu' nuovo che rompe le prove
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-vecchio
git -C "$SB" checkout -q night/test-vecchio
printf 'function morta() {}\n' > "$SB/utils.js"   # c2 toglie la funzione viva: l'avversario la smaschera
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm "c2 che rompe"
C2=$(git -C "$SB" rev-parse HEAD); git -C "$SB" reset -q --hard HEAD~1; git -C "$SB" checkout -q main
python3 - "$C2" > "$GHSTUB_JSON" <<'PY'
import sys, json
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 7, "title": "caccia: miglioria", "headRefName": "night/test-vecchio", "headRefOid": sys.argv[1],
  "isDraft": True, "state": "OPEN", "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=60)).isoformat()}))
PY
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! grep -q "gh pr merge" <<<"$OUT" \
  && ok "ramo locale vecchio: si giudica il commit della PR (c2, che rompe) — nessuna fusione" || ko "giudicato il ramo locale vecchio (rc $RC): $(echo "$OUT" | tail -1)"
# il commit della PR non e' leggibile qui: fail-closed
python3 > "$GHSTUB_JSON" <<'PY'
import json
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 7, "title": "caccia: miglioria", "headRefName": "night/test-vecchio", "headRefOid": "0123456789abcdef0123456789abcdef01234567",
  "isDraft": True, "state": "OPEN", "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=60)).isoformat()}))
PY
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -ne 0 ] && [ "$RC" -ne 1 ] && ! grep -q "gh pr merge" <<<"$OUT" \
  && ok "commit della PR sconosciuto: nessun giudizio, nessuna fusione (rc $RC)" || ko "commit sconosciuto: rc $RC"

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
  *"LENTE SICUREZZA"*) printf '{"sicuro":%s,"rilievi":["stub: la lente dice cosi"]}\n' "${REVISORE_STUB_LENTE:-true}" ;;
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
[ "$RC" -eq 2 ] && ! grep -q "gh pr merge" <<<"$OUT" \
  && ok "D1: PR che tocca .night-verify → rinvio, nessun merge (le prove sono del ramo di default)" \
  || ko "D1: rc $RC — una PR che addomestica le proprie prove e' stata deliberata: $(echo "$OUT" | tail -1)"

# 10. D2: il comando avversario con redirezione NON deve scrivere nel repo ne' contare come prova
STUB_SCRIVE=$(mktemp "$RADICE/stub-avv-scrive.XXXXXX")
cat > "$STUB_SCRIVE" <<'EOF'
#!/bin/bash
MODELLO="$1"; shift; PROMPT=$(cat)
case "$PROMPT" in
  *"LENTE SICUREZZA"*) printf '{"sicuro":%s,"rilievi":["stub: la lente dice cosi"]}\n' "${REVISORE_STUB_LENTE:-true}" ;;
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
[ "$RC" -eq 2 ] && ! grep -q "gh pr merge" <<<"$OUT" && ok "D3: data illeggibile → rinvio (quarantena fail-closed)" \
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
[ "$RC" -eq 2 ] && ! grep -q "gh pr merge" <<<"$OUT" && ok "D4: diff vuoto → rinvio, nessun merge del nulla" \
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
[ "$RC" -eq 2 ] && grep -q "verifiche-vuote" <<<"$OUT" && ! grep -q "gh pr merge" <<<"$OUT" \
  && ok "verifiche-vuote sulla base → rc 2, mai al censore" \
  || ko "verifiche-vuote NON rilevate (rc $RC): $(echo "$OUT" | grep -iE 'prove|integer|merge' | head -2)"

# ── (D10, decisione di Luca 2026-09-23: «b») le PR delle ISSUE: il censore le giudica e lascia
#    un PARERE motivato come commento, ma NON FONDE MAI — la fusione resta di Luca. ──────────────
pr_issue() { # pr_issue <dir> <eta_min>: PR night/issue-4 col titolo del solver
  nuova_pr "$1" "$2" night/issue-4
  python3 - "$2" > "$GHSTUB_JSON" <<'PY'
import sys, json
from datetime import datetime, timezone, timedelta
print(json.dumps({"number": 7, "title": "fix: raddoppio documentato (issue 4)", "headRefName": "night/issue-4",
  "isDraft": True, "state": "OPEN", "createdAt": (datetime.now(timezone.utc) - timedelta(minutes=int(sys.argv[1]))).isoformat()}))
PY
}
STUB_PAR=$(mktemp "$RADICE/stub-parere.XXXXXX")
cat > "$STUB_PAR" <<STUBPAR
#!/bin/bash
MODELLO="\$1"; shift; PROMPT=\$(cat)
case "\$PROMPT" in
  *"LENTE SICUREZZA"*) printf '{"sicuro":true,"rilievi":[]}\n' ;;
  *SMASCHERA*) printf '\`\`\`\ngrep -c "function viva" utils.js\n\`\`\`\n' ;;
  *CENSORE*) printf '%s' "\$PROMPT" > "$RADICE/prompt-censore.txt"
             printf '{"verdetto":"%s","rischio":"basso","motivi":["fa quello che chiede la issue"]}\n' "\${REVISORE_STUB_VERDETTO:-APPROVA}" ;;
esac
STUBPAR
chmod +x "$STUB_PAR"
SB=$(nuova_repo); pr_issue "$SB" 30
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB_PAR" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 4 ] && grep -q "\[DRY\] gh pr comment 7" <<<"$OUT" \
  && ok "PR di issue: parere APPROVA → commento motivato, rc 4 (parere dato)" || ko "PR di issue: rc $RC, nessun commento di parere: $(echo "$OUT" | tail -1)"
grep -qE "\[DRY\] gh pr (merge|ready|close)" <<<"$OUT" \
  && ko "PR di issue: il censore ha provato a FONDERE/chiudere — il patto lo vieta" || ok "PR di issue: nessun merge, ready o close (la fusione resta di Luca)"
grep -q "Titolo della issue 4" "$RADICE/prompt-censore.txt" 2>/dev/null \
  && ok "il censore giudica la PR contro il testo della ISSUE (non contro la categoria della caccia)" || ko "il prompt del censore non porta la issue"
[ -n "$(ls "$SB"/.git/revisore/parere-7-* 2>/dev/null)" ] && ok "il parere dato si ricorda per quel commit (non si rifa' a ogni ciclo)" || ko "nessuna traccia del parere dato"
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB_PAR" bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! grep -q "gh pr comment" <<<"$OUT" && ok "stesso commit, secondo passaggio: nessun parere ripetuto" || ko "parere ripetuto sullo stesso commit (rc $RC)"
SB=$(nuova_repo); pr_issue "$SB" 30
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB_PAR" REVISORE_STUB_VERDETTO=RIGETTA bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 4 ] && grep -q "\[DRY\] gh pr comment 7" <<<"$OUT" && ! grep -qE "\[DRY\] gh pr (merge|close)" <<<"$OUT" \
  && ok "parere RIGETTA → commento motivato, la PR resta aperta" || ko "parere RIGETTA: rc $RC o PR chiusa"
SB=$(nuova_repo); pr_issue "$SB" 30
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" REVISORE_STUB_LENTE=false bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -q "\[DRY\] gh pr comment 7" <<<"$OUT" \
  && ok "PR di issue con la lente sicurezza non pulita: parere negativo scritto, niente verdetto del censore" || ko "lente non pulita su PR di issue: rc $RC, nessun commento"
rm -f "$STUB_PAR"

# (D11, Luca 2026-09-23) il limite del censore segue il profilo: con CENSORE_MAX_RIGHE=0 la stessa
# PR (1 riga) che passa col default viene rinviata per taglia — con 0 — la chiave cambia davvero il comportamento
SB=$(nuova_repo); nuova_pr "$SB" 30 night/test-profilo
OUT=$(cd "$SB" && PATH="$GHSTUB:$PATH" REVISORE_DRY=1 REVISORE_STUB="$STUB" CENSORE_MAX_RIGHE=0 bash "$REV" "$SB" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -q "(max 0)" <<<"$OUT" && ! grep -q "gh pr merge" <<<"$OUT" \
  && ok "CENSORE_MAX_RIGHE=0 dal profilo: la PR va al giorno per taglia (il profilo comanda)" || ko "CENSORE_MAX_RIGHE ignorato (rc $RC): $(echo "$OUT" | tail -1)"

# 8. sfida coi cervelli VERI (skip dichiarato se Ollama non gira o il modello del censore manca;
#    giro 19 2026-09-20: cercava il 27b abbandonato il 2026-09-19 — sarebbe stata saltata per sempre)
CENSORE_MODEL="${REVISORE_MODEL:-qwen3.8-27b:iq3s}"
if curl -sf --max-time 2 http://localhost:11434/api/tags 2>/dev/null | grep -c "$CENSORE_MODEL" >/dev/null; then
  echo "· sfida modello vero: fatta girare a mano nel turno (il censore e' lento: fuori dalla suite)"
else
  echo "⊘ sfida modello vero saltata (censore $CENSORE_MODEL non attivo — dichiarato, non taciuto)"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
