#!/bin/bash
# test-pre-commit.sh — il gancio rapido sotto prova, COL SUO METODO: caso
# avverso vero (glifo staged → rosso) e caso pulito. Nato dall'incasso subito
# in prima persona: la prima versione dell'hook diceva OK col glifo staged
# perché il grep BSD di macOS non ha -P e moriva nel silenzio del 2>/dev/null
# — falso verde trovato verificando l'hook esattamente come lui verifica gli
# altri (il tool si prova quando DEVE fallire).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/pre-commit.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# (Q23): il test non deve toccare l'indice dell'hub — si fotografa all'inizio, si confronta alla fine
INDICE_PRIMA=$(git -C "$HERE" diff --cached --name-only 2>/dev/null)

bash -n "$HOOK" && ok "sintassi" || ko "sintassi rotta"
[ -x "$HERE/.githooks/pre-commit" ] && ok "il gancio git esiste ed è eseguibile" || ko ".githooks/pre-commit assente"
grep -qE "git .*grep --cached -lP" "$HOOK" && ok "usa git grep -P (il grep BSD non ha -P: falso verde storico)" || ko "usa grep -P nudo: muore in silenzio su macOS"

# (Q23, 2026-09-23, giro A9 della notte): i casi col gancio giravano nell'INDICE DELL'HUB — il
# gancio verde stage-ava graphify-out/graph.json (spina del grafo) e un file gia' stage-ato da chi
# lavora entrava nel verdetto («niente staged: via libera» rosso per colpa sua). Ora girano in un
# repo di prova col gancio copiato: l'hub non si tocca. I nomi nudi che il caso 2 risolve
# (docs/campo/, tools/) vi si creano vuoti; i casi --commit-msg restano sul gancio vero (contano
# i test dell'hub e non toccano l'indice).
SB=$(mktemp -d)
git -C "$SB" init -q
git -C "$SB" -c user.email=prova@invalid -c user.name=prova commit -q --allow-empty -m inizio   # restore --staged vuole HEAD
mkdir -p "$SB/tools" "$SB/docs/campo"
cp "$HOOK" "$HERE/tools/cita-verifica.sh" "$SB/tools/"
: > "$SB/docs/campo/2026-08-28-repo-l-fix.md"; : > "$SB/tools/indici_crisi.py"
gancio() { ( cd "$SB" && HOME="$SB" bash tools/pre-commit.sh "$@" ); }
trap 'rm -rf "$SB"' EXIT

# (2026-09-24, notte dei giri, T1#3): la CHIAVE della privacy (repos.key: nomi, persone, termini) e la
# lista ~/.privacy-nomi non hanno nessun guardiano al commit — l'hub si affida al .gitignore, e un
# `git add -f`, o la chiave in un altro percorso (in un satellite), la mandava nel commit.
for CHIAVE in night-shift/repos.key altrove/repos.key .privacy-nomi; do
  mkdir -p "$SB/$(dirname "$CHIAVE")"; printf 'TERMINI=finto\n' > "$SB/$CHIAVE"; git -C "$SB" add -f "$CHIAVE"
  OUT=$(gancio); RC=$?
  [ "$RC" -ne 0 ] && grep -c "$CHIAVE" <<<"$OUT" >/dev/null && ok "$CHIAVE in stage: il gancio rifiuta e dice quale" || ko "$CHIAVE in stage e il gancio passa (rc=$RC)"
  git -C "$SB" rm -q --cached "$CHIAVE"; rm -f "$SB/$CHIAVE"
done

# caso avverso: glifo staged → rosso (costruito a runtime, E-007)
PROBE="$SB/docs/_probe_glifo.md"
cleanup() { git -C "$SB" restore --staged "$PROBE" >/dev/null 2>&1; rm -f "$PROBE"; }
GLIFO=$(python3 -c "print(chr(0x81ea))")
printf 'test %s dentro\n' "$GLIFO" > "$PROBE"
git -C "$SB" add "$PROBE"
OUT=$(gancio); RC=$?
[ "$RC" -ne 0 ] && grep -qi "alieni" <<<"$OUT" \
  && ok "glifo staged: l'hook diventa rosso e dice perché" \
  || ko "glifo staged NON visto (rc=$RC) — falso verde"
cleanup

# nomi NUDI col convenzione: un .md staged che cita un report di campo per
# basename NON è pendente (docs/campo/ è una delle radici di risoluzione)
PROBE2="$SB/docs/_probe_menu.md"
printf 'vedi `2026-08-28-repo-l-fix.md` e `indici_crisi.py`\n' > "$PROBE2"
git -C "$SB" add "$PROBE2"
OUT=$(gancio); RC=$?
[ "$RC" -eq 0 ] && ok "nomi nudi risolti contro tools/ e docs/campo/ (convenzioni)"   || { echo "$OUT" | grep pendenti | head -1 | sed 's/^/    /'; ko "convenzione dei nomi nudi non risolta"; }
git -C "$SB" restore --staged "$PROBE2" >/dev/null 2>&1; rm -f "$PROBE2"

# pipeline seguita da && (controllo 5, report REPO-W 5/9: la regola-prosa violata
# 3 volte in una sessione) — il dente deve diventare rosso sul colpevole
PROBE3="$SB/tools/_probe_pipe_and.sh"
# il colpevole si costruisce con %s: il sorgente del test NON contiene il pattern
# (il dente morde anche chi scrive la sonda che lo prova — accaduto, 5/9)
printf '#!/bin/bash\ncmd | tail -1 %s git commit -m x\n' '&&' > "$PROBE3"
chmod +x "$PROBE3"
git -C "$SB" add "$PROBE3"
OUT=$(gancio); RC=$?
[ "$RC" -ne 0 ] && grep -q "pipeline" <<<"$OUT" && ok "pipe+&& staged: il dente morde" \
  || ko "pipe+&& NON visto (rc=$RC) — la regola del 3/9 è ancora sola prosa"
git -C "$SB" restore --staged "$PROBE3" >/dev/null 2>&1; rm -f "$PROBE3"

# e il benigno (|| true, pipe senza &&) non deve scattare
PROBE4="$SB/tools/_probe_pipe_ok.sh"
# (D8, 2026-09-23): anche l'OR logico seguito da && non e' una pipe — il dente scattava su un
# commento di bootstrap-app.sh («[ dry ] || git add -A && …»)
printf '#!/bin/bash\nls | xargs grep -l foo 2>/dev/null || true\ngrep -q x file || exit 1\n[ -n "$x" ] || echo a %s echo b\n' '&&' > "$PROBE4"
git -C "$SB" add "$PROBE4"
OUT=$(gancio); RC=$?
[ "$RC" -eq 0 ] && ok "pipe senza && : via libera (nessun falso positivo)" \
  || { echo "$OUT" | grep pipeline | head -1 | sed 's/^/    /'; ko "falso positivo su pipe legittima"; }
git -C "$SB" restore --staged "$PROBE4" >/dev/null 2>&1; rm -f "$PROBE4"

# (D9, test del sistema completo 2026-09-20): il rilevatore che MUORE deve essere rosso.
# `git grep -P` sotto un locale non-UTF muore con rc 128 («code point too large»); la
# vecchia pipeline lo passava a xargs (che mappa 1 E 128 sullo stesso 123) e poi a un
# `grep -v` finale (che lo faceva diventare 1 = «nessun reperto»): la guardia E-024 non
# poteva scattare MAI, e un commit in cirillico e' passato su una macchina senza
# en_US.UTF-8. Qui il locale C forza la morte del rilevatore: il verdetto deve dirlo.
PROBE5="$SB/docs/_probe_morto.md"
printf 'solo ascii qui\n' > "$PROBE5"
git -C "$SB" add "$PROBE5"
OUT=$(LC_ALL=C LANG=C gancio 2>/dev/null); RC=$?
if git -C "$SB" grep -lP '[\x{4E00}]' -- :docs/_probe_morto.md >/dev/null 2>&1 || [ "$(LC_ALL=C LANG=C git -C "$SB" grep -lP '[\x{4E00}]' -- :docs/_probe_morto.md >/dev/null 2>&1; echo $?)" -lt 2 ]; then
  echo "· D9: su questa macchina git grep -P non muore sotto LC_ALL=C — il caso «morto» non e' forzabile qui (dichiarato)"
else
  [ "$RC" -ne 0 ] && grep -q "MORTO" <<<"$OUT" \
    && ok "D9: rilevatore glifi morto (rc 128) → l'hook e' ROSSO e lo dice" \
    || ko "D9: rilevatore morto e l'hook e' verde (rc=$RC) — falso verde: $(echo "$OUT" | tail -1)"
fi
git -C "$SB" restore --staged "$PROBE5" >/dev/null 2>&1; rm -f "$PROBE5"

# (D10): il numero-test nel messaggio si controlla nel gancio commit-msg (il pre-commit
# di git non conosce il messaggio: il vecchio .githooks/pre-commit passava "" e il
# controllo 4 non girava MAI dall'hook — «test: 999 test verdi» e' passato).
[ -x "$HERE/.githooks/commit-msg" ] && ok "D10: il gancio commit-msg esiste ed e' eseguibile" || ko "D10: .githooks/commit-msg assente"
MSGF=$(mktemp); printf 'test: 999 test verdi\n' > "$MSGF"
OUT=$(bash "$HOOK" --commit-msg "$MSGF" 2>/dev/null); RC=$?
[ "$RC" -ne 0 ] && grep -q "999 test" <<<"$OUT" \
  && ok "D10: messaggio con numero-test sbagliato → rosso dal gancio commit-msg" \
  || ko "D10: «999 test» passa ancora (rc=$RC): $(echo "$OUT" | tail -1)"
printf 'docs: aggiorna il diario\n' > "$MSGF"
OUT=$(bash "$HOOK" --commit-msg "$MSGF" 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "D10: messaggio senza numeri-test → via libera" || ko "D10: falso rosso su messaggio benigno: $OUT"
# (revisione 10 giri, 2026-09-23): «sei file rossi» si poteva scrivere solo in lettere —
# «6 test rossi» veniva letto come il TOTALE della suite. Un conteggio parziale non e' la
# dichiarazione che la guardia difende («N test verdi», il totale).
printf 'fix: 6 test rossi curati, 2 test nuovi\n' > "$MSGF"
OUT=$(bash "$HOOK" --commit-msg "$MSGF" 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "conteggio parziale («6 test rossi», «2 test nuovi») → via libera" || ko "falso rosso su conteggio parziale: $OUT"
N_VERI=$(ls "$HERE"/tests/test-*.sh | wc -l | tr -d ' ')
printf 'fix: suite %s test verdi\n' "$N_VERI" > "$MSGF"
OUT=$(bash "$HOOK" --commit-msg "$MSGF" 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "totale vero («$N_VERI test verdi») → via libera" || ko "falso rosso sul totale vero: $OUT"
rm -f "$MSGF"

# caso pulito: nessun file staged → via libera
OUT=$(gancio); RC=$?
[ "$RC" -eq 0 ] && ok "niente staged: via libera" || { echo "$OUT" | tail -2 | sed 's/^/    /'; ko "rosso a vuoto"; }

# --- Q9 (2026-09-23, giro A2 della notte): il gancio giudicava il WORKING TREE, non l'indice.
#     Il commit porta l'indice: un glifo stage-ato e poi tolto solo dal working tree passava
#     (falso verde), il caso inverso bloccava (falso rosso). E i nomi accentati arrivavano
#     da `git diff --name-only` fra virgolette ottali ("perch\303\251.md"): `[ -f ]` li
#     saltava in silenzio. Si prova in un repo temporaneo: l'indice dell'hub non si tocca.
Q9=$(mktemp -d)
git -C "$Q9" init -q
mkdir -p "$Q9/tools" "$Q9/docs"
cp "$HOOK" "$HERE/tools/cita-verifica.sh" "$Q9/tools/"
q9() { ( cd "$Q9" && HOME="$Q9" bash tools/pre-commit.sh >"$Q9/out" 2>&1 ); echo $?; }
q9_pulisci() { git -C "$Q9" read-tree --empty; rm -rf "$Q9/docs" "$Q9/tools/p.sh"; mkdir -p "$Q9/docs"; }
printf 'test %s dentro\n' "$GLIFO" > "$Q9/docs/a.md"; git -C "$Q9" add docs/a.md
printf 'test pulito\n' > "$Q9/docs/a.md"
[ "$(q9)" -ne 0 ] && grep -qi alieni "$Q9/out" \
  && ok "Q9: glifo nell'INDICE (working tree gia' pulito) → rosso: si giudica cio' che si committa" \
  || ko "Q9: glifo nell'indice non visto perche' il working tree e' pulito — falso verde"
q9_pulisci
printf 'test pulito\n' > "$Q9/docs/b.md"; git -C "$Q9" add docs/b.md
printf 'test %s dentro\n' "$GLIFO" > "$Q9/docs/b.md"
[ "$(q9)" -eq 0 ] && ok "Q9: glifo solo nel working tree (non stage-ato) → verde: non entra nel commit" \
  || ko "Q9: glifo NON stage-ato blocca il commit — falso rosso: $(head -3 "$Q9/out")"
q9_pulisci
printf 'vedi `inesistente-q9.md`\n' > "$Q9/docs/perché.md"; git -C "$Q9" add "docs/perché.md"
[ "$(q9)" -ne 0 ] && grep -q "inesistente-q9.md" "$Q9/out" \
  && ok "Q9: un .md con nome ACCENTATO si controlla (path pendente visto)" \
  || ko "Q9: il .md accentato e' saltato in silenzio: $(head -3 "$Q9/out")"
q9_pulisci
printf 'citato `tools/cita-verifica.sh:999`\n' > "$Q9/docs/c.md"; git -C "$Q9" add docs/c.md
printf 'citato niente\n' > "$Q9/docs/c.md"
[ "$(q9)" -ne 0 ] && grep -q "cita-verifica.sh:999" "$Q9/out" \
  && ok "Q9: la citazione file:riga rotta nell'INDICE si vede (e il messaggio cita il path vero)" \
  || ko "Q9: citazione rotta nell'indice non vista: $(head -3 "$Q9/out")"
q9_pulisci
printf '#!/bin/bash\ncmd | tail -1 %s git commit -m x\n' '&&' > "$Q9/tools/p.sh"; git -C "$Q9" add tools/p.sh
printf '#!/bin/bash\necho pulito\n' > "$Q9/tools/p.sh"
[ "$(q9)" -ne 0 ] && grep -q pipeline "$Q9/out" \
  && ok "Q9: pipe+&& nell'INDICE → rosso anche col working tree pulito" \
  || ko "Q9: pipe+&& nell'indice non visto — falso verde"
rm -rf "$Q9"

# (2026-09-23, notte): il dente pipe+&& guarda solo i file stage-ati — le righe vecchie dormono
# finche' qualcuno tocca il loro file (due in tests/test-fork-stato.sh, una in
# tests/test-privacy-storia.sh). Cricchetto sull'albero intero: zero, e resta zero.
DORMIENTI=$(git -C "$HERE" ls-files '*.sh' '*.py' | grep -vE '^(tools/pre-commit.sh|\.githooks/pre-commit)$' \
  | (cd "$HERE" && xargs grep -nE '(^|[^|])\|[[:space:]]*[A-Za-z][a-zA-Z0-9 ._-]*&&' 2>/dev/null) || true)
[ -z "$DORMIENTI" ] && ok "nessuna riga pipe+&& dorme nell'albero (non solo nei file stage-ati)" \
  || ko "righe pipe+&& nell'albero: $(cut -d: -f1,2 <<<"$DORMIENTI" | tr '\n' ' ')"
# (2026-09-24, terzo ventaglio, V5 R3b): due fix sul lock e sul watchdog hanno cambiato la regola del codice
# ancorato, e i pattern che la descrivono sono rimasti com'erano — nessuno ha chiesto «il pattern dice ancora
# il vero?». Ora il gancio lo chiede quando si tocca un file ancorato senza il suo pattern. Avviso, non blocco.
mkdir -p "$SB/patterns" "$SB/night-shift"
printf '# lock-finto\n**Àncora**: night-shift/lib.sh:prendi_lock · **Nato**: oggi\nregola\n' > "$SB/patterns/lock-finto.md"
printf 'prendi_lock() { :; }\n' > "$SB/night-shift/lib.sh"; git -C "$SB" add night-shift/lib.sh
OUT=$(gancio); RC=$?
grep -c 'patterns/lock-finto.md' <<<"$OUT" >/dev/null && ok "file ancorato in stage senza il suo pattern: il gancio chiede se il pattern dice ancora il vero" \
  || ko "file ancorato toccato in silenzio: $OUT"
git -C "$SB" add patterns/lock-finto.md; OUT=$(gancio)
! grep -c 'dice ancora il vero' <<<"$OUT" >/dev/null && ok "file ancorato e pattern insieme: nessun avviso" || ko "avviso anche col pattern in stage: $OUT"
git -C "$SB" rm -rq --cached night-shift/lib.sh patterns/lock-finto.md >/dev/null
[ "$(git -C "$HERE" diff --cached --name-only 2>/dev/null)" = "$INDICE_PRIMA" ] \
  && ok "Q23: l'indice dell'hub e' com'era prima del test" \
  || ko "Q23: il test ha cambiato l'indice dell'hub: $(git -C "$HERE" diff --cached --name-only | tr '\n' ' ')"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
