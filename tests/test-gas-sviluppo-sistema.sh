#!/bin/bash
# test-gas-sviluppo-sistema.sh — 6° ciclo, "la rotta corretta" (2026-08-24): il parco
# REPO-E non è una cava di formule ma il CORPUS dell'esperienza. Questa skill porta
# quel corpus nell'hub. La guardia presidia: (1) provenienza dichiarata (l'autorità
# resta la skill gas-agent di REPO-E — il distillato non si spaccia per originale);
# (2) le regole non negoziabili ci sono tutte (clasp mai, banco prima, parità a
# livelli dichiarati, esegui-non-dedurre); (3) le famiglie portano POPOLAZIONI
# misurate (una famiglia senza numero è un'opinione); (4) i due agenti generali
# esistono e caricano per disclosure progressiva; (5) le due modalità
# consulenza/consegna sono distinte.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$HERE/.claude/skills/gas-sviluppo/SKILL.md"
METODO="$HERE/.claude/skills/gas-sviluppo/references/metodo.md"
FAMIGLIE="$HERE/.claude/skills/gas-sviluppo/references/famiglie-difetti.md"
CONSEGNA="$HERE/.claude/skills/gas-sviluppo/references/consegna.md"
DOMINI="$HERE/.claude/skills/gas-sviluppo/references/domini-gestionali.md"
DEV="$HERE/.claude/agents/sviluppatore-gas.md"
REV="$HERE/.claude/agents/revisore-gas.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# 1. struttura completa della skill
TUTTI=1
for f in "$SKILL" "$METODO" "$FAMIGLIE" "$CONSEGNA" "$DOMINI"; do
  [ -f "$f" ] || { ko "manca $f"; TUTTI=0; }
done
[ "$TUTTI" -eq 1 ] && ok "skill gas-sviluppo completa: SKILL + 4 references"

# 2. provenienza dichiarata: il distillato non si spaccia per originale
grep -q "gas-agent" "$SKILL" && grep -qi "l'autorità" "$SKILL" \
  && ok "provenienza dichiarata: l'autorità resta la skill gas-agent di REPO-E" \
  || ko "provenienza mancante: il distillato sembra originale"

# 3. le regole non negoziabili
grep -q "clasp push\` mai" "$SKILL" && grep -q "Esegui, non dedurre" "$SKILL" \
  && ok "SKILL: clasp mai + esegui non dedurre in testa" \
  || ko "SKILL: regole non negoziabili mancanti"
grep -q "il banco si scrive PRIMA della correzione" "$METODO" \
  && ok "metodo: il banco si scrive PRIMA" || ko "metodo: banco-prima mancante"
grep -q "PARITÀ" "$METODO" && grep -q "CORREZIONE" "$METODO" \
  && ok "metodo: i due gruppi di attese (PARITÀ+CORREZIONE)" || ko "metodo: gruppi attese mancanti"
grep -q "attese eseguite: N/M · fallite: K" "$METODO" \
  && ok "metodo: riga-verdetto unica canonica" || ko "metodo: riga-verdetto mancante"
grep -qi "codice di uscita NON è un verdetto" "$METODO" \
  && ok "metodo: exit code non è verdetto" || ko "metodo: exit-code mancante"

# 4. consegna: parità a livelli e cancello umano
grep -q "Livello" "$CONSEGNA" && grep -q "parità NON dimostrata" "$CONSEGNA" \
  && ok "consegna: 3 livelli di parità, il 3° dichiarato NON dimostrato" \
  || ko "consegna: livelli di parità incompleti"
grep -q "clasp" "$CONSEGNA" && grep -qi "mai, in nessuna circostanza" "$CONSEGNA" \
  && ok "consegna: clasp mai in nessuna circostanza" || ko "consegna: cancello clasp debole"

# 5. le famiglie portano POPOLAZIONI (numeri misurati, non impressioni)
N_POP=$(grep -cE "[0-9]+(/| su )[0-9]+|[0-9]+ (progetti|siti|webapp|su 80|su 93|occorrenze in)" "$FAMIGLIE")
[ "$N_POP" -ge 15 ] \
  && ok "famiglie: $N_POP popolazioni numeriche citate (misurate, non opinioni)" \
  || ko "famiglie: solo $N_POP popolazioni — il corpus ha perso i numeri"
grep -qi "domanda discriminante" "$FAMIGLIE" \
  && ok "famiglie: la domanda discriminante è dichiarata come criterio" \
  || ko "famiglie: manca il criterio del discriminante"
grep -q "Number('')" "$FAMIGLIE" && grep -q "nextLink" "$FAMIGLIE" \
  && grep -q "atHour" "$FAMIGLIE" && grep -q "0001-01-01" "$FAMIGLIE" \
  && ok "famiglie chiave presenti: confine numerico, paginazione, fascia oraria, sentinella" \
  || ko "famiglie: una famiglia chiave manca"

# 6. gli agenti generali: esistono e caricano progressivamente
[ -f "$DEV" ] && [ -f "$REV" ] && ok "agenti generali: sviluppatore-gas e revisore-gas" \
  || ko "agente generale mancante"
grep -q "gas-sviluppo" "$DEV" && grep -q "gas-sviluppo" "$REV" \
  && ok "gli agenti caricano il canone dalla skill (progressive disclosure)" \
  || ko "agente senza aggancio al canone"
grep -q "CONSULENZA" "$SKILL" && grep -q "CONSEGNA" "$SKILL" \
  && ok "le due modalità consulenza/consegna distinte in testa alla skill" \
  || ko "modalità non distinte"

# 7. privacy: nessun nome cliente nei file nuovi (i progetti REPO-E si citano come categoria)
if grep -rEq 'Brico|Hasslach|Egger|MaxiD|Golilla|Fibris|Teotto|Giovannini' "$HERE/.claude/skills/gas-sviluppo/" "$DEV" "$REV"; then
  ko "nomi di clienti nei file dell'hub (privacy: Public repo, private work)"
else
  ok "nessun nome cliente nei file del corpus (privacy)"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
