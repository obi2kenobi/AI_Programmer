#!/bin/bash
# test-morning-digest.sh — due bug reali trovati con dogfooding (nuovo ciclo 10 giri):
# 1) BODY veniva assegnato al PERCORSO del report ($REPORT), non al suo CONTENUTO —
#    il digest avrebbe spedito il path del file invece del report vero.
# 2) subject/content/destinatario finivano non-escaped in una stringa AppleScript —
#    una virgoletta o un backslash nel report rompe o inietta nello script osascript
#    (stessa classe di bug già chiusa in morning-gate.sh, mai applicata qui).
# Nessun Mail.app/osascript reale in sandbox: si intercetta osascript con un finto
# eseguibile che salva l'argomento -e ricevuto, per ispezionarlo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
mkdir -p "$TMP/bin" "$TMP/repo/night-shift"
cp "$HERE/night-shift/morning-digest.sh" "$TMP/repo/night-shift/"
cp "$HERE/night-shift/gate-summary.sh" "$TMP/repo/night-shift/" 2>/dev/null || true
mkdir -p "$TMP/repo/metrics"; echo "data,repo,pr,issue,verifiche,banco,esito" > "$TMP/repo/metrics/gate.csv"

echo 'DIGEST_EMAIL=test@esempio.it' > "$TMP/repo/night-shift/repos.key"

# report avversariale: virgolette e backslash dentro, come farebbe un titolo PR reale
cat > "$HOME/morning-gate-report.md" <<'EOF'
# Report

Totale: 3 PR verificate, una "urgente"

Nota con "virgolette" e un backslash \ dentro.
EOF

# finto osascript: salva l'argomento -e (il secondo argomento) e finisce con successo
cat > "$TMP/bin/osascript" <<'EOF'
#!/bin/bash
[ "$1" = "-e" ] && printf '%s' "$2" > "$OSASCRIPT_CAPTURE"
exit 0
EOF
chmod +x "$TMP/bin/osascript"
export PATH="$TMP/bin:$PATH"
export OSASCRIPT_CAPTURE="$TMP/captured.txt"

bash "$TMP/repo/night-shift/morning-digest.sh" >"$TMP/out.log" 2>&1
RC=$?
[ $RC -eq 0 ] && ok "digest eseguito senza errore (rc=0)" || ko "rc=$RC: $(cat "$TMP/out.log")"
[ -f "$TMP/captured.txt" ] && ok "osascript invocato con -e" || ko "osascript non invocato — vedi $TMP/out.log"

CAPTURED=$(cat "$TMP/captured.txt" 2>/dev/null || echo "")
grep -q "Totale: 3 PR verificate" <<<"$CAPTURED" && ok "il body contiene il CONTENUTO del report, non il suo path" \
  || ko "body non contiene il testo del report: $CAPTURED"
grep -qF "$HOME/morning-gate-report.md" <<<"$CAPTURED" && ko "il body contiene ancora il PATH letterale del report" \
  || ok "il body non contiene il path letterale (bug corretto)"
grep -qF '\"virgolette\"' <<<"$CAPTURED" && ok "le virgolette nel report sono escaped nello script AppleScript" \
  || ko "virgolette non escaped: $CAPTURED"
grep -qF '\\' <<<"$CAPTURED" && ok "il backslash nel report è escaped nello script AppleScript" \
  || ko "backslash non escaped: $CAPTURED"
# (2026-09-24, terzo ventaglio, V2 S12b): l'oggetto viene dalla riga «Totale:» e si escapa a parte
# (SUBJ_ESC); senza virgolette su quella riga, `SUBJ_ESC=$SUBJ` restava verde
grep -qF '[Gate] Totale: 3 PR verificate, una \"urgente\"' <<<"$CAPTURED" && ok "le virgolette dell'oggetto sono escaped" \
  || ko "oggetto non escaped: $(grep -o 'subject:[^,]*' <<<"$CAPTURED")"

# ── (revisione 10 giri, 2026-09-23): la memoria del turno ─────────────────────────────
# Tre difetti misurati: (a) `.sal-turni.md` si svuotava PRIMA dell'invio — se Mail e mail
# fallivano la memoria era persa e il digest usciva 0 su «ERRORE invio»; (b) «PR» contava le
# righe d'intestazione dei turni che contengono «PR bozza», non le PR; (c) «ASPETTA» contava
# ogni riga con due spazi dal primo marcatore alla fine del file — anche il log dei turni dopo.
SALT="$TMP/repo/night-shift/.sal-turni.md"
cat > "$TMP/salt.orig" <<'EOF'

### 2026-09-22, turno automatico — 3 PR bozza, 0 proposte in issue, 0 fallite, 0 saltate per Design/Territorio

  [01:00:00] === TURNO INIZIATO ===
  [01:00:01] riga di log

**ASPETTA IL GIORNO** (proposta pubblicata, decisione diurna pendente):
  owner/repo #7: una decisione vera

### 2026-09-22, turno automatico — 2 PR bozza, 0 proposte in issue, 0 fallite, 0 saltate per Design/Territorio

  [02:00:00] === TURNO INIZIATO ===
  [02:00:01] altra riga di log
  [02:00:02] altra ancora

**ASPETTA IL GIORNO** (proposta pubblicata, decisione diurna pendente):
EOF
cp "$TMP/salt.orig" "$SALT"
bash "$TMP/repo/night-shift/morning-digest.sh" >"$TMP/out2.log" 2>&1
CAP2=$(cat "$TMP/captured.txt" 2>/dev/null)
grep -q "Cicli notturni\*\*: 2 " <<<"$CAP2" && ok "cicli = turni scritti (2)" || ko "cicli: $(grep -o 'Cicli notturni[^/]*' <<<"$CAP2")"
grep -q "\*\*PR\*\*: 5 " <<<"$CAP2" && ok "PR = somma delle PR dei turni (3+2 = 5), non il numero di turni" || ko "PR: $(grep -o 'PR\*\*: [0-9]*' <<<"$CAP2")"
grep -q "ASPETTA IL GIORNO\*\*: 1 decisioni" <<<"$CAP2" && ok "ASPETTA = le decisioni pendenti (1), non il log dei turni dopo" || ko "ASPETTA: $(grep -o 'ASPETTA IL GIORNO[^p]*' <<<"$CAP2")"
PRIMA_RIGA_SUMMARY=$(bash "$TMP/repo/night-shift/gate-summary.sh" 0 2>/dev/null | head -1)
[ -z "$PRIMA_RIGA_SUMMARY" ] || [ "$(grep -cF "$PRIMA_RIGA_SUMMARY" <<<"$CAP2")" -eq 1 ] \
  && ok "il riepilogo del gate compare UNA volta" || ko "riepilogo del gate duplicato nel digest"
# invio fallito: la memoria RESTA e l'esito e' rosso
cp "$TMP/salt.orig" "$SALT"
printf '#!/bin/bash\nexit 1\n' > "$TMP/bin/osascript"; printf '#!/bin/bash\nexit 1\n' > "$TMP/bin/mail"; chmod +x "$TMP/bin/mail"
bash "$TMP/repo/night-shift/morning-digest.sh" >"$TMP/out3.log" 2>&1; RC3=$?
[ "$RC3" -ne 0 ] && ok "invio fallito → esito rosso (rc=$RC3)" || ko "invio fallito ma rc 0"
cmp -s "$SALT" "$TMP/salt.orig" && ok "invio fallito → la memoria del turno RESTA (non svuotata)" || ko "invio fallito e memoria svuotata: persa"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
