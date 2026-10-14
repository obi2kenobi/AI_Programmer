#!/bin/bash
# lente-scudo.sh — lo SCUDO: l'harness stesso come superficie d'attacco
# (furto da affaan-m/ECC «AgentShield»: scansiona prompt, hook, config, segreti
# del SISTEMA, non del codice che produce). Qui, declinato alla nostra casa:
# cinque controlli deterministici sull'hub — segreti negli script tracciati,
# integrita' dei ganci (drift da main = manomissione o stale), permessi della
# chiave, sporcizia tracciata, sanita' del profilo del turno.
#
# Uso: lente-scudo.sh [dir-hub]        (default: l'hub di questo script)
# Esce: 0 = scudo integro · 1 = rilievi (con cura scritta) · 2 = uso errato
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$HERE}"
cd "$DIR" || exit 2
RILIEVI=0
scudo() {  # scudo <esito:0|1> <riga>
  echo "$2"
  [ "$1" -eq 1 ] && RILIEVI=$((RILIEVI + 1))
}

# 1. segreti negli script tracciati (le SHAPES, la nostra unica lista)
if [ -f tools/privacy-check.sh ]; then
  SHAPES=$(sed -n "s/^SHAPES='\(.*\)'$/\1/p" tools/privacy-check.sh)
  if [ -n "$SHAPES" ]; then
    N=0
    while IFS= read -r f; do
      # esenti come nel pre-commit: giri-avversari CONTIENE le forme per prova
      case "$f" in tools/privacy-check.sh|tools/giri-avversari.sh|SAL-ARCHIVIO.md|repos.key) continue ;; esac
      C=$(grep -cE "$SHAPES" "$f" 2>/dev/null || true)
      N=$((N + C))
    done < <(git ls-files '*.sh' 2>/dev/null | head -400)
    [ "$N" -gt 0 ] && scudo 1 "1. SEGRETI: $N forme di segreto negli script tracciati — via dal codice (la lista vive solo in privacy-check)" \
                       || scudo 0 "1. segreti negli script: nessuno"
  fi
fi

# 2. integrita' dei ganci: i file dell'hub non devono divergere da main
DRIFT=$(git status --porcelain -- llm/ night-shift/ tools/ .githooks/ profiles/ 2>/dev/null | grep -c . || true)
if [ "${DRIFT:-0}" -gt 0 ]; then
  scudo 1 "2. GANCI: $DRIFT file dell'harness divergono da main (manomissione o lavoro non consegnato — guarda git status)"
else
  scudo 0 "2. ganci integri: harness allineato a main"
fi

# 3. la chiave delle repo: solo il padrone la legge
if [ -f night-shift/repos.key ]; then
  PERM=$(stat -f '%Lp' night-shift/repos.key 2>/dev/null || echo 644)
  case "$PERM" in 600|400) scudo 0 "3. chiave repos.key: permessi $PERM" ;; *) scudo 1 "3. CHIAVE: repos.key leggibile ($PERM) — chmod 600 night-shift/repos.key" ;; esac
else
  scudo 0 "3. repos.key assente (dichiarato)"
fi

# 4. sporcizia che non deve mai finire tracciata
SPORCO=""
for p in ".git/sacca" "consegna-fuori"; do :; done  # (i primi vivono in .git: gitnon li vede)
if git ls-files --error-unmatch graphify-out/.spina.log >/dev/null 2>&1; then SPORCO="$SPORCO spina.log"; fi
if [ -n "$(git status --porcelain -- night-shift/repos.conf 2>/dev/null)" ]; then :; fi  # repos.conf e' locale per design
[ -n "$SPORCO" ] && scudo 1 "4. SPORCIZIA tracciata:$SPORCO" || scudo 0 "4. sporcizia: nessuna tracciata"

# 5. il profilo del turno: il modello dichiarato esiste davvero in ollama
if [ -f profiles/notturno.conf ]; then
  MOD=$(sed -n 's/^MODELLO=//p' profiles/notturno.conf | head -1)
  if [ -n "$MOD" ] && command -v ollama >/dev/null 2>&1; then
    if ollama list 2>/dev/null | grep -qi "^$MOD "; then
      scudo 0 "5. profilo: MODELLO=$MOD presente in ollama"
    else
      scudo 1 "5. PROFILO: MODELLO=$MOD dichiarato ma ASSENTE in ollama (ollama pull $MOD) — la notte resterebbe muta"
    fi
  fi
fi

echo ""
[ "$RILIEVI" -eq 0 ] && { echo "SCUDO: INTEGRO"; exit 0; }
echo "SCUDO: $RILIEVI rilievi (cure scritte a fianco)"
exit 1
