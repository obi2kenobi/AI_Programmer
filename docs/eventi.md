# Catalogo degli eventi — ogni firma, chi la scrive, chi la legge

(ispirato a event-producer-consumer.md di deepseek-harness, studio 2026-09-23:
una firma senza consumatori e' un contatore cieco — audit-2 ce l'ha dimostrato
col funnel: DELIBERA: contava zero da sempre). Scritto leggendo il codice reale e presidiato da
`tests/test-eventi.sh`: ogni produttore contiene la firma, ogni consumatore esiste.

| Firma | Produttori | Consumatori | Guardia |
|---|---|---|---|
| `TURNO INIZIATO` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `TURNO FINITO` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi |
| `cervello: domanda del giorno` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi |
| `impara:` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi |
| `onesto niente` | `tools/cervello-impara.sh` | `tools/cervello-impara.sh` | test-eventi |
| `scopa-rami:` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi |
| `attivo la CACCIA` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `caccia: sana e nessuna miglioria` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `AGENTE FALLITO` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `LENTE MUTA` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi, test-dashboard |
| `non dichiarato` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi, test-caccia-smistamento |
| `pass VIVO da oltre 24 ore` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi, test-grafo-notturno |
| `gh non ha detto lo stato della PR` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi, test-lib |
| `gh non ha risposto` | `night-shift/night-shift.sh` | `night-shift-console.log` (battito) | test-eventi, test-lib |
| `TRASFORMATORE deterministico` | `night-shift/night-shift.sh`, `night-shift/caccia-miglioria.sh` | `tools/dashboard.py`, `night-shift/night-shift.sh` | test-eventi |
| `gate BOCCIA` | `night-shift/night-shift.sh`, `night-shift/caccia-miglioria.sh` | `tools/dashboard.py`, `night-shift/night-shift.sh` | test-eventi |
| `MIGLIORIA pronta` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `commit/push` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `PR di` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `in quarantena` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `censore rinvia la PR #` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `DELIBERA: APPROVA` | `night-shift/revisore.sh`, `night-shift/night-shift.sh` | `night-shift/night-shift.sh` | test-eventi |
| `DELIBERA: RIGETTA` | `night-shift/revisore.sh`, `night-shift/night-shift.sh` | `night-shift/night-shift.sh` | test-eventi |
| `VERIFICA ROSSA` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `Ollama wedged` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `rianimato dal watchdog` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `Sonda di generazione muta` | `night-shift/night-shift.sh` | `night-shift/night-shift.sh` | test-eventi |
| `ERRORE` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `ALLINEATO` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `DIVERGENTE` | `night-shift/night-shift.sh` | `tools/dashboard.py` | test-eventi |
| `registro: debito famiglie` | `tools/caccia-registro.sh` | `tools/cervello-impara.sh` | test-eventi |
| `registro:` | `tools/caccia-registro.sh` | `tools/dashboard.py` | test-eventi |
| `coda ILLEGGIBILE` | `night-shift/night-shift.sh` | `tools/dashboard.py`, `tools/cervello-impara.sh` | test-eventi, test-dashboard |
| `⛔ MANCA` | `night-shift/night-shift.sh` | `tools/cervello-impara.sh` | test-eventi |
| `SENTINELLA` | `tools/suite.sh`, `night-shift/lib.sh` | `tools/cervello-impara.sh` | test-eventi, test-lib |
| `rianima_ollama: esito` | `night-shift/lib.sh` | `night-shift/night-shift.sh`, `tools/cervello-impara.sh` | test-eventi, test-rianima-ollama |
| `SFORO DEL BUDGET` | `night-shift/lib.sh` | `tools/cervello-impara.sh` | test-eventi, test-lib |

## Righe ⚠/⛔ del turno lette solo dal battito

Il turno (`night-shift/night-shift.sh`) scrive queste avvertenze nel log. Nessun programma le conta: le legge
una persona che guarda il log (il battito). Sono dichiarate qui perché `tests/test-eventi.sh` vuole che ogni
riga ⚠/⛔ del turno sia nel catalogo o in questo elenco. Una riga nuova senza dichiarazione è rossa.

- Ollama e sonde: `server non visto`, `Sonda di generazione muta`, `Ollama wedged al via del turno`,
  `Ollama NON risponde nemmeno dopo il rilancio`.
- Avvio: `⛔ MANCA …: il turno non parte`.
- Coda e copie: `riclone di … fallito`, `TURNO su …: coda ILLEGGIBILE`, `riallineo NON riuscito`.
- Auto-miglioramento dell'hub: `commit o push del branch notte FALLITI`, `stderr del commit/push`,
  `auto-fix BOCCIATI dal banco`, `creazione issue ciclo-vivo fallita`, `banco rosso e creazione issue fallita`.
- Censore: `censore ha RIGETTATO la PR`, `censore in errore sulla PR`, `censore in errore sul parere`.
- Caccia: `LENTE SEGNALA`, `commit/push della … fallito`.
- Issue: `commento della proposta fallito`, `… sul remoto ha … commit non del turno`, `PR NON creata`,
  `commit/push FALLITO`, `WATCHDOG scattato`, `agente terminato`, `LOOP DI RIPLETTURA rilevato`.

Note (2026-09-24, quinto ventaglio, R4 R6): la dashboard legge il censimento del registro dal file storia e
mostra le righe `registro:` fra le recenti; `⛔ MANCA` lo conta fra gli errori (ogni `⛔`). Il guardiano ora
vuole che ogni consumatore CERCHI la firma, non solo che esista, e fa il censimento inverso delle righe
`⚠`/`⛔` di `night-shift/night-shift.sh` contro questo catalogo (l'elenco qui sopra).
