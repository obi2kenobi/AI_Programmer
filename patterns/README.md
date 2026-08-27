# patterns/ — i trucchi ancorati

Ogni pattern è uno snippet/rule **provato**, con l'ÀNCORA al codice che lo usa (file:funzione)
e la lezione che l'ha creato. Regola ereditata da `pattern-strumenti.js` di REPO-A:
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
| [verdetto-sempre-visibile](verdetto-sempre-visibile.md) | REPO-A: tools/banco-lib.js:verdetto | 2026-08-17 |
| [regola-provata-non-assunta](regola-provata-non-assunta.md) | REPO-A: tools/test-motore.js:eq + blocco vm | 2026-07-30 |
| [oracolo-indipendente](oracolo-indipendente.md) | REPO-A: tools/grafo-verifica.js (assi C/D) | 2026-08-21 |
| [citazione-non-presidio](citazione-non-presidio.md) | REPO-A: tools/pattern-strumenti.js:senzaControllo | 2026-08-07 |
| [trovare-non-e-fallire](trovare-non-e-fallire.md) | REPO-A: tools/riallinea-mirror.sh:trova | 2026-08-12 |
| [versione-sugli-artefatti](versione-sugli-artefatti.md) | REPO-A: tools/grafo-findings.js:221 | 2026-08-08 |
| [segreto-come-impronta](segreto-come-impronta.md) | REPO-A: tools/maschera-segreti.js:mascheraSegreti | 2026-08-11 |
| [soglia-con-provenienza](soglia-con-provenienza.md) | REPO-A: tools/soglie.js:derive | 2026-08-07 |
| [banco-sintetico-per-calcoli-critici](banco-sintetico-per-calcoli-critici.md) | REPO-G: tools/test-sp.js · gas/Sp.js:366 | 2026-08-21 |
| [scarto-mai-silenzioso](scarto-mai-silenzioso.md) | progetto onboardato: Extractor.gs:applicaVincoliRange_ | 2026-08-21 |
| [stato-vuoto-dalla-pipeline](stato-vuoto-dalla-pipeline.md) | progetto onboardato: WebApp.gs:aggregaPerDashboard_ | 2026-08-21 |
| [banco-browser-per-webapp-gas](banco-browser-per-webapp-gas.md) | progetto onboardato: dashboard.html/dashboard_scripts.html | 2026-08-21 |
| [copertura-dal-glob](copertura-dal-glob.md) | questo hub: tests/test-skills-structure.sh, .night-verify | 2026-08-23 |

| [somma-diversa-da-zero-non-e-presenza](somma-diversa-da-zero-non-e-presenza.md) | REPO-H: ProcessData.gs findDisposals (report: docs/campo/2026-08-27-revisione-cespiti-gas-bc.md) | 2026-08-27 |
| [estrazione-per-testabilita](estrazione-per-testabilita.md) | REPO-I: quasi ogni fix del ciclo 2026-08-27 | 2026-08-27 |
| [guardia-nel-ponte-non-nella-condivisa](guardia-nel-ponte-non-nella-condivisa.md) | REPO-F: AccessoWeb.gs (incidente 2026-08-15) | 2026-08-27 |
| [soglia-con-default-guardato](soglia-con-default-guardato.md) | REPO-I: soglie di legge indici di crisi | 2026-08-27 |
| [riga-in-coda-non-interposta](riga-in-coda-non-interposta.md) | REPO-H: Main.gs generateCopertina_ | 2026-08-27 |
| [dipendenza-tra-rami-paralleli](dipendenza-tra-rami-paralleli.md) | REPO-H: 2 occorrenze auto-corrette | 2026-08-27 |
| [estrattore-test-dipendenza-refactor](estrattore-test-dipendenza-refactor.md) | REPO-G: test-computeperiod.js estraiFunzioneRigaSingola | 2026-08-27 |
| [estensione-testata-non-distruttiva](estensione-testata-non-distruttiva.md) | REPO-G: Sheets.js estendiHeaderSeManca_ | 2026-08-27 |