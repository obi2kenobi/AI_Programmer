#!/bin/bash
# test-deploy-gas-esito.sh — due difetti trovati nel deploy VERO del Riordino acquisti (2026-10-15),
# letti dall'uscita di tools/deploy-gas.sh:
#   1. «backup vivo: <dir> (N byte verificati)» contava i caratteri dell'ELENCO dei percorsi
#      (find | wc -c), non i byte dei file: 66 file avevano dato «5688 byte». Il messaggio mentiva.
#   2. `clasp push | tail -2` seguito da un «DEPLOY-GAS: SI» incondizionato: l'uscita di tail
#      mascherava quella di clasp, e «SI» compariva anche col push fallito.
# clasp e' FINTO (script in PATH): niente rete, niente GAS vero, solo ID finti.
# Il banco non toglie nessun cancello: la sezione E li prova ancora in piedi (backup vuoto/fallito).
# FAKE_CLASP_PULL: "file" (scrive due file di byte noti) | "vuoto" (nessun file) | "errore" (rc 1)
# FAKE_CLASP_PUSH_RC: codice di uscita del push finto
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DG="$HERE/tools/deploy-gas.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "OK   $1"; }; ko(){ FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$DG" && ok "sintassi" || exit 1

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME" "$T/bin"
export LENTE_SOLO_FORME=1   # la lente senza cervello: il banco non chiama il modello
export CLASP_LOG="$T/clasp.log"

# clasp finto: pull scrive 10+20 byte (piu' .clasp.json, che il conteggio esclude), push esce come dice il banco
cat > "$T/bin/clasp" <<'FINTO'
#!/bin/bash
echo "clasp $1" >> "$CLASP_LOG"
case "$1" in
  pull)
    case "${FAKE_CLASP_PULL:-file}" in
      file)   printf 'AAAAAAAAAA' > Codice.js; printf 'BBBBBBBBBBBBBBBBBBBB' > Pagina.html ;;
      vuoto)  : ;;
      errore) exit 1 ;;
    esac ;;
  push) echo "clasp finto: push esce con ${FAKE_CLASP_PUSH_RC:-0}"; exit "${FAKE_CLASP_PUSH_RC:-0}" ;;
esac
FINTO
chmod +x "$T/bin/clasp"; export PATH="$T/bin:$PATH"

# progetto finto con target gia' approvato (il cancello dei target resta in piedi: non lo aggira nessuno)
P="$T/proj"; mkdir -p "$P"; cd "$P" || exit 1
git init -q -b main; git -c user.name=t -c user.email=t@t commit -qm i --allow-empty
printf '{"scriptId":"1BANCOFINTO_FAKE"}' > .clasp.json
echo "1BANCOFINTO_FAKE" > .git/gas-targets
deploy(){ rm -rf .git/deploy-backup; : > "$CLASP_LOG"; OUT=$(bash "$DG" "$P" 2>&1); RC=$?; }

# ── A. il messaggio del backup dice i byte VERI (10+20=30), non i caratteri dell'elenco dei percorsi
FAKE_CLASP_PULL=file FAKE_CLASP_PUSH_RC=0 deploy
grep -q "(30 byte verificati, isolato)" <<<"$OUT" && ok "A. backup: 30 byte veri (10+20, .clasp.json escluso)" || ko "A. backup: byte falsi — $(grep '3. backup' <<<"$OUT")"

# ── B. push riuscito: SI, exit 0, e il push e' stato davvero chiamato
grep -q "DEPLOY-GAS: SI" <<<"$OUT" && [ "$RC" -eq 0 ] && grep -q "clasp push" "$CLASP_LOG" && ok "B. push ok -> DEPLOY-GAS: SI, rc 0" || ko "B. push ok (rc=$RC) $OUT"
[ -f MANIFEST.md ] && ok "B. il MANIFEST col rollback e' scritto" || ko "B. MANIFEST mancante"

# ── C. push FALLITO: NO, exit 1, mai SI (il difetto: tail mascherava l'uscita di clasp)
rm -f MANIFEST.md
FAKE_CLASP_PULL=file FAKE_CLASP_PUSH_RC=1 deploy
grep -q "DEPLOY-GAS: NO" <<<"$OUT" && ok "C. push fallito -> DEPLOY-GAS: NO" || ko "C. push fallito: manca NO — $(tail -2 <<<"$OUT")"
grep -q "DEPLOY-GAS: SI" <<<"$OUT" && ko "C. push fallito ma compare SI (il difetto)" || ok "C. push fallito: nessun SI"
[ "$RC" -eq 1 ] && ok "C. push fallito -> exit 1" || ko "C. push fallito -> exit $RC (atteso 1)"
grep -q "rc=1" <<<"$OUT" && ok "C. il codice di uscita di clasp e' detto (rc=1)" || ko "C. rc di clasp non detto"

# ── D. push con rc diverso da 1: nessun SI (qualunque errore di clasp ferma)
FAKE_CLASP_PULL=file FAKE_CLASP_PUSH_RC=7 deploy
grep -q "DEPLOY-GAS: SI" <<<"$OUT" && ko "D. clasp rc=7 ma compare SI" || ok "D. clasp rc=7: nessun SI"

# ── E. i cancelli restano in piedi: backup vuoto o fallito fermano PRIMA del push
FAKE_CLASP_PULL=vuoto FAKE_CLASP_PUSH_RC=0 deploy
grep -q "BACKUP vuoto" <<<"$OUT" && [ "$RC" -eq 1 ] && ! grep -q "clasp push" "$CLASP_LOG" && ok "E. backup vuoto: stop, push mai chiamato" || ko "E. backup vuoto (rc=$RC) $OUT"
FAKE_CLASP_PULL=errore FAKE_CLASP_PUSH_RC=0 deploy
grep -q "BACKUP non riuscito" <<<"$OUT" && [ "$RC" -eq 1 ] && ! grep -q "clasp push" "$CLASP_LOG" && ok "E. backup fallito: stop, push mai chiamato" || ko "E. backup fallito (rc=$RC) $OUT"
printf '{"scriptId":"1ALTRO_FAKE"}' > .clasp.json
FAKE_CLASP_PULL=file deploy
grep -q "TARGET SCONOSCIUTO" <<<"$OUT" && [ "$RC" -eq 1 ] && ! grep -q "clasp push" "$CLASP_LOG" && ok "E. target sconosciuto: stop, push mai chiamato" || ko "E. target (rc=$RC) $OUT"

echo ""; echo "$PASS OK, $FAIL FAIL"; [ "$FAIL" -eq 0 ]
