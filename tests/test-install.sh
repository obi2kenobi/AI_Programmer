#!/bin/bash
# test-install.sh — idempotenza di install.sh (giro 7/10): si esegue DUE VOLTE in una
# HOME finta e deve lasciare lo stato identico, non duplicato né rotto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
FAKE=$(mktemp -d)
mkdir -p "$FAKE/bin" "$FAKE/Library/LaunchAgents"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# (revisione 10 giri, 2026-09-23): $FAKE/bin era VUOTO — il PATH arrivava a /usr/bin e su
# un Mac install.sh chiamava il launchctl VERO (bootout/bootstrap del turno di produzione
# da una HOME temporanea che il test poi cancella). Ora un launchctl FINTO registra le
# chiamate: il banco non tocca mai launchd, e le etichette si possono verificare.
cat > "$FAKE/bin/launchctl" <<'STUB'
#!/bin/bash
echo "$*" >> "$(dirname "$0")/launchctl.log"
case "$1" in print) echo "path = ${LAUNCHCTL_FINTO_PATH:-}";; esac
exit 0
STUB
chmod +x "$FAKE/bin/launchctl"

# patch temporanea di HOME per install.sh (usa ~ e launchctl — simuliamo il minimo)
run_install() {
  # (revisione 10 giri): $FAKE dentro le virgolette singole non era espanso ne' esportato —
  # il PATH del figlio non ha MAI contenuto $FAKE/bin. Ora si passa espanso.
  HOME="$FAKE" bash -c 'HUB="'"$HERE"'"; cd "$HUB"; PATH="'"$FAKE"'/bin:/usr/bin:/bin" bash night-shift/install.sh' 2>&1
}

# (E-032, test del sistema completo 2026-09-20): install.sh scrive night-shift/repos.conf
# nell'hub VIVO se manca — il test lo lasciava li' (coda "example" che il turno senza
# argomenti avrebbe letto). Si ricorda se c'era, e a fine test si rimuove se l'ha creato lui.
CONF_PRIMA=0; [ -f "$HERE/night-shift/repos.conf" ] && CONF_PRIMA=1
trap '[ "$CONF_PRIMA" -eq 0 ] && rm -f "$HERE/night-shift/repos.conf"; rm -rf "$FAKE"' EXIT
# un'installazione VECCHIA ha lasciato symlink: scrivere il lanciatore attraverso il link
# riscriverebbe il file a cui punta (nell'installazione vera: il file dell'hub)
mkdir -p "$FAKE/.local/bin"; echo "bersaglio" > "$FAKE/bersaglio.sh"; ln -s "$FAKE/bersaglio.sh" "$FAKE/.local/bin/ask-qwen"
OUT1=$(run_install)
[ "$(cat "$FAKE/bersaglio.sh")" = "bersaglio" ] && ok "un symlink vecchio si sostituisce, il file a cui puntava resta intatto" \
  || ko "il lanciatore e' stato scritto ATTRAVERSO il symlink vecchio (sull'hub vero: file sovrascritto)"
# (audit-2): un install che esplode a meta' non puo' passare come 'parziale'
grep -q "Fatto" <<<"$OUT1" && ok "prima esecuzione: completa" || ko "prima esecuzione incompleta: $(echo "$OUT1" | tail -1 | cut -c1-80)"
# symlinks creati? (mutation-testing 2026-08-28: prima era ok||ok — un install
# rotto che non fa NIENTE passava lo stesso; ora l'artefatto è obbligatorio)
[ -x "$FAKE/.local/bin/ask-qwen" ] && ok "comando ask-qwen creato" || ko "install non ha creato ~/.local/bin/ask-qwen"
# (2026-09-23, notte dei giri): il comando installato deve GIRARE, non solo esistere. Da symlink,
# i cinque comandi risolvevano HERE nella cartella del link e morivano al primo `source` («_usage.sh:
# No such file or directory», rc 1). ask-glm senza chiave deve dare il suo rc 2 documentato.
OUT_GLM=$(env -u ZHIPUAI_API_KEY "$FAKE/.local/bin/ask-glm" ping 2>&1); RC_GLM=$?
[ $RC_GLM -eq 2 ] && grep -c "non configurata" <<<"$OUT_GLM" >/dev/null && ok "ask-glm installato gira (rc 2: via non configurata)" \
  || ko "ask-glm installato non gira (rc $RC_GLM): $(head -1 <<<"$OUT_GLM")"
LS1=$(ls "$FAKE/.local/bin" 2>/dev/null | wc -l | tr -d ' ')
# seconda esecuzione: idempotente
OUT2=$(run_install)
LS2=$(ls "$FAKE/.local/bin" 2>/dev/null | wc -l | tr -d ' ')
[ "$LS1" = "$LS2" ] && ok "seconda esecuzione: numero symlink identico ($LS2)" || ko "symlink duplicati: $LS1 → $LS2"
# (revisione 10 giri): qui c'era `… && ok || ok` (non poteva fallire) e una scrittura in
# un file senza senso. Il contratto vero: repos.conf gia' presente resta intatto.
CONF="$HERE/night-shift/repos.conf"
IMPRONTA_CONF=$(cksum < "$CONF" 2>/dev/null)
run_install >/dev/null
[ "$(cksum < "$CONF" 2>/dev/null)" = "$IMPRONTA_CONF" ] && ok "repos.conf gia' presente: intatto dopo una nuova installazione" || ko "install ha riscritto repos.conf"
# le etichette: launchd conosce i job per la Label DEL PLIST (__USER__.<job>), non per il nome
# del file (com.<utente>.<job>.plist). bootout/print sul nome del file non trovano mai il job.
U=$(id -un)
LOG="$FAKE/bin/launchctl.log"
[ -f "$LOG" ] && ok "launchctl finto usato (launchd vero mai toccato)" || ko "launchctl finto mai chiamato: install ha usato quello vero?"
grep -qE "^bootout gui/[0-9]+/$U\.nightshift$" "$LOG" 2>/dev/null && ok "bootout sulla Label vera ($U.nightshift)" \
  || ko "bootout su un'etichetta che launchd non conosce: $(grep '^bootout' "$LOG" 2>/dev/null | head -1)"
grep -qE "^print gui/[0-9]+/$U\.morningdigest$" "$LOG" 2>/dev/null && ok "print sulla Label vera ($U.morningdigest)" \
  || ko "print su un'etichetta sbagliata: $(grep '^print' "$LOG" 2>/dev/null | head -1)"
# plist generati senza __PLACEHOLDER__ (e ALMENO UNO deve esistere)
NPLIST=0
for f in "$FAKE/Library/LaunchAgents"/*.plist; do
  [ -e "$f" ] || continue
  NPLIST=$((NPLIST+1))
  grep -q "__USER__\|__HOME__\|__HUB__\|__DIR__" "$f" && ko "placeholder non sostituito in $f" || ok "placeholder sostituiti in $(basename "$f")"
done
[ "$NPLIST" -ge 1 ] && ok "almeno un LaunchAgent installato ($NPLIST)" || ko "nessun plist generato: install non ha installato niente"

rm -rf "$FAKE"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
