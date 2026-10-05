#!/bin/bash
# adatta-night-verify.sh — scrive il .night-verify GIUSTO per ogni repo.
#
# (2026-10-04, Luca: «i nostri agenti e le nostre lenti sono adatti ai repo?»)
# L'installazione di massa ha lasciato .night-verify vuoti o senza comandi.
# Questo tool rileva il tipo di progetto (GAS, Python, JS) e scrive i gate
# appropriati: gas-gate per .gs, py-gate per .py, node --check per .js.
#
# Uso: adatta-night-verify.sh <dir-repo> (o senza argomenti per tutti i repo del turno)
set -uo pipefail
HUB="${ADATTA_HUB:-$(cd "$(dirname "$0")/.." && pwd)}"  # override per batch

adatta() { # adatta <dir>
  local DIR="$1"
  [ -d "$DIR/.git" ] || return 0
  cd "$DIR" || return 0
  local N=$(basename "$DIR")

  # rileva il tipo: conta i file
  local GS=$(find . -maxdepth 3 -name '*.gs' -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
  local PY=$(find . -maxdepth 3 -name '*.py' -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
  local JS=$(find . -maxdepth 3 -name '*.js' -not -path './.git/*' -not -path './node_modules/*' -not -path './graphify-out/*' 2>/dev/null | wc -l | tr -d ' ')
  local HTML=$(find . -maxdepth 3 -name '*.html' -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')

  # se non ci sono i gate nei tool, copiali dall'hub
  for T in gas-gate.sh py-gate.sh; do
    [ -f "$HUB/tools/$T" ] && [ ! -f "tools/$T" ] && cp "$HUB/tools/$T" "tools/$T" && chmod +x "tools/$T"
  done

  # costruisce il .night-verify
  local CMD=""
  [ "$GS" -gt 0 ] && CMD="bash tools/gas-gate.sh"
  [ "$PY" -gt 0 ] && CMD="${CMD:+$CMD
}bash tools/py-gate.sh"
  # JS: solo se ce ne sono tanti (> 5) e non sono gia' coperti da gas-gate (.html inline)
  if [ "$JS" -gt 5 ] && [ "$GS" -eq 0 ]; then
    CMD="${CMD:+$CMD
}for f in \$(find . -name '*.js' -not -path './.git/*' -not -path './node_modules/*' -maxdepth 3); do node --check \"\$f\" || exit 1; done"
  fi

  # se il .night-verify esiste e ha gia' comandi: NON toccare (lo ha definito il progetto)
  # (2026-10-05, lente del doppio zero): `grep -c ... || echo 0` qui dava «0\n0» —
  # non intero, il -gt sotto era errore-di-sintassi=falso. Forma canonica: || true + default.
  local HA_CMD=$(grep -cvE '^\s*#|^\s*$' .night-verify 2>/dev/null || true)
  HA_CMD=${HA_CMD:-0}
  if [ "$HA_CMD" -gt 0 ]; then
    echo "  ✓ $N: gia' configurato ($HA_CMD comandi)"
    return 0
  fi

  # scrivi il gate appropriato
  if [ -n "$CMD" ]; then
    cat > .night-verify << NV
# Verifiche del turno (adattate al tipo di progetto da adatta-night-verify.sh)
# GAS: $GS file · PY: $PY file · JS: $JS file · HTML: $HTML file
$CMD
NV
    echo "  ✓ $N: scritto ($([ $GS -gt 0 ] && echo "gas-gate ")$([ $PY -gt 0 ] && echo "py-gate")$([ $JS -gt 5 ] && [ $GS -eq 0 ] && echo " js-check"))"
  else
    echo "  ⚠ $N: nessun file codice ($GS .gs, $PY .py, $JS .js) — solo documenti?"
  fi

  # commit se qualcosa e' cambiato
  git add .night-verify tools/ 2>/dev/null
  git diff --cached --quiet 2>/dev/null || git commit -qm "chore: .night-verify adattato al tipo di progetto (auto-rilevato)" >/dev/null 2>&1
}

# con argomento: un solo repo; senza: tutti i repo nel repos.conf
if [ -n "${1:-}" ]; then
  adatta "$1"
else
  CONF="$HUB/night-shift/repos.conf"
  [ -f "$CONF" ] || { echo "usare: $0 <dir-repo> (o senza argomenti per tutti)"; exit 1; }
  while read -r REPO _t; do
    case "$REPO" in ''|'#'*) continue ;; esac
    NOME="${REPO##*/}"
    DIR="$HOME/night-shift-work/$NOME"
    [ -d "$DIR" ] || continue
    adatta "$DIR"
  done < "$CONF"
fi
