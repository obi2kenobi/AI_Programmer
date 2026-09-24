#!/bin/bash
# test-profilo.sh — il profilo unico del turno (studio deepseek-harness
# profiles/bundles): una dichiarazione, caricata a ogni ciclo, i default nel
# codice sono fallback. Prova: caricamento, validazione chiavi, profilo
# mancante = zero chiavi (non morte), override da env vince sul file.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

OUT=$(bash -c '. "$1/tools/profilo.sh" notturno; echo "M=$MODELLO T=$AGENTE_TIMEOUT I=$IMPARA_ORA"' _ "$HERE" 2>/dev/null)
grep -q "M=qwen3.8-27b:iq3s" <<<"$OUT" && grep -q "T=600" <<<"$OUT" && grep -q "I=22" <<<"$OUT" \
  && ok "profilo notturno: le tre chiavi critiche caricate" \
  || ko "caricamento: $OUT"

OUT=$(bash -c '. "$1/tools/profilo.sh" inesistente 2>/dev/null; echo "N=$([ -n "${MODELLO:-}" ] && echo pieno || echo vuoto)"' _ "$HERE" 2>/dev/null)
grep -q "N=vuoto" <<<"$OUT" \
  && ok "profilo mancante: zero chiavi, nessuna morte" \
  || ko "profilo mancante: $OUT"

OUT=$(bash -c 'MODELLO=override-manuale; . "$1/tools/profilo.sh" notturno >/dev/null 2>&1; echo "V=$MODELLO"' _ "$HERE" 2>/dev/null)
grep -q "V=qwen3.8-27b:iq3s" <<<"$OUT" \
  && ok "il file profilo PREVALE sui default del codice (e' la fonte)" \
  || ko "il profilo non riesce a prevalere: $OUT"

[ -f "$HERE/profiles/notturno.conf" ] && grep -q "^MODELLO=" "$HERE/profiles/notturno.conf" \
  && ok "profiles/notturno.conf esiste e dichiara il modello" \
  || ko "profilo file assente"

# ── (D11, decisione di Luca 2026-09-23: «a, pausa a 30 minuti») il profilo e' COLLEGATO: ogni
#    chiave ha un lettore vero nel codice, e i valori del file sono quelli che il turno usa oggi.
#    Prima 11 chiavi su 15 non le leggeva nessuno: cambiarle nel file non cambiava il turno.
PROF="$HERE/profiles/notturno.conf"
SENZA=""
for K in $(grep -oE '^[A-Z_]+=' "$PROF" | tr -d '='); do
  grep -rqE "\\\$\\{$K[:}]|\\\$$K\\b" "$HERE/night-shift" "$HERE/llm" "$HERE/tools" --include=*.sh --exclude=profilo.sh 2>/dev/null || SENZA="$SENZA $K"
done
[ -z "$SENZA" ] && ok "ogni chiave del profilo ha un lettore nel codice ($(grep -cE '^[A-Z_]+=' "$PROF") chiavi)" || ko "chiavi del profilo che nessuno legge:$SENZA"
AMMESSE=$(sed -n 's/^_PROF_OK="\(.*\)"$/\1/p' "$HERE/tools/profilo.sh")
FUORI=""
for K in $(grep -oE '^[A-Z_]+=' "$PROF" | tr -d '='); do case " $AMMESSE " in *" $K "*) ;; *) FUORI="$FUORI $K" ;; esac; done
[ -z "$FUORI" ] && ok "ogni chiave del profilo e' nell'allowlist del caricatore" || ko "chiavi scartate in silenzio dal caricatore:$FUORI"
# i valori: quelli che il turno usa oggi (nessun comportamento cambiato dal collegamento)
v() { sed -n "s/^$1=//p" "$PROF"; }
[ "$(v CACCIATORIA_COOLDOWN_SEC)" = "1800" ] && ok "pausa della caccia dopo una repo pulita: 1800 s (30 minuti, decisione di Luca)" || ko "CACCIATORIA_COOLDOWN_SEC='$(v CACCIATORIA_COOLDOWN_SEC)' (atteso 1800)"
[ "$(v MIGLIORIA_COOLDOWN_SEC)" = "21600" ] && ok "pausa per file e categoria della miglioria: 21600 s (6 ore, quella di oggi)" || ko "MIGLIORIA_COOLDOWN_SEC='$(v MIGLIORIA_COOLDOWN_SEC)' (atteso 21600)"
grep -q 'CACCIATORIA_COOLDOWN_SEC:-1800' "$HERE/night-shift/night-shift.sh" && grep -q 'MIGLIORIA_COOLDOWN_SEC:-21600' "$HERE/night-shift/caccia-miglioria.sh" \
  && ok "le due pause leggono ognuna la sua chiave (fallback = valore di oggi)" || ko "le due pause non leggono le loro chiavi"
grep -q 'NIGHT_CICLO_MIN_SEC:-${CICLO_MIN_SEC' "$HERE/night-shift/night-shift.sh" \
  && ok "CICLO_MIN_SEC arriva al turno (il nome vecchio NIGHT_CICLO_MIN_SEC resta come override)" || ko "il turno non legge CICLO_MIN_SEC"
# il comportamento segue la chiave: il censore con CENSORE_MAX_RIGHE=1 boccia per taglia
grep -q 'MAX_RIGHE="${CENSORE_MAX_RIGHE:-60}"' "$HERE/night-shift/revisore.sh" \
  && ok "il censore legge i suoi limiti dal profilo (CENSORE_*)" || ko "il censore ha ancora i limiti scritti a mano"
grep -q 'GIUDICE_MODEL="${REVISORE_MODEL:-${MODELLO:-' "$HERE/night-shift/revisore.sh" && grep -q 'AUTORE_MODEL="${NIGHT_MODEL:-${MODELLO:-' "$HERE/night-shift/revisore.sh" \
  && ok "il modello del censore segue MODELLO (gli override per ruolo restano)" || ko "il censore ignora MODELLO del profilo"

# (Q28, 2026-09-23, giro A5 della notte): il parser del profilo, su un file scritto a mano.
# Riprodotti: un commento a fine riga finiva nel valore («240  # quattro minuti»), un CR pure,
# `CHIAVE = valore` e l'ultima riga senza a capo si perdevano in silenzio, e la variabile NOME
# del CHIAMANTE veniva cancellata (unset NOME).
P="$HERE/profiles/_prova_q28_$$.conf"
printf 'SONDA_SEC=240  # quattro minuti\r\nSONDA_ROUND = 6\nTHINK=true\r\nCHIAVE_IGNOTA=1\nIMPARA_ORA=5' > "$P"
OUT=$( ( NOME=del-chiamante; unset SONDA_SEC SONDA_ROUND THINK IMPARA_ORA
  . "$HERE/tools/profilo.sh" "_prova_q28_$$" 2>"$P.err"
  printf '%s|%s|%s|%s|%s' "${SONDA_SEC:-}" "${SONDA_ROUND:-}" "${THINK:-}" "${IMPARA_ORA:-}" "${NOME:-}" ) )
ERR=$(cat "$P.err" 2>/dev/null); rm -f "$P" "$P.err"
[ "$(cut -d'|' -f1 <<<"$OUT")" = "240" ] && ok "Q28: il commento a fine riga e il CR non entrano nel valore" || ko "Q28: SONDA_SEC vale [$(cut -d'|' -f1 <<<"$OUT" | od -c | head -1)]"
[ "$(cut -d'|' -f2 <<<"$OUT")" = "6" ] && ok "Q28: «CHIAVE = valore» con gli spazi si legge" || ko "Q28: SONDA_ROUND con gli spazi perso"
[ "$(cut -d'|' -f3 <<<"$OUT")" = "true" ] && ok "Q28: THINK=true con CRLF vale «true»" || ko "Q28: THINK porta il CR"
[ "$(cut -d'|' -f4 <<<"$OUT")" = "5" ] && ok "Q28: l'ultima riga senza a capo si legge" || ko "Q28: l'ultima riga persa"
[ "$(cut -d'|' -f5 <<<"$OUT")" = "del-chiamante" ] && ok "Q28: la variabile NOME del chiamante resta com'era" || ko "Q28: NOME del chiamante cancellata"
grep -q "CHIAVE_IGNOTA" <<<"$ERR" && ok "Q28: una chiave fuori allowlist si dice (refuso visibile), non si tace" || ko "Q28: chiave ignota taciuta: $ERR"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
