#!/bin/bash
# test-brain.sh — il banco del Brain (tools/brain*.py): indice ad albero parallelo e incrementale,
# ricerca con riferimenti al volo, verifica delle fonti a due giudici, permessi per ruolo.
# Ogni attesa nasce da un difetto delle LLM Wiki a grafo (docs/brain.md): se torna, qui arrossisce.
# Moduli presidiati (tutti attraverso tools/brain.py): brain_db.py e brain_ingest.py (§0-3),
# brain_riassunto.py (§1, §7), brain_interroga.py e brain_risposta.py (§4, §7, §8),
# brain_testo.py e brain_verifica.py (§5-6), brain_modello.py (§6-7), brain_permessi.py (§8).
# Nessuna rete, nessun modello vero: il «modello» è uno script finto col contratto di llm/.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
export BRAIN_DB="$TMP/brain.db"
unset BRAIN_LLM BRAIN_GIUDICE BRAIN_UTENTE
brain() { python3 "$HERE/tools/brain.py" "$@" 2>"$TMP/err"; }

C="$TMP/corpus"
mkdir -p "$C/manuali/sub" "$C/paghe" "$C/contratti"
printf '# Legno\n\nIl legno di abete arriva dalla segheria in pacchi da 40 tavole.\nNon stoccare il legno all aperto.\n' > "$C/manuali/legno.md"
printf '# Essiccazione\n\nLa camera di essiccazione porta il legno al 18%% di umidita in 6 giorni.\nPrima di caricare la camera leggi manuali/legno.md per lo stoccaggio.\n' > "$C/manuali/sub/essiccazione.md"
printf '# Paghe di marzo\n\nLo stipendio del reparto segheria aumenta del 3%% da aprile.\n' > "$C/paghe/marzo.md"
printf '# Contratto fornitore\n\nIl fornitore consegna entro 15 giorni dall ordine.\n' > "$C/contratti/fornitore.md"
printf 'Nota libera sul piazzale: i pacchi si contano ogni lunedi.\n' > "$C/note.txt"

# 0. Chiedere a un Brain mai indicizzato è un errore d'uso, non una risposta vuota.
brain chiedi "legno"; RC=$?
[ "$RC" -eq 2 ] && grep -q "database assente" "$TMP/err" && ok "database assente: rc 2, detto" || ko "database assente: rc $RC"

# 1. Indicizzazione parallela; il secondo giro non tocca gli invariati (incrementale).
OUT=$(brain indicizza "$C" --paralleli 4)
grep -q "nuovi_o_cambiati 5" <<<"$OUT" && ok "primo giro: 5 documenti riassunti" || ko "primo giro: $OUT"
grep -q "in parallelo (4 alla volta)" "$TMP/err" && ok "il riassunto dichiara il parallelismo" || ko "parallelismo non dichiarato"
OUT=$(brain indicizza "$C")
grep -q "nuovi_o_cambiati 0 · spariti 0 · invariati 5 · cartelle 0" <<<"$OUT" && ok "secondo giro: niente da rifare" || ko "secondo giro: $OUT"

# 2. Un documento cambiato costa i suoi antenati, non l'albero intero (niente healing globale).
printf '\nLa camera si pulisce ogni venerdi.\n' >> "$C/manuali/sub/essiccazione.md"
OUT=$(brain indicizza "$C")
grep -q "nuovi_o_cambiati 1 · spariti 0 · invariati 4 · cartelle 3" <<<"$OUT" && ok "un cambiato: rifatte solo 3 cartelle (sub, manuali, radice)" || ko "un cambiato: $OUT"

# 3. Un documento sparito esce dall'indice.
printf 'Nota da togliere: parola ornitorinco.\n' > "$C/via.txt"; brain indicizza "$C" >/dev/null
rm "$C/via.txt"; OUT=$(brain indicizza "$C")
grep -q "spariti 1" <<<"$OUT" && ok "sparito: tolto dall'indice" || ko "sparito: $OUT"
brain chiedi "ornitorinco" >"$TMP/out"; RC=$?
! grep -q "via.txt" "$TMP/out" && [ "$RC" -eq 4 ] && ok "sparito: non si cita più (rc 4, nessuna parte citata)" || ko "sparito ancora citato (rc $RC): $(head -3 "$TMP/out")"

# 4. Risposta estrattiva (nessun modello): citata riga per riga e verificata; riferimento al volo.
brain chiedi "umidita camera essiccazione" >"$TMP/out"; RC=$?
[ "$RC" -eq 0 ] && grep -q "\[manuali/sub/essiccazione.md:3\]" "$TMP/out" && ok "estrattiva: cita la riga vera (rc 0)" || ko "estrattiva (rc $RC): $(cat "$TMP/out")"
grep -q "parti citate e verificate 3/3\|parti citate e verificate [1-9]/[1-9]" "$TMP/out" && ok "estrattiva: tutte le parti citate verificate" || ko "estrattiva: $(tail -1 "$TMP/out")"
grep -q "riferimento al volo: manuali/sub/essiccazione.md -> manuali/legno.md" "$TMP/err" && ok "il grafo si fa al volo: dal pezzo al documento nominato" || ko "riferimento al volo mancato: $(grep -c riferimento "$TMP/err")"

# 5. Verifica delle fonti: i quattro esiti.
verifica() { printf '%s\n' "$1" | brain verifica "${@:2}" >"$TMP/out"; echo $?; }
RC=$(verifica "La camera porta il legno al 18% di umidita in 6 giorni [manuali/sub/essiccazione.md:3].")
[ "$RC" -eq 0 ] && grep -q "verificate 1/1" "$TMP/out" && ok "verifica: frase fedele -> verificata" || ko "frase fedele (rc $RC): $(cat "$TMP/out")"
RC=$(verifica "La camera porta il legno al 12% di umidita in 6 giorni [manuali/sub/essiccazione.md:3].")
[ "$RC" -eq 3 ] && grep -q "numeri assenti dalle righe citate: 12" "$TMP/out" && ok "verifica: numero sbagliato -> incerta, detto quale" || ko "numero sbagliato (rc $RC): $(cat "$TMP/out")"
RC=$(verifica "Stoccare il legno all aperto [manuali/legno.md:4].")
[ "$RC" -eq 3 ] && grep -q "negata da una parte sola" "$TMP/out" && ok "verifica: negazione rovesciata -> incerta" || ko "negazione rovesciata (rc $RC): $(cat "$TMP/out")"
RC=$(verifica "Il legno arriva in pacchi da 40 tavole [manuali/legno.md:3]. Non stoccare il legno all aperto [manuali/legno.md:4].")
[ "$RC" -eq 0 ] && grep -q "verificate 2/2" "$TMP/out" && ok "verifica: una negazione fedele non è un falso allarme" || ko "negazione fedele (rc $RC): $(cat "$TMP/out")"
RC=$(verifica "Il legno di abete profuma di resina.")
[ "$RC" -eq 4 ] && grep -q "\[generale\]" "$TMP/out" && ok "verifica: senza citazione -> conoscenza generale (rc 4)" || ko "senza citazione (rc $RC): $(cat "$TMP/out")"
RC=$(verifica "Il legno arriva in pacchi [manuali/legno.md:99].")
[ "$RC" -eq 3 ] && grep -q "fuori dal documento" "$TMP/out" && ok "verifica: righe inesistenti -> rotta" || ko "righe inesistenti (rc $RC): $(cat "$TMP/out")"
RC=$(verifica "Le tavole sono tutte dritte e senza nodi [manuali/legno.md:3].")
[ "$RC" -eq 3 ] && grep -q "nessun giudice utile" "$TMP/out" && ok "verifica: sotto soglia senza giudice -> incerta, detto" || ko "sotto soglia (rc $RC): $(cat "$TMP/out")"

# 6. Il secondo giudice (modello finto): salva la sotto soglia, MAI un numero assente.
F="$TMP/finto.sh"
cat > "$F" <<'EOF'
#!/bin/bash
cat >/dev/null
case "$1" in
  Riassumi*) echo "RIASSUNTO-FINTO" ;;
  Questi\ sono*) echo "SINTESI-FINTA" ;;
  Rispondi\ solo\ SI*) echo "${GIUDICE_DICE:-NO}" ;;
  *BOZZA*) echo "La camera porta il legno al 18% di umidita [manuali/sub/essiccazione.md:3]." ;;
  *) echo "La camera porta il legno al 12% di umidita [manuali/sub/essiccazione.md:3]. Il legno profuma." ;;
esac
EOF
chmod +x "$F"
export BRAIN_GIUDICE="$F"
RC=$(GIUDICE_DICE=SI verifica "Le tavole sono tutte dritte e senza nodi [manuali/legno.md:3].")
[ "$RC" -eq 0 ] && grep -q "verificate 1/1" "$TMP/out" && ok "giudice SI: la sotto soglia diventa verificata dal giudice" || ko "giudice SI (rc $RC): $(cat "$TMP/out")"
RC=$(GIUDICE_DICE=SI verifica "La camera porta il legno al 12% di umidita [manuali/sub/essiccazione.md:3].")
[ "$RC" -eq 3 ] && ok "giudice SI non salva un numero assente (il deterministico vince)" || ko "numero salvato dal giudice (rc $RC): $(cat "$TMP/out")"
unset BRAIN_GIUDICE

# 7. Con un modello: bozza, verifica, correzione, riverifica; la frase senza fonte resta «generale».
BRAIN_LLM="$F" brain chiedi "a quanto si essicca il legno" >"$TMP/out"; RC=$?
grep -q "fase 4/5 correzione" "$TMP/err" && ok "modello: la bozza col numero sbagliato va in correzione" || ko "modello: nessuna correzione: $(grep fase "$TMP/err" | tr '\n' ' ')"
grep -q "18% di umidita" "$TMP/out" && grep -q "verificate 1/1" "$TMP/out" && [ "$RC" -eq 0 ] && ok "modello: dopo la correzione la parte citata è verificata" || ko "modello dopo correzione (rc $RC): $(cat "$TMP/out")"
BRAIN_LLM="$F" brain indicizza "$C" --forza >/dev/null
brain mappa --profondita 0 >"$TMP/out"
grep -q "SINTESI-FINTA" "$TMP/out" && ok "modello: la sintesi delle cartelle la scrive il modello" || ko "sintesi modello: $(cat "$TMP/out")"

# 8. Permessi: nega vince su leggi; niente trapela da sintesi, ricerca o verifica.
brain permessi regola stagista leggi '*' >/dev/null
brain permessi regola stagista nega 'paghe/*' >/dev/null
brain permessi ruolo mario stagista >/dev/null
brain permessi regola direzione leggi '*' >/dev/null
brain permessi ruolo anna direzione >/dev/null
brain chiedi "stipendio reparto segheria aprile" --utente mario >"$TMP/out"
! grep -q "paghe/" "$TMP/out" && ok "permessi: lo stagista non riceve le paghe" || ko "paghe allo stagista: $(cat "$TMP/out")"
brain chiedi "stipendio reparto segheria aprile" --utente anna >"$TMP/out"
grep -q "\[paghe/marzo.md:3\]" "$TMP/out" && ok "permessi: la direzione le riceve" || ko "direzione senza paghe: $(cat "$TMP/out")"
RC=$(verifica "Lo stipendio aumenta del 3% da aprile [paghe/marzo.md:3]." --utente mario)
[ "$RC" -eq 3 ] && grep -q "sconosciuto o non leggibile" "$TMP/out" && ok "permessi: citare un documento negato è una citazione rotta (senza dire che esiste)" || ko "verifica negata (rc $RC): $(cat "$TMP/out")"
brain mappa --utente mario >"$TMP/out"
grep -q "sintesi nascosta" "$TMP/out" && ! grep -q "^ *paghe/" "$TMP/out" && ok "permessi: la sintesi della radice si nasconde, la cartella negata sparisce" || ko "mappa stagista: $(cat "$TMP/out")"
printf '# Riservato\n\nLa penale per ritardo vale il 2 per mille al giorno.\n' > "$C/contratti/riservato.md"
brain indicizza "$C" >/dev/null; brain permessi regola stagista nega 'contratti/riservato.md' >/dev/null
brain chiedi "penale ritardo" --utente mario >"$TMP/out"
! grep -q "scelgo \['contratti'\]" "$TMP/err" && ! grep -q "riservato" "$TMP/out" \
  && ok "permessi: la cartella letta in parte non usa la sintesi salvata (la parola negata non guida la discesa)" \
  || ko "sintesi parziale trapela: $(grep scelgo "$TMP/err" | head -2)"
brain chiedi "legno" --utente sconosciuto >"$TMP/out"; RC=$?
[ "$RC" -eq 4 ] && grep -q "non ha ruoli con regole" "$TMP/err" && ok "permessi: senza ruolo non si legge niente, detto" || ko "senza ruolo (rc $RC): $(tail -2 "$TMP/err")"

# 9. Più persone insieme: WAL acceso (chi legge non blocca chi indicizza).
MODO=$(python3 -c "import sqlite3,sys; print(sqlite3.connect(sys.argv[1]).execute('PRAGMA journal_mode').fetchone()[0])" "$BRAIN_DB")
[ "$MODO" = "wal" ] && ok "database in modalità WAL" || ko "journal_mode: $MODO"

echo "$PASS OK, $FAIL FAIL"
echo "attese eseguite: $((PASS+FAIL))/$((PASS+FAIL)) · fallite: $FAIL"
[ "$FAIL" -eq 0 ]
