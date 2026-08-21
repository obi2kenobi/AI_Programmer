# patterns/ — i trucchi ancorati

Ogni pattern è uno snippet/rule **provato**, con l'ÀNCORA al codice che lo usa (file:funzione)
e la lezione che l'ha creato. Regola ereditata da `pattern-strumenti.js` di AI_Develop:
**l'ancora deve esistere, o la voce non sopravvive** — lo snippet non ancorato è folklore.
Consumo: gli agenti citano il pattern nelle commesse invece di iniettare codice. La ricerca
oggi è il registro qui sotto; l'indicizzazione nel grafo richiede il pass semantico dei
documenti (DEBITI: da valutare se vale i token).

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
| [verdetto-sempre-visibile](verdetto-sempre-visibile.md) | AI_Develop: tools/banco-lib.js:verdetto | 2026-08-17 |
| [regola-provata-non-assunta](regola-provata-non-assunta.md) | AI_Develop: tools/test-motore.js:eq + blocco vm | 2026-07-30 |
| [oracolo-indipendente](oracolo-indipendente.md) | AI_Develop: tools/grafo-verifica.js (assi C/D) | 2026-08-21 |
| [citazione-non-presidio](citazione-non-presidio.md) | AI_Develop: tools/pattern-strumenti.js:senzaControllo | 2026-08-07 |
| [trovare-non-e-fallire](trovare-non-e-fallire.md) | AI_Develop: tools/riallinea-mirror.sh:trova | 2026-08-12 |
| [versione-sugli-artefatti](versione-sugli-artefatti.md) | AI_Develop: tools/grafo-findings.js:221 | 2026-08-08 |
| [segreto-come-impronta](segreto-come-impronta.md) | AI_Develop: tools/maschera-segreti.js:mascheraSegreti | 2026-08-11 |
| [soglia-con-provenienza](soglia-con-provenienza.md) | AI_Develop: tools/soglie.js:derive | 2026-08-07 |
| [banco-sintetico-per-calcoli-critici](banco-sintetico-per-calcoli-critici.md) | Bilancio_periodico: tools/test-sp.js · gas/Sp.js:366 | 2026-08-21 |
| [scarto-mai-silenzioso](scarto-mai-silenzioso.md) | progetto onboardato: Extractor.gs:applicaVincoliRange_ | 2026-08-21 |
| [stato-vuoto-dalla-pipeline](stato-vuoto-dalla-pipeline.md) | progetto onboardato: WebApp.gs:aggregaPerDashboard_ | 2026-08-21 |
