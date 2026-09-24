#!/bin/bash
# test-opencode-agent-sync.sh — 6° ciclo, set 3 giro 3 (2026-08-24). Chiude il limite
# dichiarato in docs/system.md §"Limiti dichiarati" #6 nella parte OpenCode: ".opencode/
# agent/ assente, solo .opencode/skills/". Ora gli stessi 5 agenti vivono anche per il
# turno notturno (OpenCode). Il CORPO dei file deve restare identico fra .claude/agents/
# e .opencode/agent/ — cambiano solo frontmatter e nota di specchio: un agente che
# diverga fra giorno e notte è due agenti diversi che si credono lo stesso. Questo test
# blocca il drift su ogni coppia (glob, mai lista hardcoded).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

shopt -s nullglob
CLAUDE=("$HERE"/.claude/agents/*.md)
OPEN=("$HERE"/.opencode/agent/*.md)

[ "${#CLAUDE[@]}" -gt 0 ] && ok "agenti Claude presenti: ${#CLAUDE[@]}" || ko "nessun agente in .claude/agents/"
[ "${#OPEN[@]}" -eq "${#CLAUDE[@]}" ] \
  && ok "agenti OpenCode specchiati: ${#OPEN[@]} = ${#CLAUDE[@]}" \
  || ko "sfasamento: ${#OPEN[@]} OpenCode vs ${#CLAUDE[@]} Claude"

corpo() { # corpo = tutto ciò che segue la chiusura del frontmatter, senza la nota specchio.
  # UNA sola sed '1,/^---$/d': il range parte dalla riga 1 e si chiude al SECONDO ---
  # (la chiusura del frontmatter), lasciando il corpo. La versione con DUE sed concatenate
  # cancellava tutto: la prima consumava già entrambe le recinzioni, la seconda non trovava
  # più --- e, per semantica sed, cancellava fino a EOF. corpo() restituiva SEMPRE vuoto,
  # diff vuoto==vuoto passava sempre: il test diceva "no drift" senza aver mai confrontato
  # niente (scoperto 2026-08-28 con gli specchi già driftati su 5 agenti su 6).
  # La nota specchio si riconosce dal commento HTML che la contiene.
  sed '1,/^---$/d' "$1" | grep -v '^<!-- Specchio' | grep -v '^     ' | sed '/^-->$/d'
}

for c in "${CLAUDE[@]}"; do
  nome="$(basename "$c" .md)"
  o="$HERE/.opencode/agent/$nome.md"
  if [ ! -f "$o" ]; then ko "$nome: nessun specchio OpenCode"; continue; fi
  # frontmatter opencode: mode subagent e description non vuota
  grep -q "^mode: subagent" "$o" \
    && ok "$nome: frontmatter OpenCode con mode subagent" \
    || ko "$nome: frontmatter senza mode: subagent"
  # il corpo estratto NON può essere vuoto: un confronto vuoto==vuoto passa sempre
  # e verificherebbe niente (la lezione del 2026-08-28). Prima si dichiara non vuoto,
  # poi si confronta.
  NC=$(corpo "$c" | wc -l | tr -d ' '); NO=$(corpo "$o" | wc -l | tr -d ' ')
  [ "$NC" -gt 0 ] || ko "$nome: estrazione corpo Claude VUOTA — il confronto non varrebbe niente"
  [ "$NO" -gt 0 ] || ko "$nome: estrazione corpo OpenCode VUOTA — il confronto non varrebbe niente"
  if [ "$NC" -gt 0 ] && [ "$NO" -gt 0 ] && diff <(corpo "$c") <(corpo "$o") >/dev/null 2>&1; then
    ok "$nome: corpo identico fra Claude e OpenCode (no drift, $NC righe confrontate)"
  else
    ko "$nome: il corpo DIVERGE fra .claude/agents e .opencode/agent — due agenti diversi che si credono lo stesso"
  fi
done

# un agente OpenCode ORFANO (presente lì, non in Claude) è anch'esso drift
for o in "${OPEN[@]}"; do
  nome="$(basename "$o" .md)"
  [ -f "$HERE/.claude/agents/$nome.md" ] || ko "$nome: orfano OpenCode senza origine Claude"
done

# (Q20, 2026-09-23, giro A6 della notte): il frontmatter degli specchi portava `tools: Read, Grep,
# Glob, Bash` — la forma di Claude Code. Per OpenCode `tools` e' una MAPPA nome→booleano (e
# deprecata a favore di `permission`, https://opencode.ai/docs/agents/): la stringa non dice nulla
# e l'agente di notte non era ristretto come quello di giorno. Ora `permission:` fedele al gemello.
fm() { awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f' "$1"; }
for o in "${OPEN[@]}"; do
  nome="$(basename "$o" .md)"; c="$HERE/.claude/agents/$nome.md"; [ -f "$c" ] || continue
  FO=$(fm "$o"); TC=$(fm "$c" | sed -n 's/^tools:[[:space:]]*//p')
  grep -qE '^tools:[[:space:]]*[A-Za-z]' <<<"$FO" && { ko "$nome: tools come stringa (forma Claude), OpenCode vuole una mappa"; continue; }
  grep -qE 'Edit|Write' <<<"$TC" && ATTESO=allow || ATTESO=deny
  grep -qE "^  edit: $ATTESO$" <<<"$FO" && ok "$nome: permission.edit = $ATTESO come il gemello Claude ($TC)" \
    || ko "$nome: permission.edit non e' $ATTESO (gemello: $TC)"
  grep -qw 'WebFetch' <<<"$TC" && AW=allow || AW=deny
  grep -qE "^  webfetch: $AW$" <<<"$FO" && ok "$nome: permission.webfetch = $AW" || ko "$nome: permission.webfetch non e' $AW"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
