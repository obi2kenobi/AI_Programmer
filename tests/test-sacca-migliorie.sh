#!/bin/bash
# test-sacca-migliorie.sh — la SACCA delle micro-migliorie: accumulo, soglia, spedizione,
# template di flotta. Tutto deterministico (repo scratch + patch), nessun modello.
# Nato dalla domanda di Luca (2026-10-09): «ma ha senso pubblicare un PR di fatto vuoto?»
# — misurato: 19 PR di caccia su 21 erano +2/-1 cosmetiche. Ora sotto soglia si accumula.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SM="$HERE/tools/sacca-migliorie.sh"
NS="$HERE/night-shift/night-shift.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$SM" && ok "sintassi" || { ko "sintassi"; exit 1; }

nuova_repo() {  # $1=dir
  git -C "$1" init -q
  git -C "$1" -c user.name=t -c user.email=t@t commit -qm init --allow-empty
}

SB=$(mktemp -d /tmp/test-sacca.XXXXXX)
trap 'rm -rf "$SB"' EXIT

# ── fixture: repo con due file ────────────────────────────────────────────────────
R="$SB/repo"; mkdir -p "$R"; nuova_repo "$R"
printf 'function alpha(x) {\n  return x + 1;\n}\n' > "$R/a.js"
printf 'function beta(y) {\n  return y * 2;\n}\n' > "$R/b.js"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm file

# ── accumula: il diff del working tree diventa patch + riga d'indice ─────────────
printf '// documenta alpha\n' >> "$R/a.js"
if ACC=$(bash "$SM" accumula "$R" docs a.js 2>&1); then
  [ -f "$R/.git/sacca/0001.patch" ] && ok "accumula: patch 0001 memorizzata" || ko "accumula: patch 0001 memorizzata"
  [ "$(grep -c . "$R/.git/sacca/indice")" -eq 1 ] && ok "accumula: indice una riga" || ko "accumula: indice una riga"
  grep -q "SACCA" <<<"$ACC" && ok "accumula: esito dichiarato in stdout" || ko "accumula: esito dichiarato in stdout"
else ko "accumula: rc 0"; fi

# accumula senza diff: rc 1 dichiarato
git -C "$R" reset -q --hard
if bash "$SM" accumula "$R" docs a.js >/dev/null 2>&1; then ko "accumula senza diff: rc 1"; else ok "accumula senza diff: rc 1"; fi

# ── pronta: sotto soglia rc 1; a 3 patch rc 0 ────────────────────────────────────
if bash "$SM" pronta "$R" 2>/dev/null; then ko "pronta: rc 1 sotto soglia (1 patch)"; else ok "pronta: rc 1 sotto soglia (1 patch)"; fi
printf '// documenta beta\n' >> "$R/b.js"
bash "$SM" accumula "$R" docs b.js >/dev/null 2>&1
if bash "$SM" pronta "$R" 2>/dev/null; then ko "pronta: rc 1 a 2 patch"; else ok "pronta: rc 1 a 2 patch"; fi
printf '// terza micro-miglioria\n' >> "$R/a.js"
bash "$SM" accumula "$R" semplice a.js >/dev/null 2>&1
if bash "$SM" pronta "$R" 2>/dev/null; then ok "pronta: rc 0 a 3 patch (soglia numero)"; else ko "pronta: rc 0 a 3 patch (soglia numero)"; fi

# ── pronta per RIGHE: 2 patch che insieme superano 10 righe ──────────────────────
R2="$SB/repo2"; mkdir -p "$R2"; nuova_repo "$R2"
printf 'uno\ndue\ntre\n' > "$R2/x.js"
git -C "$R2" add -A && git -C "$R2" -c user.name=t -c user.email=t@t commit -qm file
for i in 1 2 3 4 5 6; do printf 'riga %s\n' "$i" >> "$R2/x.js"; done
bash "$SM" accumula "$R2" semplice x.js >/dev/null 2>&1
git -C "$R2" reset -q --hard
for i in 7 8 9 10 11 12; do printf 'riga %s\n' "$i" >> "$R2/x.js"; done
bash "$SM" accumula "$R2" semplice x.js >/dev/null 2>&1
git -C "$R2" reset -q --hard
if bash "$SM" pronta "$R2" 2>/dev/null; then ok "pronta: rc 0 a 12 righe in 2 patch (soglia righe)"; else ko "pronta: rc 0 a 12 righe in 2 patch (soglia righe)"; fi

# ── spedisci: ramo nuovo, patch applicate, SENZA commit ──────────────────────────
SPED=$(bash "$SM" spedisci "$R2" 2>&1); RC_SPED=$?
RAMO=$(sed -n 's/^RAMO //p' <<<"$SPED" | tail -1)
if [ "$RC_SPED" -eq 0 ] && [ -n "$RAMO" ]; then
  [ "$(git -C "$R2" branch --show-current)" = "$RAMO" ] && ok "spedisci: ramo nuovo attivo ($RAMO)" || ko "spedisci: ramo nuovo attivo"
  DN2=$(git -C "$R2" diff --name-only)
  grep -q x.js <<<"$DN2" && ok "spedisci: le patch sono nel working tree" || ko "spedisci: le patch sono nel working tree"
  DD2=$(git -C "$R2" diff)
  grep -q 'riga 1$' <<<"$DD2" && grep -q 'riga 12$' <<<"$DD2" && ok "spedisci: entrambe le patch applicate" || ko "spedisci: entrambe le patch applicate"
  [ "$(grep -c '^+riga' <<<"$DD2")" -eq 12 ] && ok "spedisci: 12 righe aggiunte in totale" || ko "spedisci: 12 righe aggiunte in totale"
  git -C "$R2" diff --cached --quiet && ok "spedisci: nessun commit (spetta alla consegna)" || ko "spedisci: nessun commit (spetta alla consegna)"
else ko "spedisci: rc 0 + nome ramo"; fi

# ── SABOTAGGIO: patch stantia (la base e' andata avanti) — salto dichiarato ──────
R3="$SB/repo3"; mkdir -p "$R3"; nuova_repo "$R3"
printf 'function buona() { return 1; }\n' > "$R3/g.js"
printf 'function vecchia() { return 2; }\n' > "$R3/v.js"
git -C "$R3" add -A && git -C "$R3" -c user.name=t -c user.email=t@t commit -qm file
printf '// documenta buona\n' >> "$R3/g.js"
bash "$SM" accumula "$R3" docs g.js >/dev/null 2>&1
git -C "$R3" reset -q --hard
printf '// documenta vecchia\n' >> "$R3/v.js"
bash "$SM" accumula "$R3" docs v.js >/dev/null 2>&1
git -C "$R3" reset -q --hard
# il main riscrive v.js: il contesto della seconda patch non esiste piu'
printf 'function v_completamente_riscritta() { return 3; }\n' > "$R3/v.js"
git -C "$R3" add -A && git -C "$R3" -c user.name=t -c user.email=t@t commit -qm riscritto
SAB=$(bash "$SM" spedisci "$R3" 2>&1); RC_SAB=$?
if [ "$RC_SAB" -eq 0 ] && grep -q "SACCA SALTA" <<<"$SAB"; then
  DN3=$(git -C "$R3" diff --name-only)
  grep -q '^g.js$' <<<"$DN3" && ok "sabotaggio: la patch sana si applica, la stantia si dichiara" || ko "sabotaggio: la patch sana si applica"
  ! grep -q '^v.js$' <<<"$DN3" && ok "sabotaggio: la stantia NON e' nel diff" || ko "sabotaggio: la stantia NON e' nel diff"
  [ "$(grep -c . "$R3/.git/sacca/indice")" -eq 1 ] && ok "sabotaggio: la stantia esce dall'indice (non si riprova in eterno)" || ko "sabotaggio: la stantia esce dall'indice"
else ko "sabotaggio: salto dichiarato + rc 0"; fi

# ── consumata: la sacca si svuota solo dopo la PR riuscita ───────────────────────
bash "$SM" consumata "$R3" >/dev/null 2>&1
[ ! -d "$R3/.git/sacca" ] && ok "consumata: sacca svuotata" || ko "consumata: sacca svuotata"

# ── fingerprint: stesso scheletro, nomi e stringhe diversi → stesso sha ──────────
DA='+_cp2=$(echo "$PROMPT") || true
+if grep -qiE '"'"'business central'"'"' <<<"$_cp2"; then'
DB='+altro_cp=$(echo "$TESTO") || true
+if grep -qiE '"'"'calcol|fattur'"'"' <<<"$_altro_cp"; then'
DC='+function nuovaFunzione() { return 1; }'
FA=$(printf '%s\n' "$DA" | bash "$SM" fingerprint)
FB=$(printf '%s\n' "$DB" | bash "$SM" fingerprint)
FC=$(printf '%s\n' "$DC" | bash "$SM" fingerprint)
[ -n "$FA" ] && [ "$FA" = "$FB" ] && ok "fingerprint: scheletro identico nonostante nomi/stringhe diversi" || ko "fingerprint: scheletro identico nonostante nomi/stringhe diversi"
[ -n "$FA" ] && [ "$FA" != "$FC" ] && ok "fingerprint: struttura diversa = sha diverso" || ko "fingerprint: struttura diversa = sha diverso"

# ── flotta: la terza repo con lo stesso template va in sacca (rc 0) ──────────────
export SACCA_WORK="$SB/work"
if bash "$SM" flotta repo-A <<<"$DA" >/dev/null 2>&1; then ko "flotta: rc 1 alla prima vista"; else ok "flotta: rc 1 alla prima vista"; fi
if bash "$SM" flotta repo-B <<<"$DA" >/dev/null 2>&1; then ko "flotta: rc 1 alla seconda vista"; else ok "flotta: rc 1 alla seconda vista"; fi
if bash "$SM" flotta repo-A <<<"$DA" >/dev/null 2>&1; then ko "flotta: rc 1 alla ripetizione dello stesso repo"; else ok "flotta: rc 1 alla ripetizione dello stesso repo"; fi
if bash "$SM" flotta repo-C <<<"$DA" >/dev/null 2>&1; then ok "flotta: rc 0 alla TERZA repo (template di flotta)"; else ko "flotta: rc 0 alla TERZA repo (template di flotta)"; fi
# finestra: il registro di ieri non conta (scheletro DIVERSO da quello di oggi,
# o il registro di oggi sporca la prova)
SHA_DC=$(printf '%s\n' "$DC" | bash "$SM" fingerprint)
mkdir -p "$SACCA_WORK/.sacca-template"
printf '%s repo-X\n%s repo-Y\n' "$SHA_DC" "$SHA_DC" > "$SACCA_WORK/.sacca-template/$(date -v-1d +%Y%m%d)"
if bash "$SM" flotta repo-Z <<<"$DC" >/dev/null 2>&1; then ko "flotta: il registro di IERI non conta (finestra di un giorno)"; else ok "flotta: il registro di IERI non conta (finestra di un giorno)"; fi

# ── cablaggio nel turno: la consegna della caccia passa dalla sacca ──────────────
grep -q 'sacca-migliorie.sh" flotta' "$NS" && ok "cablaggio: il turno consulta il template di flotta" || ko "cablaggio: il turno consulta il template di flotta"
grep -q 'sacca-migliorie.sh" accumula' "$NS" && ok "cablaggio: il turno accumula sotto soglia" || ko "cablaggio: il turno accumula sotto soglia"
grep -q 'sacca-migliorie.sh" pronta' "$NS" && ok "cablaggio: il turno chiede se la sacca e' pronta" || ko "cablabgio: il turno chiede se la sacca e' pronta"
grep -q 'sacca-migliorie.sh" spedisci' "$NS" && ok "cablaggio: il turno spedisce la sacca piena" || ko "cablaggio: il turno spedisce la sacca piena"
grep -q 'sacca-migliorie.sh" consumata' "$NS" && ok "cablaggio: il turno consuma la sacca dopo la PR" || ko "cablaggio: il turno consuma la sacca dopo la PR"
grep -q -- '--title "$TITLE_PR"' "$NS" && ok "cablaggio: il titolo della PR e' variabile (sacca-aware)" || ko "cablaggio: il titolo della PR e' variabile (sacca-aware)"
# il debito NON passa dalla sacca: viaggia sempre per conto suo
grep -q 'debito.*viaggia sempre per conto suo\|!= "debito"' "$NS" && ok "cablaggio: il debito resta fuori dalla sacca" || ko "cablaggio: il debito resta fuori dalla sacca"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
