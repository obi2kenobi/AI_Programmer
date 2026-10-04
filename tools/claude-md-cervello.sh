#!/bin/bash
# claude-md-cervello.sh — il CLAUDE.md SOTTILE del satellite: un puntatore al cervello.
#
# (2026-10-04, decisione di Luca: «il cervello del repo che Claude legge»).
# Il satellite NON ha una fotocopia delle regole: le legge dall'hub, sempre correnti.
# Niente più drift di CLAUDE.md, pattern, skills: un posto solo, un puntatore.
#
# Uso: claude-md-cervello.sh <dir-satellite>
# Scrive: <dir>/CLAUDE.md (il puntatore)
set -euo pipefail
DIR="${1:?uso: claude-md-cervello.sh <dir>}"
HUB="${2:-$HOME/night-shift-work/AI_Programmer}"

cat > "$DIR/CLAUDE.md" << 'CLAUDE'
# Questo repo lavora col metodo AI_Programmer

## REGOLE COMPLETE (leggile PRIMA di fare qualsiasi cosa)

Le regole vincolanti NON sono in questo file: vivono nel cervello centrale.

**PRIMA di iniziare qualsiasi lavoro, leggi:**
→ `~/.night-shift-work/AI_Programmer/CLAUDE.md` (le regole complete)

**Durante il lavoro, consulta:**
→ Skills: `~/.night-shift/AI_Programmer/.claude/skills/`
→ Patterns (lezioni apprese): `~/.night-shift-work/AI_Programmer/patterns/`
→ Registro errori: `~/.night-shift-work/AI_Programmer/docs/errori/REGISTRO.md`

**Perché così:** le regole cambiano ogni giorno. Una fotocopia invecchia. Il cervello è sempre corrente.

## Regole LOCALI di questo repo

Ogni repo può avere regole aggiuntive in `PROJECT.md` e `.night-verify`.
CLAUDE

echo "claude-md-cervello: CLAUDE.md sottile scritto in $DIR/CLAUDE.md"
echo "  (puntatore al cervello: $HUB)"
