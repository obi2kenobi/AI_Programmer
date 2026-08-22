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

Totale: 3 PR verificate

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

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
