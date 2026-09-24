#!/bin/bash
# test-privacy.sh — privacy-check v2 sotto prova (giro 4/10).
# Il guardiano si prova quando DEVE fallire: si pianta una leak in un file temporaneo
# e il check deve vederla. Persone e termini aziendali oltre ai nomi di repo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# il check lavora su git ls-files: serve un repo git temporaneo col tool copiato
TMP=$(mktemp -d)
mkdir -p "$TMP/tools" "$TMP/night-shift"
cp "$HERE/tools/privacy-check.sh" "$TMP/tools/"
printf '# chiave di test\nREPO-T=finto/prova\nPERSONA=IlPagoDelleCose\nTERMINI=SuperSegretoAziendale\n' > "$TMP/night-shift/repos.key"
git -C "$TMP" init -q && git -C "$TMP" add tools/ && git -C "$TMP" -c user.email=t@t -c user.name=t commit -qm tools

# 1) pulito: passa
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "pulito: exit 0" || ko "pulito rc=$RC: $OUT"

# 2) leak di REPO nel file versionato → deve fallire
echo "guarda finto/prova" > "$TMP/docs.md" && git -C "$TMP" add docs.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "finto/prova\|NOME PRIVATO" <<<"$OUT" && ok "leak repo: FAIL con il nome citato" || ko "leak repo rc=$RC"
rm "$TMP/docs.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached docs.md

# 3) leak di PERSONA → deve fallire (nuovo in v2)
echo "chiesto a IlPagoDelleCose" > "$TMP/nota.md" && git -C "$TMP" add nota.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
if [ $RC -eq 1 ]; then ok "leak persona: FAIL (v2)"; elif grep -q "non ancora" <<<"$OUT"; then ko "v2 non implementata: $OUT"; else ko "persona rc=$RC"; fi
rm "$TMP/nota.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached nota.md

# 4) leak di TERMINE aziendale → deve fallire (nuovo in v2)
echo "progetto SuperSegretoAziendale" > "$TMP/x.md" && git -C "$TMP" add x.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && ok "leak termine: FAIL (v2)" || ko "termine rc=$RC"
rm "$TMP/x.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached x.md

# 5) la chiave stessa non è versionata → non conta come leak
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "la chiave locale non versionata non è leak" || ko "fine rc=$RC: $OUT"

# 6) v4 (2026-08-24, report dal campo): chiave ASSENTE = gate degradato, NON "pulito"
rm "$TMP/night-shift/repos.key"
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "GATE DEGRADATO" <<<"$OUT" \
  && ok "chiave assente: exit 1 con GATE DEGRADATO dichiarato (non 'pulito')" \
  || ko "chiave assente: rc=$RC — il gate cieco si spaccia ancora per pulito: $OUT"

# 6b) (revisione 10 giri, 2026-09-23): chiave assente ma FORMA di segreto piantata — le
# shapes devono girare comunque (commento A20 nel tool; decisione DEBITI 2026-09-23 «le
# SHAPES girano nel repo»). Prima l'uscita anticipata del degradato le saltava: il
# degradato taceva anche su un token vero.
echo "token ghp_ABCDEFGHIJKLMNOPQRSTUVWX" > "$TMP/fuga.md" && git -C "$TMP" add fuga.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "FORMA DI SEGRETO" <<<"$OUT" && grep -q "GATE DEGRADATO" <<<"$OUT" \
  && ok "chiave assente: le SHAPES girano comunque (forma vista) e il degradato resta dichiarato" \
  || ko "chiave assente: forma di segreto NON vista (rc=$RC): $OUT"
git -C "$TMP" rm -q --cached fuga.md; rm -f "$TMP/fuga.md"

# 6c) (revisione 10 giri): la forma cercata era `sk-ANTHROPIC`, che nessuna chiave vera ha —
# le chiavi Anthropic iniziano `sk-ant-`. Il token finto si compone a runtime: in questo file
# non c'e' nessuna stringa che somigli a una chiave.
PFX="sk-an""t-"; printf 'chiave %sFINTOFINTOFINTOFINTOFINTO\n' "$PFX" > "$TMP/fuga2.md" && git -C "$TMP" add fuga2.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1)
grep -q "FORMA DI SEGRETO" <<<"$OUT" && ok "chiave in forma sk-ant-… vista" || ko "chiave sk-ant-… NON vista: $OUT"
git -C "$TMP" rm -q --cached fuga2.md; rm -f "$TMP/fuga2.md"
# 6d) (2026-09-23, notte dei giri, T5#3): le forme di QUESTO parco — Google OAuth (clasp: la
# produzione), l'URL con credenziali, la chiave Zhipu nuda. Valori finti composti a runtime.
F20=ABCDEFGHIJKLMNOPQRST
for campione in "ya2""9.$F20" "1/""/0$F20" "GOCSP""X-$F20" "https://luca:$F20""@github.com/x" "$(printf '%032d' 7 | tr 0 a).$F20"; do
  printf 'x %s\n' "$campione" > "$TMP/fuga3.md" && git -C "$TMP" add fuga3.md
  grep -c "FORMA DI SEGRETO" <<<"$(bash "$TMP/tools/privacy-check.sh" 2>&1)" >/dev/null \
    && ok "forma vista: «${campione:0:8}…»" || ko "forma NON vista: «${campione:0:8}…»"
  git -C "$TMP" rm -q --cached fuga3.md; rm -f "$TMP/fuga3.md"
done

# 7) bug reale (revisione 14 lenti, 2026-08-28): repos.key SENZA newline finale — `while
# read` salta silenziosamente l'ultima riga, un nome sensibile su quella riga passava
# "pulito" per errore. printf senza \n finale riproduce esattamente il caso.
printf '# chiave di test\nREPO-T=finto/prova\nREPO-U=ultimo/senzanewline' > "$TMP/night-shift/repos.key"
echo "guarda ultimo/senzanewline" > "$TMP/leak-ultima-riga.md" && git -C "$TMP" add leak-ultima-riga.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "NOME PRIVATO" <<<"$OUT" \
  && ok "repos.key senza newline finale: ultima riga letta comunque, leak rilevato" \
  || ko "ultima riga di repos.key ignorata silenziosamente: rc=$RC — $OUT"
rm "$TMP/leak-ultima-riga.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached leak-ultima-riga.md

# 8) (2026-09-23, notte dei giri, T5#4): l'uscita del check finisce nell'issue «[banco]» del repo
# PUBBLICO (banco-passaggio -> night-shift.sh). Il tripwire stampava il termine che proteggeva: ora
# ne stampa l'impronta (CLAUDE.md «Mask, don't omit»), sia per repos.key sia per ~/.privacy-nomi.
printf 'TERMINI=SuperSegretoAziendale\n' > "$TMP/night-shift/repos.key"
mkdir -p "$TMP/casa"; printf 'FornitoreRiservato\n' > "$TMP/casa/.privacy-nomi"
printf 'SuperSegretoAziendale e FornitoreRiservato\n' > "$TMP/SuperSegretoAziendale.md" && git -C "$TMP" add SuperSegretoAziendale.md
OUT=$(HOME="$TMP/casa" bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -c "TERMINE PRIVATO" <<<"$OUT" >/dev/null && grep -c "lista locale" <<<"$OUT" >/dev/null \
  && ok "leak di termine e di nome locale: vista (rc 1)" || ko "leak non vista rc=$RC: $OUT"
grep -cE "SuperSegretoAziendale|FornitoreRiservato" <<<"$OUT" >/dev/null \
  && ko "l'uscita porta il termine protetto in chiaro: $(grep -cE 'SuperSegretoAziendale|FornitoreRiservato' <<<"$OUT") righe" \
  || ok "l'uscita non porta il termine protetto in chiaro"
[ "$(grep -cE '«termine [0-9a-f]{8} · [0-9]+ caratteri»' <<<"$OUT")" -ge 2 ] \
  && ok "al posto del termine, la sua impronta («termine <sha8> · N caratteri»)" || ko "impronta assente: $OUT"
grep -c "NOME PRIVATO NEL REPO" <<<"$OUT" >/dev/null && ko "un TERMINE riportato anche come NOME di repo" \
  || ok "un termine si riporta come TERMINE, non anche come nome di repo"
git -C "$TMP" rm -q --cached SuperSegretoAziendale.md

rm -rf "$TMP"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
