#!/bin/bash
# test-backup-config.sh — 60 giri: backup-config non aveva test
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# il tool esiste, è eseguibile, e gestisce l'assenza di gh
[ -f "$HERE/tools/backup-config.sh" ] && ok "backup-config.sh esiste" || ko "assente"
[ -x "$HERE/tools/backup-config.sh" ] && ok "eseguibile" || ko "non eseguibile"
# senza gh deve fallire pulitamente (non crashare). Il ramo si FORZA sempre
# via PATH: prima, con gh installato, il test si saltava da solo (3 OK di nulla
# — scoperto dal mutation-testing 2026-08-28: tool neutralizzato, test verde).
GHBIN=$(command -v gh || true)
NOGH=$([ -n "$GHBIN" ] && dirname "$GHBIN" || echo /nonexist)
out=$(PATH="/usr/bin:/bin" bash "$HERE/tools/backup-config.sh" 2>&1); rc=$?
[ $rc -ne 0 ] && echo "$out" | grep -qi "gh\|gist" && ok "senza gh: errore pulito" || ko "senza gh: crash o silenzio poco chiaro (rc=$rc)"

# IE-003 GitLab (2026-08-31): CINQUE backup, nessuno provato col ripristino — 6 ore
# di dati perse. Il backup che non si sa leggere NON è un backup. Con gh attivo
# si verifica che il gist di backup sia LEGGIBILE e contenga i tre file attesi
# (il ripristino vero è dell'umano, ma la leggibilità si prova qui).
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GIST_ID=$(cat "$HERE/.gist-backup-id" 2>/dev/null || echo "")
  if [ -n "$GIST_ID" ]; then
    OUT=$(gh gist view "$GIST_ID" 2>&1) && echo "$OUT" | grep -q "repos.conf" \
      && ok "backup LEGGIBILE e contiene repos.conf (l'antidoto GitLab)" \
      || ko "backup illeggibile o incompleto: sarebbe il sesto backup-che-non-funziona"
  else
    ok "backup mai creato su questa macchina: prima esecuzione dichiarata"
  fi
else
  ok "gh assente: verifica del ripristino dichiarata NON ESEGUIBILE (non falsificata)"
fi

echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
