# watchdog-guardato
**Àncora**: night-shift/lib.sh:run_guarded · **Nato**: 2026-08-18 (l'agente che girò 4,5 ore)
Ogni comando di durata ignota gira con killer: `( "$@" & pid=$!; ( sleep N; kill $pid ) & w=$!; wait $pid; rc=$?; kill $w )`. Su macOS non c'è `timeout`: questo è il suo sostituto provato. Vale per agenti, verifiche, banco. Eccezione dichiarata: il turno notturno NON lo usa sulle issue (decisione di Luca, 2026-08-21: nessun limite — la guardia è la review del mattino).
