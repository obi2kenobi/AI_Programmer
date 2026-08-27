# 2026-08-27 — test: AI_Programmer usato per correggere REPO-E
**Autore**: sessione ZCode su mandato di Luca · 43+ giri (censimento 91/91 + fan-out 2×21), 34 rilievi veri, 4 PR (#371-374: Logistica_Esterna 12 commit, SD 8, Golilla 6, Scadenzario 6; banchi PRIMA/DOPO, sabotaggi, guardia-nel-ponte verificata col grep, 3 difetti NUOVI trovati correggendo).

**Cosa ho usato**: canone gas-sviluppo completo, gas_qualita (lead), verifica_banco, famiglie, metodo, corpus-prima-di-attaccare (14 rilavorazioni evitate).
**Cosa ha retto**: il metodo end-to-end in autonomia — ogni PR col banco che prova il difetto PRIMA; il grep-sul-frontend ha salvato 4 funzioni che l'audit voleva rinominare; il banco ha fermato in itinere una regressione (SD caso zero-ordini).
**Cosa ho improvvisato**: worktree separati per PR parallele (pattern dipendenza-tra-rami applicato d'ufficio); gate pre-commit auto-montati dal correttore sul repo di lavoro.
**Proposta al canone**: (1) il rilevatore migliorato DAL CAMPO: ombre solo top-level (65/65 FP chiusi) + clearContent() incluso (falsa negativa peggiore) — GIÀ su main; (2) difetti del rilevatore restanti: paginazione mal-ancorata, security-codes nel sorgente non visti; (3) pattern candidato "il banco ferma in itinere" (regressione colta durante la correzione, non dopo); (4) i difetti trovati CORREGGENDO (funzione chiamata inesistente da un trigger, contatore test sempre-0) confermano: correggere È un giro di audit.
**11 domande di dominio aperte per Luca** (4 LE + 7 gruppo 1) — nelle PR.
