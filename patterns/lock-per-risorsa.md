# lock-per-risorsa
**Àncora**: night-shift/night-shift.sh (LOCK) · **Nato**: 2026-08-21 (turni sovrapposti)
Due esecuzioni sulla stessa risorsa (il turno manuale e quello delle 23:00) = caos. Lock a directory con ETÀ: occupato di fresco → salto; più vecchio di 12h → considerato morto e preso. `mkdir` è atomico, `trap ... RETURN` rilascia.

**Vedi anche**: `cuore-unico-proprietario` · `workdir-e-proprietario` · `watchdog-guardato`
