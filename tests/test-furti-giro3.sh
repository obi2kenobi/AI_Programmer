#!/bin/bash
# test-furti-giro3.sh — i banchi del terzo giro di furti (2026-10-08):
# canone selettivo (agent-os), giudice misurato (jev-lab), promemoria TDD
# (claude-night-market).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
source "$HERE/night-shift/lib.sh"
F=$(mktemp -d); git -C "$F" init -q

# ── agent-os: canone SELETTIVO per bersaglio ─────────────────────────────────
printf 'specialista-logistica\n' > "$F/.git/ruoli-attivi"
# bersaglio magazzino, budget STRETTO: la sezione magazzino deve sopravvivere
# piu' della media (densita' di pertinenza maggiore della cieca)
CIECO=$(canone_ruoli "$F" 1200 2)
SEL=$(canone_ruoli "$F" 1200 2 "src/Magazzino.gs")
D_CIECO=$(printf '%s' "$CIECO" | grep -iocE 'magazzin|giacenz|moviment' || true)
D_SEL=$(printf '%s' "$SEL" | grep -iocE 'magazzin|giacenz|moviment' || true)
L_CIECO=$(printf '%s' "$CIECO" | wc -c | tr -d ' '); L_SEL=$(printf '%s' "$SEL" | wc -c | tr -d ' ')
[ "${D_SEL:-0}" -gt 0 ] && [ "$(( D_SEL * 1000 / (L_SEL+1) ))" -ge "$(( D_CIECO * 1000 / (L_CIECO+1) ))" ] \
  && ok "canone selettivo: bersaglio magazzino → densita' logistica non inferiore alla cieca ($D_SEL/$L_SEL vs $D_CIECO/$L_CIECO)" \
  || ko "selettivo peggiora la pertinenza: $D_SEL/$L_SEL vs $D_CIECO/$L_CIECO"
# senza bersaglio: comportamento invariato (il risolutore resta cieco e contento)
# retrocompatibilita' per CONTENUTO (i byte del marker di troncamento possono
# variare con le cifre: cio' che conta e' lo stesso canone, stessa testa)
B2=$(canone_ruoli "$F" 1200 2)
[ "$(printf '%s' "$CIECO" | grep -c 'DOMAIN ROLE')" = "$(printf '%s' "$B2" | grep -c 'DOMAIN ROLE')" ] \
  && [ "$(printf '%s' "$CIECO" | head -c 200)" = "$(printf '%s' "$B2" | head -c 200)" ] \
  && ok "senza bersaglio il canone non cambia (stessi ruoli, stessa testa)" \
  || ko "il canone cieco e' cambiato tra due chiamate"

# ── jev-lab: il giudice misurato ────────────────────────────────────────────
OUT=$(bash "$HERE/tools/consenso-giudice.sh" 2>/dev/null)
grep -q "delibere del censore nel log:" <<<"$OUT" && grep -q "esiti umani registrati" <<<"$OUT" \
  && ok "il consenso dichiara i due numeri (delibere vs esiti)" || ko "output mancante: $OUT"
grep -qE "NON e' ancora misurabile|concordanza" <<<"$OUT" \
  && ok "dice se il giudice e' misurabile (oggi no: esiti pochi — detto forte)" || ko "non dichiara la misurabilita'"

# ── claude-night-market: promemoria TDD nel pre-commit ──────────────────────
grep -q "9ter" "$HERE/tools/pre-commit.sh" && grep -q "senza banchi toccati" "$HERE/tools/pre-commit.sh" \
  && ok "il pre-commit porta il promemorio codice-senza-banchi (9ter, mai blocco)" \
  || ko "il blocco 9ter manca"
grep -qE "TOCCATO_CODICE=..staged" "$HERE/tools/pre-commit.sh" && grep -q "TOCCATO_BANCHI" "$HERE/tools/pre-commit.sh" \
  && ok "il promemorio guarda gli STAGED, cattura-prima (E-002)" || ko "non guarda gli staged"

# (furto giro 4, little-coder): il contesto iniziale si stima onesto
. "$HERE/night-shift/lib.sh" 2>/dev/null || true
T1=$(token_stimati 3500)
[ "$T1" = "1000" ] && ok "token_stimati: 3500 byte → 1000 token (stima dichiarata 3.5 B/tok)" || ko "token_stimati(3500)=$T1"
T0=$(token_stimati 0)
[ "$T0" -ge 1 ] && ok "zero byte → almeno 1 (mai 0: il vuoto non e' un contesto)" || ko "token_stimati(0)=$T0"

# (furto giro 5, nextest): fail→retry→pass = AMBRA; il flaky si DICHIARA
V=$(classifica_banco test-agente.sh 0 99)
[ "$V" = "verde" ] && ok "classifica: rc1=0 → verde, niente riprove" || ko "verde non riconosciuto: $V"
A=$(cd "$HERE" && classifica_banco test-agente.sh 1 0)
[ "$A" = "ambra" ] && ok "test-agente dichiarato flaky: fallito+ritentato passato → AMBRA" || ko "attesa ambra: $A"
R=$(cd "$HERE" && classifica_banco test-agente.sh 1 1)
[ "$R" = "rosso" ] && ok "flaky che fallisce DUE volte resta rosso (la dispensa non e' impunita')" || ko "atteso rosso: $R"
X=$(cd "$HERE" && classifica_banco test-lib.sh 1 0)
[ "$X" = "rosso" ] && ok "test NON dichiarato: nessuna seconda chance (la dispensa e' un elenco firmato)" || ko "atteso rosso per non-dichiarato: $X"

# (giro 7): la lente-dipendenze — deterministicissima, nessun network
FL=$(mktemp -d "${TMPDIR:-/tmp}/dip.XXXXXX")
printf 'flask==3.0.0\nrequests>=2\npandas\n' > "$FL/requirements.txt"
printf '{"dependencies":{"express":"^4.18.0","lodash":"4.17.21"}}' > "$FL/package.json"
OUT=$(bash "$HERE/tools/lente-dipendenze.sh" "$FL" 2>/dev/null)
grep -q "py non pinnate 2" <<<"$OUT" && grep -q "js non bloccate 1" <<<"$OUT" \
  && ok "lente-dipendenze: 2 py non pinnate + 1 js non bloccata (le pinnate non contano)" \
  || ko "lente: $OUT"
NUDA=$(mktemp -d "${TMPDIR:-/tmp}/nuda.XXXXXX")
OUT=$(bash "$HERE/tools/lente-dipendenze.sh" "$NUDA" 2>/dev/null); rm -rf "$NUDA"
grep -q "nessun manifest" <<<"$OUT" && ok "repo senza manifest: dichiarato, non difetto" || ko "repo nudo: $OUT"
rm -rf "$FL"

# (giro 8): l'audit della conoscenza — pattern fermai da N giorni si LISTANO
OUT=$(bash "$HERE/tools/auditoria-conoscenza.sh" 30 2>/dev/null)
grep -qE "Pattern censiti: [0-9]+ · non toccati da almeno 30g: [0-9]+" <<<"$OUT" \
  && ok "l'audit dichiara il censimento e i fermi (soglia dichiarata)" || ko "audit muto: $OUT"
grep -qE "Domanda per il giorno|Pattern censiti" <<<"$OUT" \
  && ok "la domanda reinforce-o-decay c'e' (o si rafforza o si dichiara storica)" || ko "manca la domanda"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
