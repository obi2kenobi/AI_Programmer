#!/bin/bash
# test-caccia-smistamento.sh — (2026-09-25, settimo ventaglio, V2 R2): lo smistamento dell'esito di caccia-lente.sh
# (night-shift/night-shift.sh) aveva «sana» come ramo di default. Un rc non dichiarato (5, 127 per lo script assente,
# 143 per un kill) e un rc 1 con l'albero sporco (la miglioria non parte) finivano in «repository in salute» con 30
# minuti di cooldown. Qui il blocco VERO, estratto per segnaposti, gira con git, log e caccia-miglioria finti.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
NS="$HERE/night-shift/night-shift.sh"

BLOCCO=$(awk '/^      MIGLIORIA_RC=1 MIGLIORIA_OUT=""/{p=1} p{print} p&&/\[ -n "\$CENSUS" \] && log/{c=1} c&&/^      fi$/{exit}' "$NS")
[ -n "$BLOCCO" ] && grep -c 'CENSUS' <<<"$BLOCCO" >/dev/null || { ko "blocco dello smistamento non trovato in night-shift.sh"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/ns"
printf '#!/bin/bash\necho "nessuna miglioria"; exit 1\n' > "$T/ns/caccia-miglioria.sh"
{
  echo 'set -uo pipefail'
  echo 'log() { echo "LOG: $*"; }'
  echo 'git() { case "$*" in *"diff --quiet"*) [ "${SPORCO:-0}" = 0 ];; *) return 0;; esac; }'
  printf 'HERE=%q; DIR=%q; REPO=r/x; DB=main; CACCIA_BRANCH=night/caccia-prova; CACCIA_MARKER=%q; CACCIA_OUT=""\n' "$T/ns" "$T" "$T/marker"
  echo 'smista() {'
  printf '%s\n' "$BLOCCO"
  echo '}'
  echo 'smista'
} > "$T/smista.sh"

prova() { # prova <rc> <sporco> → uscita; il marker resta in $T/marker
  rm -f "$T/marker"
  CACCIA_RC="$1" SPORCO="$2" bash -c 'CACCIA_RC=$CACCIA_RC; source "$1"' _ "$T/smista.sh" 2>&1
}
for RC in 5 127 143; do
  OUT=$(prova "$RC" 0)
  ! grep -c 'repository in salute' <<<"$OUT" >/dev/null && [ ! -f "$T/marker" ] && grep -c "rc $RC non dichiarato" <<<"$OUT" >/dev/null \
    && ok "V2 R2: rc $RC non dichiarato: né sana né malata, e niente cooldown" \
    || ko "V2 R2: rc $RC letto come salute (marker $([ -f "$T/marker" ] && echo scritto || echo assente)): $(grep LOG <<<"$OUT" | tail -1)"
done
OUT=$(prova 1 1)
! grep -c 'nessuna miglioria trovata' <<<"$OUT" >/dev/null && [ ! -f "$T/marker" ] && grep -c 'albero sporco' <<<"$OUT" >/dev/null \
  && ok "V2 R2: sana con l'albero sporco: «miglioria non tentata», non «nessuna trovata», e niente cooldown" \
  || ko "V2 R2: sana con l'albero sporco: $(grep LOG <<<"$OUT" | tail -1)"
OUT=$(prova 1 0)
grep -c 'repository in salute' <<<"$OUT" >/dev/null && [ -f "$T/marker" ] \
  && ok "sana, albero pulito, miglioria vuota: salute e cooldown (invariato)" || ko "sana e pulita non e' piu' salute: $(grep LOG <<<"$OUT" | tail -1)"
OUT=$(prova 0 0)
grep -c 'problemi segnalati' <<<"$OUT" >/dev/null && [ ! -f "$T/marker" ] && ok "problemi: il giorno giudica, niente cooldown (invariato)" || ko "rc 0: $(grep LOG <<<"$OUT" | tail -1)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
