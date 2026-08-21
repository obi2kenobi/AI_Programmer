# patterns/ — i trucchi ancorati

Ogni pattern è uno snippet/rule **provato**, con l'ÀNCORA al codice che lo usa (file:funzione)
e la lezione che l'ha creato. Regola ereditata da `pattern-strumenti.js` di AI_Develop:
**l'ancora deve esistere, o la voce non sopravvive** — lo snippet non ancorato è folklore.
Consumo: gli agenti citano il pattern nelle commesse invece di iniettare codice; il grafo
li indicizza (`graphify query "watchdog"` → il pattern con la sua àncora).

## Registro

| Pattern | Ancora | Nato il |
|---|---|---|
| [watchdog-guardato](watchdog-guardato.md) | night-shift/lib.sh:run_guarded | 2026-08-18 |
| [itera-su-array](itera-su-array.md) | night-shift/night-shift.sh (ROWS) | 2026-08-19 |
| [jq-slurp](jq-slurp.md) | night-shift/morning-gate.sh | 2026-08-21 |
| [cuore-unico-proprietario](cuore-unico-proprietario.md) | night-shift/night-shift.sh (probe/kickstart) | 2026-08-21 |
| [lock-per-risorsa](lock-per-risorsa.md) | night-shift/night-shift.sh (LOCK) | 2026-08-21 |
| [allowlist-per-segmento](allowlist-per-segmento.md) | night-shift/lib.sh:gate_allowlist_ok | 2026-08-21 |
| [csv-con-python](csv-con-python.md) | night-shift/gate-summary.sh | 2026-08-21 |
| [forma-dei-dati-verificata](forma-dei-dati-verificata.md) | .github/ISSUE_TEMPLATE/night-shift.md | 2026-08-21 |
| [workdir-e-proprietario](workdir-e-proprietario.md) | regola processo (SAL 2026-08-21) | 2026-08-21 |
| [esegui-non-leggere](esegui-non-leggere.md) | standard di verifica (SAL/dev-critic) | 2026-08-21 |
