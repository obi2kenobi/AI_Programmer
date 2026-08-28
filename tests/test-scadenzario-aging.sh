#!/bin/bash
# test-scadenzario-aging.sh — 5° ciclo, SET 1 giro 4. Quinto caso risolto con la skill
# controllo-gestione, quinto dominio diverso dai precedenti (magazzino, produzione,
# cespiti, crisi d'impresa): scadenzario clienti/fornitori (aging), letto riga per riga
# sul codice reale di un modulo di scadenzario (repo esterno REPO-E, gas-src/). Confini
# delle fasce e convenzione di segno fornitori derivati a mano PRIMA di eseguire il tool
# (regola CLAUDE.md "L'aspettativa si deriva").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

RISULTATO=$(cd "$HERE" && python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from scadenzario_aging import fascia_dettaglio, importo_fornitore, aggrega_totali

checks = []

# Confini esatti delle fasce (derivati a mano dal codice reale: <, non <=, ai limiti)
checks.append(("giorni=-61 -> SCADUTO >60", fascia_dettaglio(-61) == "SCADUTO >60"))
checks.append(("giorni=-60 -> SCADUTO 31-60 (limite: < non <=)", fascia_dettaglio(-60) == "SCADUTO 31-60"))
checks.append(("giorni=-31 -> SCADUTO 31-60", fascia_dettaglio(-31) == "SCADUTO 31-60"))
checks.append(("giorni=-30 -> SCADUTO <=30 (limite)", fascia_dettaglio(-30) == "SCADUTO <=30"))
checks.append(("giorni=-1 -> SCADUTO <=30", fascia_dettaglio(-1) == "SCADUTO <=30"))
checks.append(("giorni=0 -> BREVE (limite: 0 non e' scaduto)", fascia_dettaglio(0) == "BREVE"))
checks.append(("giorni=30 -> BREVE (limite <=30)", fascia_dettaglio(30) == "BREVE"))
checks.append(("giorni=31 -> MEDIO", fascia_dettaglio(31) == "MEDIO"))
checks.append(("giorni=90 -> MEDIO (limite <=90)", fascia_dettaglio(90) == "MEDIO"))
checks.append(("giorni=91 -> LUNGO", fascia_dettaglio(91) == "LUNGO"))
checks.append(("giorni assente -> LUNGO (nessuna data di scadenza)", fascia_dettaglio(None) == "LUNGO"))

# Convenzione di segno fornitori: fattura=uscita(negativo), nota credito=entrata(positivo)
checks.append(("fattura fornitore 300 -> -300 (uscita futura)", importo_fornitore(300, "Invoice") == -300))
checks.append(("Fattura (IT) 300 -> -300", importo_fornitore(300, "Fattura") == -300))
checks.append(("nota di credito 50 -> +50 (entrata)", importo_fornitore(50, "CreditMemo") == 50))
checks.append(("importo raw gia' negativo -> segno normalizzato comunque -20", importo_fornitore(-20, "Invoice") == -20))

# Aggregazione totali: 6 righe, riscontro a mano
# CLIENTE +1000 (SCADUTO>60) / +500 (SCADUTO31-60) / +200 (MEDIO) / +80 (LUNGO, no data)
# FORNITORE -300 (SCADUTO<=30, fattura) / +50 (BREVE, nota credito)
righe = [
    {"tipo": "CLIENTE", "importo": 1000.0, "fascia": fascia_dettaglio(-90)},
    {"tipo": "CLIENTE", "importo": 500.0, "fascia": fascia_dettaglio(-45)},
    {"tipo": "FORNITORE", "importo": importo_fornitore(300.0, "Invoice"), "fascia": fascia_dettaglio(-10)},
    {"tipo": "FORNITORE", "importo": importo_fornitore(50.0, "CreditMemo"), "fascia": fascia_dettaglio(15)},
    {"tipo": "CLIENTE", "importo": 200.0, "fascia": fascia_dettaglio(60)},
    {"tipo": "CLIENTE", "importo": 80.0, "fascia": fascia_dettaglio(None)},
]
r = aggrega_totali(righe)
# a mano: entrate = 1000+500+50+200+80 = 1830; uscite = -300; saldo = 1530
# scaduto_totale = 1000 (>60) + 500 (31-60) + (-300) (<=30) = 1200
checks.append(("entrate = 1830.00", abs(r["entrate"] - 1830.0) < 1e-9))
checks.append(("uscite = -300.00", abs(r["uscite"] - (-300.0)) < 1e-9))
checks.append(("saldo = 1530.00", abs(r["saldo"] - 1530.0) < 1e-9))
checks.append(("scaduto_totale = 1200.00 (due fasce scadute positive + una negativa)",
                abs(r["scaduto_totale"] - 1200.0) < 1e-9))
checks.append(("per_fascia BREVE = 50.00 (solo la nota credito fornitore)",
                abs(r["per_fascia"]["BREVE"] - 50.0) < 1e-9))
checks.append(("per_fascia LUNGO = 80.00 (riga senza data di scadenza)",
                abs(r["per_fascia"]["LUNGO"] - 80.0) < 1e-9))

for nome, esito in checks:
    print(f"{'OK' if esito else 'KO'}\t{nome}")
PY
)
while IFS=$'\t' read -r stato nome; do
  if [ "$stato" = "OK" ]; then ok "$nome"; else ko "$nome"; fi
done <<< "$RISULTATO"

grep -q "REPO-E" "$HERE/tools/scadenzario_aging.py" \
  && ok "il tool cita la fonte reale della formula (per codice anonimo)" \
  || ko "il tool non cita più la fonte della formula"

# Riscontro anche via CLI (main() che legge CSV da stdin) sulle prime due righe clienti
CLI_OUT=$(printf 'tipo,importo,giorni\nCLIENTE,1000,-90\nCLIENTE,500,-45\n' | python3 "$HERE/tools/scadenzario_aging.py")
echo "$CLI_OUT" | grep -q "Entrate: +1500.00€" \
  && ok "CLI: entrate = 1500.00€ su due righe cliente" \
  || ko "CLI: entrate inattese — output: $CLI_OUT"

# bug reale (revisione 14 lenti, 2026-08-28): importo_fornitore() era definita e testata
# in isolamento (sopra) ma MAI chiamata da main() — una riga fornitore attraversava la CLI
# col segno grezzo di BC, finendo in "entrate" invece che in "uscite". Il test CLI sopra
# non lo prendeva: usava solo righe cliente. Questo caso esercita il percorso vero.
CLI_OUT_FORN=$(printf 'tipo,importo,giorni\nFornitore Fattura,1000,10\n' | python3 "$HERE/tools/scadenzario_aging.py")
echo "$CLI_OUT_FORN" | grep -q "Uscite: -1000.00€" \
  && ok "CLI: fattura fornitore = uscita -1000.00€ (non entrata)" \
  || ko "CLI: segno fornitore non applicato — output: $CLI_OUT_FORN"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
