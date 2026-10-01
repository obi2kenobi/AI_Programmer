#!/bin/bash
# test-morning-digest.sh — il digest v3 sotto banco (2026-09-30, dalla mail che
# diceva «196 cicli / 156 PR» di sempre e il gate-summary di REPO-A morto da 40
# giorni): la mail del mattino porta I NUMERI DEL BILANCINO di stanotte, i fossili
# non compaiono, e l'escaping AppleScript regge anche dai contenuti nuovi.
# Nessun Mail.app reale: osascript finto che cattura l'argomento -e.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d /tmp/test-morning-digest.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
mkdir -p "$TMP/bin" "$TMP/repo/night-shift" "$TMP/night-shift-work/cervello-da-approvare"
cp "$HERE/night-shift/morning-digest.sh" "$TMP/repo/night-shift/"
echo 'DIGEST_EMAIL=test@esempio.it' > "$TMP/repo/night-shift/repos.key"

IERI=$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F)
LALTROGIORNO=$(date -v-2d +%F 2>/dev/null || date -d '2 days ago' +%F)

# finto osascript: cattura l'argomento -e
cat > "$TMP/bin/osascript" <<'EOF'
#!/bin/bash
[ "$1" = "-e" ] && printf '%s' "$2" > "$OSASCRIPT_CAPTURE"
exit 0
EOF
chmod +x "$TMP/bin/osascript"
export PATH="$TMP/bin:$PATH" OSASCRIPT_CAPTURE="$TMP/captured.txt"

# il bilancino finto: stanotte 2 repo (uno col delta debiti), e il FOSSILE REPO-A di agosto
cat > "$TMP/funnel.csv" <<EOF
data,repo,cicli,verify_verdi,verify_rosse,pr_aperte,pr_fuse,pr_rigettate,rigetti_det,gpu_s,debiti_aperti,lezioni
$LALTROGIORNO,RepoDue,9,3,0,0,0,0,0,10,5,0
$IERI,RepoUno,8,4,1,1,2,1,1,42,46,1
$IERI,RepoDue,7,3,0,0,1,0,0,10,3,0
2026-08-21,REPO-A,1,0,0,0,0,0,0,0,0,0
EOF

# i sospesi del cervello: contenuti avversariali per l'escaping (virgolette e backslash)
printf 'IN SOSPESO (2026-09-30)\n  - nota con "virgolette" e un backslash \\ dentro\n\n## lezioni da approvare (proposte dal turno, /learn)\n  - Il watchdog rianima Ollama — lezione-il-watchdog\n  (coda: cervello-da-approvare)\n' > "$TMP/night-shift-work/.cervello-$(date +%F)"

# il SAL: una decisione pendente vera (questa resta, i contatori no)
cat > "$TMP/repo/night-shift/.sal-turni.md" <<EOF

### $IERI, turno automatico — 1 PR bozza, 0 proposte in issue

  [01:00:00] === TURNO INIZIATO ===

**ASPETTA IL GIORNO** (proposta pubblicata, decisione diurna pendente):
  owner/repo #7: una decisione vera
EOF

MORNING_FUNNEL="$TMP/funnel.csv" bash "$TMP/repo/night-shift/morning-digest.sh" >"$TMP/out.log" 2>&1
RC=$?
[ $RC -eq 0 ] && ok "digest eseguito senza errore (rc=0)" || ko "rc=$RC: $(cat "$TMP/out.log")"
CAPTURED=$(cat "$TMP/captured.txt" 2>/dev/null || echo "")

# 1. i numeri VERI di stanotte, dal bilancino
grep -q "LA NOTTE (dal bilancino" <<<"$CAPTURED" && ok "la sezione LA NOTTE apre la mail" || ko "manca LA NOTTE: $CAPTURED"
grep -qF "RepoUno: 8 cicli · PR: 1 aperte, 2 fuse, 1 rigettate · 42s GPU · 1 lezioni" <<<"$CAPTURED" \
  && ok "riga di RepoUno coi numeri veri" || ko "riga RepoUno: $(grep -o 'RepoUno[^·]*' <<<"$CAPTURED" | head -1)"
grep -qF "RepoDue" <<<"$CAPTURED" && grep -q "debiti 5→3" <<<"$CAPTURED" \
  && ok "il delta dei debiti sulla notte prima (5→3)" || ko "delta debiti: $(grep -o 'RepoDue.*' <<<"$CAPTURED" | head -1)"
grep -qF "Mattina $IERI — cicli 15 · fuse 3 · rigettate 1 · 52s GPU" <<<"$CAPTURED" \
  && ok "l'oggetto porta i totali di stanotte" || ko "oggetto: $(grep -o 'subject:[^,]*' <<<"$CAPTURED" | head -1)"

# 2. i fossili NON compaiono piu'
grep -q 'REPO-A' <<<"$CAPTURED" && ko "il fossile REPO-A e' ancora in mail" || ok "niente REPO-A"
grep -q 'Gate summary\|Cicli notturni\|morning-gate' <<<"$CAPTURED" && ko "il gate in pensione e' ancora in mail" || ok "niente gate-summary ne' contatori cumulativi"

# 3. le decisioni pendenti contano ancora
grep -q "ASPETTA IL GIORNO\*\*: 1 decisioni" <<<"$CAPTURED" && ok "ASPETTA: le decisioni pendenti restano" || ko "ASPETTA: $(grep -o 'ASPETTA[^:]*' <<<"$CAPTURED" | head -1)"

# 4. sospesi e lezioni dalla coda di approvazione
grep -qF 'nota con \"virgolette\"' <<<"$CAPTURED" \
  && ok "i sospesi entrano, con le virgolette escaped per AppleScript" || ko "sospesi/escaping: $(grep -o 'nota con[^e]*' <<<"$CAPTURED" | head -1)"
grep -qF 'Il watchdog rianima Ollama' <<<"$CAPTURED" && ok "la lezione in coda compare tra le da-approvare" || ko "lezione in coda non elencata"

# 5. niente righe di ieri: lo si DICE, non si tace
mv "$TMP/funnel.csv" "$TMP/funnel.datum"
printf '' > "$TMP/funnel.csv"
MORNING_FUNNEL="$TMP/funnel.csv" bash "$TMP/repo/night-shift/morning-digest.sh" >"$TMP/out2.log" 2>&1
grep -q "nessuna riga di ieri" "$TMP/captured.txt" \
  && ok "bilancino vuoto: dichiarato («nessuna riga di ieri»)" || ko "bilancino vuoto non dichiarato: $(grep -o 'LA NOTTE[^\]*' "$TMP/captured.txt" | head -1)"
mv "$TMP/funnel.datum" "$TMP/funnel.csv"

# 5b. (2026-10-01, giro accurato): una riga MONCA del bilancino (campi vuoti) non
# deve ammazzare la mail: l'aritmetica sotto set -e morirebbe in silenzio
printf 'data,repo,cicli,verify_verdi,verify_rosse,pr_aperte,pr_fuse,pr_rigettate,rigetti_det,gpu_s,debiti_aperti,lezioni\n%s,RepoMonco,,4,1,,2,,1,,3,\n' "$IERI" >> "$TMP/funnel.csv"
MORNING_FUNNEL="$TMP/funnel.csv" bash "$TMP/repo/night-shift/morning-digest.sh" >"$TMP/out5b.log" 2>&1; RC5b=$?
[ "$RC5b" -eq 0 ] && grep -q "RepoMonco" "$TMP/captured.txt" \
  && ok "riga monca nel bilancino: la mail parte comunque (e la dichiara)" || ko "riga monca ammazza la mail (rc=$RC5b): $(tail -1 "$TMP/out5b.log")"

# 6. invio fallito: esito rosso e la memoria del turno resta
printf '#!/bin/bash\nexit 1\n' > "$TMP/bin/osascript"
printf '#!/bin/bash\nexit 1\n' > "$TMP/bin/mail"; chmod +x "$TMP/bin/mail"
cp "$TMP/repo/night-shift/.sal-turni.md" "$TMP/salt.orig"
MORNING_FUNNEL="$TMP/funnel.csv" bash "$TMP/repo/night-shift/morning-digest.sh" >"$TMP/out3.log" 2>&1; RC3=$?
[ "$RC3" -ne 0 ] && ok "invio fallito → esito rosso (rc=$RC3)" || ko "invio fallito ma rc 0"
cmp -s "$TMP/repo/night-shift/.sal-turni.md" "$TMP/salt.orig" && ok "invio fallito → la memoria del turno RESTA" || ko "memoria svuotata con invio fallito"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
