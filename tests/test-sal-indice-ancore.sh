#!/bin/bash
# test-sal-indice-ancore.sh — banco di regressione nato dalla revisione "L'Hub Allo
# Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in tools/sal-indice.sh, il
# generatore di ancore ([^a-z0-9]+) non traslitterava le lettere accentate italiane —
# "città" generava il link "#citt" invece di "#citt%C3%A0"/"#città", non corrispondente
# all'ancora reale che GitHub assegna allo stesso heading. Difetto ricorrente in un diario
# scritto in italiano (città, già, così, perché, più...). Nessun test esisteva.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/tools"
cp "$HERE/tools/sal-indice.sh" "$TMP/tools/"
printf '# Titolo\n\nintro\n\n### Terzo giro: nuova funzionalità\n\ncontenuto\n\n### Perché è così\n\naltro\n' > "$TMP/SAL.md"

OUT=$(bash "$TMP/tools/sal-indice.sh" 2>&1)
grep -q "indice rigenerato: 2 voci" <<<"$OUT" \
  && ok "indice rigenerato con 2 voci" \
  || ko "rigenerazione indice fallita: $OUT"

grep -q '\[Terzo giro: nuova funzionalità\](#terzo-giro-nuova-funzionalità)' "$TMP/SAL.md" \
  && ok "ancora con 'à' preservata (non 'terzo-giro-nuova-funzionalit')" \
  || ko "ancora con lettera accentata rotta — riga: $(grep 'Terzo giro' "$TMP/SAL.md")"

grep -q '\[Perché è così\](#perché-è-così)' "$TMP/SAL.md" \
  && ok "ancora con 'é'/'è'/'ì' preservate" \
  || ko "ancora con più accenti rotta — riga: $(grep 'Perché' "$TMP/SAL.md")"

# (giro 25, 2026-09-20 — D38): un titolo > 130 caratteri spariva dall'indice in silenzio
LUNGO="Titolo lunghissimo $(printf 'x%.0s' $(seq 1 140))"
printf '# T\n\nintro\n\n### %s\n\ncorpo\n' "$LUNGO" > "$TMP/SAL.md"
OUT=$(bash "$TMP/tools/sal-indice.sh" 2>&1)
grep -qF "[$LUNGO](" "$TMP/SAL.md" && ok "titolo di $(printf '%s' "$LUNGO" | wc -c | tr -d ' ') caratteri indicizzato (non scartato)" || ko "titolo lungo scartato dall'indice"
grep -q "titolo lungo" <<<"$OUT" && ok "il titolo lungo e' DICHIARATO (canone <=130), non taciuto" || ko "titolo lungo indicizzato senza avviso"
cp "$HERE/tools/sal-indice.sh" "$TMP/tools/"

# giri avversari 2026-08-28 (A19): il marker del SAL VERO poteva essere
# sostituito senza che nessun test diventasse rosso (questo test prova solo
# fixture). Il marker è il contratto con sal-indice.sh: senza, la rigenerazione
# duplica l'indice invece di sostituirlo.
grep -q "<!-- SAL-INDICE: generato da tools/sal-indice.sh" "$HERE/SAL.md" \
  && ok "il SAL vero porta il marker dell'indice" \
  || ko "il SAL vero ha perso il marker SAL-INDICE (sal-indice duplicherebbe)"

# (2026-09-24, quinto ventaglio, R1 R4): l'ancora fondeva ogni gruppo di non-parola in UN trattino. GitHub
# toglie la punteggiatura e fa di OGNI spazio un trattino, senza fondere: «(8) — l'hub: n.2» da' «8--lhub-n2».
# Sul diario vero 146 link su 146 non combaciavano. ASSUNTO dichiarato: l'algoritmo e' quello di
# github-slugger (la libreria di riferimento), non verificato contro github.com da questa sessione.
printf '# T\n\nintro\n\n### 2026-08-27 (8) — l'"'"'hub: n.2\n\nx\n\n### Doppio\n\ny\n\n### Doppio\n\nz\n' > "$TMP/SAL.md"
bash "$TMP/tools/sal-indice.sh" >/dev/null 2>&1
grep -c '](#2026-08-27-8--lhub-n2)' "$TMP/SAL.md" >/dev/null && ok "R1 R4: punteggiatura tolta, ogni spazio un trattino (8--lhub-n2)" \
  || ko "R1 R4: ancora non GitHub — $(grep '2026-08-27' "$TMP/SAL.md" | head -1)"
grep -c '](#doppio-1)' "$TMP/SAL.md" >/dev/null && ok "R1 R4: il secondo titolo uguale prende il suffisso -1, come su GitHub" \
  || ko "R1 R4: duplicati senza suffisso — $(grep -c '](#doppio)' "$TMP/SAL.md") link a #doppio"

# (2026-09-24, quinto ventaglio, R1 R5): l'indice di SAL-ARCHIVIO.md non lo rigenerava nessuno — copiato alla
# separazione, 30 link su 167 puntavano a voci rimaste in SAL.md. Ora il tool rigenera anche l'archivio.
printf '# T\n\nintro\n\n### Voce del diario\n\nx\n' > "$TMP/SAL.md"
printf '# A\n\nintro\n\n<!-- SAL-INDICE: generato da tools/sal-indice.sh — non editare a mano -->\n## Indice del diario\n\n- [Voce del diario](#voce-del-diario)\n\n### Voce archiviata\n\ny\n' > "$TMP/SAL-ARCHIVIO.md"
bash "$TMP/tools/sal-indice.sh" >/dev/null 2>&1
grep -c '](#voce-archiviata)' "$TMP/SAL-ARCHIVIO.md" >/dev/null && ! grep -c '](#voce-del-diario)' "$TMP/SAL-ARCHIVIO.md" >/dev/null \
  && ok "R1 R5: l'indice dell'archivio elenca le sue voci, non quelle del diario" || ko "R1 R5: indice dell'archivio fermo: $(grep '^- \[' "$TMP/SAL-ARCHIVIO.md" | tr '\n' ' ')"
# sul vero: ogni link dei due indici ha la sua voce nello stesso file
for F in SAL.md SAL-ARCHIVIO.md; do
  MORTI=$(python3 - "$HERE/$F" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
def slug(v): return re.sub(r"[^\w\- ]", "", v.lower()).replace(" ", "-")
visti, ancore = {}, set()
for h in re.findall(r"^#{1,6} (.+?)\s*$", t, flags=re.M):
    b = slug(h); n = visti.get(b, 0); visti[b] = n + 1
    ancore.add(b if n == 0 else f"{b}-{n}")
link = re.findall(r"^- \[.*\]\(#([^)]+)\)$", t, flags=re.M)
print(sum(1 for l in link if l not in ancore))
PY
)
  [ "$MORTI" = 0 ] && ok "R1 R4-R5: $F — nessun link dell'indice senza la sua voce" || ko "R1 R4-R5: $F — $MORTI link senza voce"
done

# (2026-09-24, sesto ventaglio, S4 R1): sal-indice riscriveva SAL.md sul posto (`open(…,"w")` tronca prima di
# scrivere) — ucciso durante la scrittura, o col disco pieno, SAL.md restava a 0 byte, con la voce nuova non
# ancora committata persa; e il giro dopo diceva «nessuna voce ### trovata», rc 0. Ora scrivi-e-rinomina, e un SAL
# vuoto si rifiuta. Il kill lo mette strace nel punto esatto (senza strace, come sul Mac: saltato e detto).
printf '# T\n\nintro\n\n### Voce del giorno, non committata\n\nlavoro\n' > "$TMP/SAL.md"; rm -f "$TMP/SAL-ARCHIVIO.md"
if command -v strace >/dev/null 2>&1; then
  strace -f -o /dev/null -P "$TMP/SAL.md" -e trace=write -e inject=write:signal=KILL bash "$TMP/tools/sal-indice.sh" >/dev/null 2>&1
  grep -c 'Voce del giorno' "$TMP/SAL.md" >/dev/null && ok "S4 R1: ucciso mentre scrive, SAL.md ha ancora la sua voce" || ko "S4 R1: kill a meta' scrittura: SAL.md = $(wc -c < "$TMP/SAL.md") byte"
else
  echo "⊘ S4 R1: strace assente — il kill a meta' scrittura non si prova qui (dichiarato)"
fi
: > "$TMP/SAL.md"; OUT=$(bash "$TMP/tools/sal-indice.sh" 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -ci 'vuoto' <<<"$OUT" >/dev/null && ok "S4 R1: un SAL vuoto si rifiuta (rc $RC), non «nessuna voce»" || ko "S4 R1: SAL vuoto: rc $RC — $OUT"

# (2026-09-24, sesto ventaglio, S2 R6): su un SAL nuovo (senza indice) il secondo giro aggiungeva una riga vuota fra
# l'indice e la prima voce, e solo il terzo convergeva. Due giri di fila: lo stesso file.
printf '# T\n\nintro\n\n### Prima voce\n\nx\n' > "$TMP/SAL.md"; rm -f "$TMP/SAL-ARCHIVIO.md"
bash "$TMP/tools/sal-indice.sh" >/dev/null 2>&1; M1=$(cksum < "$TMP/SAL.md")
bash "$TMP/tools/sal-indice.sh" >/dev/null 2>&1; M2=$(cksum < "$TMP/SAL.md")
[ "$M1" = "$M2" ] && ok "S2 R6: il secondo giro su un SAL nuovo non cambia niente" || ko "S2 R6: il secondo giro cambia il SAL: $(diff <(bash -c true) /dev/null; echo "$M1 → $M2")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
