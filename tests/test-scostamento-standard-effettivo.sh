#!/bin/bash
# test-scostamento-standard-effettivo.sh — 4° ciclo, SET 1 giro 6. Secondo caso risolto
# con la skill controllo-gestione (giro 1): scostamento standard/effettivo, letto RIGA PER
# RIGA sul codice reale di un progetto di controllo di gestione produzione (repo esterno
# REPO-E, gas-src/) — non riassunto a memoria da un report. Prova che il metodo generalizza
# oltre il primo caso (riconciliazione magazzino, giro 1): stesso schema
# censimento->oracolo->input/output->verifica, dominio diverso. Aritmetica contata a mano
# (regola CLAUDE.md "L'aspettativa si deriva").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

RISULTATO=$(cd "$HERE" && python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from scostamento_standard_effettivo import media_pesata, calcola_scostamento, calcola_trend, valuta_alert

# 3 ordini di produzione, costo effettivo unitario e quantità, in ordine cronologico.
# mediaEff = (12.0*100 + 13.0*50 + 14.0*50) / 200 = (1200+650+700)/200 = 2550/200 = 12.75
odps = [
    {"costo_eff_unitario": 12.0, "qta_prodotta": 100.0},
    {"costo_eff_unitario": 13.0, "qta_prodotta": 50.0},
    {"costo_eff_unitario": 14.0, "qta_prodotta": 50.0},
]
media_eff = media_pesata(odps)
# scostPerc = ((12.75 - 10.0) / 10.0) * 100 = 27.5
scost = calcola_scostamento(10.0, media_eff)
alert = valuta_alert(10.0, len(odps), scost)

checks = []
checks.append(("media pesata effettiva = 12.75", abs(media_eff - 12.75) < 1e-9))
checks.append(("scostamento = +27.5%", abs(scost - 27.5) < 1e-9))
checks.append(("alert generato (soglia 10 superata)", alert is not None))
checks.append(("direzione = sopra (scostamento positivo)", alert and alert["direzione"] == "sopra"))
checks.append(("gravita = MEDIO (27.5 non supera 50)", alert and alert["gravita"] == "MEDIO"))

# variante: scostamento estremo -> gravita ALTO
alert_alto = valuta_alert(10.0, 3, 60.0)
checks.append(("gravita = ALTO quando |scostamento| > 50", alert_alto and alert_alto["gravita"] == "ALTO"))

# variante: sotto soglia -> nessun alert
checks.append(("nessun alert sotto soglia (5% < 10%)", valuta_alert(10.0, 3, 5.0) is None))

# variante: meno di 2 ordini -> nessun alert anche con scostamento alto
checks.append(("nessun alert con un solo OdP anche se lo scostamento è alto", valuta_alert(10.0, 1, 90.0) is None))

# l'oracolo richiede >=4 ordini per un verdetto di trend (odps.length < 4 -> insufficiente):
# con questi 3 ordini il trend deve restare DATI_INSUFFICIENTI, non un verdetto inventato
checks.append(("trend = DATI_INSUFFICIENTI con solo 3 ordini (l'oracolo richiede >=4)", calcola_trend(odps) == "DATI_INSUFFICIENTI"))

# con 4 ordini: prima meta = [12.0*50,12.0*50] -> media1 12.0
# seconda meta = [13.0*50,14.0*50] -> media2 = (650+700)/100 = 13.5
# variazione = ((13.5-12.0)/12.0)*100 = 12.5% > 5 -> IN_SALITA
odps_trend = [
    {"costo_eff_unitario": 12.0, "qta_prodotta": 50.0},
    {"costo_eff_unitario": 12.0, "qta_prodotta": 50.0},
    {"costo_eff_unitario": 13.0, "qta_prodotta": 50.0},
    {"costo_eff_unitario": 14.0, "qta_prodotta": 50.0},
]
checks.append(("trend = IN_SALITA con 4 ordini (12.5% > 5%)", calcola_trend(odps_trend) == "IN_SALITA"))
# con 4 ordini identici il trend è STABILE (variazione 0)
stabile = calcola_trend([{"costo_eff_unitario": 10.0, "qta_prodotta": 10.0}] * 4)
checks.append(("trend = STABILE su ordini identici", stabile == "STABILE"))

for nome, esito in checks:
    print(f"{'OK' if esito else 'KO'}\t{nome}")
PY
)
while IFS=$'\t' read -r stato nome; do
  if [ "$stato" = "OK" ]; then ok "$nome"; else ko "$nome"; fi
done <<< "$RISULTATO"

grep -q "REPO-E" "$HERE/tools/scostamento_standard_effettivo.py" \
  && ok "il tool cita la fonte reale della formula (per codice anonimo)" \
  || ko "il tool non cita più la fonte della formula"

# bug reale (revisione 14 lenti, 2026-08-28): costo_standard non passato da riga di
# comando diventava silenziosamente 0, indistinguibile da uno scostamento vero nullo.
# L'argomento mancante deve fallire con un errore, non un "nessuno scostamento" muto.
if printf 'costo_eff_unitario,qta_prodotta\n10,5\n' | python3 "$HERE/tools/scostamento_standard_effettivo.py" >/tmp/scost_out 2>&1; then
  ko "argomento costo_standard mancante: doveva fallire (exit != 0), è uscito con successo"
else
  ok "argomento costo_standard mancante: fallisce con errore (non più 'nessuno scostamento' silenzioso)"
fi
rm -f /tmp/scost_out

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
