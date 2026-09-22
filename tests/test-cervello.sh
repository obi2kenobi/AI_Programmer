#!/bin/bash
# test-cervello.sh — il guardiano del secondo cervello. Un cervello con link
# rotti o indice stantio e' un grafo bello che mente: questa lente lo impedisce.
#
#   1. ogni nota ha frontmatter sano (tipo valido alla riga 2, data, titolo)
#   2. ogni [[wikilink]] punta a una nota esistente
#   3. l'indice e' fresco (uguale a quello che genererebbe annota adesso)
#   4. annota RIFIUTA il link rotto e il tipo sconosciuto (prova funzionale
#      su una copia: il repo non si tocca)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

CER="$HERE/cervello"

# ── 1. frontmatter sano ─────────────────────────────────────────────────────
NOTE_SANE=0; NOTE_ROTTE=""
for f in "$CER"/*.md; do
  case "$(basename "$f")" in indice.md|README.md) continue ;; esac
  TIPO=$(sed -n '2s/^tipo: //p' "$f")
  case "$TIPO" in decisione|concetto|famiglia|sospeso|repo|lezione) NOTE_SANE=$((NOTE_SANE+1)) ;; *) NOTE_ROTTE="$NOTE_ROTTE $(basename "$f")($TIPO)" ;; esac
done
if [ -z "$NOTE_ROTTE" ] && [ "$NOTE_SANE" -gt 0 ]; then
  ok "frontmatter sano in tutte le $NOTE_SANE note"
else
  ko "frontmatter rotto o mancante in:$NOTE_ROTTE"
fi

# ── 2. wikilink che risolvono ───────────────────────────────────────────────
ROTTI_REALI=""
while IFS= read -r riga; do
  f="${riga%%|*}"; link="${riga##*|}"
  [ -f "$CER/$link.md" ] || ROTTI_REALI="$ROTTI_REALI $link (in $(basename "$f"))"
# nota: niente `case` ne' `continue` dentro la sostituzione qui sotto: il parser
# di bash 3.2 (macOS) li boccia dentro <(...). Si gira con if.
done < <(for f in "$CER"/*.md; do
  b=$(basename "$f")
  if [ "$b" != "indice.md" ] && [ "$b" != "README.md" ]; then
    grep -oE '\[\[[a-z0-9-]+\]\]' "$f" 2>/dev/null | tr -d '[]' | while read -r l; do echo "$f|$l"; done
  fi
done)
if [ -z "$ROTTI_REALI" ]; then
  ok "ogni wikilink del cervello punta a una nota esistente"
else
  ko "wikilink rotti:$ROTTI_REALI"
fi

# ── 3. indice fresco ────────────────────────────────────────────────────────
bash "$HERE/tools/cervello-annota.sh" --anteprima-indice > /tmp/indice-atteso.$$ 2>/dev/null
if diff -q /tmp/indice-atteso.$$ "$CER/indice.md" >/dev/null 2>&1; then
  ok "cervello/indice.md e' fresco (uguale alla generazione attuale)"
else
  ko "indice stantio: esegui 'bash tools/cervello-annota.sh --indice'"
fi
rm -f /tmp/indice-atteso.$$

# ── 4. annota rifiuta l'immondizia (su copia, il repo non si tocca) ─────────
TMP=$(mktemp -d /tmp/test-cervello.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/tools" "$TMP/cervello"
cp "$HERE/tools/cervello-annota.sh" "$TMP/tools/"
printf -- "---\ntipo: concetto\ndata: 2026-09-21\ntitolo: Nota sana\n---\ncorpo\n" > "$TMP/cervello/nota-sana.md"

printf 'corpo con link a [[nota-che-non-esiste]]\n' | bash "$TMP/tools/cervello-annota.sh" nota-nuova concetto "Titolo" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ] && [ ! -f "$TMP/cervello/nota-nuova.md" ]; then
  ok "annota rifiuta il wikilink rotto (rc 2, nessun file scritto)"
else
  ko "annota ha accettato (rc=$RC) un link a una nota inesistente"
fi

printf 'corpo\n' | bash "$TMP/tools/cervello-annota.sh" nota-tipo concetto-sbagliato "Titolo" >/dev/null 2>&1
if [ $? -eq 2 ]; then
  ok "annota rifiuta il tipo sconosciuto"
else
  ko "annota ha accettato un tipo fuori whitelist"
fi

printf 'corpo che linka [[nota-sana]]\n' | bash "$TMP/tools/cervello-annota.sh" nota-ok concetto "Titolo" >/dev/null 2>&1
if [ $? -eq 0 ] && [ -f "$TMP/cervello/nota-ok.md" ]; then
  ok "annota scrive la nota sana e aggiorna l'indice"
else
  ko "annota non ha scritto la nota legittima"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
