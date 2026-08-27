# 2026-08-27 — test: AI_Programmer usato per correggere REPO-E
**Autore**: sessione ZCode su mandato di Luca · 43+ giri (censimento 91/91 + fan-out 2×21), 34 rilievi veri, 4 PR (#371-374: Logistica_Esterna 12 commit, SD 8, Golilla 6, Scadenzario 6; banchi PRIMA/DOPO, sabotaggi, guardia-nel-ponte verificata col grep, 3 difetti NUOVI trovati correggendo).

**Cosa ho usato**: canone gas-sviluppo completo, gas_qualita (lead), verifica_banco, famiglie, metodo, corpus-prima-di-attaccare (14 rilavorazioni evitate).
**Cosa ha retto**: il metodo end-to-end in autonomia — ogni PR col banco che prova il difetto PRIMA; il grep-sul-frontend ha salvato 4 funzioni che l'audit voleva rinominare; il banco ha fermato in itinere una regressione (SD caso zero-ordini).
**Cosa ho improvvisato**: worktree separati per PR parallele (pattern dipendenza-tra-rami applicato d'ufficio); gate pre-commit auto-montati dal correttore sul repo di lavoro.
**Proposta al canone**: (1) il rilevatore migliorato DAL CAMPO: ombre solo top-level (65/65 FP chiusi) + clearContent() incluso (falsa negativa peggiore) — GIÀ su main; (2) difetti del rilevatore restanti: paginazione mal-ancorata, security-codes nel sorgente non visti; (3) pattern candidato "il banco ferma in itinere" (regressione colta durante la correzione, non dopo); (4) i difetti trovati CORREGGENDO (funzione chiamata inesistente da un trigger, contatore test sempre-0) confermano: correggere È un giro di audit.
**11 domande di dominio aperte per Luca** (4 LE + 7 gruppo 1) — nelle PR.

**Postilla (Luca, stesso giorno)**: il processo serve SOLO a migliorare la procedura di AI_Programmer e AI_Develop — le 4 PR sono state CHIUSE come artefatti di test (branch conservati), i rilievi e le correzioni vivono nei report (copiati in AI_Develop/docs/campo-audit). Leva per il canone: chi corregge PER TEST dichiara test-only nella PR fin dall apertura, non lascia merge in attesa.

**Chiusura (Luca)**: AI_Develop è SCOLLEGATO dai veri script (specchio, non sorgente del vivo) — le correzioni mergiate non toccano produzione. Il ciclo di test si chiude qui: procedura migliorata (rilevatore corretto dal campo, regola test-only, canone), parco-specchio migliorato senza rischio, 11 domande di dominio registrate nei report per quando il vivo verrà toccato davvero.
