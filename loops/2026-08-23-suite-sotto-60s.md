# Loop /goal — la suite tests/test-*.sh resta sotto 60s dopo la crescita di questo ciclo

**Obiettivo verificabile**: `l'intera suite tests/test-*.sh completa in meno di 60s su
una run pulita` | max 2 tentativi.

**Livello di verifica**: 2 — regola numerica (soglia di tempo), misurata dal vivo con
`time`, non presunta.

**Perché ora**: primo esercizio reale del comando `/goal` (implementato nel 4° ciclo,
mai eseguito da allora — `loops/` conteneva solo il README). Motivato da un dato reale
di questo stesso ciclo: la suite è cresciuta da 50 a 55 file in poche ore (5° ciclo,
Set 1+Set 2 giro 1-2), lo stesso trend monotono già annotato in `DEBITI.md` — verificare
ora, non aspettare che il debito diventi un problema.

## Tentativo 1

Modifica: nessuna — misura pura, nessun cambiamento al codice.

Comando: `time (for t in tests/test-*.sh; do bash "$t" >/dev/null 2>&1 || exit 1; done)`
sull'ordine alfabetico standard del glob.

Risultato: **35.1s reali** (54 file eseguiti con successo — 55 test-*.sh incluso
questo giro stesso, uno dei quali era ancora in scrittura al momento della prima
misura). Sotto la soglia di 60s con ampio margine.

## Verifica avversariale (obbligatoria prima della vittoria, livello 1-2)

Non basta un solo passaggio in condizioni "calde" — rieseguita la stessa suite in
**ordine casuale** (`ls tests/test-*.sh | shuf`), per escludere che il tempo dipendesse
da un ordine favorevole o da uno stato caldo del primo run.

Risultato: **34.8s reali**, 55/55 superati. Coerente col tentativo 1 (differenza
<1s) — la soglia non dipende dall'ordine di esecuzione.

## Esito

**Vittoria al primo tentativo**, confermata dalla verifica avversariale — non serve
un secondo tentativo. Nessun cambiamento al codice richiesto: la suite regge la
crescita di questo ciclo con margine (35s misurati vs 60s obiettivo, vs 120s ceiling
del watchdog `run_guarded()` in `night-shift/morning-gate.sh`).

Lezione per il metodo (riportata in `SAL.md`): un comando costruito e documentato ma
mai eseguito (`/goal`, da quando esiste nel 4° ciclo) è lo stesso rischio già trovato
per `.claude/agents/` nel Set 1 di questo ciclo — "costruito" non è "provato". Questo
loop chiude quel gap per `/goal` specificamente.
