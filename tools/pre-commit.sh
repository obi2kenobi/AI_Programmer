#!/bin/bash
# pre-commit.sh — il TRUCCETTO che avrei voluto ieri: i controlli VELOCI (2-3
# secondi, non la suite) prima di ogni commit. Nato dai 100 giri assurdi
# (2026-08-29): un commit con un numero sbagliato nel messaggio, glifi alieni,
# un link pendente — tutte cose che una passata di grep becca prima che la
# vergogna diventi pubblica. Si attiva con:
#   git config core.hooksPath .githooks
# (install.sh lo fa per le nuove installazioni; qui si dichiara nel repo.)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"
FALLITI=0

# 1. caratteri alieni nei file STAGE-ATI (non tutto il repo: il commit è la frontiera).
#    NOTA: si usa git grep -P, NON grep -P: il grep BSD di macOS non ha -P e
#    moriva in silenzio nel 2>/dev/null — l'hook diceva OK col glifo staged
#    (falso verde trovato verificando l'hook col caso avverso, suo stesso metodo).
ALIENI=$(git diff --cached --name-only 2>/dev/null | sed 's/^/:/' | xargs git grep -lP '[\x{4E00}-\x{9FFF}\x{0400}-\x{04FF}]' -- 2>/dev/null | grep -vE 'docs/errori/REGISTRO.md' || true)
[ -n "$ALIENI" ] && { echo "⛔ glifi alieni nei file committati:"; echo "$ALIENI"; FALLITI=1; }

# 2. CRLF negli script staged (passano bash -n, muoiono a runtime)
CRLF=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(sh|py)$' | xargs git grep -lP '\r$' -- 2>/dev/null || true)
[ -n "$CRLF" ] && { echo "⛔ fine-riga CRLF (muoiono a runtime):"; echo "$CRLF"; FALLITI=1; }

# 3. path in backtick nei file .md staged: devono esistere (link pendenti alla
#    frontiera). I nomi NUDI seguono due convenzioni del repo: gli oracoli vivono
#    in tools/, i report di campo in docs/campo/ e il SAL li cita per basename
#    (campo-triage li grepge così). Il path nudo si risolve contro le tre radici
#    prima di dichiararlo pendente — altrimenti l'hook blocca la convenzione
#    invece del difetto (successo alla prima: il commit di chi scriveva l'hook).
PEND=""
TARGET=$(grep -vE '^#|^$' "$HERE/tools/.file-del-target" 2>/dev/null || true)
while IFS= read -r f; do
  [ -f "$f" ] || continue
  while IFS= read -r m; do
    echo "$TARGET" | grep -qxF "$m" && continue          # file-del-target: nel progetto, non qui
    [ -e "$m" ] || [ -e "tools/$m" ] || [ -e "tests/$m" ] || [ -e "docs/campo/$m" ] || PEND="$PEND $f: $m"
  done < <(grep -oE '`[A-Za-z0-9_./-]+\.(md|sh|py)`' "$f" | tr -d '`')
done < <(git diff --cached --name-only 2>/dev/null | grep '\.md$')
[ -n "$PEND" ] && { echo "⛔ path citati ma inesistenti:"; echo "$PEND"; FALLITI=1; }

# 4. il messaggio di commit non contiene numeri-test sbagliati: se cita "N test",
#    conta i file veri (ieri: scritto 118, erano 117 — due volte)
MSG="${1:-}"
if echo "$MSG" | grep -qE '[0-9]+ test'; then
  N_CLAIM=$(echo "$MSG" | grep -oE '[0-9]+ test' | grep -oE '^[0-9]+' | head -1)
  N_REAL=$(ls tests/test-*.sh 2>/dev/null | wc -l | tr -d ' ')
  [ "$N_CLAIM" != "$N_REAL" ] && { echo "⛔ il messaggio dice \"$N_CLAIM test\" ma i file sono $N_REAL"; FALLITI=1; }
fi

[ "$FALLITI" -eq 0 ] && echo "pre-commit: controlli rapidi OK" || echo "pre-commit: correggi e ricommetti (oppure --no-verify, sapendo cosa fai)"
exit $FALLITI
