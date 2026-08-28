#!/bin/bash
# status-page.sh — una pagina HTML locale con tutto il sistema a colpo d'occhio (giro 7/10).
# Genera ~/ai-programmer-status.html e lo apre nel browser.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HOME/ai-programmer-status.html"

# I quattro blocchi della pagina sono le quattro domande del mattino: come sta
# il sistema (health), cosa dice l'ultimo gate (summary), quando ha girato
# l'ultimo turno notturno, quando l'ultimo gate mattutino. Se un blocco è
# "mai eseguito" la pagina lo dice invece di nasconderlo: l'assenza di dato
# è un dato.
HEALTH=$(bash "$HERE/tools/system-health.sh" 2>/dev/null | sed 's/&/\&amp;/g; s/</\&lt;/g' | head -30)
SUMMARY=$(bash "$HERE/night-shift/gate-summary.sh" 1 2>/dev/null | sed 's/&/\&amp;/g; s/</\&lt;/g' | head -20)
ULTIMO_TURNO=$(grep -aE "TURNO FINITO" ~/night-shift.log 2>/dev/null | tail -1 | sed 's/&/\&amp;/g' || echo "mai eseguito")
ULTIMO_GATE=$(grep -aE "Gate completato" ~/morning-gate.log 2>/dev/null | tail -1 | sed 's/&/\&amp;/g' || echo "mai eseguito")
NOW=$(date '+%Y-%m-%d %H:%M')

cat > "$OUT" <<HTML
<!DOCTYPE html>
<html lang="it"><head><meta charset="utf-8"><title>AI_Programmer — Status</title>
<style>
body{font-family:system-ui,sans-serif;background:#1a1a2e;color:#e0e0e0;margin:0;padding:24px;max-width:900px;margin:0 auto}
h1{color:#8be9fd;font-size:20px} h2{color:#bd93f9;font-size:16px;margin-top:24px}
pre{background:#282a36;border-radius:8px;padding:16px;font-size:12px;overflow-x:auto;line-height:1.5;color:#f8f8f2}
.timestamp{color:#6272a4;font-size:12px;margin-bottom:20px}
a{color:#8be9fd}
</style></head><body>
<h1>🧠 AI_Programmer — Status</h1>
<p class="timestamp">generato: $NOW · <a href="#" onclick="location.reload();return false">aggiorna</a></p>
<h2>Ultimo turno notturno</h2><pre>$ULTIMO_TURNO</pre>
<h2>Ultimo gate</h2><pre>$ULTIMO_GATE</pre>
<h2>Salute</h2><pre>$HEALTH</pre>
<h2>Metriche</h2><pre>$SUMMARY</pre>
</body></html>
HTML
# NOOPEN=1 (test): genera la pagina senza aprire il browser
if [ "${NOOPEN:-0}" = "1" ]; then echo "pagina generata (no browser): $OUT"
else open "$OUT" 2>/dev/null || echo "pagina generata: $OUT"; fi
