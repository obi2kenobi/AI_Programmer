#!/bin/bash
# test-skills-structure.sh — set 2: le skill sono prosa per Claude, non codice eseguibile,
# ma possono comunque essere verificate: frontmatter YAML valido (name/description),
# stile consistente con le skill esistenti (dev-critic/audit-commessa/verifica-visiva),
# e ogni percorso citato nel corpo esiste davvero (altrimenti è la stessa "citazione
# senza presidio" che ha causato il debito che questo giro chiude).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

check_skill_frontmatter() {
  local nome="$1" path="$2"
  [ -f "$path" ] && ok "$nome: SKILL.md esiste" || { ko "$nome: SKILL.md assente"; return; }
  [ "$(sed -n '1p' "$path")" = "---" ] && ok "$nome: apre con frontmatter YAML" \
    || ko "$nome: non apre con ---"
  grep -q "^name: $nome$" "$path" && ok "$nome: campo 'name' presente e corretto" \
    || ko "$nome: campo 'name' assente o diverso dalla directory"
  grep -q "^description: .\{100,\}" "$path" && ok "$nome: description sostanziosa (non un placeholder)" \
    || ko "$nome: description troppo corta o assente"
  local closing
  closing=$(awk 'NR>1 && /^---$/{print NR; exit}' "$path")
  [ -n "$closing" ] && ok "$nome: frontmatter chiuso correttamente" || ko "$nome: frontmatter senza chiusura ---"
}

check_referenced_paths() {
  local nome="$1" path="$2"
  # estrae percorsi citati in backtick che sembrano file del repo (contengono '/' o '.md')
  local refs missing=0
  refs=$(grep -oE '`[A-Za-z0-9_./-]+\.(md|sh|py|js|toml)`' "$path" | tr -d '`' | sort -u)
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in
      *"<"*|*SKILL.md) continue ;;  # placeholder generici, non percorsi reali
      # 5° ciclo, set 2 giro 8 (attivare il glob su tutte le skill ha svelato questi due
      # falsi positivi, mai visti prima perché audit-commessa/dev-critic non erano mai
      # stati controllati): "se esiste X nel progetto" è una condizionale su un
      # progetto ONBOARDATO, non un'affermazione che X esista in questo hub.
      # file-del-target: unica fonte in tools/.file-del-target (dal 2026-08-29
      # anche questo test la legge, non la duplica)
      *) grep -qxF "$ref" "$HERE/tools/.file-del-target" 2>/dev/null && continue ;;
      # gas/Sp.js e tools/test-sp.js appartengono al debito privacy già tracciato in
      # DEBITI.md (4° ciclo, Set 1 giro 7: nomi di repo esterni pre-esistenti, fuori
      # scope finché Luca non chiede una bonifica) — non toccarli qui, non farli
      # apparire come una citazione rotta di questo hub.
      gas/Sp.js|tools/test-sp.js) continue ;;
    esac
    if [ ! -e "$HERE/$ref" ]; then
      echo "   riferimento non trovato: $ref"
      missing=$((missing+1))
    fi
  done <<< "$refs"
  [ "$missing" -eq 0 ] && ok "$nome: tutti i percorsi citati esistono davvero" \
    || ko "$nome: $missing percorso/i citato/i che non esiste/esistono"
}

# 5° ciclo, set 2 giro 8: prima 4 skill erano elencate per nome fisso — audit-commessa,
# dev-critic e verifica-visiva non sono mai state verificate da questo test, per anni di
# giri diversi, senza che nulla lo segnalasse. Stesso identico bug già corretto due volte
# altrove in questo ciclo (.night-verify Set1 4°ciclo, .claude/agents/*.md giro1 di
# questo ciclo, lì scritto giusto la PRIMA volta): itera sul glob, non su nomi hardcoded.
shopt -s nullglob
SKILL_FILES=("$HERE"/.claude/skills/*/SKILL.md)
if [ ${#SKILL_FILES[@]} -eq 0 ]; then
  ko "nessuna skill trovata in .claude/skills/"
else
  for path in "${SKILL_FILES[@]}"; do
    nome="$(basename "$(dirname "$path")")"
    check_skill_frontmatter "$nome" "$path"
    check_referenced_paths  "$nome" "$path"
  done
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
