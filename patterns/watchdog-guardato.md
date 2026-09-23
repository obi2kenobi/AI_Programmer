# watchdog-guardato
**Àncora**: night-shift/lib.sh:run_guarded · **Nato**: 2026-08-18 (l'agente che girò 4,5 ore)
Ogni comando di durata ignota gira con killer: `( "$@" & pid=$!; ( sleep N; kill $pid ) & w=$!; wait $pid; rc=$?; kill $w )`. Su macOS non c'è `timeout`: questo è il suo sostituto provato. Vale per agenti, verifiche, banco. Eccezione RITRATTA (Luca, 2026-08-31): il turno notturno ora usa il watchdog per-issue (NIGHT_SHIFT_TIMEOUT=240min di default). Il no-limit del 2026-08-21 è costato 3 notti (28-30/8: loop da 59 ore, job vivo che bloccava i turni seguenti) e la review del mattino non poteva guardare ciò che non vedeva. La review resta l'appello: il watchdog limita il loop, non la qualità.


**Aggiornamento (revisione 10 giri, 2026-09-23 — misurato)**: il killer del solo figlio non basta. Un nipote che tiene aperta la pipe (`bash -c 'sleep …'` dentro `$(…)`) tiene il chiamante per l'intera durata, e un comando che ignora TERM torna con il SUO esito (verde) a fine corsa. La forma giusta uccide il GRUPPO, manda KILL dopo il TERM e restituisce 124: è `ai_timeout` di `llm/_timeout.sh` (GNU `timeout -k`, o il fallback perl con `setpgrp` su macOS), che `run_guarded` ora usa — le attese in `tests/test-lib.sh`.

**Vedi anche**: `regola-provata-non-assunta`
