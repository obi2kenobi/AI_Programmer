#!/bin/bash
# test-indici-crisi.sh — 4° ciclo, SET 1 giro 10. Quarto caso risolto con la skill
# controllo-gestione, quarto dominio diverso (dopo magazzino, produzione, cespiti): indici
# della crisi d'impresa (CNDCEC/CCII), la lettura "temi economico-industriali" più diretta
# fra quelle chieste. Le soglie sono pubbliche (CNDCEC, settore ATECO G46) — non un dato
# aziendale — verificate leggendo l'oracolo riga per riga. I tre scenari di test qui sotto
# non sono inventati: sono gli STESSI tre scenari già validati nel Test.js dell'oracolo
# (azienda sana, caso limite sulla soglia "le", caso ricavi/attivo a zero) — riscontro
# doppio: contro l'oracolo E contro l'aritmetica derivata a mano.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

RISULTATO=$(cd "$HERE" && python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from indici_crisi import valuta_indici_crisi, crisi_presunta

checks = []

# Scenario 1 (oracolo: "sana") — azienda sana su tutti e cinque, nessun allarme.
sana = {"oneriFin": 10, "ricavi": 10000, "pn": 500000, "passivoTot": 1000000,
        "cashFlow": 50000, "attivo": 1000000, "attCorrenti": 800000, "passCorrenti": 400000,
        "debTrib": 1000, "debPrev": 1000}
i_sana = valuta_indici_crisi(sana)
checks.append(("sana: zero indici in allarme", sum(1 for i in i_sana if i["allarme"]) == 0))
checks.append(("sana: liquidità = attCorrenti/passCorrenti*100 = 200.0%",
                round(i_sana[3]["valore"], 1) == 200.0))
checks.append(("sana: nessuna presunzione di crisi", crisi_presunta(sana["pn"], i_sana) is False))

# Scenario 2 (oracolo: "alLimite") — cash flow ESATTAMENTE alla soglia 0.6 (verso "le"
# include il valore: un < al posto di <= toglierebbe l'allarme al caso limite).
al_limite = {"oneriFin": 0, "ricavi": 100, "pn": 1, "passivoTot": 100,
             "cashFlow": 0.6, "attivo": 100, "attCorrenti": 1, "passCorrenti": 100,
             "debTrib": 0, "debPrev": 0}
i_limite = valuta_indici_crisi(al_limite)
checks.append(("al limite: cash flow esattamente alla soglia -> allarme (<=, non <)",
                i_limite[2]["allarme"] is True))

# Scenario 3 (oracolo: "senzaRicavi") — ricavi e attivo a zero: pct(n,0)=0, i due indici
# "ge" non possono scattare (limite noto dell'oracolo, non un difetto di questo tool).
senza_ricavi = {"oneriFin": 5000, "ricavi": 0, "pn": -1, "passivoTot": 100,
                "cashFlow": -1, "attivo": 0, "attCorrenti": 1, "passCorrenti": 100,
                "debTrib": 50, "debPrev": 50}
i_senza = valuta_indici_crisi(senza_ricavi)
checks.append(("senza ricavi: oneri/ricavi NON scatta (0/0 = 0, limite noto di pct)",
                i_senza[0]["allarme"] is False))
checks.append(("senza ricavi: esattamente 3 indici in allarme (mai tutti e 5 in questo caso)",
                sum(1 for i in i_senza if i["allarme"]) == 3))
# PN negativo fa presunzione DA SOLO, anche con soli 3/5 indici in allarme
checks.append(("senza ricavi: PN negativo -> crisi presunta comunque (da solo, non serve il 5/5)",
                crisi_presunta(senza_ricavi["pn"], i_senza) is True))

# Variante propria: 4 indici su 5 in allarme, PN positivo -> NON basta (serve tutti e 5)
# a mano: oneriFinRicavi=10% (ge 2.1 TRUE), pnDebiti=1% (le 6.3 TRUE),
# cashFlowAttivo=0% (le 0.6 TRUE), liquidita=1% (le 101.4 TRUE),
# tribPrevAttivo=0% (ge 2.9 FALSE, debTrib=debPrev=0) -> esattamente 4/5
quattro_su_cinque = {"oneriFin": 10, "ricavi": 100, "pn": 1, "passivoTot": 100,
                      "cashFlow": 0, "attivo": 100, "attCorrenti": 1, "passCorrenti": 100,
                      "debTrib": 0, "debPrev": 0}
i_4su5 = valuta_indici_crisi(quattro_su_cinque)
n_allarmi = sum(1 for i in i_4su5 if i["allarme"])
checks.append(("4 indici su 5 in allarme, PN positivo -> NESSUNA presunzione (serve 5/5)",
                n_allarmi < 5 and crisi_presunta(quattro_su_cinque["pn"], i_4su5) is False))

for nome, esito in checks:
    print(f"{'OK' if esito else 'KO'}\t{nome}")
PY
)
while IFS=$'\t' read -r stato nome; do
  if [ "$stato" = "OK" ]; then ok "$nome"; else ko "$nome"; fi
done <<< "$RISULTATO"

grep -q "REPO-E" "$HERE/tools/indici_crisi.py" \
  && ok "il tool cita la fonte reale della formula (per codice anonimo)" \
  || ko "il tool non cita più la fonte della formula"

grep -q "CNDCEC" "$HERE/tools/indici_crisi.py" \
  && ok "le soglie sono attribuite alla fonte regolatoria pubblica (non spacciate per invenzione)" \
  || ko "le soglie non citano più la fonte regolatoria"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
