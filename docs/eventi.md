# Catalogo degli eventi — ogni firma, chi la scrive, chi la legge

(ispirato a event-producer-consumer.md di deepseek-harness, studio 2026-09-23:
una firma senza consumatori e' un contatore cieco — audit-2 ce l'ha dimostrato
col funnel: DELIBERA: contava zero da sempre. Generato dal codice reale:

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
| `registro: debito famiglie` | `tools/caccia-registro.sh` | `tools/dashboard.py` | test-eventi |
