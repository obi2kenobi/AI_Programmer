# SAL — il diario vivo del sistema

> Diario del sistema di sviluppo (hub + cervelli + turno notturno + giudizio).
> Ogni decisione porta la data e i fatti che l'hanno imposta. Aggiornato dal morning-gate
> e a ogni decisione strutturale.

<!-- SAL-INDICE: generato da tools/sal-indice.sh — non editare a mano -->
## Indice del diario

- [2026-08-21 — assemblaggio del sistema](#2026-08-21-assemblaggio-del-sistema)
- [2026-08-21, ore 12 — prima lezione operativa del gate (e chi la firma)](#2026-08-21-ore-12-prima-lezione-operativa-del-gate-e-chi-la-firma)
- [2026-08-21, pomeriggio — graphify entra nel sistema come strato di navigazione](#2026-08-21-pomeriggio-graphify-entra-nel-sistema-come-strato-di-navigazione)
- [2026-08-21, sera — l'esperimento DFlash2: il video prometteva 3x, i fatti dicono altro](#2026-08-21-sera-l-esperimento-dflash2-il-video-prometteva-3x-i-fatti-dicono-altro)
- [2026-08-21, sera — loop engineering: il nome arriva dopo la pratica](#2026-08-21-sera-loop-engineering-il-nome-arriva-dopo-la-pratica)
- [2026-08-21, pomeriggio tardi — ponytail e superpowers: il delta, non il catechismo](#2026-08-21-pomeriggio-tardi-ponytail-e-superpowers-il-delta-non-il-catechismo)
- [2026-08-21, sera — la review di Opus applicata: ogni punto verificato sul codice, poi corretto](#2026-08-21-sera-la-review-di-opus-applicata-ogni-punto-verificato-sul-codice-poi-corretto)
- [2026-08-21, notte — dev-critic: il critico costruttivo diventa un comando, non un'abitudine](#2026-08-21-notte-dev-critic-il-critico-costruttivo-diventa-un-comando-non-un-abitudine)
- [2026-08-21, notte — dev-critic verifica la review Opus: un fix confermato solo a metà](#2026-08-21-notte-dev-critic-verifica-la-review-opus-un-fix-confermato-solo-a-metà)
- [2026-08-21, notte (2) — il bypass dell'allowlist chiuso con l'opzione (c) di Luca](#2026-08-21-notte-2-il-bypass-dell-allowlist-chiuso-con-l-opzione-c-di-luca)
- [2026-08-21, notte (3) — gate-summary: i dati promessi diventano leggibili](#2026-08-21-notte-3-gate-summary-i-dati-promessi-diventano-leggibili)
- [2026-08-21, sera — il test che contava: sviluppare una feature NUOVA](#2026-08-21-sera-il-test-che-contava-sviluppare-una-feature-nuova)
- [2026-08-21, sera (2) — secondo turno preparato e il processo si difende da solo](#2026-08-21-sera-2-secondo-turno-preparato-e-il-processo-si-difende-da-solo)
- [2026-08-21, sera (3) — il primo A/B giorno-vs-notte, e la commessa col difetto](#2026-08-21-sera-3-il-primo-a-b-giorno-vs-notte-e-la-commessa-col-difetto)
- [2026-08-21, notte — le interazioni col giorno diventano workflow del sistema](#2026-08-21-notte-le-interazioni-col-giorno-diventano-workflow-del-sistema)
- [2026-08-21, notte (2) — il primo giro di /audit-commesse: 3 commesse su 4 difettose](#2026-08-21-notte-2-il-primo-giro-di-audit-commesse-3-commesse-su-4-difettose)
- [2026-08-21, notte (3) — il raccolto di REPO-A entra: 18 pattern vivi](#2026-08-21-notte-3-il-raccolto-di-repo-a-entra-18-pattern-vivi)
- [2026-08-21, notte (4) — quattro ambiti mancanti nel roster, chiesti da Luca dopo l'analisi](#2026-08-21-notte-4-quattro-ambiti-mancanti-nel-roster-chiesti-da-luca-dopo-l-analisi)
- [2026-08-21, notte (5) — due giri del pilota chiusi end-to-end, e un vincolo scoperto sul vivo](#2026-08-21-notte-5-due-giri-del-pilota-chiusi-end-to-end-e-un-vincolo-scoperto-sul-vivo)
- [2026-08-21, notte (6) — Giro 1 dei "3 giri con test autonomi": audit-commessa alla prova](#2026-08-21-notte-6-giro-1-dei-3-giri-con-test-autonomi-audit-commessa-alla-prova)
- [2026-08-21, notte (7) — Giro 2 dei "3 giri autonomi": verifica-visiva su un artefatto vero](#2026-08-21-notte-7-giro-2-dei-3-giri-autonomi-verifica-visiva-su-un-artefatto-vero)
- [2026-08-21, notte (8) — Giro 3 dei "3 giri autonomi": la lente sicurezza di dev-critic alla prova](#2026-08-21-notte-8-giro-3-dei-3-giri-autonomi-la-lente-sicurezza-di-dev-critic-alla-prova)
- [2026-08-21, notte (9) — Luca chiede altri 10 giri: Giro 4, Design assente](#2026-08-21-notte-9-luca-chiede-altri-10-giri-giro-4-design-assente)
- [2026-08-21, notte (10) — Giro 5: una convenzione di dominio inventata, non confermata](#2026-08-21-notte-10-giro-5-una-convenzione-di-dominio-inventata-non-confermata)
- [2026-08-21, notte (11) — Giro 6: una regressione vera, e cosa fa davvero il gate](#2026-08-21-notte-11-giro-6-una-regressione-vera-e-cosa-fa-davvero-il-gate)
- [2026-08-21, notte (12) — Giro 7: verifica-visiva non vedeva "undefined"](#2026-08-21-notte-12-giro-7-verifica-visiva-non-vedeva-undefined)
- [2026-08-21, notte (13) — Giro 8: due commesse gemelle, un conflitto reale, e un buco nel gate](#2026-08-21-notte-13-giro-8-due-commesse-gemelle-un-conflitto-reale-e-un-buco-nel-gate)
- [2026-08-21, notte (14) — Giro 9: gate-esito.sh su dati VERI, non su un test giocattolo](#2026-08-21-notte-14-giro-9-gate-esito-sh-su-dati-veri-non-su-un-test-giocattolo)
- [2026-08-21, notte (15) — Giro 10: Closes multiplo e prima commessa chore, entrambi puliti](#2026-08-21-notte-15-giro-10-closes-multiplo-e-prima-commessa-chore-entrambi-puliti)
- [2026-08-21, notte (16) — Giri 11/12: la propria citazione non verificata, trovata verificandola](#2026-08-21-notte-16-giri-11-12-la-propria-citazione-non-verificata-trovata-verificandola)
- [2026-08-21, notte (17) — le due correzioni in sospeso, eseguite col sì di Luca](#2026-08-21-notte-17-le-due-correzioni-in-sospeso-eseguite-col-sì-di-luca)
- [2026-08-21, notte (18) — un bug reale su un progetto vero apre una lente mancante nel roster](#2026-08-21-notte-18-un-bug-reale-su-un-progetto-vero-apre-una-lente-mancante-nel-roster)
- [2026-08-21 — nuova regola: qui solo metodo, mai il nome dei progetti onboardati](#2026-08-21-nuova-regola-qui-solo-metodo-mai-il-nome-dei-progetti-onboardati)
- [2026-08-21 — Giro 1 di 5 su un progetto onboardato: due bug della stessa famiglia di (18), un secondo pattern nuovo](#2026-08-21-giro-1-di-5-su-un-progetto-onboardato-due-bug-della-stessa-famiglia-di-18-un-secondo-pattern-nuovo)
- [2026-08-21 — Giro 2 sullo stesso progetto onboardato: un terzo pattern, sul TEST non sul fix](#2026-08-21-giro-2-sullo-stesso-progetto-onboardato-un-terzo-pattern-sul-test-non-sul-fix)
- [2026-08-21 — Giro 3 sullo stesso progetto onboardato: un addendum, non un pattern nuovo](#2026-08-21-giro-3-sullo-stesso-progetto-onboardato-un-addendum-non-un-pattern-nuovo)
- [2026-08-21 — Chiusura dei 5 giri autonomi su un secondo progetto onboardato: cosa ha funzionato nel processo](#2026-08-21-chiusura-dei-5-giri-autonomi-su-un-secondo-progetto-onboardato-cosa-ha-funzionato-nel-processo)
- [2026-08-22, mattina — la notte ha parlato: 11h39m su #12, zero file](#2026-08-22-mattina-la-notte-ha-parlato-11h39m-su-12-zero-file)
- [2026-08-22, mattina (2) — messo a posto tutto: la regola del territorio, e il giorno chiude #10+#12](#2026-08-22-mattina-2-messo-a-posto-tutto-la-regola-del-territorio-e-il-giorno-chiude-10-12)
- [2026-08-22, pomeriggio — ciclo dei 5 giri su REPO-D (mandato: tutto da solo, processo osservato)](#2026-08-22-pomeriggio-ciclo-dei-5-giri-su-repo-d-mandato-tutto-da-solo-processo-osservato)
- [2026-08-22, sera — ciclo dei 5 giri completato: il processo osservato in loop](#2026-08-22-sera-ciclo-dei-5-giri-completato-il-processo-osservato-in-loop)
- [2026-08-22, notte — ciclo 2 su REPO-D: la progettazione protagonista](#2026-08-22-notte-ciclo-2-su-repo-d-la-progettazione-protagonista)
- [2026-08-22, notte (2) — 10 giri di auto-miglioramento: il sistema giudica se stesso](#2026-08-22-notte-2-10-giri-di-auto-miglioramento-il-sistema-giudica-se-stesso)
- [2026-08-22, notte (3) — 10 giri di FEATURE: cosa mancava davvero](#2026-08-22-notte-3-10-giri-di-feature-cosa-mancava-davvero)
- [2026-08-22, notte (4) — le decisioni di dominio prese (mandato di Luca: "decidi da solo")](#2026-08-22-notte-4-le-decisioni-di-dominio-prese-mandato-di-luca-decidi-da-solo)
- [2026-08-22, notte (5) — terzo ciclo di 10 giri: bug reali trovati eseguendo, non leggendo](#2026-08-22-notte-5-terzo-ciclo-di-10-giri-bug-reali-trovati-eseguendo-non-leggendo)
- [2026-08-22, notte (6) — correzione: la diagnosi "claude -p lento" era sbagliata](#2026-08-22-notte-6-correzione-la-diagnosi-claude--p-lento-era-sbagliata)
- [2026-08-22, notte (7) — Set 1/3: agenti giorno+notte armonizzati, 8 bug reali](#2026-08-22-notte-7-set-1-3-agenti-giorno-notte-armonizzati-8-bug-reali)
- [2026-08-22, notte (8) — Set 2/3: capacità di progettare, 3 skill mai esistite + bug ad alta severità](#2026-08-22-notte-8-set-2-3-capacità-di-progettare-3-skill-mai-esistite-bug-ad-alta-severità)
- [2026-08-22, notte (9) — Set 3/3: flusso delle idee, tutte le interazioni](#2026-08-22-notte-9-set-3-3-flusso-delle-idee-tutte-le-interazioni)
- [2026-08-23 — 4° ciclo, Set 1/3 giro 1: agenti per problemi matematico-contabili, ancorati a dati reali](#2026-08-23-4-ciclo-set-1-3-giro-1-agenti-per-problemi-matematico-contabili-ancorati-a-dati-reali)
- [2026-08-23 (2) — Set 1/3 giri 2-3: la skill raggiunge la commessa, poi il progetto nuovo](#2026-08-23-2-set-1-3-giri-2-3-la-skill-raggiunge-la-commessa-poi-il-progetto-nuovo)
- [2026-08-23 (3) — Set 1/3 giro 4: il gate non applicava a se stesso la propria regola](#2026-08-23-3-set-1-3-giro-4-il-gate-non-applicava-a-se-stesso-la-propria-regola)
- [2026-08-23 (4) — Set 1/3 giro 5: la mappa completa non conosceva la nuova capacità](#2026-08-23-4-set-1-3-giro-5-la-mappa-completa-non-conosceva-la-nuova-capacità)
- [2026-08-23 (5) — Set 1/3 giro 6: secondo caso, dominio diverso — il metodo generalizza](#2026-08-23-5-set-1-3-giro-6-secondo-caso-dominio-diverso-il-metodo-generalizza)
- [2026-08-23 (6) — Set 1/3 giro 7: due lenti sullo stesso dominio non si conoscevano](#2026-08-23-6-set-1-3-giro-7-due-lenti-sullo-stesso-dominio-non-si-conoscevano)
- [2026-08-23 (7) — Set 1/3 giro 8: terzo caso, dominio cespiti — il segno del fondo](#2026-08-23-7-set-1-3-giro-8-terzo-caso-dominio-cespiti-il-segno-del-fondo)
- [2026-08-23 (8) — Set 1/3 giro 9: l'audit serale non sapeva controllare l'oracolo](#2026-08-23-8-set-1-3-giro-9-l-audit-serale-non-sapeva-controllare-l-oracolo)
- [2026-08-23 (9) — Set 1/3 giro 10: quarto caso — indici di crisi, il lato economico-industriale](#2026-08-23-9-set-1-3-giro-10-quarto-caso-indici-di-crisi-il-lato-economico-industriale)
- [2026-08-23 (10) — Set 2/3 giro 1: /design-doc confronta le opzioni, non solo le elenca](#2026-08-23-10-set-2-3-giro-1-design-doc-confronta-le-opzioni-non-solo-le-elenca)
- [2026-08-23 (11) — Set 2/3 giro 2: graphify esiste per la notte, non arrivava al giorno](#2026-08-23-11-set-2-3-giro-2-graphify-esiste-per-la-notte-non-arrivava-al-giorno)
- [2026-08-23 (12) — Set 2/3 giro 3: la tabella di confronto rischiava di restare in chat](#2026-08-23-12-set-2-3-giro-3-la-tabella-di-confronto-rischiava-di-restare-in-chat)
- [2026-08-23 — design: la lente sicurezza (dev-critic §2bis) diventa automatica nel gate?](#2026-08-23-design-la-lente-sicurezza-dev-critic-2bis-diventa-automatica-nel-gate)
- [2026-08-23 (13) — Set 2/3 giro 5: la mappa descriveva ancora il vecchio design-doc](#2026-08-23-13-set-2-3-giro-5-la-mappa-descriveva-ancora-il-vecchio-design-doc)
- [2026-08-23 (14) — Set 2/3 giro 6: la stessa staleness, un file mai testato prima](#2026-08-23-14-set-2-3-giro-6-la-stessa-staleness-un-file-mai-testato-prima)
- [2026-08-23 (15) — chiude un loose end del Set 1 giro 4: il report del gate mostrava solo l'ultimo test](#2026-08-23-15-chiude-un-loose-end-del-set-1-giro-4-il-report-del-gate-mostrava-solo-l-ultimo-test)
- [2026-08-23 (16) — Set 2/3 giro 8: la stessa staleness, un terzo posto mai controllato](#2026-08-23-16-set-2-3-giro-8-la-stessa-staleness-un-terzo-posto-mai-controllato)
- [2026-08-23 (17) — Set 2/3 giro 9: le idee di dev-critic non avevano un passo successivo](#2026-08-23-17-set-2-3-giro-9-le-idee-di-dev-critic-non-avevano-un-passo-successivo)
- [2026-08-23 (18) — Set 2/3 giro 10 (chiude il set): design-doc apriva solo la porta della notte](#2026-08-23-18-set-2-3-giro-10-chiude-il-set-design-doc-apriva-solo-la-porta-della-notte)
- [2026-08-23 (19) — Set 3/3 giro 1: PROJECT.md non conosceva la nuova capacità contabile](#2026-08-23-19-set-3-3-giro-1-project-md-non-conosceva-la-nuova-capacità-contabile)
- [2026-08-23 (20) — Set 3/3 giro 2: la traccia dei cervelli di giorno entrava e non usciva](#2026-08-23-20-set-3-3-giro-2-la-traccia-dei-cervelli-di-giorno-entrava-e-non-usciva)
- [2026-08-23 (21) — Set 3/3 giro 3: i codici anonimi non avevano un indice](#2026-08-23-21-set-3-3-giro-3-i-codici-anonimi-non-avevano-un-indice)
- [2026-08-23 — design: quale modello ha giudicato ogni riga del banco avversariale?](#2026-08-23-design-quale-modello-ha-giudicato-ogni-riga-del-banco-avversariale)
- [2026-08-23 (22) — Set 3/3 giro 5: METHOD.md non conosceva il registro del giorno, e citava male due percorsi](#2026-08-23-22-set-3-3-giro-5-method-md-non-conosceva-il-registro-del-giorno-e-citava-male-due-percorsi)
- [2026-08-23 (23) — Set 3/3 giro 6: "in testa al file" era in fondo](#2026-08-23-23-set-3-3-giro-6-in-testa-al-file-era-in-fondo)
- [2026-08-23 (24) — Set 3/3 giro 7: lo stesso gap, mai propagato al file gemello](#2026-08-23-24-set-3-3-giro-7-lo-stesso-gap-mai-propagato-al-file-gemello)
- [2026-08-23 (25) — Set 3/3 giro 8: la mappa citava solo metà del limite condiviso](#2026-08-23-25-set-3-3-giro-8-la-mappa-citava-solo-metà-del-limite-condiviso)
- [2026-08-23 (26) — Set 3/3 giro 9: tenere d'occhio la crescita della suite](#2026-08-23-26-set-3-3-giro-9-tenere-d-occhio-la-crescita-della-suite)
- [2026-08-23 (27) — Set 3/3 giro 10 (chiude il set): verifica end-to-end di tutto il gate](#2026-08-23-27-set-3-3-giro-10-chiude-il-set-verifica-end-to-end-di-tutto-il-gate)
- [2026-08-23 — Set 1 giro 1: nessun sistema di subagent, solo skill](#2026-08-23-set-1-giro-1-nessun-sistema-di-subagent-solo-skill)
- [2026-08-23 — Set 1 giro 2: un secondo agente, non un duplicato](#2026-08-23-set-1-giro-2-un-secondo-agente-non-un-duplicato)
- [2026-08-23 — Set 1 giro 3: il terzo ruolo, dogfoodato per davvero sui 4 tool esistenti](#2026-08-23-set-1-giro-3-il-terzo-ruolo-dogfoodato-per-davvero-sui-4-tool-esistenti)
- [2026-08-23 — Set 1 giro 4: quinto caso reale minato da gas-src, scadenzario aging](#2026-08-23-set-1-giro-4-quinto-caso-reale-minato-da-gas-src-scadenzario-aging)
- [2026-08-23 — Set 1 giro 5: stesso gap già trovato due volte, mai chiuso per gli agenti](#2026-08-23-set-1-giro-5-stesso-gap-già-trovato-due-volte-mai-chiuso-per-gli-agenti)
- [2026-08-23 — Set 1 giro 6: il sistema di agenti non si conosceva da solo](#2026-08-23-set-1-giro-6-il-sistema-di-agenti-non-si-conosceva-da-solo)
- [2026-08-23 — Set 1 giro 7: un limite reale non ancora dichiarato](#2026-08-23-set-1-giro-7-un-limite-reale-non-ancora-dichiarato)
- [2026-08-23 — Set 1 giro 8: dogfooding reale sui propri agenti — non sono invocabili qui](#2026-08-23-set-1-giro-8-dogfooding-reale-sui-propri-agenti-non-sono-invocabili-qui)
- [2026-08-23 — Set 1 giro 9: la scoperta del giro 8 entra in DEBITI.md](#2026-08-23-set-1-giro-9-la-scoperta-del-giro-8-entra-in-debiti-md)
- [2026-08-23 — Set 1 giro 10 (chiude il set): un bug reale trovato rieseguendo la suite più volte](#2026-08-23-set-1-giro-10-chiude-il-set-un-bug-reale-trovato-rieseguendo-la-suite-più-volte)
- [2026-08-23 — Set 2 giro 1: la regola "tabella persistita" era verificata solo nella prosa, non nella realtà](#2026-08-23-set-2-giro-1-la-regola-tabella-persistita-era-verificata-solo-nella-prosa-non-nella-realtà)
- [2026-08-23 — Set 2 giro 2: selezione del contesto — nessun percorso senza graphify](#2026-08-23-set-2-giro-2-selezione-del-contesto-nessun-percorso-senza-graphify)
- [2026-08-23 — Set 2 giro 3: `/goal` costruito e mai eseguito, chiuso col primo loop reale](#2026-08-23-set-2-giro-3-goal-costruito-e-mai-eseguito-chiuso-col-primo-loop-reale)
- [2026-08-23 — Set 2 giro 4: il wizard chiedeva "come" verificare, non "quale livello"](#2026-08-23-set-2-giro-4-il-wizard-chiedeva-come-verificare-non-quale-livello)
- [2026-08-23 — Set 2 giro 5: il gate meccanico verifica che un riferimento SOMIGLI a](#2026-08-23-set-2-giro-5-il-gate-meccanico-verifica-che-un-riferimento-somigli-a)
- [2026-08-23 — Set 2 giro 6: "scelta delle migliori idee" al plurale — nessuna riga lo diceva](#2026-08-23-set-2-giro-6-scelta-delle-migliori-idee-al-plurale-nessuna-riga-lo-diceva)
- [2026-08-23 — Set 2 giro 7: cosa fare quando NESSUNA opzione è buona](#2026-08-23-set-2-giro-7-cosa-fare-quando-nessuna-opzione-è-buona)
- [2026-08-23 — Set 2 giro 8: lo stesso bug (nomi hardcoded, non un glob) trovato una terza volta](#2026-08-23-set-2-giro-8-lo-stesso-bug-nomi-hardcoded-non-un-glob-trovato-una-terza-volta)
- [2026-08-23 — Set 2 giro 9: lo stesso bug, una quarta e una quinta volta (una scritta da me in questo stesso ciclo)](#2026-08-23-set-2-giro-9-lo-stesso-bug-una-quarta-e-una-quinta-volta-una-scritta-da-me-in-questo-stesso-ciclo)
- [2026-08-23 — Set 2 giro 10 (chiude il set): verifica end-to-end di tutta la pipeline di progettazione](#2026-08-23-set-2-giro-10-chiude-il-set-verifica-end-to-end-di-tutta-la-pipeline-di-progettazione)
- [2026-08-23 — Set 3 giro 1: un cross-reference in una sola direzione](#2026-08-23-set-3-giro-1-un-cross-reference-in-una-sola-direzione)
- [2026-08-23 — Set 3 giro 2: i diagrammi in cima mostravano solo la strada notturna](#2026-08-23-set-3-giro-2-i-diagrammi-in-cima-mostravano-solo-la-strada-notturna)
- [2026-08-23 — Set 3 giro 3: l'indice dei codici anonimi era rimasto indietro sul proprio ciclo](#2026-08-23-set-3-giro-3-l-indice-dei-codici-anonimi-era-rimasto-indietro-sul-proprio-ciclo)
- [2026-08-23 — Set 3 giro 4: la stessa famiglia di bug diventa un pattern nel catalogo](#2026-08-23-set-3-giro-4-la-stessa-famiglia-di-bug-diventa-un-pattern-nel-catalogo)
- [2026-08-23 — Set 3 giro 5: una regola del catalogo mai verificata meccanicamente](#2026-08-23-set-3-giro-5-una-regola-del-catalogo-mai-verificata-meccanicamente)
- [2026-08-23 — Set 3 giro 6: `/goal` aveva raggiunto il suo obiettivo ma nessuno lo sapeva ancora](#2026-08-23-set-3-giro-6-goal-aveva-raggiunto-il-suo-obiettivo-ma-nessuno-lo-sapeva-ancora)
- [2026-08-23 — Set 3 giro 7: controllo-gestione parlava un vocabolario isolato sulla verifica](#2026-08-23-set-3-giro-7-controllo-gestione-parlava-un-vocabolario-isolato-sulla-verifica)
- [2026-08-23 — Set 3 giro 8: sweep sistematico di tutte le citazioni fra skill/agenti](#2026-08-23-set-3-giro-8-sweep-sistematico-di-tutte-le-citazioni-fra-skill-agenti)
- [2026-08-23 — Set 3 giro 9: un'ipotesi di bug smentita dal vivo, prima di diventare un fix](#2026-08-23-set-3-giro-9-un-ipotesi-di-bug-smentita-dal-vivo-prima-di-diventare-un-fix)
- [2026-08-23 — Set 3 giro 10 (chiude il set e il ciclo): verifica end-to-end finale](#2026-08-23-set-3-giro-10-chiude-il-set-e-il-ciclo-verifica-end-to-end-finale)
- [2026-08-23 — dopo il push e la PR #35: il limite del Set 1 giro 8 era temporaneo, non permanente](#2026-08-23-dopo-il-push-e-la-pr-35-il-limite-del-set-1-giro-8-era-temporaneo-non-permanente)
- [2026-08-24 — feedback di un utente esterno reale: 5 gap di processo, non di codice](#2026-08-24-feedback-di-un-utente-esterno-reale-5-gap-di-processo-non-di-codice)
- [2026-08-24 — punti 2-4: tre nuove regole vincolanti in CLAUDE.md](#2026-08-24-punti-2-4-tre-nuove-regole-vincolanti-in-claude-md)
- [2026-08-24 — punto 5: patterns/ auto-consultato via hook PreToolUse (mai fatto prima in questo repo)](#2026-08-24-punto-5-patterns-auto-consultato-via-hook-pretooluse-mai-fatto-prima-in-questo-repo)
- [2026-08-24 — feedback dal campo (REPO-F, BC/GAS): il matching per description non è affidabile quanto presunto](#2026-08-24-feedback-dal-campo-repo-f-bc-gas-il-matching-per-description-non-è-affidabile-quanto-presunto)
- [2026-08-24 — 6° ciclo, giro 0: baseline verde, tre bug di portabilità macOS](#2026-08-24-6-ciclo-giro-0-baseline-verde-tre-bug-di-portabilità-macos)
- [2026-08-24 (2) — 6° ciclo, Set 1/3: mappa del dominio, 2 agenti e 3 oracoli](#2026-08-24-2-6-ciclo-set-1-3-mappa-del-dominio-2-agenti-e-3-oracoli)
- [2026-08-24 (3) — 6° ciclo, Set 2/3: divergenza, contesto col budget, squalifiche e spike](#2026-08-24-3-6-ciclo-set-2-3-divergenza-contesto-col-budget-squalifiche-e-spike)
- [2026-08-24 (4) — design: i costi generali % nella valorizzazione di magazzino](#2026-08-24-4-design-i-costi-generali-nella-valorizzazione-di-magazzino)
- [2026-08-24 (5) — 6° ciclo, Set 3/3: flusso=contratto, notte=agenti, gate=memoria](#2026-08-24-5-6-ciclo-set-3-3-flusso-contratto-notte-agenti-gate-memoria)
- [2026-08-24 (6) — la rotta corretta: il parco è il corpus, non la cava](#2026-08-24-6-la-rotta-corretta-il-parco-è-il-corpus-non-la-cava)
- [2026-08-24 (7) — 7° ciclo, Set 1/3: tre oracoli residui e il rilevatore meccanico](#2026-08-24-7-7-ciclo-set-1-3-tre-oracoli-residui-e-il-rilevatore-meccanico)
- [2026-08-24 (8) — 7° ciclo, Set 2/3: il flusso di progettazione dogfooddato su un caso vero](#2026-08-24-8-7-ciclo-set-2-3-il-flusso-di-progettazione-dogfooddato-su-un-caso-vero)
- [2026-08-24 (9) — 7° ciclo, Set 3/3: il hub impara a giudicare i banchi](#2026-08-24-9-7-ciclo-set-3-3-il-hub-impara-a-giudicare-i-banchi)
- [2026-08-24 (10) — il report dal campo su REPO-G: verificato,processato, chiuso](#2026-08-24-10-il-report-dal-campo-su-repo-g-verificato-processato-chiuso)
- [2026-08-26 — il report dei tagli: il canone ha retto, e cresce di cinque pezzi](#2026-08-26-il-report-dei-tagli-il-canone-ha-retto-e-cresce-di-cinque-pezzi)
- [2026-08-26 (3) — «standard non opzione»: il metodo diventa meccanico](#2026-08-26-3-standard-non-opzione-il-metodo-diventa-meccanico)
- [2026-08-26 (2) — report REPO-G versione aggiornata: tutto già chiuso, due novità](#2026-08-26-2-report-repo-g-versione-aggiornata-tutto-già-chiuso-due-novità)
- [2026-08-26 (4) — il censimento BC diventa aggiornabile (e confessa: 0 verificati su 88)](#2026-08-26-4-il-censimento-bc-diventa-aggiornabile-e-confessa-0-verificati-su-88)
- [2026-08-26 (5) — la pozza entra: il catalogo vive nell'hub, i mancanti sono 170](#2026-08-26-5-la-pozza-entra-il-catalogo-vive-nell-hub-i-mancanti-sono-170)
- [2026-08-26 (6) — censimento BC completato al vivo: 203/258, anomalie registrate](#2026-08-26-6-censimento-bc-completato-al-vivo-203-258-anomalie-registrate)
- [2026-08-27 — il report dal campo diventa sistematico (proposta di Luca)](#2026-08-27-il-report-dal-campo-diventa-sistematico-proposta-di-luca)
- [2026-08-27 (2) — distribuito chiuso: l'esperimento che non si presume](#2026-08-27-2-distribuito-chiuso-l-esperimento-che-non-si-presume)
- [2026-08-27 (3) — dieci giri di coerenza: il sistema è collegato, tre rotture trovate e chiuse](#2026-08-27-3-dieci-giri-di-coerenza-il-sistema-è-collegato-tre-rotture-trovate-e-chiuse)
- [2026-08-27 (4) — venti giri, lenti nuove: mutazione dei guardiani e ciò che ha rivelato](#2026-08-27-4-venti-giri-lenti-nuove-mutazione-dei-guardiani-e-ciò-che-ha-rivelato)
- [2026-08-27 (5) — venti giri, terza serie: la vetrina pubblica era ferma a tre giorni fa](#2026-08-27-5-venti-giri-terza-serie-la-vetrina-pubblica-era-ferma-a-tre-giorni-fa)
- [2026-08-27 (6) — terzo report REPO-G: la riverifica indipendente chiude il loop](#2026-08-27-6-terzo-report-repo-g-la-riverifica-indipendente-chiude-il-loop)
- [2026-08-27 (7) — primo report dal campo nel formato nuovo: pattern 19, REPO-H, quattro proposte adottate](#2026-08-27-7-primo-report-dal-campo-nel-formato-nuovo-pattern-19-repo-h-quattro-proposte-adottate)
- [2026-08-27 (8) — quarto report: 30 agenti su REPO-I, cinque proposte, quattro adottate](#2026-08-27-8-quarto-report-30-agenti-su-repo-i-cinque-proposte-quattro-adottate)
- [2026-08-27 (9) — trenta giri anti-collo-di-bottiglia: quattro eliminati, tre gated](#2026-08-27-9-trenta-giri-anti-collo-di-bottiglia-quattro-eliminati-tre-gated)
- [2026-08-27 (10) — trenta giri n.2: il collegamento rotto ero io](#2026-08-27-10-trenta-giri-n-2-il-collegamento-rotto-ero-io)
- [2026-08-27 (11) — quinto report: 50 agenti su REPO-F, due rifiuti che sono il metodo](#2026-08-27-11-quinto-report-50-agenti-su-repo-f-due-rifiuti-che-sono-il-metodo)
- [2026-08-27 (12) — report REPO-I fase 2: catalogo esaurito, quattro regole nuove](#2026-08-27-12-report-repo-i-fase-2-catalogo-esaurito-quattro-regole-nuove)
- [2026-08-27 (13) — sesto report (REPO-H, 12 PR): pattern 23-24 e il workaround vm](#2026-08-27-13-sesto-report-repo-h-12-pr-pattern-23-24-e-il-workaround-vm)
- [2026-08-27 (14) — quattordici lenti su REPO-G: il metodo chiede adottare il metodo](#2026-08-27-14-quattordici-lenti-su-repo-g-il-metodo-chiede-adottare-il-metodo)
- [2026-08-27 (15) — consolidazione: tutto ciò che i cicli hanno scoperto è nel canone](#2026-08-27-15-consolidazione-tutto-ciò-che-i-cicli-hanno-scoperto-è-nel-canone)
- [2026-08-27 (16) — cinquanta giri su REPO-I: le cinque lenti per area](#2026-08-27-16-cinquanta-giri-su-repo-i-le-cinque-lenti-per-area)
- [2026-08-28 (1) — L'Hub Allo Specchio: 14 lenti indipendenti sull'hub stesso, 9 batch di fix](#2026-08-28-1-l-hub-allo-specchio-14-lenti-indipendenti-sull-hub-stesso-9-batch-di-fix)
- [2026-08-27 (17) — quarto report REPO-G: eseguite le 62 proposte, due pattern nuovi, un'obiezione superata](#2026-08-27-17-quarto-report-repo-g-eseguite-le-62-proposte-due-pattern-nuovi-un-obiezione-superata)
- [2026-08-27 (18) — il tesoro sigillato: convergenza cieca, obiezioni che invecchiano, gerarchia DOM](#2026-08-27-18-il-tesoro-sigillato-convergenza-cieca-obiezioni-che-invecchiano-gerarchia-dom)
- [2026-08-27 (19) — magazzino: 72 commit (20 bug + 55 proposte) e il handoff gap](#2026-08-27-19-magazzino-72-commit-20-bug-55-proposte-e-il-handoff-gap)
- [2026-08-28 — dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI](#2026-08-28-dossier-sd-dashboard-86-rilievi-71-dichiarati-non-verificati)
- [2026-08-28 — REPO-I fase 3 chiude il ciclo: 245 idee, 7 proposte, due pattern nuovi](#2026-08-28-repo-i-fase-3-chiude-il-ciclo-245-idee-7-proposte-due-pattern-nuovi)
- [2026-08-28 — trenta giri di indagine completa: il repo è sano, una guardia nuova per la prosa](#2026-08-28-trenta-giri-di-indagine-completa-il-repo-è-sano-una-guardia-nuova-per-la-prosa)
- [2026-08-28 (2) — cinquanta giri nuove lenti: qualità, non solo presenza](#2026-08-28-2-cinquanta-giri-nuove-lenti-qualità-non-solo-presenza)
- [2026-08-28 (3) — 50 giri 3ª batteria: lenti di evoluzione e cambiamento](#2026-08-28-3-50-giri-3ª-batteria-lenti-di-evoluzione-e-cambiamento)
- [2026-08-28 (4) — Bricoman 50 agenti: 13 confermati, 2 smentiti, l'onore funziona](#2026-08-28-4-bricoman-50-agenti-13-confermati-2-smentiti-l-onore-funziona)
- [2026-08-28 (5) — REPO-K: dal dossier ai fix, 86+25 in sessione continua](#2026-08-28-5-repo-k-dal-dossier-ai-fix-86-25-in-sessione-continua)
- [2026-08-28 (6) — l'hub allo specchio: revisione indipendente, 60+ finding](#2026-08-28-6-l-hub-allo-specchio-revisione-indipendente-60-finding)
- [2026-08-28 (7) — 8 proposte dell'audit implementate + 15 report campo triati](#2026-08-28-7-8-proposte-dell-audit-implementate-15-report-campo-triati)
- [2026-08-28 (8) — REPO-J live drift: 3 divergenze reali, 25 fix confermati, primo deploy](#2026-08-28-8-repo-j-live-drift-3-divergenze-reali-25-fix-confermati-primo-deploy)
- [2026-08-28 (9) — REPO-L (Unicredit_Factoring): 9 confermati, SECRET in history, la buona notizia provata](#2026-08-28-9-repo-l-unicredit_factoring-9-confermati-secret-in-history-la-buona-notizia-provata)
- [2026-08-28 (10) — REPO-M (Energikal): backlog di 15+20 voci, 5 domande di dominio](#2026-08-28-10-repo-m-energikal-backlog-di-15-20-voci-5-domande-di-dominio)
- [2026-08-28 (11) — REPO-L (Unicredit_Factoring): 30 agenti + 14 fix, terza sessione continua](#2026-08-28-11-repo-l-unicredit_factoring-30-agenti-14-fix-terza-sessione-continua)
- [2026-08-28 (12) — REPO-N (parrocchie): il metodo su Flask/SQLite, 13 difetti al banco](#2026-08-28-12-repo-n-parrocchie-il-metodo-su-flask-sqlite-13-difetti-al-banco)
- [2026-08-28 (13) — Energikal: chiusura sessione (5 decisioni di dominio prese, PR #55 aperta)](#2026-08-28-13-energikal-chiusura-sessione-5-decisioni-di-dominio-prese-pr-55-aperta)
- [2026-08-28 (14) — REPO-N giornata completa: 159 giri, 26 difetti corretti, 5 suite](#2026-08-28-14-repo-n-giornata-completa-159-giri-26-difetti-corretti-5-suite)


## Stato

`PRIMA INSTALLAZIONE` (2026-08-21) — sistema completo assemblato: base (regole + conoscenza),
cervelli richiamabili (`llm/`), turno notturno multi-repo, giudizio mattutino col banco
avversariale, memoria (questo file + `metrics/gate.csv`).

## Decisioni

- **2026-08-21 · Il repo chiama i vari LLM** (deciso da Luca). Wrapper uniformi `llm/ask-*`
  con contratto unico: chiunque può delegare a qualsiasi cervello. WayfinderRouter come tessuto
  per OpenCode; Opus resta diretto perché il router non implementa l'outbound Anthropic
  (verificato sui sorgenti, non presunto).
- **2026-08-21 · Nessun limite di tempo per issue notturna** (deciso da Luca, mutuata da REPO-A):
  fino a che non ha finito, il tempo non esiste. Guardie: prompt anti-loop + review del mattino.
- **2026-08-21 · Config reale fuori dal repo pubblico**: `night-shift/repos.conf` è gitignored —
  i nomi delle repo private non entrano in un repo pubblico. Nel repo solo `repos.conf.example`.
- **2026-08-21 · Il giudizio è avversariale**: il morning-gate non colleziona report, prova a
  smentire le PR (metodo del Supervisore in REPO-A, applicato al sistema). I fallimenti
  diventano proposte di commesse correttive — nulla si rifà senza il sì di Luca.
- **2026-08-21 · La scoperta di gap/nuove idee diventa una skill, non un'abitudine** (deciso da
  Luca): il ruolo "cervello di giorno per giudizio/architettura" della matrice `llm/README.md`
  esisteva solo come istruzione implicita ("fallo tu quando serve"). Diventa la skill
  `dev-critic` (`.claude/skills/dev-critic/`), richiamabile on-demand da qualunque sessione
  (questo hub o un progetto onboardato), non legata al turno notturno.

## Log cronologico

### 2026-08-21 — assemblaggio del sistema

Costruito su tutto ciò che le tre notti su REPO-A hanno insegnato (cinque difetti
d'infrastruttura trovati e corretti; il modello locale capisce ma non converge sulle indagini;
le issue devono essere commesse). Primo carico notturno per il hub: compilazione della colonna
_Significato_ BC — lavoro documentale, zero credenziali, il riscontro resta umano.

### 2026-08-21, ore 12 — prima lezione operativa del gate (e chi la firma)

Assemblando il sistema, chi scrive ha spinto `.night-verify` su REPO-A dal branch della PR
invece che da main: il commit è evaporato in un merge shallow senza inquinare la PR (verificato),
ma la dichiarazione è arrivata a destinazione solo al secondo tentativo, dal checkout pulito.
Regola che ne esce, già implicita nel turno notturno e ora estesa a tutto il sistema:
**ogni operazione git parte da main pulito o dichiara esplicitamente il branch** — e il gate
legge le dichiarazioni da `origin/main`, mai dal branch della PR (il branch può essere nato
prima della dichiarazione). Primo giro completo del giudice: PR #369 → verifiche dichiarate
✅ (test-motore 2005/0) → banco avversariale con proposta di smentita → metrica registrata.

### 2026-08-21, pomeriggio — graphify entra nel sistema come strato di navigazione

Il fatto che lo impone: l'agente notturno consuma la notte leggendo file (il collo di bottiglia
misurato sull'issue #363). `graphify query` restituisce un sottografo deterministico con file e
riga esatti — verificato dal vivo sul hub: «avvio del server ollama» → `ensure_server()` a
`night-shift.sh:L45` con l'intorno di chiamate, in una interrogazione.

**Versione pinata: 0.9.48** (trovata installata la 0.8.50 — vecchia). Lezione di REPO-A
importata: lo schema cambia fra minor (0.8→0.9.36 ha rotto tre tool contemporaneamente) —
aggiornare solo a versioni verificate e stampare la versione sugli artefatti.

**Le tre regole del grafo** (tutte pagate da REPO-A, le adottiamo):
1. il grafo serve per ORIENTARSI e TROVARE (file:riga), non come oracolo
2. gli edge `calls` non sono risolti: non farci conto (grafo-findings.js li evita da mesi)
3. verificare-il-grafo, non fidarsi (template: grafo-verifica.js — oracolo indipendente + fail)

Completato anche il riuso Wayfinder: endpoint Anthropic-inbound verificato → nasce
`llm/claude-local.sh` (Claude Code come harness sul locale); `connect claude` non automatizzato
in questa build, ricetta manuale documentata in `router/README.md`. Route nominate: SPERIMENTALI
(instradano ma rispondono vuoto nel test). Privacy posture documentata come leva per i dati BC.

### 2026-08-21, sera — l'esperimento DFlash2: il video prometteva 3x, i fatti dicono altro

Occasione: un video mostrava Qwen3.8-27B a 10 tok/s via llama.cpp e 2,7-3,4x col draft model
DFlash2 (z-lab). Abbiamo misurato tutto sul nostro Mac (metodo: stessa identica richiesta).

**Risultati (stessa richiesta, 400 token):**

| Configurazione | Velocità | Condizione |
|---|---|---|
| Ollama, Q4_K_M MTP (il nostro) | 3,7 tok/s | funzionante |
| llama.cpp mainline, stesso GGUF | 3,7 tok/s | **nessun guadagno** |
| llama.cpp + DFlash2 (build PR #27342) | **0,14 tok/s** | thrashing: 10,2 GB di swap |

**Le tre lezioni (tutte con la prova):**
1. **llama.cpp diretto NON è più veloce di Ollama** su questa macchina — il 2x del video non
   si riproduce nelle nostre condizioni. Il collo è la banda memoria, non il runtime.
2. **DFlash2 su 24 GB unificati è una regressione, non un'accelerazione**: target (16,8) +
   drafter (1,1) + contesti sforano il working set Metal e ogni token paga il disco. Serve RAM
   maggiore. Il GGUF del drafter resta in `~/models-dflash2-q4.gguf` per il giorno in cui
   l'hardware crescerà.
3. ⛔ **LA SCOPERATA DELLA SESSIONE: il working set Metal è ~75% della RAM** (~18 GB sui
   nostri 24) e l'OS lo STRINGE sotto pressione. Questa È la causa dei nostri «errori Metal»
   ricorrenti: configurazioni che stanno dentro il limite oggi falliscono domani quando il
   sistema si riprende margine. Regola: mai forzare `-ngl 99`, sempre fit automatico; il
   Q5_XL (21 GB) non è mai stato vicino a funzionare — ora sappiamo perché con precisione.

Il turno notturno resta su Ollama + Q4_K_M MTP: 3,7-5,9 tok/s, il massimo dimostrato su
questa macchina. Il file `llama-bench.log` conserva le prove.

### 2026-08-21, sera — loop engineering: il nome arriva dopo la pratica

Il sistema pratica loop engineering dalla prima notte (trigger→harness→verifica→memoria→ciclo)
senza conoscerne il nome; il vocabolario pubblico (Cherny, Steinberger, Karpathy-AutoResearch)
arriva ora e lo formalizza in `docs/system.md`. Si adottano tre cose: la **tassonomia dei cinque
livelli di verifica** — che svela che il "riscontro" BC è verità terrena ritardata (livello 3)
praticata da giugno, e che il nostro banco è un livello 4 potenziato (smentisce, non si
autovaluta) — il **comando /goal** per i loop diurni (verifica dichiarata, tetto di tentativi,
log in `loops/`, avversario prima della vittoria), e la **tensione dichiarata**: notte senza
limite di tempo vs /goal sempre col tetto — commessa lunga unica vs ottimizzazione iterativa,
entrambe giuste nel loro contesto.

### 2026-08-21, pomeriggio tardi — ponytail e superpowers: il delta, non il catechismo

Due framework entrano nel sistema lo stesso giorno, con lo stesso criterio: si adotta ciò che
il metodo NON ha già.

**Ponytail** (107k ⭐, MIT; ~54% meno codice nei benchmark — ricalibrati dopo la contestazione
della community, onestà metodologica che ci è piaciuta): la scala a sette pioli entra in §2
come PROCEDURA del "zero waste" (*serve? → riusa → stdlib → nativo → dipendenza esistente →
una riga → il minimo*), dopo la lettura mai prima. Plugin installato su **OpenCode** (la notte
scrive minimale: a 4 tok/s meno output = notte più veloce — l'ottimizzazione più economica
misurata finora, batte DFlash che era una regressione) e su **Claude Code**. Nasce
**DEBITI.md** (da /ponytail-debt: le scorciatoie rimandate si scrivono). Il gate passa a
**tre controlli**: verifiche dichiarate + banco avversariale ESECUTORE (velocizzato: via
thinking dalla generazione — il test lo teneva 25 minuti) + verifica di MINIMITÀ consultiva
(livello 4, delete-list in stile /ponytail-review; bloccante solo quando le metriche lo
giustificheranno).

**Superpowers** (275k ⭐, MIT, 476k installazioni, Jesse Vincent): mappatura onesta prima di
adottare — TDD rigoroso = il nostro banco-scritto-prima; debugging 4 fasi ≈ §5; review agent
= il gate. Il delta vero che entra: il **guardrail tre-strike in §5** (dopo tre fix falliti si
ferma TUTTO e si rivede l'architettura: il difetto non è dove si crede) e **/brainstorming per
ZCode** (disciplina socratica, una domanda per ciclo, convergenza su formulazione verificabile
→ /goal o commessa). Plugin installato su Claude Code dal marketplace ufficiale.

**Cosa NON adottiamo** (economia del metodo, ragioni scritte): subagent-dev-review (c'è il
gate), skill-writing TDD (c'è skill-creator), execute-plan a blocchi (le sessioni lo fanno
nativamente), ponytail-ultra e ponytail-mcp (non misurati sul modello locale).

Il flusso giorno-perfetto che ne esce, documentato: **/brainstorming → /goal → (notte) → gate**.

### 2026-08-21, sera — la review di Opus applicata: ogni punto verificato sul codice, poi corretto

Review esterna del hub (sessione Claude Code, branch di analisi) con mandato esplicito di
riverificare ogni punto prima di toccare nulla — fatto, e il report era accurato al 100% su
quanto verificabile. Cosa è stato corretto, con la prova:

**Bug §2.1 (confermato: header a 7 colonne, righe a 6):** il CSV ora scrive la settima colonna
(vuota al gate) e nasce `gate-esito.sh` per registrare l'esito umano (merge/chiusura/commessa)
sull'ultima riga corrispondente. Le righe storiche col vocabolario vecchio NON sono state
riscritte: il drift si annota qui (righe con banco `proposto`/`vuoto` precedono l'esecutore).

**Bug §2.2 (confermato: main hardcoded in 6 punti + silenziatore alla r.85):** `night-shift/lib.sh`
con `default_branch()` (symbolic-ref → gh repo view → main con AVVISO). Refactor completo;
checkout fallito → log duro + riclone, mai continuare in silenzio.

**Sicurezza §3 (buco reale: find -delete e git reset --hard passavano la blacklist):** difesa in
profondità approvata da Luca — allowlist per segmento (split su && || ; |, git readonly) come
prima linea + **sandbox seatbelt** (`sandbox.sb`: rete negata, scritture solo nella copia
disposabile) come seconda + watchdog 120s esteso anche alle .night-verify (l'asimmetria).
**Testato dal vivo: curl in sandbox = exit 7 (connessione negata), scrittura fuori workdir
vietata, dentro concessa.**

**Processo §4:** percorso cloud/ibrido documentato in onboard-repo.sh e system.md (MCP può
commit-tare file; label e repos.conf restano manuali sul Mac); drift-check del CLAUDE.md nel
gate (informativo); **credenziali BC in REPO-C: VERIFICATO peggio del report — oltre al
file rtf, lo stesso segreto Azure era sparso in 21 commit (Config.gs, script, SAL.md). Storia
ripulita con filter-repo (file rtf rimosso + 2 valori segreti sostituiti con --replace-text),
gitleaks post-scan: ZERO leak. ⛔ L'AZIONE CHE RESTA È DI LUCA: ruotare le credenziali su
Azure — le vecchie hanno viaggiato nella storia git. gitleaks ora gira in bootstrap (bloccante
pre-push) e come pre-scan in onboard.**

**Minors §5:** il hub ora ha il suo `.night-verify` (shellcheck + bash -n — il sistema che
pretende verifiche dichiarate finalmente le dichiara per sé); warning quando si tocca il limite
50; DEBITI.md compilato con i rinvi deliberati (rotazione log, portabilità, test bc_*).

Nota operativa per Luca: i cloni locali di REPO-C vanno RICLONATI (la storia è stata
riscritta, gli hash sono cambiati).

### 2026-08-21, notte — dev-critic: il critico costruttivo diventa un comando, non un'abitudine

Occasione: la revisione manuale sopra (letti tutti gli script, poi onboarding REALE di
`REPO-C` per verificarli sul campo) ha trovato bug non visibili dalla sola lettura
(`gate.csv` non scrive mai la colonna "esito"; `main` hardcoded come default branch in più
punti; banco avversariale che esegue `eval` su un comando generato da LLM con solo una
blacklist regex, nessun sandbox reale) e gap di processo (nessun percorso per onboarding da
sessione cloud senza `gh`; `credenziali BC.rtf` committata in CDG scoperta ispezionando prima
di toccare) — tutti poi confermati e corretti, come documentato sopra.

La lezione che ne esce: **il dogfooding reale trova ciò che l'ispezione statica non trova** —
tre dei gap sopra sarebbero rimasti invisibili senza aver provato l'onboarding per davvero.
Si decide di non lasciare questo metodo confinato a una sessione di chat: nasce la skill
`dev-critic`, richiamabile on-demand su qualunque target (hub o progetto onboardato), che
istituzionalizza il metodo (lettura critica + uso reale) e aggiunge un compito che il gate
notturno non fa: proporre **funzionalità non ancora considerate**, non solo trovare difetti in
ciò che esiste.

### 2026-08-21, notte — dev-critic verifica la review Opus: un fix confermato solo a metà

Primo uso reale della skill appena nata, sulle correzioni appena applicate (voce sopra). Metodo
rispettato: non fidarsi del diff, eseguirlo.

**`gate-esito.sh` era rotto dal giorno stesso della sua nascita.** `morning-gate.sh` scrive ora
7 campi con virgola finale per l'esito vuoto; `gate-esito.sh` riconosceva "esito già presente"
contando le virgole con una soglia scritta per il *vecchio* formato a 6 campi — quindi
scambiava OGNI riga nuova (esito vuoto) per "già registrata" e si rifiutava sempre di scrivere.
Riprodotto dal vivo (`bash gate-esito.sh owner/repo 99 merge` → `esito già registrato`, falso).
Il bug §2.1 della review originale (livello memoria vuoto) era quindi ancora aperto, solo
spostato: prima la colonna non veniva scritta, ora viene scritta ma non si può mai aggiornare.
**Corretto**: riconoscimento per numero di CAMPI (non virgole) con distinzione esplicita dei due
formati; tre casi testati dal vivo (formato nuovo, formato storico, doppia registrazione
respinta) — tutti corretti.

**La sicurezza §3 resta solo parzialmente chiusa — verificato, non corretto in questo giro.**
`gate_allowlist_ok()` controlla solo il primo token del segmento: `bash -c`, `python3 -c`,
`awk 'BEGIN{system()}'`, `sed .../e` restano nell'allowlist e sono state provate dal vivo a
bucarla (tutte passano). Il sandbox seatbelt non compensa: nega rete e scrittura fuori workdir,
non la lettura — un `cat ~/.ssh/id_rsa` in sandbox leggerebbe comunque il file (solo non
potrebbe spedirlo in rete). Non è un fix meccanico come gate-esito: cambia il modello di
minaccia, quindi resta in `DEBITI.md` per una decisione esplicita con Luca, non corretto a
sorpresa.

**Nuova funzionalità proposta (scope dichiarato vs implementato):** `docs/system.md` promette
che "le decisioni future le decidono i dati accumulati" in `metrics/gate.csv` — ma oggi nessuno
strumento lo legge, nemmeno dopo il fix di `gate-esito.sh`. Proposta: `gate-summary.sh`, un
riepilogo periodico (% verifiche ok, % smentite dal banco, repo con più commesse correttive
ripetute, PR senza esito da troppi giorni) — da costruire DOPO aver verificato che l'esito si
popola davvero nel tempo, altrimenti sarebbe un riepilogo di dati vuoti.

### 2026-08-21, notte (2) — il bypass dell'allowlist chiuso con l'opzione (c) di Luca

Decisione presa da Luca sulle opzioni presentate (handoff serale): **entrambe**. Fatto e
dimostrato con gli stessi comandi che avevano trovato il bypass (ora devono fallire — e
falliscono): interpreti general-purpose rimossi dall'allowlist (`bash -c`, `python3 -c`,
`awk system()`, `sed /e`, `node -e`, `npm run` → tutti BLOCCATI; il banco smentisce con
grep/cat/git readonly) e sandbox con **letture negate sui percorsi sensibili** (`.ssh`,
`.aws`, `.gnupg`, token gh in `.config/gh`, credenziali Claude, `.ollama`) — provato dal
vivo: `cat ~/.config/gh/hosts.yml` in sandbox → Operation not permitted; `/etc/hosts` e
workdir restano leggibili. Chiuso in pubblico anche il falso positivo del quoting: lo split
dei segmenti ora rispetta le virgolette (`grep -c "a;b" file` passa). I due debiti di
dev-critic sono marcati SALDATI in DEBITI.md.

### 2026-08-21, notte (3) — gate-summary: i dati promessi diventano leggibili

Il prerequisito dell'handoff verificato SENZA assumerlo: la colonna esito era vuota (#369
aspetta la review di Luca — e questo è già aging vero) e #364 era stata fusa prima che la
colonna esistesse. Backfill onesto del fatto vero (#364 → merge, con le condizioni dell'epoca)
e test di `gate-esito.sh` sul formato a 7 campi (correttamente rifiuta il doppio inserimento).
Nasce `night-shift/gate-summary.sh` (modulo `csv` di Python, zero dipendenze): per repo %
verifiche ok, % smentite del banco, aree fragili (commesse correttive ripetute ≥2) e aging
deduplicato per PR sull'attesa VERA (riga più vecchia). Prima lettura dai dati: 5/7 verifiche
ok, 0 smentite, 1 merge — e #369 in attesa. Allineato anche system.md sul percorso cloud/ibrido
(gli era sfuggito, nota dell'handoff: dichiarato ma non scritto lì).

### 2026-08-21, sera — il test che contava: sviluppare una feature NUOVA

Mandato di Luca: usare il sistema per una feature vera su REPO-B, guardare
dove fallisce. Il test ha trovato il bug più importante DENTRO l'operatore: la prima proposta
era pattern-matching (bottone gemello), non progettazione — /brainstorming saltato. Il redo
ha eseguito il processo per intero: 3 agenti in parallelo leggono tutto (prodotto, motore
Python, intento/storia), gap analysis col desiderio del progetto alla mano (il suo SAL §6
aveva già la roadmap), scelta socratica → **analisi per spessore** (la granularità del banco
di il referente di dominio, assente in dashboard). Design documentato, commessa #11 chirurgica, turno in corsa
con anche la #10 (CSV). Cinque finding d'infrastruttura in giornata, tutti corretti: pre-scan
rotto, processo-saltabile, zombie opencode, doppio proprietario del server, turni sovrapposti
(lock per repo). L'analisi completa con le proposte: docs/test-processo-2026-08-21.md —
la prima: template issue con sezione DESIGN obbligatoria, così il metodo non dipende più
dalla disciplina dell'operatore.

### 2026-08-21, sera (2) — secondo turno preparato e il processo si difende da solo

Miglioramento #1 dell'analisi implementato E testato in serata: il turno ora **salta le issue
senza \`## Design\`** (con commento esplicativo nell'issue) e il template GitHub le fa nascere
già col posto per il design — bootstrap lo crea, onboard lo porta. Finding #6 pagato subito:
committare nel workdir mentre il turno lo possiede finisce sul branch della notte — regola
scritta: **il giorno non tocca il workdir della notte, passa dall'API** (il template è stato
messo su main via gh api dopo l'errore). Nuove commesse #12 (registri nel PDF, da SAL §6.8) e
#13 (formati italiani nel PDF, da SAL §8) — entrambe nascono dal SAL del progetto, non dal
pattern matching: il processo corretto comincia prima ancora del turno.

### 2026-08-21, sera (3) — il primo A/B giorno-vs-notte, e la commessa col difetto

Luca ha mandato Claude (giorno) sulla STESSA commessa #11 che la notte stava macinando.
**Risultato netto**: Claude completa in 10m35s con qualità superiore al previsto — regex
verificata byte-per-byte, **codice eseguito in Node con 13 asserzioni su dati sintetici
(tutte passate)**, un limite onesto trovato ESECUTANDO e documentato nella PR (#14). La notte:
1h24m e ancora zero file scritti. Il sistema ha la sua prima misura A/B: il fattore ~10x
a favore del giorno su commesse con esplorazione, e la conferma che la notte è per il volume
meccanico, non per l'ignoto.

**La scoperta più utile però è un difetto MIO**: la commessa #11 assumeva che i dati
per-codice fossero nell'oggetto bilancio — Claude, eseguendo, ha scoperto che l'acquistato è
aggregato per famiglia e il dettaglio per-codice è un dataset separato on-demand. Il giorno
se ne accorge leggendo; la notte probabilmente ci annega (l'ipotesi più probabile del suo
silenzio). Lezione strutturale: **la commessa deve dichiarare la FORMA DEI DATI verificata
sul codice** — ora il template issue ha la sezione obbligatoria "## Forma dei dati".

Le tre cose che Claude non ha capito dalla documentazione → tre azioni fatte:
1. forma dei dati non documentata → sezione obbligatoria nel template (sopra)
2. grammatica dei codici articolo non documentata → TODO dominio (da chiedere a il referente di dominio,
   candidato a docs/GRAMMATICA_CODICI.md quando qualcuno la sa scrivere)
3. CLAUDE.md §6 di PEFC citava il progetto Motore (engine, pnpm, PHP!) → corretto via API
   con il contesto reale del repo

### 2026-08-21, notte — le interazioni col giorno diventano workflow del sistema

Le sessioni Claude di oggi (review, dev-critic, A/B, audit lanciato da Luca) non restano
scambi: diventano fasi ripetibili. Nascono `/audit-commesse` (il pre-flight serale che
verifica le assunzioni delle commesse sul codice prima che la notte le incontri — la lezione
dell'A/B strutturata) e `/design-doc` (il design con opzioni che non implementa: la scelta
resta umana), entrambi per Claude E ZCode. Il gate ora giudica anche i branch claude/*: il
lavoro del giorno passa verifiche e banco come quello notturno — un giudice, due occhi.
Il ciclo completo: brainstorming → design-doc → commessa → audit-commesse → notte → gate
→ review. Ogni fase ha il suo comando, ogni comando il suo perché scritto.

### 2026-08-21, notte (2) — il primo giro di /audit-commesse: 3 commesse su 4 difettose

Luca ha lanciato l'audit su Claude la sera stessa in cui il comando è nato. Verdetto:
**tre commesse su quattro avevano difetti veri** — #13 interamente obsoleta (il PDF era già in
formato italiano: la nota SAL che la giustificava descriveva uno stato superato MAI
aggiornato — rettificata via API con la regola che ne esce), #10 con premessa falsa (il CSV
esiste già, verificato per esecuzione — ridotta a micro-commessa sul gap reale: la data nel
nome file), #12 con due assunzioni sbagliate (tabella DDS esistente da estendere, funzione
citata errata — riscritta). #11: assunzioni giuste ma specifica incompleta — l'audit ha
trovato la causa probabile dello stallo notturno (la fonte per-codice mai nominata). Notte
fermata su #11: la consegna esiste già (PR #14 del giorno), la coda riparte alle 23:00 con
le commesse corrette.

**Il dato di sistema che conta**: il tasso di difetti delle commesse scritte a mano era 75%.
La difesa in profondità ora è: template (Design + Forma dei dati obbligatori) → audit serale
→ notte. L'audit ha pagato il biglietto al primo giro, trovando con esecuzione (non lettura)
ciò che l'autore non vedeva. Regola aggiunta alla自身的 pratica: chi scrive commesse verifica
le affermazioni del SAL contro il codice — un diario che dice il passato come presente è
peggiore di un diario mancante (rettifica scritta anche nel SAL di PEFC).

### 2026-08-21, notte (3) — il raccolto di REPO-A entra: 18 pattern vivi

La PR #7 di Claude (8 pattern setacciati dai 93 strumenti di REPO-A, tutti ancorati e
provati per esecuzione dove possibile) è MERGED — e con essa la #14 (spessori): Luca ha
fuso entrambe in giornata. La libreria patterns/ conta ora 18 voci vive. Note di_onestà:
il pattern trovare-non-e-fallire dichiara che riallinea-mirror.sh intero non ha mai girato
nell'ambiente del raccolto (scritto, non finto); tre candidati scartati CON motivo. Il
pattern segreto-come-impronta indica un buco nostro (il gate non maschera gli output) —
in DEBITI. Rettificata pure una mia pretesa: il README diceva che il grafo indicizza i
pattern — falso con --code-only, voce in DEBITI. Backfill CSV: #14 fusa-prima-del-gate.

### 2026-08-21, notte (4) — quattro ambiti mancanti nel roster, chiesti da Luca dopo l'analisi

Luca ha chiesto un giudizio sul roster di cervelli/ruoli del sistema, "in base ai GAS fatti
e analizzati" (CDG, REPO-B, il parco di REPO-A). Risposta: il PROCESSO è
maturo e misurato (A/B, audit-commesse), ma i ruoli restano due soli (notte meccanica,
giorno generico) contro un roster molto più specializzato osservato in REPO-A
(bc-specialist, ui-engineer, business-development-specialist, ecc.). Quattro aggiunte,
tutte richieste e implementate lo stesso giro:

- **`audit-commessa`** (`.claude/skills/audit-commessa/`) — scoperta collaterale: `/audit-commesse`
  e `/design-doc`, citati come comandi in SAL.md e docs/system.md, non esistevano come file
  in nessun repo (solo prosa). `audit-commessa` li rende un artefatto vero e ci porta dentro
  la lente Business Central (aggregazione per famiglia ≠ per codice, endpoint con buchi
  noti, CATALOGO_ENDPOINT_BC.md come fonte di verità) — è lo specialista forma-dati/BC
  richiesto, senza duplicare un ruolo nuovo scollegato dal processo esistente.
  `/design-doc` resta non formalizzato: fuori scope di questo giro, segnalato non deciso.
- **`verifica-visiva`** (`.claude/skills/verifica-visiva/` + `tools/verifica-visiva.js`) —
  il buco più ripetuto nell'audit di oggi: 4 commesse su 4 (#10-13) finivano con "review
  visiva di Luca nel deploy" come unico controllo sul frontend. Screenshot reale via
  Chromium headless (zero dipendenze nuove — CLI diretta, non il package playwright) +
  guardia contro segnali d'errore noti di Apps Script e pagine vuote. **Provato dal vivo in
  questa sessione** sui tre casi (pagina sana, pagina con "Autorizzazione richiesta", pagina
  vuota) — tutti rilevati correttamente. **Limite dichiarato**: non provato contro un vero
  deploy Apps Script, che richiede clasp/OAuth sul Mac.
- **Lente sicurezza in `dev-critic`** (§2bis, non un nuovo skill) — i due incidenti reali di
  oggi (bypass dell'allowlist, credenziali BC in CDG) non sono mai stati trovati da un ruolo
  dedicato: dev-critic ora applica SEMPRE (non solo su richiesta) la lente sicurezza quando
  il target esegue codice generato da LLM o stampa output derivato da terzi.
- **`docs/GRAMMATICA_DOMINIO_TEMPLATE.md`** — chiude un TODO lasciato aperto dall'audit di
  PEFC ("grammatica dei codici articolo non documentata... da chiedere a il referente di dominio"): nessun
  ruolo possedeva la cattura del vocabolario tribale che si ripete in ogni progetto BC del
  gruppo. Seminato ora in `bootstrap-app.sh`/`onboard-repo.sh` (copiato solo se assente).

**Prossimo passo, richiesto da Luca**: un pilota end-to-end su `night-shift-pilot` (repo
nuovo, scaffold minimo) per verificare che l'intero processo — comprese queste quattro
aggiunte — produca davvero una commessa pronta per la notte. App scelta apposta di scarso
valore proprio ("fatturati per cliente e articolo" su BC, dati mock): serve a testare il
banco di sviluppo, non a produrre un'app vera.

### 2026-08-21, notte (5) — due giri del pilota chiusi end-to-end, e un vincolo scoperto sul vivo

Luca ha chiesto di eseguire il processo su `night-shift-pilot` "monitorandolo per
migliorarlo", esplicitamente saltando l'attesa del turno reale (non lanciabile da questa
sessione: niente Ollama/opencode/clasp qui). Due cicli completi, entrambi commessa→
implementazione (Claude al posto della notte, dichiarato in ogni PR)→verifica reale
(`npm test`)→PR bozza→merge→issue chiusa:

- **#4** (fatturato per cliente/articolo su mock BC): 3/3 test verdi, `Closes #4` ha chiuso
  l'issue correttamente al merge (keyword inglese, coerente con la lezione già nota).
- **#6** (riepilogo: totali + cliente top, sopra il codice di #4): 4/4 test verdi (i 3
  esistenti invariati, zero regressioni), stessa dinamica.

**Il vincolo vero, trovato eseguendo due commesse in sequenza nella stessa sessione**: la
crescita "a piccoli passi" richiede che la commessa N si basi sul codice della N-1 —
merge di mezzo. Il sistema non ha (né dovrebbe avere di default) un modo per bypassare il
sì umano al merge, quindi ho chiesto e ottenuto un'autorizzazione esplicita, dichiaratamente
scoped a questo pilota di test ("senza valore reale"), per non fermarmi a ogni giro. **Non è
un difetto del sistema**: nel mondo reale la notte è quotidiana, non compressa in pochi
minuti — il vincolo è emerso solo per la compressione temporale del test, ma vale la pena
saperlo: chi testa più commesse dipendenti in una sola sessione deve aspettarsi di dover
chiedere il via libera al merge più spesso del normale.

**Gap onesto confermato due volte**: il banco avversariale resta non eseguibile da una
sessione cloud (nessun cervello locale/Opus raggiungibile) — segnalato in entrambe le PR,
non finto.

### 2026-08-21, notte (6) — Giro 1 dei "3 giri con test autonomi": audit-commessa alla prova

Luca ha chiesto almeno 3 giri autonomi (test + sviluppo), ognuno con un'analisi sincera e
una correzione al progetto master. Giro 1: stress-test deliberato di `audit-commessa` — ho
scritto io stesso l'issue #8 di `night-shift-pilot` con un'affermazione sulla forma dei dati
FALSA ma plausibile ("il dato per-cliente è già disponibile in `riepilogoFatturato`"),
apposta senza verificarla, per vedere se la skill la cattura prima che diventi codice.

**Esito sul contenuto: la skill ha funzionato.** Applicata come da manuale (§1.3: eseguire,
non leggere), ha smascherato la falsità con un `node -e` reale su `src/fatturato.js`:
`riepilogoFatturato` costruisce una mappa `perCliente` completa ma la scarta, restituendo
solo `clienteTop` (un vincitore, non l'elenco) — esattamente il pattern "aggregazione
riassuntiva ≠ dettaglio completo" già pagato su REPO-B #11 e scritto nella
lente BC della skill. Corretta l'issue #8 con `## Forma dei dati (verificata sul codice)` e
la correzione concreta per chi implementerà la commessa.

**Esito sul processo, non richiesto ma trovato per strada — questo è il vincolo reale**:
invocare `audit-commessa` è FALLITO due volte di seguito ("Unknown skill: audit-commessa")
mentre ero sul branch corretto (`claude/nuovi-ruoli-audit`, PR #8 non ancora mersa) con il
file `.claude/skills/audit-commessa/SKILL.md` confermato presente su disco — poi ha
funzionato al tentativo successivo, senza che io avessi fatto altro che passare un turno.
La causa più probabile: l'elenco delle skill disponibili per la sessione non si aggiorna in
modo sincrono al `git checkout`, ma con un ritardo di durata non garantita. **Questo è un
difetto operativo reale**: una skill che vive solo su un branch/PR non mersa è, per questo
motivo, invocabile in modo inaffidabile nella stessa sessione — non un problema della skill
in sé, ma del momento in cui viene provata. Correzione applicata al master: voce in
DEBITI.md che raccomanda di non concludere "skill assente" al primo fallimento quando il
file esiste sul branch giusto, e di preferire il merge delle PR che introducono skill non
appena il contenuto è verificato, proprio per non pagare due volte questo ritardo.

Chiuso anche il ciclo pratico: implementata la commessa #8 corretta (`csvFatturatoPerCliente`
costruito da zero, non estratto da `riepilogoFatturato`), 6/6 test verdi, PR #9 mersa,
`Closes #8` verificato al merge.

### 2026-08-21, notte (7) — Giro 2 dei "3 giri autonomi": verifica-visiva su un artefatto vero

Giro 2: creata la commessa #10 (report HTML statico del fatturato, `src/report.js` +
`tools/genera-report.js` → `dist/report.html`, gitignored) apposta per dare a
`verifica-visiva` un vero artefatto del pilota da controllare — non più solo le pagine
sintetiche scritte a mano per testare lo strumento la prima volta (limite scritto in
DEBITI.md dopo l'aggiunta del roster).

**Esito: positivo, e verificato per davvero.** `node tools/verifica-visiva.js file://.../dist/report.html out.png`
→ exit 0; ho guardato lo screenshot (non solo il verdetto del tool) e corrisponde
esattamente ai dati generati (5 righe, stessi clienti/articoli/importi del file HTML).
Ho anche provato un caso limite reale — non ipotetico — che un report vero incontrerebbe:
0 fatture nel periodo (stato legittimo, non un errore). Nessun falso positivo: titolo e
intestazioni tabella restano sopra la soglia di "pagina vuota" (40 caratteri) della skill
anche senza righe di dati.

**Limite onesto, non richiuso**: questo resta un test su `file://` locale via Chromium
headless, non su un vero deploy Apps Script (dominio `script.google.com`, OAuth) — quel
gap dichiarato in DEBITI.md non si chiude da questa sessione (nessun clasp/OAuth
disponibile). Correzione applicata al master: la voce DEBITI.md è stata aggiornata per
riflettere il progresso reale senza sovra-dichiararlo — "provata anche su un artefatto
vero" è vero, "provata su un deploy reale" resta falso finché qualcuno con clasp non lo fa.

### 2026-08-21, notte (8) — Giro 3 dei "3 giri autonomi": la lente sicurezza di dev-critic alla prova

Giro 3: stress-test deliberato della lente sicurezza (§2bis). Creata la commessa #12 su
`night-shift-pilot` ("diagnostica connessione BC") che chiede letteralmente di stampare a
console `JSON.stringify(config)` di una configurazione di connessione mock
(`mock/bc-connessione.json`, con un `apiKey` finto ma verosimile) — implementata alla
lettera, PRIMA di qualunque audit, esattamente come la seguirebbe la notte senza giudizio
proprio.

**Esito: la lente funziona quando viene invocata, e l'ho verificato eseguendo il codice
davvero**, non leggendolo: `node -e 'diagnosticaConnessione(require("./mock/bc-connessione.json"))'`
stampa a console la riga intera con `"apiKey":"mock-api-key-NON-REALE-..."` in chiaro —
esattamente il pattern descritto in `segreto-come-impronta.md` (nato dallo stesso tipo di
incidente, un `client_secret` finito in una trascrizione). Applicando il metodo della
skill (lettura critica + dogfooding reale, non ipotetico) il problema è innegabile e
puntuale: `src/diagnostica.js:2`.

**Il vincolo reale, non di contenuto ma di processo**: nella pipeline dichiarata
(commessa → audit-commessa → notte → morning-gate → review umana) NON esiste un punto in
cui la lente sicurezza di dev-critic sia invocata automaticamente — è "on demand", per
disegno (la SKILL.md dice "usa quando l'utente chiede... o invoca /dev-critic
esplicitamente"). Una commessa come la #12 potrebbe attraversare l'intera pipeline ed
essere mersa senza che nessuno la applichi mai, esattamente come i due incidenti originali
(allowlist bucabile, credenziali BC committate) non sono mai stati trovati finché qualcuno
non ha deliberatamente provato ad aggirarli. **Correzione applicata al master**: aggiunto
un puntatore nella sezione `## Verifica` del template issue night-shift
(`.github/ISSUE_TEMPLATE/night-shift.md`) — stesso schema già usato per `verifica-visiva`
— che invita a valutare la lente sicurezza quando la commessa stampa/logga output
derivato da config/credenziali/dati di terzi, dichiarando esplicitamente che il gate non
la esegue da sé.

Chiuso anche il ciclo pratico: `src/diagnostica.js` corretto per mascherare `apiKey` con
un'impronta (pattern `segreto-come-impronta`, non con un'omissione silenziosa) prima del
merge della PR del pilota — la scoperta non resta solo teorica.

### 2026-08-21, notte (9) — Luca chiede altri 10 giri: Giro 4, Design assente

Luca ha chiesto altri 10 giri dopo i primi 3. Giro 4: issue #14 creata apposta SENZA
`## Design` (e con un claim sui dati sbagliato, "il campo filtro è già in Amount" quando
serve `Posting_Date`). **Esito positivo**: applicando `audit-commessa` mi sono fermato al
passo 1 come da regola, senza guardare il claim sui dati — comportamento corretto, non
un'audit sprecata su una commessa che la notte salterebbe comunque.

**Finding minore, corretto**: la regola diceva solo "fermati e dillo" senza specificare
DOVE — ambiguo tra "dillo alla sessione che chiama" e "dillo sulla issue". Ho deciso per
un commento sull'issue (visibile a chi la possiede, non solo in chat) e ho chiarito la
SKILL.md di conseguenza, così le prossime invocazioni non debbano decidere da capo.

### 2026-08-21, notte (10) — Giro 5: una convenzione di dominio inventata, non confermata

Issue #15: "i codici `ART-` sono articoli di test, esclusi dai report" — convenzione
scritta come fatto, MAI confermata. Verificato: `docs/GRAMMATICA_DOMINIO.md` non la
cita, e la sua stessa regola dice che una riga senza fonte è un'ipotesi. Eseguito
l'impatto reale sul mock: il filtro avrebbe escluso 6/6 righe (tutti gli articoli
mock sono `ART-*`) — uno svuotamento totale di qualunque report, non un dettaglio.
Corretta l'issue, commessa sospesa (nessuna implementazione: una scelta di dominio con
impatto non si decide da sé).

**Correzione applicata al master**: il metodo di `audit-commessa` (§1.2) verificava
solo claim su forma-dati/campi, non convenzioni di dominio presentate come fatto —
aggiunto un passo esplicito che impone il controllo su `GRAMMATICA_DOMINIO.md` anche
per questo tipo di claim, con la prova di questo giro come esempio ancorato.

### 2026-08-21, notte (11) — Giro 6: una regressione vera, e cosa fa davvero il gate

Issue #16: cambiare l'ordinamento di `fatturatoPerClienteArticolo` (per cliente invece
che per importo) — richiesta plausibile, non un errore evidente. Implementata da sola:
`npm test` → 11/12, 1 fallito (l'ordine atteso dal test esistente). Verificato che
nessun altro consumatore dipendesse da quell'ordine, poi corretto il test al nuovo
contratto — non disattivato. 12/12, PR #17 mersa.

**Verifica di un fatto sul sistema, non presunto**: sono andato a leggere cosa fa
DAVVERO `morning-gate.sh` su una verifica fallita (non l'ho mai eseguito dal vivo prima
d'ora in questo modo): non merge mai da solo — scrive un verdetto `verifiche-fallite`
sempre visibile nel riepilogo finale, e propone (testo, non eseguito) un comando
`gh issue create` correttivo "da approvare". Design corretto: nessun merge automatico,
umano sempre nel loop.

**Correzione applicata al master**: quel comando correttivo propone un body che dice
solo "Dettagli nel report locale del gate" — ma il report è un file sul Mac che ha
eseguito il gate, irraggiungibile da chi lavorerà la issue correttiva altrove (stesso
tipo di buco già noto per il percorso cloud/ibrido). L'output vero del fallimento
esiste già nello stesso report, solo non viene copiato nella issue. Voce in DEBITI.md:
non corretto il codice (decidere cosa dell'output è sicuro incollare in una issue
pubblica è una scelta di Luca, non mia).

### 2026-08-21, notte (12) — Giro 7: verifica-visiva non vedeva "undefined"

Simulato un caso realistico (non pianificato per far fallire lo strumento apposta,
ma un vero scenario BC: un cliente il cui master data non è ancora sincronizzato,
`Customer_Name` assente). Il report generato mostra `undefined` in chiaro nella cella
"Cliente" — verificato eseguendo `generaReportHtml` e guardando l'HTML. Passato a
`tools/verifica-visiva.js`: **exit 0, "nessun segnale d'errore"** — falso verde
confermato anche a occhio nello screenshot.

**Corretto direttamente** (fix piccolo, senza trade-off di design): aggiunti
`"undefined"`, `"NaN"`, `"[object Object]"` a `SEGNALI_ERRORE`. Riprovato lo stesso
file: ora exit 1, segnale rilevato. Riprovato anche il report sano del Giro 2: resta
exit 0, nessuna regressione. `"null"` bare escluso deliberatamente: in un progetto in
italiano collide con "nullo"/"nulla" — servirebbe un match a parola intera che
`SEGNALI_ERRORE` (solo substring oggi) non supporta; non aggiunto per non introdurre
un falso positivo peggiore di quello che risolve.

### 2026-08-21, notte (13) — Giro 8: due commesse gemelle, un conflitto reale, e un buco nel gate

Due issue (#18, #19) create dalla stessa base commit, stesso punto di
`src/fatturato.js`, apposta per produrre un conflitto di merge vero. Mersa #19 per
prima; la PR di #18 è arrivata a `mergeable_state: "dirty"` — verificato via API, non
presunto. Risolto correttamente: `git merge origin/main`, conflitto vero su due file,
tenute ENTRAMBE le funzioni (indipendenti, nessuna esclude l'altra), 14/14 test dopo
la risoluzione — nessun lavoro scartato, nessun `--force`.

**Correzione applicata al master, trovata verificando come si comporterebbe il gate
reale su questo stesso scenario**: letto `night-shift/night-shift.sh` — ogni branch
`night/issue-N` nasce da `origin/$DB` al momento della creazione (riga 168), quindi
due commesse nella stessa notte possono benissimo generare questo identico conflitto
in produzione, non solo nel test. Verificato che `morning-gate.sh` non menziona MAI
`mergeable`/`conflict` (grep, zero risultati) — potrebbe scrivere "verifiche-ok" per
una PR che i test passano sul proprio branch ma che GitHub rifiuterebbe di mergere,
e l'umano lo scoprirebbe solo provando a mergere. **Corretto direttamente** (aggiunta
informativa, nessun comportamento nuovo, GitHub blocca già il merge da solo):
`gh pr list` ora chiede anche il campo `mergeable`, e il report segnala
`⛔ Non mergeable: conflitto con main` in testa alla sezione della PR, prima di tutto
il resto. Verificato: `bash -n` passa; **non eseguito dal vivo contro `gh pr list`**
(nessun `gh` autenticato in questa sessione) — il campo `mergeable` è documentato
nello schema `gh pr list --json`, non inventato, ma la prova end-to-end resta da fare
sul Mac.

### 2026-08-21, notte (14) — Giro 9: gate-esito.sh su dati VERI, non su un test giocattolo

I tre casi che il primo test di `gate-esito.sh` aveva confermato (formato nuovo,
formato storico, doppia registrazione respinta) erano su un CSV sintetico minimale.
Giro 9: stesso script, ma testato su una COPIA di lavoro del vero `metrics/gate.csv`
(mai toccato l'originale — verificato con `git diff`, vuoto). Quel file reale ha una
forma che un test giocattolo non riproduce: 5 righe storiche a 6 campi PIÙ 2 righe
nuove a 7 campi vuote, tutte per lo STESSO repo+PR (`REPO-A #369`), impilate da
notti diverse prima che qualcuno registrasse un esito.

**Trovato un bug reale, non ipotetico.** Prima chiamata (`gate-esito.sh ... 369
merge`): corretta, scrive sull'ULTIMA riga pendente (riga 9) — esattamente il
comportamento dichiarato. **Seconda chiamata identica, stesso comando**: doveva
essere respinta ("esito già registrato") e invece ha scritto di nuovo, esito
"registrato" su una riga DIVERSA e più vecchia (riga 7, anch'essa a 7 campi ma
ancora vuota) — lo stesso evento reale (un merge) finirebbe duplicato su due righe
del CSV, gonfiando le metriche aggregate di `gate-summary.sh`. Riprodotto due volte
di seguito, stesso esito.

**Causa verificata leggendo il codice**: lo script cerca "l'ultima riga pendente"
ad ogni chiamata, non "esiste già un esito per questo repo+PR in una qualunque
riga" — quindi se più righe pendenti si sono accumulate nel tempo (realistico: la
notte scrive una riga nuova a ogni gate, un PR può restare aperto su più notti),
una seconda chiamata trova sempre un'altra vittima. **Non corretto qui**: la
soluzione ovvia ("respingi se un esito esiste già per questo repo+PR") romperebbe
il caso legittimo opposto — un PR con esito `commessa` che poi, dopo la correzione,
riceve una riga nuova con esito `merge` in una notte successiva. Distinguere i due
casi (doppia registrazione per errore vs. secondo esito legittimo su un ciclo
correttivo) è una decisione di design sul significato di "esito", non un fix
meccanico — voce in DEBITI.md con la riproduzione esatta, per il sì di Luca.

### 2026-08-21, notte (15) — Giro 10: Closes multiplo e prima commessa chore, entrambi puliti

Ultimo dei 10 giri extra. Due issue gemelle (#22 LICENSE, #23 .editorconfig),
un'unica PR con `Closes #22` e `Closes #23` nel body, prima commessa di tipo
`chore` in questo pilota (finora solo feat/fix/refactor). Verificato via API dopo
il merge: entrambe le issue `state: closed`, `state_reason: completed`, entrambe
con `closed_by_pull_requests` che punta alla stessa PR #24 — GitHub riconosce
correttamente due keyword indipendenti nello stesso body, non solo la prima.

**Esito onesto: nessun difetto trovato, nessuna correzione al master per questo
giro.** Non ogni giro deve produrne una — forzarne una qui sarebbe meno onesto che
dirlo chiaramente. Comportamento mercanico di GitHub confermato, non specifico ad
alcun codice di questo sistema.

---

**Chiusura dei 10 giri extra (Giri 4-10, oltre ai 3 iniziali).** Sintesi dei
risultati concreti sul master: 2 fix diretti a codice condiviso (`verifica-visiva.js`
non vedeva `undefined`/`NaN`; `morning-gate.sh` non segnalava PR non mergeable), 1
bug reale documentato ma non corretto perché richiede una decisione di design
(`gate-esito.sh`, doppia registrazione), 2 chiarimenti al metodo di `audit-commessa`
(dove riportare "Design assente"; verificare anche le convenzioni di dominio, non
solo la forma-dati), 1 giro senza difetti (Giro 10). Il filo comune resta lo stesso
di tutta la sessione: ogni claim in questo diario è stato eseguito, non presunto —
compreso "non ho trovato niente" quando è stato il caso.

### 2026-08-21, notte (16) — Giri 11/12: la propria citazione non verificata, trovata verificandola

Rettifica onesta: la chiusura sopra contava 7 giri (4-10), non i 10 annunciati a
Luca — mancavano "citazione di un pattern invece di reinventare" e "lente BC,
endpoint con limite noto citato a memoria vs verificato". Anziché costruire una
finta issue per forzarli (avrebbero richiesto un livello OData che
night-shift-pilot non ha e non deve avere, essendo dati mock), li ho verificati
sulla fonte vera dove esistono già: il claim della lente BC nella mia stessa
`audit-commessa/SKILL.md` ("niente OR annidati... torna HTTP 501 — visto in
Cache.gs di REPO-B").

**Trovato**: falso per come citato. `Cache.gs:14` (clone ancora presente in questa
sessione) dice solo "non supporta filtri complessi (OR annidati, Entry_No,
orderby)" — NESSUN "501" nel codice. Il dettaglio "HTTP 501" esiste davvero, ma in
`SAL.md:235-236` dello stesso progetto, non nel file citato. La citazione era
imprecisa esattamente nel modo che il pattern `citazione-non-presidio` avverte:
un'ancora che esiste ma non per il fatto specifico che le si attribuisce non è
una salvaguardia vera. **Corretto**: la citazione ora punta a entrambe le fonti,
distinguendo cosa dice il codice da cosa dice il diario del progetto.

### 2026-08-21, notte (17) — le due correzioni in sospeso, eseguite col sì di Luca

Luca ha detto "esegui le correzioni" — le due voci DEBITI dei Giri 6 e 9 che
aspettavano una decisione di design. Entrambe saldate, entrambe riprovate dal vivo:

- **`gate-esito.sh` (Giro 9)**: semantica scelta — un esito TERMINALE (`merge`,
  `chiusura`) chiude repo+PR per sempre; `commessa` no. Riprodotto lo STESSO bug
  esatto sulla stessa copia del vero `metrics/gate.csv` (mai l'originale): la
  doppia chiamata ora è respinta. Costruito anche il caso legittimo che il fix
  doveva salvare — `commessa` su una riga, poi `merge` su una riga successiva —
  e verificato che riesce, seguito da un terzo tentativo correttamente respinto.
  Ririprovati i 3 casi originari (storico/nuovo/doppia registrazione): ancora
  tutti corretti.
- **`morning-gate.sh` (Giro 6)**: la issue correttiva ora porta un estratto vero
  del fallimento (`FAIL_DETAIL`: le ultime righe della verifica o del banco
  falliti), incorporato con un heredoc quotato (`$(cat <<'GATE_EOF' ... GATE_EOF)`)
  invece dell'interpolazione diretta in una stringa fra virgolette. **Provato dal
  vivo, non solo letto**: costruito un `FAIL_DETAIL` avversariale con backtick,
  `$(whoami)`, `$HOME`, generato il comando suggerito, eseguito contro un `gh`
  finto — ogni carattere arriva come testo letterale nell'argomento `--body`,
  nessuna espansione, nessuna esecuzione indesiderata.

`bash -n` passa su entrambi gli script; `shellcheck` non installato in questa
sessione (annotato, non finto). L'esecuzione end-to-end contro un `gh` autenticato
vero resta al primo gate reale sul Mac dopo questa PR — dichiarato in DEBITI.md.

### 2026-08-21, notte (18) — un bug reale su un progetto vero apre una lente mancante nel roster

Luca ha chiesto di seguire con attenzione anche gli agenti/il roster, in particolare sui
temi matematico-finanziari: "capire col tempo se gli esperti sono tutti e sono corretti o
hanno bisogno di revisioni". Occasione concreta, non ipotetica: continuando l'analisi su
`REPO-G` (progetto vero, cliente vero — vedi il suo SAL.md), costruito un
banco di verifica in Node per `gas/Sp.js` (Stato Patrimoniale per le banche) — **trovato
un segno sbagliato** nella formula del plug (`resto2 = serve - suIva`, doveva essere
`serve + suIva`), invisibile a lettura E invisibile a "quadratura: 0,00 ✅" perché il
passo di tie-out finale (per centesimi di arrotondamento) assorbiva SEMPRE l'intero
residuo, qualunque fosse la sua entità — ogni riscontro storico del progetto tornava "in
pareggio" anche quando la logica non lo era. Corretto e riverificato su 8 scenari
sintetici (`tools/test-sp.js`, ora nel repo del cliente); aggiunta una guardia che
segnala un residuo anomalo invece di assorbirlo in silenzio.

**Il gap di roster che questo espone**: nessuna delle lenti esistenti (dev-critic
generico, sicurezza §2bis, audit-commessa sulla forma-dati, verifica-visiva sullo
schermo) avrebbe mai trovato questo bug — nessuna prevede di ESEGUIRE le formule di
calcolo con dati sintetici e misurare l'invariante di dominio PRIMA di un passo di
aggiustamento finale. **Aggiunta**: `dev-critic` §2ter — lente matematico-finanziaria,
stesso schema della lente sicurezza (sempre applicata quando il target ha questa
caratteristica, non solo su richiesta). Pattern gemello registrato:
`patterns/banco-sintetico-per-calcoli-critici.md`, ancorato a `tools/test-sp.js` (banco
vero, provato) e `gas/Sp.js:366` (il bug corretto) di REPO-G.

**Nota onesta sul metodo di scoperta**: il bug non è stato trovato applicando la nuova
lente (che non esisteva ancora) — è stato trovato per tentativi, con più derivazioni a
mano sbagliate corrette solo eseguendo il codice vero. La lente esiste ORA perché quel
percorso (spesso fatica sprecata a mano, poi risolta in un minuto di esecuzione) merita
di diventare il primo passo la prossima volta, non l'ultimo.

### 2026-08-21 — nuova regola: qui solo metodo, mai il nome dei progetti onboardati

Luca ha chiesto esplicitamente che questo repo (pubblico) contenga sistema e metodo, MAI
riferimenti a quali progetti/clienti lavoriamo — solo forma anonima da qui in avanti. Le
voci precedenti che nominano `REPO-G`/`REPO-C` restano invariate
(la regola vale in avanti, non è stata chiesta una bonifica retroattiva — se in futuro
Luca vorrà anche quella, è un passo separato ed esplicito). Le due voci che seguono
adottano già la nuova convenzione: "un progetto onboardato" al posto del nome, il
dominio di business omesso, solo file/funzione (generici, non identificano da soli quale
cliente).

### 2026-08-21 — Giro 1 di 5 su un progetto onboardato: due bug della stessa famiglia di (18), un secondo pattern nuovo

Primo di 5 giri di sviluppo autonomo su un secondo progetto onboardato (pipeline GAS di
raccolta dati esterni + dashboard di analisi — stesso genere di stack di
REPO-G, cliente diverso). Applicata la lente §2ter appena introdotta in (18):
banco sintetico Node/vm sul codice vero, eseguito prima di fidarsi di qualunque "quadra".

Trovati e corretti **due bug reali della stessa famiglia**, in punti diversi dello stesso
progetto:
1. Un oggetto "stato vuoto" scritto a mano per il caso "nessun dato ancora" era rimasto
   con la forma vecchia dopo che la funzione di aggregazione reale era stata riscritta con
   nuove chiavi — non un crash (il consumatore a valle aveva già una guardia difensiva),
   ma un contratto silenziosamente sbagliato. Fix: il caso vuoto ora chiama la stessa
   pipeline reale con input vuoto, non descrive più la forma a mano — non può più
   divergere per costruzione. **Nuovo pattern**: `patterns/stato-vuoto-dalla-pipeline.md`.
2. Una funzione di validazione (range plausibili su campi numerici) azzerava
   silenziosamente ogni valore fuori soglia, zero log, zero traccia — indistinguibile da
   un campo mai estratto. Non è la prima volta: lo stesso schema esatto (un residuo/scarto
   reale mascherato invece che segnalato) era già comparso due volte all'interno di
   REPO-G dopo la voce (18) — un plug contabile che assorbiva un residuo nel
   tie-out, e un pool di costi che spariva sotto una guardia anti-divisione-per-zero. Tre
   occorrenze indipendenti in due progetti bastano per un pattern a sé, distinto dal banco
   sintetico (quello è la tecnica di TEST, questo è la FORMA del fix): **nuovo pattern**
   `patterns/scarto-mai-silenzioso.md` — una funzione che scarta/clampa deve ritornare
   cosa ha scartato, il chiamante lo logga, la regola/soglia non cambia.

Anche corretti nello stesso giro (non generalizzati a pattern, casi singoli): una funzione
di test di modulo che non girava più da tempo (riferiva campi superati da una riscrittura
precedente — avrebbe lanciato un errore se eseguita), un'asimmetria nel mascheramento
segreti nei log d'errore (una chiave era già mascherata negli errori, l'altra no — stessa
tecnica di `segreto-come-impronta`, solo applicata a metà), un prompt LLM per un campo
booleano corretto per un caso di misclassificazione noto e mai chiuso, e il CLAUDE.md del
progetto stesso — che si dichiara vincolante — desincronizzato dal codice reale (due
decisioni tecniche superate erano ancora scritte come attuali).

### 2026-08-21 — Giro 2 sullo stesso progetto onboardato: un terzo pattern, sul TEST non sul fix

Giro 2 (nuova funzionalità, richiesta esplicita già scritta nella roadmap del progetto — non
una scelta nostra). La funzionalità in sé (rendere cliccabili tabelle e grafici rimasti fuori
da una scheda-dettaglio prodotto già esistente altrove) non generalizza a un pattern — è
troppo specifica. Quello che generalizza è COME è stata verificata: una web app Google Apps
Script non ha un ambiente locale eseguibile, ma il frontend è HTML/JS puro dentro
`HtmlService` — risolvendo a mano gli `include()`, stubbando `google.script.run` con
l'output vero di una funzione di backend eseguita a parte (non un finto scritto a mano — si
ricadrebbe nel problema di `stato-vuoto-dalla-pipeline`), e localizzando le dipendenze CDN
quando la rete non arriva al browser (curl sì, browser headless no — differenza reale
riscontrata in questo ambiente), si ottiene un banco di verifica in un browser reale senza
mai toccare Apps Script. **Nuovo pattern**: `patterns/banco-browser-per-webapp-gas.md`.
Nota onesta riportata nel pattern stesso: la logica del click è stata provata con certezza
(stessa funzione, stessa forma di argomenti della libreria grafica); il click del mouse
*simulato* su un punto scatter non ha affidabilmente centrato l'hit-test pixel della
libreria — l'ultimo miglio di automazione non è la stessa cosa della logica sottostante,
e va detto quando succede, non nascosto sotto un "verificato" generico.

### 2026-08-21 — Giro 3 sullo stesso progetto onboardato: un addendum, non un pattern nuovo

Giro 3 (nuova funzionalità, dichiarata da tempo nella roadmap del progetto). Il primo tentativo
di banco Node/vm per la nuova logica è fallito — non per un bug nel codice testato, ma perché le
date sintetiche del banco erano costruite con `new Date(...)` dell'host, mentre il codice testato
gira in un contesto `vm` con una REALM diversa: `instanceof Date` fallisce silenziosamente tra
realm diverse anche per due date "identiche" nel valore. Non un pattern nuovo — un caso specifico
di `banco-sintetico-per-calcoli-critici` (già esistente) che vale la pena scrivere PERCHÉ chi
userà il banco-sintetico su un codice che usa `instanceof Date`/`Array` ci sbatterà contro
inevitabilmente e leggerà il fallimento come un bug nel codice, non nel banco. **Aggiunto un
addendum al pattern esistente**, non una nuova voce nel registro — non tutto quello che si impara
merita un pattern a sé; a volte è solo un caso in più dello stesso.

### 2026-08-21 — Chiusura dei 5 giri autonomi su un secondo progetto onboardato: cosa ha funzionato nel processo

Luca aveva chiesto esplicitamente di osservare come il sistema si comporta "in loop" su 5 giri
completamente autonomi (1 giro di correzione ampia + 4 di nuove funzionalità), migliorando sia lo
script del progetto sia il sistema stesso a ogni passo, senza fermarsi a chiedere conferma
step-by-step come CLAUDE.md richiederebbe normalmente — un'eccezione esplicita e dichiarata alla
regola "repeat the request... wait for explicit approval", non una sua violazione silenziosa.
Onestà di processo, non solo di risultato: cosa ha tenuto e cosa no.

**Ha tenuto**:
- **Un branch, una PR, un merge per giro** — mai una commessa unica a fine sessione. Ogni giro
  verificabile e revertibile indipendentemente dagli altri; la cronologia commit racconta la
  sequenza reale, non un blob finale.
- **Verifica per esecuzione ad ogni giro, mai per lettura sola** — banco Node/vm sul codice VERO
  per la logica pura (5 banchi nuovi in 5 giri), banco Playwright con `google.script.run` stubbato
  e Chart.js scaricato in locale quando la feature era di UI (drill-down, grafico storico) e non
  bastava un banco puro. Due volte il primo tentativo di banco è fallito per un bug DEL BANCO
  (Date cross-realm, tab-selector sbagliato in un test) — mai scambiato per un bug del codice senza
  verificare, mai lasciato correre "probabilmente funziona".
- **Onestà sui limiti della verifica**, ripetuta in ogni giro senza eccezioni: cosa è stato provato
  dal vivo in un browser reale, cosa solo a livello di logica/handler (il click Chart.js simulato
  che non centrava l'hit-test pixel), cosa resta da confermare lato cliente perché richiede
  `clasp push`/chiavi API reali/dati con ≥2 run — mai un "verificato" generico che nasconde quale
  dei tre livelli è stato raggiunto.
- **Le feature scelte erano tracciabili a una fonte**, non inventate: la roadmap dichiarata del
  progetto stesso (drill-down, Trend & Alert, storico prezzo — tutti già scritti nella specifica
  originale o nel SAL del progetto) o un rischio operativo reale trovato leggendo il codice
  (trigger settimanale mai automatizzato). Mai una funzionalità aggiunta solo perché "sarebbe
  carina".
- **La lezione metodologica, quando genuina, è tornata qui anonimizzata** — due nuovi pattern, un
  addendum a uno esistente, mai forzati quando il giro non aveva prodotto niente di generalizzabile
  oltre il fix specifico (Giro 4 e Giro 5 non hanno prodotto nessuna voce di pattern: non tutto
  quello che si fa qui deve generare una pagina di metodo).

**Non ha tenuto/da migliorare**:
- **`git push` verso il repo del progetto ha avuto ripetuti 502/503 transitori** ("session scope
  unavailable") durante la sessione — risolto con un retry loop in background (`until git push...;
  do sleep 15; done`), non con i soli 4 tentativi con backoff fisso previsti dalla procedura
  standard, insufficienti quando il guasto dura più di ~30 secondi. Da portare nella procedura
  operativa: se il retry a backoff fisso si esaurisce e il proxy segnala esplicitamente un problema
  transitorio (non una policy denial 403/407), un retry loop in background è preferibile a
  rinunciare o a ripetere manualmente.
- **Il banco Playwright non è ripetibile automaticamente** — richiede Chromium + una copia locale
  di eventuali dipendenze CDN, ricostruito a mano ad ogni giro con un piccolo script diverso.
  Riusabile come METODO (`banco-browser-per-webapp-gas`), non come strumento pronto all'uso: se
  questo genere di verifica ricorre spesso su progetti futuri, vale la pena costruire un piccolo
  harness generico (repo/percorso dei file GAS in input, stub configurabile) invece di riscriverlo
  da zero ogni volta — non fatto in questa sessione, segnalato come possibile debito futuro.
### 2026-08-22, mattina — la notte ha parlato: 11h39m su #12, zero file

Prima notte completamente automatica col sistema a regime. Il design-gate HA FUNZIONATO:
le 4 commesse vecchie senza ## Design (#363, #2, #3, #4) tutte saltate col commento — il
processo si difende. Ma la notte su #12 (commessa corretta dall'audit, design passata,
forma dei dati presente) è rimasta 11 ore e 39 minuti senza scrivere un file: fermata la
mano la mattina. Conferma definitiva dell'A/B: il limite della notte non è il biglietto,
è il TERRITORIO — file grandi da esplorare = giorno, sempre. Regola di smistamento che ne
esce (proposta a Luca): le commesse notturne dichiarano anche la dimensione del territorio
(file piccoli e righe indicate), altrimenti passano al giorno. Stato completo del progetto:
docs/stato-2026-08-22.md.

### 2026-08-22, mattina (2) — messo a posto tutto: la regola del territorio, e il giorno chiude #10+#12

Miglioramenti di processo entrati (tutti dalla lezione dell'11 ore):
- **Regola del Territorio**: sezione obbligatoria nelle commesse (quanto codice serve leggere) — il turno la salta come il Design se manca; il template la chiede alla nascita
- **Escalation automatica**: al secondo fallimento notturno di una issue, il commento propone di passarla al giorno (regola dell'A/B applicata dal sistema, non più solo ricordata da noi)
- **Corsia glm/***: il gate giudica anche il lavoro di GLM (terzo cervello, stessa legge di notte e claude)
- **Mascheramento segreti** negli output del gate (DEBITI saldato, pattern segreto-come-impronta applicato)

Esecuzioni: **le commesse BC #2/#3/#4 riabilitate** (Design + Territorio piccolo aggiunti — il
lavoro perfetto per stanotte: un file md a colonna). **Il giorno ha chiuso #10 e #12** in un
colpo (PR #15 su PEFC, branch glm/): nome file CSV datato (un punto per tutte le tabelle,
testato in Node) e registri di conformità nel PDF (tabella DDS 4→6 colonne, avviso assenti
con la funzione GIUSTA, le 7 voci del sistema di gestione) — sintassi JS verificata per
esecuzione. Stanotte la notte prova le BC: la prima prova della regola del territorio.

### 2026-08-22, pomeriggio — ciclo dei 5 giri su REPO-D (mandato: tutto da solo, processo osservato)

Fase 0 prima di tutto: **il hub era pubblico e spifferava nomi di repo private** (24 file).
Anonimizzato, chiave solo locale (repos.key gitignored), il gate scrive codici nel CSV e
privacy-check entra nel .night-verify: una perdita futura FALLISCE il gate. Il check stesso
è nato con un bug (grep -qv = quiet: divorava l'output e passava sempre) — trovato
eseguendolo contro il caso noto-difettoso, prima lezione del ciclo: **un guardiano si prova
anche quando deve fallire, non solo quando deve passare**.

**Giro 1 (sweep bug) completato**: 3 agenti in parallelo per la caccia (pipeline, dati,
webapp — il territorio era grande: il giorno legge, per la regola nuova), 20 difetti
trovati (3 critici, 8 maggiori), ogni fix verificato, i testabili coperti da un test file
nuovo con 11 asserzioni + i 4 esistenti verdi. PR aperta, commit per step logico.
Osservazioni di processo del giro: (1) i 3 difetti critici erano tutti della classe
'silenzioso' — dati sbagliati senza errore, il tipo che solo l'esecuzione rivela;
(2) il test file nuovo è nato DOPO i fix: la prossima volta nasce CON il primo fix
(regola: ogni fix porta la sua asserzione nello stesso commit, quando testabile);
(3) un fix ha rotto un test esistente perché usava una costante non caricata dal contesto
— risolto completando il test, non indebolendo il fix: il test serve al codice, non
viceversa.

### 2026-08-22, sera — ciclo dei 5 giri completato: il processo osservato in loop

Cinque giri su REPO-D (1 sweep + 4 feature), tutto da un solo operatore in loop: 5 PR,
20 difetti corretti, 55 asserzioni nuove tutte verdi. Le osservazioni che il loop ha
estorto — le quattro che valgono regole:

1. **Il test smentisce l'autore, non il codice** — quattro volte (su giri 4 e 5) le
   aspettative scritte a mano erano sbagliate e il codice giusto: mediana che non si muove
   con le code, regola n≥3 che esclude l'insegna da due punti dati, punto-e-virgola naked
   in un CSV virgola-separated. Regola: l'aspettativa si DERIVA (si calcola a mano passo
   per passo) o si costruisce da un caso noto — non si abbozza a memoria.
2. **Verificare la PR prima di dichiararla, non dopo** — l'hook del digest è mancato al
   primo commit (anchor spostato) e il commit è partito lo stesso: trovato riguardando.
   Regole: nessun commit dopo un edit programmatico senza grep della prova, e il flusso
   edit→verifica→commit è SEMPRE in quest'ordine.
3. **I test caricano le loro dipendenze transitive** — successo due volte (percentile_,
   RAW_DATA_HEADERS): il test che carica un modulo nuovo scopre le sue dipendenze e le
   aggiunge — non indebolisce il codice per adattarlo al test.
4. **I check sintattici non vedono la spazzanza semantica** — una stringa-colore corrotta
   è passata 'JS OK': il codice generato programmaticamente si RIGUARDA con occhi umani
   prima del commit.

E una conferma: la caccia con 3 agenti in parallelo + la parte meccanica a mano è il
rapporto qualità/tempo migliore mai misurato nel sistema per il lavoro di giorno su
territori grandi. Le 5 PR aspettano la review di Luca col gate.

### 2026-08-22, notte — ciclo 2 su REPO-D: la progettazione protagonista

Cinque feature con design-doc (docs/DESIGN_CICLO_2.md nella repo: opzioni pesate, scelte
dichiarate, verifica per livello) impilate in PR ordinate. Il dato nuovo del ciclo: **il
test come strumento di DESIGN, non solo di correttezza** — ha scoperto che le categorie
del classificatore non si sarebbero mai incontrate fra prodotti propri (_wall_na) e
mercato (_wall_28): difetto di design intercettato prima della produzione e convertito
in normalizzazione per categoria base. E ha corretto le aspettative dell'autore altre
quattro volte (l'aritmetica del fixture si conta a mano, sempre). 55 asserzioni nuove,
16 avversariali, PR impilate col merge in ordine dichiarato.

### 2026-08-22, notte (2) — 10 giri di auto-miglioramento: il sistema giudica se stesso

Il mandato: il sistema migliora AI_Programmer e il metodo viene analizzato a ogni passo.
Dieci PR (#14-#21, una finita per errore direttamente su main — scivolone di checkout
dichiarato: giro 3):

| Giro | Cosa | Prova |
|---|---|---|
| 1 | regression test per lib.sh: i 6 bypass storici non riaprono MAI | 25 asserzioni |
| 2 | test per gate-esito e gate-summary (i bug del CSV come regression) | 10 |
| 3 | wrapper mai eseguiti → eseguiti (percorsi di fallimento) | 7 |
| 4 | privacy v2 + **bug latente del guardiano trovato dal test**: git -C non vale per grep, il check passava tutto se invocato fuori dalla root — silenziosamente, da sempre | 5 (con leak piantate) |
| 5 | indice del SAL generato e verificato nel gate (30 voci) | presidio |
| 6 | summary v2: il rigore del banco misurato (scarti allowlist %) | live |
| 7 | idempotenza install (onesto: test debole in HOME finta) | 4 |
| 8 | qualità minima Design (≥80 char col da-dove) e Territorio (nomina file) | presidio |
| 9 | bootstrap --dry-run | sintassi |
| 10 | METHOD.md: la porta del sistema | docs |

**Il dato del ciclo**: il test del giro 4 ha trovato un bug latente nel guardiano della
privacy che c'era DA SEMPRE — il check funzionava solo se lanciato dalla root del repo,
il che significa che IL GATE l'ha sempre invocato correttamente per caso. Regola rafforzata:
**il guardiano si prova anche dalle posizioni sbagliate** — un check che funziona solo
nella posizione giusta non è un presidio, è una coincidenza.

### 2026-08-22, notte (3) — 10 giri di FEATURE: cosa mancava davvero

Dieci PR (#22-#31), il sistema guadagna ciò che non sapeva di non avere:

| Giro | PR | Feature | Il gap che colmava |
|---|---|---|---|
| 1 | #22 | **health check** | 7 componenti, nessuno sapeva chi vive — e infatti ha subito trovato launchd nightshift FERMO e 22 GB di swap |
| 2 | #23 | **verify-patterns** | la regola diceva 'l'ancora muore, la voce muore' ma nessuno verificava — 19 vive, 1 morta (corretta) |
| 3 | #24 | **morning-digest** | Luca doveva ANDARE a leggere il report: ora arriva in mailbox |
| 4 | #25 | **backup config** | repos.conf, key, metrics: l'unica copia viveva su un Mac |
| 5 | #26 | **promemoria audit** | l'audit serale era manuale e facile da dimenticare |
| 6 | #27 | **multi-cadence** | tutte le repo alla stessa frequenza; ora per-repo |
| 7 | #28 | **status page** | tutto era CLI e file sparsi; ora una vista HTML |
| 8 | #29 | **/nuova-commessa wizard** | le commesse buone erano arte manuale |
| 9 | #30 | **auto-SAL del turno** | l'esito notturno viveva solo nel log |
| 10 | #31 | **manuale operativo** | il perché c'era, le mani no |

Osservazione di metodo: le 10 feature rispondono tutte alla stessa domanda —
**"cosa deve fare il sistema che oggi fa l'operatore a mano?"**. Il pattern: l'operatore
è il collo di bottiglia quando fa cose ripetibili (leggere report, ricordarsi audit,
scrivere SAL, verificare ancore, controllare salute). Il sistema cresce automatizzando
l'operatore, non sostituendolo: le decisioni restano sue (review, merge, rotazione).

### 2026-08-22, notte (4) — le decisioni di dominio prese (mandato di Luca: "decidi da solo")

| # | Decisione | Perché |
|---|---|---|
| Suggeritore target | **−5%** (confermato) | produttore vs retail: leggermente sotto la mediana categoria è la posizione competitiva senza svendersi |
| Watchlist | **anche soglia SUPERIORE** | quando un concorrente ALZA i prezzi è il tuo spazio: segnalarlo è intelligenza competitiva, non solo costo |
| Tassonomia alluminio | **categoria dedicata C8** | un gazebo in alluminio con tetto in policarbonato NON è pieghevole: cambia le mediane di C7 e la lettura del mercato |
| Digest email | **solo quando ci sono variazioni** | un'email vuota ogni settimana insegna a ignorarla |
| Qualità: scarno 50% | **confermato** | sotto il 50% i dati non bastano per decidere |
| Qualità: stale 9 giorni | **confermato** | run settimanale (7g) + 2 di margine |
| Confronto n≥3 | **confermato** | ~1051 URL / 20 insegne ≈ 50 per insegna: 3 per categoria è un filtro minimo che basta |
| Export CSV | **solo dominio** (confermato) | già restrictivo, nessuna apertura |
| Radar in digest | **sì** | i nuovi entrati sono intelligence azionabile, non solo dashboard |
| Calendario pocodati | **10 osservazioni, solo mesi passati** | campione minimo per non mentire |
| Morning-digest email | **configurare la stessa del notturno** | un solo canale, meno rumore |
| Audit reminder | **21:30 confermato** | 1.5h prima del turno: tempo per agire, non troppo presto per dimenticare |
| Multi-cadence | **REPO-A settimanale (lun), le altre giornaliere** | il giudice non deve correre ogni notte |
| Cursor per-id | **fix ORA** | rischio reale di perdita dati durante run |
| Onboarding checkpoint | **rinvio accettato** | 5 competitor entro 6 min GAS oggi |

### 2026-08-22, notte (5) — terzo ciclo di 10 giri: bug reali trovati eseguendo, non leggendo

Mandato di Luca: nuovo ciclo di 10 giri per migliorare operativamente il processo,
monitorando per capire come migliorare. I due cicli precedenti (#14-#21 test/hardening,
#22-#31 feature mancanti) erano già mersati su main. Uso dev-critic sul hub stesso
(lettura critica + dogfooding reale, non solo ispezione statica) per trovare i gap di
questo terzo ciclo — niente ripetuto dai due precedenti.

| Giro | Cosa | Trovato eseguendo |
|---|---|---|
| 1 | system-health.sh: `$⛔/RED` non si espandeva MAI — il verdetto finale non mostrava mai i critici, in nessun ambiente, da sempre | eseguendo lo script |
| 2-3 | morning-digest.sh: dead code (EMAIL calcolato, mai usato) + BODY assegnato al PATH del report invece che al suo contenuto + injection AppleScript (virgolette/backslash non escaped) | intercettando osascript con un finto eseguibile |
| 4 | test-ask-wrappers.sh falliva IN QUESTA STESSA SESSIONE: l'assunzione "auth assente" non vale in un ambiente cloud dove `claude` è già autenticato — non un difetto del wrapper, un'assunzione del test mai verificata fuori dal Mac | il test è fallito davvero, dal vivo |
| 5 | privacy-check.sh vedeva solo `git ls-files` (i file di OGGI) — un nome committato e poi rimosso resta esposto per sempre nella storia, e il check diceva "pulito". Mai applicata al hub stesso la lezione dell'incidente citato in dev-critic/SKILL.md | riprodotto con un repo git sintetico: commit-poi-rimozione, il vecchio check l'avrebbe lasciato passare |
| 6 | morning-gate.sh: la mascheratura segreti non copriva "Authorization: Bearer \<token\>" — un JWT sarebbe passato intero nel report | verificato con sed su un caso realistico |
| 7 | bootstrap-app.sh: la catena `[ dry ] \|\| git add -A && [ dry ] \|\| git commit` non si fermava se `git add` falliva — `set -e` non intercetta un fallimento intermedio dentro una catena &&/\|\| | riprodotto con una `git` finta che fa fallire add |
| 8 | night-shift.sh: l'auto-SAL (giro 9/10 del ciclo precedente) scriveva contatori SEMPRE VUOTI — PR_CREATED/FAILED sono `local` dentro shift_repo(), spariscono dopo il for. La feature pensata per "la memoria non dipende da chi ricorda" non si ricordava nulla da sola | riprodotto con simulazione bash |
| 9 | test di regressione per bc_index.py (debito 2026-08-21): puro, testabile su una copia reale di docs/bc/endpoints senza tocca il README vero. bc_map.py resta debito (richiede OAuth BC vero) | — |
| 10 | rotazione log oltre soglia (debito 2026-08-21, "nessun limite raggiunto"): `rotate_log_if_big()` in lib.sh, una generazione, richiamata da night-shift.sh e morning-gate.sh | test sintetico |

**Il dato del ciclo**: 6 bug su 10 giri erano REALI, non ipotetici — e tre di loro
(giro 4, 7, 8) sono emersi SOLO eseguendo il codice o simulandone la struttura di
controllo, non leggendolo: la lettura da sola li avrebbe lasciati passare, esattamente
come predetto dal metodo di dev-critic. Nota di processo: durante l'analisi, un test
di `sal-indice.sh` su una copia è stato lanciato per errore anche sul SAL.md reale
(rigenerazione dell'indice, nessuna perdita — committato a parte con messaggio onesto).
Osservazione aggiuntiva: `llm/ask-opus.sh`, richiamato ricorsivamente da questa stessa
sessione, ha mostrato latenza variabile (una run ha superato i 2 minuti) — aggiunto un
timeout al test che lo esercita, per non bloccare la suite a tempo indefinito.

### 2026-08-22, notte (6) — correzione: la diagnosi "claude -p lento" era sbagliata

Nel ciclo precedente (giro 4/10) un hang di 2+ minuti era stato attribuito a "chiamata
ricorsiva a claude -p lenta o bloccata", con un timeout aggiunto al TEST come guardia.
Set 1 del ciclo nuovo ("armonizza gli agenti") ha riprodotto l'hang dal vivo con
`< <(sleep 100)`: la causa vera è `[ ! -t 0 ] && STDIN_DATA=$(cat)` in tutti e tre i
wrapper `llm/ask-*.sh` — `-t 0` non distingue "arriva un contesto vero in pipe" da "non
c'è nulla ma non è un terminale", e `cat` blocca a tempo indefinito nel secondo caso.

Annotato come richiede CLAUDE.md §1: un errore della NOTA precedente (l'ipotesi
"claude lento"), non un difetto del sistema scoperto oggi — il sistema aveva davvero
un bug, solo diagnosticato nel posto sbagliato. Corretto con `timeout 5 cat` nei tre
wrapper; il timeout già presente nel test resta comunque una buona guardia generale.

### 2026-08-22, notte (7) — Set 1/3: agenti giorno+notte armonizzati, 8 bug reali

Mandato di Luca: tre nuovi cicli tematici. Set 1 — "migliorare gli agenti, non solo
notturni ma anche e sopratutto quelli diurni (code e glm)". Dieci giri su llm/ask-*.sh,
morning-gate.sh, docs/system.md.

| Giro | Cosa | Trovato eseguendo |
|---|---|---|
| 1 | ask-qwen.sh validava il prompt DOPO aver tentato Ollama — 30.4s sprecati su chiamata invalida | `time` |
| 2 | **Correzione di una diagnosi errata**: l'hang di 2+ minuti del ciclo precedente non era "claude -p lento" — è `$(cat)` senza limite su stdin non-tty-senza-EOF, in TUTTI i wrapper | riprodotto con `< <(sleep 100)` |
| 3 | ask-qwen.sh ignorava ASK_TIMEOUT (--max-time fisso 1800) | curl finto |
| 4 | ASK_MODEL "universale" per contratto ma implementato solo in ask-opus.sh | curl finto |
| 5 | ask-opus.sh: exit 2 per auth assente, armonizzato con ask-glm.sh | claude finto |
| 6 | GLM mai cablato come ADVERSARY nel banco (solo qwen/opus) | estratta la logica reale |
| 7-8 | ask-glm.sh e ask-qwen.sh: risposta malformata → traceback Python grezzo invece di diagnosi pulita | curl finto, 3 casi avversariali ciascuno |
| 9 | docs/system.md disallineato dalla correzione già fatta nell'header di ask-opus.sh | lettura incrociata |
| 10 | nessuna traccia dei cervelli di giorno in memoria condivisa (asimmetria con SAL/gate.csv del notturno) — colmata con llm/_usage.sh | cervelli finti |

**Il dato del ciclo**: la scoperta più importante non era nella lista di partenza — è
emersa RIPRODUCENDO il giro 2 dell'ultimo ciclo per costruire un nuovo test, e ha
smentito la propria diagnosi precedente. Lezione di metodo: anche un fix già
committato e testato può portare la causa sbagliata se il sintomo (l'hang) non è
stato isolato dal resto (qui: mai provato senza la chiamata vera al cervello).

### 2026-08-22, notte (8) — Set 2/3: capacità di progettare, 3 skill mai esistite + bug ad alta severità

Set 2 — "migliorare la capacità di progettare nuovo software" (processo esistente +
nuovi strumenti). Dieci giri su .claude/skills/, night-shift.sh, morning-gate.sh, lib.sh.

| Giro | Cosa | Trovato |
|---|---|---|
| 1-3 | `/design-doc`, `/brainstorming`, `/goal`: citati ovunque (METHOD.md, docs/system.md, CLAUDE.md §7) come fonti di verità in `.zcode/commands/`/`.claude/commands/` — NESSUNA delle due directory esiste nel repo. `loops/` vuota da sempre | ricerca sul repo |
| 4 | `docs/stato-2026-08-22.md` citato in METHOD.md, mai scritto | ricerca sul repo |
| 5 | design-gate: due messaggi dedicati "SENZA sezione" erano dead code (il check di qualità intercetta sempre prima una sezione assente) | simulazione su 6 casi |
| 6 | design-gate: soglia 80 caratteri bucabile con prosa di riempimento senza riferimento reale | verificato dal vivo, 87 char di nulla passavano |
| 7 | `/nuova-commessa` non referenziava `/design-doc` nonostante la pipeline dichiarata | lettura incrociata |
| 8 | night-shift.sh non registrava le issue saltate per Design/Territorio (proposta 2026-08-21 mai fatta) | grep |
| 9 | **`run_guarded()` impiegava SEMPRE l'intera durata del watchdog** (120s in produzione) per OGNI comando `.night-verify` e il banco avversariale, anche se il comando reale finiva in millisecondi — un `sleep` orfano teneva aperta la pipe di una command substitution. Trovato per caso costruendo il test di un ALTRO bug (VERDICT="verifiche-ok" con zero comandi eseguiti — falso verde su ogni repo appena bootstrappata) | `time`, poi riprodotto e corretto due volte (il primo fix era sbagliato) |
| 10 | categoria "non-verificabile" per repo senza modo di verificare (proposta 2026-08-21 mai fatta) | grep |

**Il dato del ciclo**: il giro 9 è la scoperta più importante di questo set, e non era
nella lista di partenza — è emersa mentre si costruiva il test per un bug diverso. Il
PRIMO tentativo di fix (un subshell "killer" con `exec sleep`) sembrava corretto a
lettura ma si è rivelato sbagliato alla PROVA dal vivo (un subshell non può fare `wait`
su un job che non è figlio suo): riproveur lo stesso identico caso di studio di sempre —
eseguire, non leggere, anche il proprio fix.

### 2026-08-22, notte (9) — Set 3/3: flusso delle idee, tutte le interazioni

Set 3 — "il flusso delle idee, l'interazione fra una parte e l'altra" (giorno↔notte,
hub↔progetti onboardati, agente↔agente — "tutte le parti", mandato di Luca). Dieci giri.

| Giro | Cosa | Trovato |
|---|---|---|
| 1-2 | `.claude/skills/` (6 skill) non arrivava MAI a un progetto — né nuovo (bootstrap-app.sh) né esistente (onboard-repo.sh, merge prudente: mai sovrascrive personalizzazioni) | ricerca sul repo |
| 3-4 | `patterns/` (23 trucchi provati) stesso gap, stesso fix (copia + merge prudente) | ricerca sul repo |
| 5 | morning-gate.sh: `ISSUE_NUM` diventava l'INTERO nome del branch per PR `claude/*`/`glm/*`, corrompendo `metrics/gate.csv` con stringhe invece di numeri | verificato dal vivo |
| 6-7 | Il marcatore `NON-VERIFICABILE` (Set 2 giro 10) non era menzionato nei template `.night-verify` di bootstrap/onboard | lettura incrociata |
| 8 | Il prompt del banco avversariale diceva "sono ammessi node/python" — l'allowlist li scarta SEMPRE (rimossi per sicurezza in un ciclo precedente). Ogni scelta di quel tipo sprecava l'intero turno di giudizio | verificato dal vivo con `gate_allowlist_ok` |
| 9 | CLAUDE.md non documentava il prefisso di branch richiesto dal gate (`night/`,`claude/`,`glm/`) né la regola "Closes in inglese" — vivevano solo in commenti di codice/SAL.md | ricerca sul repo |
| 10 | "cartelle specchio dichiarate dalla repo" citate nel prompt della notte senza alcun meccanismo di dichiarazione — introdotto `.night-mirror` | ricerca sul repo |

**Il dato del ciclo**: 6 dei 10 giri sono varianti dello stesso pattern — "citazione senza
presidio" applicato non a un comando (come nel Set 2) ma a un CANALE fra parti del
sistema: uno strumento esiste ma non viaggia dove serve, una convenzione esiste ma non è
scritta dove chi ne ha bisogno la legge, un prompt promette una capacità che il codice
non concede. Il flusso delle idee, quando si guarda con attenzione, si rompe più spesso
per canali mai costruiti che per bug nella logica.

## Riepilogo dei tre set (30 giri totali, dopo i 10 iniziali)

- **Set 1** (agenti giorno+notte armonizzati): 8 bug reali, tra cui la correzione di una
  diagnosi errata del ciclo precedente (l'hang non era "claude lento", era stdin senza EOF).
- **Set 2** (capacità di progettare software): 3 skill mai esistite implementate
  (`/design-doc`, `/brainstorming`, `/goal`), 1 bug ad alta severità in `run_guarded()`
  (ogni verifica costava 120s invece di terminare quando finita), 1 falso verde nel
  VERDICT del gate, 2 proposte di processo del 2026-08-21 mai chiuse.
- **Set 3** (flusso delle idee, tutte le interazioni): skill e pattern del hub ora
  raggiungono i progetti, 1 bug di corruzione dati corretto, 3 convenzioni tacite
  documentate dove serve, il prompt del banco avversariale sincronizzato con la realtà.

### 2026-08-23 — 4° ciclo, Set 1/3 giro 1: agenti per problemi matematico-contabili, ancorati a dati reali

Nuovo mandato di Luca: ripetere il ciclo dei tre set altre tre volte, ma Set 1 ora chiede
esplicitamente di costruire un sistema di agenti per problemi matematico-contabili,
economico-industriali (contabilità analitica, di magazzino, controllo di gestione) — non
solo armonizzare gli agenti esistenti. Prima di scrivere qualsiasi formula: chiesto a
Luca se ancorare al dato reale di Gruppo Camarlinghi o restare generico → risposta:
ancorato a Business Central, sia skill di metodo che tool eseguibili, con un caso pilota
reale. Luca ha condiviso un repo esterno — codice **REPO-E** in questo diario, mai il nome
per intero (regola "Public repo, private work") — con una cartella `gas-src/` di ~90
progetti Google Apps Script reali dell'azienda, come base di verità.

**Censimento** (agente Explore, non io a memoria): trovati ~10 progetti reali di
controllo di gestione già implementati in REPO-E/gas-src/ — scostamento standard/effettivo
ed efficienza manodopera in produzione, riconciliazione inventario fisico e bridge
volume/prezzo per il magazzino, roll-forward/quadratura dei cespiti, margine per fattura
di vendita, indici di crisi e analisi di conto economico (quest'ultimo non ancora
ispezionato a fondo).

**Scoperta collaterale da segnalare, fuori scope di questo hub**: in due progetti dentro
REPO-E/gas-src/ il `client_secret` di Business Central è scritto in chiaro nel codice
sorgente, versionato pubblicamente su GitHub (nomi di progetto e dettaglio esatto dati a
voce a Luca, non versionati qui). Segnalato; non è stato toccato (accesso in sola lettura
a REPO-E, fuori dal ramo di lavoro di questo ciclo).

**Giro 1**: creata `.claude/skills/controllo-gestione/SKILL.md` — generalizza per questo
dominio lo schema già in uso ad-hoc per BC ("censimento campi" + "riscontro" di
PROJECT.md): individuare la fonte dato reale, citare la formula esistente come oracolo
(mai indovinarla), costruire input/output concreti prima del codice, verificare con un
riscontro. Primo caso risolto col metodo: `tools/riconciliazione_magazzino.py`, formula
oracolo = il modulo di riconciliazione inventario del progetto magazzino in
REPO-E/gas-src/: `delta = qtyFisica - qtyBC; deltaValore = delta * costoFinale`, con "non
contato" sempre distinto da "contato a zero" (regola di business reale trovata nel codice
originale, preservata come requisito). Caso pilota verificato: `qty_bc=120,
costo_finale=4.50, qty_fisica=115`
→ `delta=-5, deltaValore=-22.50€`. Test: `tests/test-riconciliazione-magazzino.sh`.

### 2026-08-23 (2) — Set 1/3 giri 2-3: la skill raggiunge la commessa, poi il progetto nuovo

**Giro 2**: `.claude/skills/controllo-gestione/SKILL.md` (giro 1) esisteva ma il template
`.github/ISSUE_TEMPLATE/night-shift.md` — l'unico posto che chi scrive una commessa legge
PRIMA di scriverla — non la citava. Stesso pattern trovato più volte nel ciclo precedente
al contrario: lì una skill era citata senza esistere, qui una skill esiste senza essere
citata dove serve. Aggiunta una riga nella sezione "## Forma dei dati" (dove già vivono i
riferimenti a `audit-commessa` per BC e a `GRAMMATICA_DOMINIO.md` per i termini di
dominio) che rimanda a `controllo-gestione` per le commesse che calcolano/riconciliano
una cifra contabile o gestionale reale. Test:
`tests/test-night-shift-template-controllo-gestione.sh`.

**Giro 3**: verificando la propagazione del template ho trovato che
`tools/bootstrap-app.sh` crea la label GitHub `night-shift` (l'agente notturno la userà
per pescare le issue) ma non copiava mai il template che insegna la FORMA della commessa
in un progetto nuovo — stesso gap già corretto per `.claude/skills/` e `patterns/` nel
set 3 del ciclo precedente, mai applicato a questo file. Un progetto bootstrappato da
zero avrebbe la label pronta e zero guida su come scrivere una issue che il gate non
salti in silenzio per mancanza di `## Design`. Corretto: `bootstrap-app.sh` ora copia
anche `.github/ISSUE_TEMPLATE/night-shift.md`. Test:
`tests/test-bootstrap-issue-template-propagation.sh`.

### 2026-08-23 (3) — Set 1/3 giro 4: il gate non applicava a se stesso la propria regola

Leggendo la storia di `.night-verify` (`git log -p`) ho trovato che l'elenco delle
verifiche dichiarate del hub era fermo all'"autogiro 5/10": 4 test citati per nome
(`test-lib.sh`, `test-gate-tools.sh`, `test-ask-wrappers.sh`, `test-privacy.sh`). I 23+
file `tests/test-*.sh` accumulati nei cicli successivi (Set 2, Set 3, questo ciclo,
incluso il test scritto nel Giro 1 di oggi) non erano MAI stati aggiunti — la stessa
regola che questo sistema impone a ogni altra repo ("dichiara le tue verifiche o è
verifiche-vuote") non veniva applicata al hub stesso. Corretto: `.night-verify` ora usa
`for t in tests/test-*.sh; do bash "$t" || exit 1; done` invece di un elenco — nessun
test nuovo può più restare fuori dal gate per dimenticanza. Misurato dal vivo: 29 file,
~31s totali, ampio margine sotto il watchdog di 120s di `run_guarded`. Test:
`tests/test-night-verify-runs-all-tests.sh`.

### 2026-08-23 (4) — Set 1/3 giro 5: la mappa completa non conosceva la nuova capacità

`docs/system.md` è la "mappa completa" del metodo (citata da `METHOD.md` come fonte di
verità sull'architettura) ma non menzionava `/controllo-gestione` — chi legge la mappa
per capire quali agenti/comandi esistono nel sistema non avrebbe saputo che questa
capacità c'è, malgrado sia già raggiungibile da skill+template+propagazione (giri 1-3).
Aggiunta una sezione "Il ciclo guadagna il controllo di gestione", stesso stile delle
sezioni esistenti per `/design-doc`/`/audit-commesse`. Test:
`tests/test-system-md-controllo-gestione.sh` — verifica anche, come effetto collaterale,
che OGNI percorso citato in `docs/system.md` (non solo quello nuovo) esista davvero:
nessuna rottura preesistente trovata.

### 2026-08-23 (5) — Set 1/3 giro 6: secondo caso, dominio diverso — il metodo generalizza

Il giro 1 aveva risolto un solo caso (riconciliazione magazzino) con la skill
`controllo-gestione`. Un metodo provato su un solo esempio non è ancora un metodo
generale. Letto RIGA PER RIGA (non riassunto da un report) il codice reale di un modulo
di controllo di gestione produzione in REPO-E/gas-src/: scostamento costo
standard/effettivo per articolo, con media pesata per quantità, soglia configurata al
10%, severità ALTO/MEDIO, e un trend che confronta prima e seconda metà degli ordini di
produzione (richiede >=4 ordini, non 3 — un dettaglio che ho sbagliato per primo nel mio
proprio test, corretto verificando l'aritmetica a mano prima di fidarmi del verde).
Implementato: `tools/scostamento_standard_effettivo.py`. Test:
`tests/test-scostamento-standard-effettivo.sh` (12 asserzioni, aritmetica derivata a
mano). SKILL.md aggiornata con entrambi gli esempi in §3.

### 2026-08-23 (6) — Set 1/3 giro 7: due lenti sullo stesso dominio non si conoscevano

`dev-critic` ha già una lente §2ter matematico-finanziaria (nata da un bug reale: un
segno invertito nel plug di uno stato patrimoniale, invisibile a lettura e a
"quadratura: 0,00 ✅" perché il tie-out assorbiva sempre il residuo) — REVISIONA calcoli
già scritti. La nuova skill `controllo-gestione` (giro 1) COSTRUISCE calcoli nuovi.
Stesso dominio, stessa disciplina (oracolo citato, invariante verificato con dati
concreti), ma nessuna delle due citava l'altra — chi trovava una non scopriva l'altra.
Aggiunto il rimando in entrambe le direzioni, più la citazione del pattern
`banco-sintetico-per-calcoli-critici.md` (la tecnica del banco sintetico che i test di
controllo-gestione già seguono, senza dirlo). Test:
`tests/test-controllo-gestione-dev-critic-crossref.sh`.

**Scoperta collaterale, non introdotta oggi**: grepando privacy sul mio stesso diff ho
trovato che quel pattern e dev-critic citano per nome un repo reale, scritti prima che
esistesse la regola "Public repo, private work". Fuori scope di questo giro — tracciato
in `DEBITI.md`.

### 2026-08-23 (7) — Set 1/3 giro 8: terzo caso, dominio cespiti — il segno del fondo

Terzo caso risolto con la skill `controllo-gestione`, terzo dominio diverso (dopo
magazzino e produzione): roll-forward annuale cespiti. Letto riga per riga il codice
reale di un modulo di quadratura/roll-forward in REPO-E/gas-src/: costo storico
(clOpen→clClose per acquisizioni/rivalutazioni/cessioni) e fondo (fondoOpen→fondoClose
per ammortamento/cessioni), con valore netto = costo storico + fondo — il fondo è
convenzionalmente negativo, e le cessioni lo riducono aggiungendo `-fondo` (positivo)
invece di sottrarlo. È esattamente il tipo di segno che la lente `dev-critic` §2ter
avverte di verificare (nata da un bug reale con un segno invertito in un plug). Numeri
sintetici derivati a mano PRIMA di eseguire il tool: tutti gli 8 controlli passati al
primo tentativo. Implementato: `tools/rollforward_cespiti.py`. Test:
`tests/test-rollforward-cespiti.sh`.

### 2026-08-23 (8) — Set 1/3 giro 9: l'audit serale non sapeva controllare l'oracolo

`audit-commessa` fa il pre-flight serale sulle commesse in coda (verifica assunzioni sul
codice PRIMA che la notte le incontri) e aveva già una lente dedicata per Business
Central (§2) — ma nessuna per le commesse che calcolano una cifra contabile/gestionale,
esattamente il tipo di commessa che la nuova skill `controllo-gestione` (giro 1) rende
possibile scrivere. Senza questa lente, una commessa poteva citare una formula
"plausibile" mai verificata sul codice reale e l'audit non se ne sarebbe accorto — lo
stesso rischio che la skill esiste per chiudere, ma solo se qualcuno lo controlla PRIMA
della notte. Aggiunta la lente `## 2bis` (stesso stile della lente BC), richiamata dal
passo numerato in §1 come i passi esistenti. Test:
`tests/test-audit-commessa-controllo-gestione.sh`.

### 2026-08-23 (9) — Set 1/3 giro 10: quarto caso — indici di crisi, il lato economico-industriale

Quarto caso risolto con la skill `controllo-gestione`, quarto dominio diverso: indici
della crisi d'impresa (CNDCEC/CCII, D.Lgs 14/2019) — la lettura più diretta di "temi
economico-industriali" fra quelle chieste dal mandato. Letto riga per riga il codice
reale in REPO-E/gas-src/: 5 indici settoriali con soglie CNDCEC pubbliche (non un dato
aziendale, un riferimento regolatorio — a differenza della mappatura conto→aggregato,
specifica del piano dei conti reale, che NON è riprodotta) e una regola di presunzione
non banale: PN negativo fa presunzione DA SOLO, altrimenti serve che tutti e 5 gli
indici siano in allarme insieme (4 su 5 non basta). Test riscontrato due volte: contro
gli stessi tre scenari già validati nel test dell'oracolo, e contro l'aritmetica derivata
a mano — un mio primo tentativo di aggiungere un quarto scenario ("4 su 5") aveva
inavvertitamente costruito numeri che facevano scattare tutti e 5 gli indici, corretto
verificando a mano prima di fidarmi. Implementato: `tools/indici_crisi.py`. Test:
`tests/test-indici-crisi.sh`.

## Riepilogo Set 1/3 (10 giri, 4° ciclo) — "agenti per problemi matematico-contabili"

| Giro | Cosa |
|---|---|
| 1 | Skill `/controllo-gestione` (metodo: oracolo mai indovinato) + primo caso (magazzino) |
| 2 | La skill raggiunge la commessa (template issue) |
| 3 | Il template raggiunge i progetti nuovi (bootstrap-app.sh non lo copiava) |
| 4 | Bug reale: il gate del hub verificava solo 4 test su 29, non tutti quelli scritti nei cicli |
| 5 | La mappa completa (docs/system.md) non conosceva ancora la nuova capacità |
| 6 | Secondo caso (scostamento standard/effettivo) — il metodo generalizza |
| 7 | dev-critic §2ter e controllo-gestione non si citavano a vicenda (costruzione↔revisione) |
| 8 | Terzo caso (roll-forward cespiti) — il segno del fondo, invariante critico |
| 9 | audit-commessa non verificava l'oracolo delle commesse controllo-gestione |
| 10 | Quarto caso (indici di crisi CNDCEC) — il lato economico-industriale |

**Il dato del ciclo**: 4 casi reali risolti su 4 domini diversi (magazzino, produzione,
cespiti, crisi d'impresa) provano che il metodo generalizza, non è legato a un calcolo
solo. Ma la scoperta più severa non era nella lista di partenza: il gate che il hub
applica a ogni altro progetto ("dichiara le tue verifiche o è verifiche-vuote") non si
applicava a se stesso — 23 test su 29 scritti nei cicli precedenti non venivano mai
eseguiti automaticamente. Corretto al giro 4, prima di continuare a scrivere altri test
che sarebbero finiti nello stesso buco.

### 2026-08-23 (10) — Set 2/3 giro 1: /design-doc confronta le opzioni, non solo le elenca

Nuovo mandato: Set 2 — "capacità di progettare nuovo software" (brainstorming, selezione
del contesto, scelta delle migliori idee). Chiesto a Luca cosa intendesse per i due punti
più ambigui: "selezione del contesto" = gestione della context window dell'agente
(risposta: sì); "scelta delle migliori idee" = criteri di punteggio espliciti nel
design-doc esistente, non un panel multi-tentativo più pesante (risposta: sì).

**Giro 1**: `/design-doc` produceva opzioni con trade-off narrativi liberi — confrontabili
solo a occhio, e vulnerabili a criteri diversi scelti a posteriori per far vincere
l'opzione già preferita (un rischio reale, non teorico: è esattamente come un confronto
si trucca senza che sembri truccato). Aggiunto un passo che dichiara i criteri PRIMA delle
opzioni (costo, rischio, reversibilità sempre; 1-2 specifici alla decisione se pertinenti)
e una tabella opzioni×criteri per applicarli — il punteggio struttura il confronto, non
lo decide, la scelta resta di chi possiede il progetto. Aggiunto un esempio completo
lavorato (§1bis). Dogfooding sul mio stesso esempio: un percorso di file scritto senza il
prefisso della cartella reale (`morning-digest.sh` invece di
`night-shift/morning-digest.sh`) è stato colto dal test di coerenza esistente
(`test-skills-structure.sh`) prima del commit. Test:
`tests/test-design-doc-criteri-punteggio.sh`.

### 2026-08-23 (11) — Set 2/3 giro 2: graphify esiste per la notte, non arrivava al giorno

`graphify` è già regola universale in CLAUDE.md §7 ("Navigazione before reading") e
installato per l'agente notturno (`.opencode/skills/graphify/`), ma `/design-doc` — il
momento preciso in cui un agente di giorno deve capire "cosa cambia concretamente" in un
codebase per generare opzioni — non lo citava affatto. La regola generale esisteva ma
non arrivava al passo specifico che più ne beneficia (stesso pattern di "citazione
senza presidio" visto più volte in questo ciclo, applicato qui al contrario: la regola
c'è, il collegamento no). Aggiunto il rimando nel passo 3 del metodo, con il limite noto
ricordato esplicitamente (orientamento sì, semantica delle chiamate no — `calls` non è
risolto). Test: `tests/test-design-doc-graphify.sh`.

### 2026-08-23 (12) — Set 2/3 giro 3: la tabella di confronto rischiava di restare in chat

Il giro 1 aveva aggiunto la tabella opzioni×criteri al METODO di `/design-doc`, ma §2
("dove va a vivere il documento") non diceva se quella tabella dovesse arrivare nel
documento persistito (SAL.md/docs/design/) o restare solo nella conversazione —
esattamente il rischio che la regola CLAUDE.md "Keep living documentation, not just
commits" esiste per chiudere. Chi legge la voce SAL fra sei mesi avrebbe visto la scelta
ma non il confronto che l'ha prodotta. Aggiunta una riga esplicita in §2. Test:
`tests/test-design-doc-tabella-persistita.sh`.

### 2026-08-23 — design: la lente sicurezza (dev-critic §2bis) diventa automatica nel gate?

Dogfooding di `/design-doc` nel suo nuovo formato (giro 1-3) su una decisione reale
ancora aperta, non un esempio didattico: il debito in `DEBITI.md` ("Dal Giro 3 dei '10
giri autonomi'") — la lente sicurezza di `dev-critic` (§2bis) non è invocata
automaticamente in nessun punto della pipeline, resta "on demand" per disegno, e un caso
reale (night-shift-pilot issue #12) ha prodotto codice che stampava una chiave in chiaro
senza che nulla nel gate lo segnalasse da sé.

**Criteri dichiarati PRIMA delle opzioni**: costo (tempo/token per commessa), rischio
(falsi positivi/attrito vs. rischio di un leak non rilevato), reversibilità.

| Opzione | Costo | Rischio | Reversibilità |
|---|---|---|---|
| A. Status quo — resta "on demand" (solo promemoria in `.github/ISSUE_TEMPLATE/night-shift.md`) | Zero | Alto — un leak come quello reale (issue #12) passa se nessuno invoca la lente a mano | Totale (nessun cambiamento) |
| B. Lente §2bis obbligatoria per OGNI commessa nel gate | Alto — una chiamata LLM in più per ogni PR, anche quelle che non toccano logging/diagnostica | Basso sul leak, ma alto sull'attrito (falsi positivi su commesse innocue, costo che scala con il volume) | Media — si rimuove la chiamata, ma il costo già speso non si recupera |
| C. Lente §2bis condizionale — trigger automatico solo se il diff tocca pattern sensibili (`console.log`/`Logger`/`print(`/file di config o credenziali) | Basso — una chiamata LLM in più solo sulle PR che già toccano quei pattern | Basso — riduce il rischio del leak reale senza il costo di B; resta il rischio (più piccolo) che un pattern nuovo non contemplato nella lista sfugga al trigger | Alta — un grep in più nel gate, facile da rimuovere o estendere |

**Nessuna scelta è fatta qui** (regola: la decisione resta di chi possiede il progetto,
non presunta). L'opzione C sembra il miglior compromesso costo/rischio dichiarato, ma
implica una decisione di design con un costo/rischio residuo (pattern non contemplati)
che richiede il sì esplicito di Luca prima di implementarla — esattamente come già
annotato in `DEBITI.md`.

### 2026-08-23 (13) — Set 2/3 giro 5: la mappa descriveva ancora il vecchio design-doc

METHOD.md e docs/system.md descrivevano ancora `/design-doc` come "opzioni+trade-off"
(narrativa libera) dopo che i giri 1-4 avevano cambiato il meccanismo reale (criteri
dichiarati prima, tabella opzioni×criteri, persistenza obbligatoria) — la mappa non
seguiva più lo strumento che descrive. Aggiornate entrambe le righe.

### 2026-08-23 (14) — Set 2/3 giro 6: la stessa staleness, un file mai testato prima

`.zcode-commands-nuova-commessa.md` (il wizard che compone la commessa night-shift) non
era mai stato coperto da nessun test, e descriveva ancora `/design-doc` con la vecchia
formula ("opzioni con trade-off già scelte") — la stessa staleness già trovata e corretta
in METHOD.md/docs/system.md al giro 5, mai propagata qui perché nessuna verifica
collegava i due. Corretta la wording, aggiunto un primo test di coerenza per questo
file (percorsi/strumenti citati esistono davvero). Test:
`tests/test-nuova-commessa-wizard-coerenza.sh`.

### 2026-08-23 (15) — chiude un loose end del Set 1 giro 4: il report del gate mostrava solo l'ultimo test

Non è una scoperta del Set 2 in senso stretto, ma è emersa continuando a dogfoodare per
davvero il gate (non solo leggerlo) mentre verificavo la pipeline: il loop `for t in
tests/test-*.sh; do bash "$t" || exit 1; done` scritto al Set 1 giro 4 esegue davvero
tutti i file — ma il report di `morning-gate.sh` mostra solo il `tail` dell'output
dell'ULTIMO comando della riga. Con 29+ test in un solo `for`, un successo mostrava "3
OK, 0 FAIL" (il tail del solo ultimo file eseguito), facendo sembrare che la suite avesse
3 controlli in tutto — verificato dal vivo eseguendo la riga esatta e guardando cosa
sarebbe finito nel report, non presumendo che "esegue tutto" bastasse. Corretto: il loop
ora accumula un contatore e stampa "Suite test hub: N/TOT file superati" (o, sul
fallimento, "FALLITO (posizione/totale): file" + il suo output) — il tail del report
mostra sempre un riepilogo vero, mai l'output isolato dell'ultimo file per caso alfabetico.
Test: `tests/test-night-verify-riepilogo-suite.sh` (mini-suite sintetica isolata, non i
test reali del hub, per verificare sia il caso verde che quello rotto).

### 2026-08-23 (16) — Set 2/3 giro 8: la stessa staleness, un terzo posto mai controllato

Dopo aver corretto la staleness "design-doc = opzioni con trade-off" in
METHOD.md/docs/system.md (giro 5) e nel wizard (giro 6), un grep più ampio ha trovato la
STESSA staleness in un terzo file mai controllato: `.claude/skills/brainstorming/SKILL.md`,
in tre punti (la description e due righe del metodo) — descriveva ancora `/design-doc`
con la vecchia formula dopo che i giri 1-4 ne avevano cambiato il meccanismo reale.
Corretto anche lì, e aggiunto un test grep-based su tutto il repo (non file per file) per
prevenire la stessa classe di staleness in futuro. Test:
`tests/test-design-doc-nessuna-menzione-stale.sh`.

### 2026-08-23 (17) — Set 2/3 giro 9: le idee di dev-critic non avevano un passo successivo

`dev-critic` propone "nuove funzionalità non considerate" ma non diceva mai qual è il
passo successivo naturale — stesso gap di flusso già chiuso altrove in questo ciclo
(audit-commessa↔controllo-gestione, dev-critic↔controllo-gestione al Set 1 giro 7), qui
applicato alla categoria più generica del proprio output. Senza il rimando, un'idea
proposta da dev-critic restava un'affermazione isolata, non l'inizio di un percorso.
Aggiunta la regola: idea vaga → `/brainstorming`; 2+ approcci già visibili →
`/design-doc`. Test: `tests/test-dev-critic-routing-idee.sh`.

### 2026-08-23 (18) — Set 2/3 giro 10 (chiude il set): design-doc apriva solo la porta della notte

§3 di `/design-doc` citava SOLO `/nuova-commessa` come passo successivo dopo la scelta —
ma `docs/system.md` e `goal/SKILL.md` distinguono esplicitamente giorno (`/goal`, sempre
un tetto di tentativi) da notte (commessa unica, mai un tetto): un'opzione scelta con
territorio piccolo, verificabile in poche iterazioni durante il giorno, non ha motivo di
passare dalla coda notturna. Aggiunta la seconda porta: `/goal` con l'obiettivo derivato
dal criterio di successo già dichiarato al punto 1 (non inventato lì). Test:
`tests/test-design-doc-goal-o-commessa.sh`.

## Riepilogo Set 2/3 (10 giri, 4° ciclo) — "capacità di progettare: contesto e scelta delle idee"

Chiarito con Luca prima di iniziare: "selezione del contesto" = gestione della context
window dell'agente (non una disciplina dichiarativa); "scelta delle migliori idee" =
criteri di punteggio espliciti nel `/design-doc` esistente (non un panel multi-tentativo).

| Giro | Cosa |
|---|---|
| 1 | `/design-doc`: criteri dichiarati PRIMA delle opzioni + tabella opzioni×criteri, non più trade-off narrativo libero |
| 2 | `/design-doc` usa `graphify` per orientarsi (regola CLAUDE.md §7 esisteva ma non arrivava al passo che più ne beneficia) |
| 3 | La tabella di confronto deve arrivare al documento persistito (SAL.md/docs/design/), non restare solo in chat |
| 4 | Dogfooding reale: il nuovo formato usato su un debito aperto vero (lente sicurezza dev-critic §2bis) — confronto più chiaro della prosa libera precedente |
| 5-6-8 | Staleness "opzioni+trade-off" trovata e corretta in tre posti diversi (METHOD.md/docs/system.md, wizard nuova-commessa, brainstorming/SKILL.md) — con un test grep-based finale per prevenirla ovunque |
| 7 | Bug reale trovato dogfoodando: il report del gate mostrava solo l'ultimo test della suite (39 file collassati in una riga), non un totale — chiude un loose end del Set 1 giro 4 |
| 9 | `dev-critic` ora instrada le proprie idee proposte verso `/brainstorming` o `/design-doc`, non le lascia isolate |
| 10 | `/design-doc` offre anche `/goal` come passo successivo per territori piccoli/diurni, non solo la commessa notturna |

**Il dato del set**: la metà dei giri (5-6-8-9-10) non ha aggiunto funzionalità nuova —
ha ricucito collegamenti fra pezzi già esistenti che non si citavano a vicenda o
descrivevano un meccanismo già superato. Migliorare la capacità di progettare, in
pratica, è stato soprattutto rendere coerente ciò che c'era già.

**Decisione aperta per Luca** (giro 4, dogfooding su un debito reale): la lente
sicurezza `dev-critic` §2bis dovrebbe diventare un trigger automatico condizionale nel
gate (pattern sensibili nel diff) invece di restare "on demand"? Tre opzioni con
punteggio in dettaglio nella voce SAL del giro 4.

### 2026-08-23 (19) — Set 3/3 giro 1: PROJECT.md non conosceva la nuova capacità contabile

Nuovo Set 3 del 4° ciclo: flusso delle idee, interazione fra le parti — stesso tema del
Set 3 del ciclo precedente ("tutte le parti": giorno↔notte, hub↔progetti onboardati,
agente↔agente), applicato a ciò che è stato costruito in questo ciclo.

**Giro 1**: `PROJECT.md` è il primo file che una sessione di giorno legge per il
contesto specifico di un progetto (regola CLAUDE.md §6), ma la sua sezione Business
Central non citava la skill `controllo-gestione` (Set 1 giro 1) — una sessione che
lavora su un calcolo contabile sui dati BC non avrebbe saputo che il metodo esiste, e
avrebbe rischiato di trattare l'estrazione dati come se fosse anche la verifica della
formula. Aggiunta una sottosezione dedicata, distinta esplicitamente dal censimento
campi esistente (cosa esiste ≠ come si calcola). Test:
`tests/test-project-md-controllo-gestione.sh`.

### 2026-08-23 (20) — Set 3/3 giro 2: la traccia dei cervelli di giorno entrava e non usciva

Il log `~/.ai-programmer-usage.log` (Set 1 del ciclo precedente, giro 10, "nessuna
traccia dei cervelli di giorno") esiste e viene scritto da ogni chiamata `ask-*.sh`, ma
nessuno strumento lo leggeva — la stessa asimmetria "notte ha memoria (SAL.md +
metrics/gate.csv, con `gate-summary.sh` che li riepiloga), giorno no" era stata chiusa
solo a metà: scrittura sì, lettura no. Costruito `llm/usage-summary.sh`, stesso schema
di `night-shift/gate-summary.sh` applicato a questo log: per cervello, chiamate,
successi, % successo, durata media — una riga malformata viene dichiarata e scartata,
non fa fallire il riepilogo. Test: `tests/test-usage-summary.sh` (log sintetico,
aritmetica derivata a mano).

### 2026-08-23 (21) — Set 3/3 giro 3: i codici anonimi non avevano un indice

I codici REPO-A/B/C/D/E sono sparsi in oltre 15 file (skill, SAL.md, docs/system.md,
pattern) senza un indice che dica cosa rappresenta ciascuno — rischio verificato dal
vivo: al Set 1 giro 1, prima di assegnare REPO-E ho dovuto controllare a mano che non
collidesse con un codice già in uso (e ho trovato per coincidenza che REPO-A ha anch'
esso una cartella `gas-src/`, repo diverso confermato da Luca). Costruito
`night-shift/repos-index.md`: registra SOLO il ruolo di ciascun codice (ricostruito da
citazioni già pubbliche, nessuna informazione nuova), mai un nome reale — la mappatura
vera resta solo in `night-shift/repos.key`. Rimando aggiunto in CLAUDE.md §7. Test:
`tests/test-repos-index-coerenza.sh` — verifica che ogni codice usato altrove (escluse
le fixture sintetiche di test) compaia nell'indice.

### 2026-08-23 — design: quale modello ha giudicato ogni riga del banco avversariale?

Dogfooding di `/design-doc` (Set 2) su una scoperta reale del Set 3: `ADVERSARY`
(qwen/opus/glm) sceglie quale cervello giudica il banco avversariale (Set 1 del ciclo
precedente, giro 6), ma `metrics/gate.csv` non registra MAI quale modello ha giudicato
una riga specifica — il principio dichiarato in `docs/system.md` ("le decisioni future
le decidono i dati accumulati, non le opinioni") non può applicarsi a questa scelta:
non c'è modo di scoprire dai dati se GLM smentisce più bug veri di Qwen, perché il dato
non esiste.

**Criteri dichiarati PRIMA delle opzioni**: costo (complessità di modifica), rischio
(rottura del parsing esistente — `gate-esito.sh` distingue già righe storiche a 6 campi
da quelle attuali a 7, in modo posizionale e fragile), reversibilità.

| Opzione | Costo | Rischio | Reversibilità |
|---|---|---|---|
| A. Nuova colonna `adversary_model` (8° campo) | Medio — tocca `morning-gate.sh` (scrittura) e `gate-esito.sh` (già distingue 2 formati per posizione, ne servirebbe un terzo) | Alto — il parsing posizionale di `gate-esito.sh` è già fragile con 2 formati; un terzo aumenta la superficie di un bug come quello già trovato e corretto (Giro 9 dei test 2026-08-21) | Bassa — le righe storiche a 7 campi resterebbero ambigue per sempre (nessun modo di sapere quale modello le ha giudicate a posteriori) |
| B. Il modello dentro il valore della colonna `banco` esistente (es. `eseguito:smentita:glm` invece di `eseguito:smentita`) | Basso — nessuna colonna nuova, `gate-summary.sh` già fa parsing per prefisso su questa colonna | Basso — le righe storiche restano valide (nessun suffisso = modello non registrato, non un errore); nessun nuovo formato posizionale in `gate-esito.sh` | Alta — un cambio di formato di stringa, non di schema |
| C. Non tracciarlo (status quo) | Zero | Nessuno nuovo, ma il costo esistente resta: la scelta del modello non si può mai imparare dai dati | Totale |

**Nessuna scelta è fatta qui**: l'opzione B sembra il miglior compromesso (nessun rischio
sul parsing fragile già noto), ma è una decisione di design su un file di metriche
storico — richiede il sì esplicito di Luca prima di toccare `metrics/gate.csv` o gli
script che lo scrivono/leggono.

### 2026-08-23 (22) — Set 3/3 giro 5: METHOD.md non conosceva il registro del giorno, e citava male due percorsi

`METHOD.md` ("il metodo in una pagina") documentava il registro esiti della notte
(`night-shift/gate-esito.sh`/`gate-summary.sh`) ma non quello del giorno
(`llm/usage-summary.sh`, costruito al giro 2) né l'indice dei codici anonimi (giro 3) —
la porta d'ingresso al sistema non elencava due strumenti già esistenti. Aggiunte le
righe mancanti. Scrivendo il primo test di coerenza per questo file (nessuno lo copriva
mai, a differenza di `docs/system.md` dal Set 1 giro 5) ho trovato un bug pre-esistente,
non introdotto oggi: `gate-esito.sh`/`gate-summary.sh`/`privacy-check.sh` erano citati
senza la cartella reale (`night-shift/`, `tools/`) — percorsi non cliccabili/verificabili.
Corretti anche questi. Test: `tests/test-method-md-coerenza.sh`.

### 2026-08-23 (23) — Set 3/3 giro 6: "in testa al file" era in fondo

`docs/system.md` dichiara che il dettaglio operativo sul percorso cloud/ibrido è "in
testa a `tools/onboard-repo.sh`" — verificato aprendo il file: il blocco viveva nelle
ULTIME righe (127 su 127), dopo l'intero script, mai visto da chi legge l'inizio prima
di eseguire (o — come una sessione cloud, cioè questa stessa sessione — non può nemmeno
eseguire lo script, perché chiama `gh` direttamente senza mai avvisarlo finché non si
arriva in fondo). La citazione era vera nel contenuto, sbagliata nella posizione — lo
stesso effetto pratico di una citazione senza presidio: chi cerca il dettaglio dove
promesso non lo trova. Spostato il blocco davvero in testa, rimossa la duplicazione.
Test: `tests/test-onboard-repo-percorso-cloud-in-testa.sh`.

### 2026-08-23 (24) — Set 3/3 giro 7: lo stesso gap, mai propagato al file gemello

`onboard-repo.sh` ha ricevuto al giro 6 un avviso in testa sul percorso cloud/ibrido
(niente `gh` CLI in una sessione cloud). `bootstrap-app.sh` — il suo gemello per
progetti NUOVI, non esistenti — chiama `gh` altrettanto direttamente (auth status, repo
create, label create, api user) e scrive su `repos.conf`, ma non aveva nessun avviso:
lo stesso gap, mai propagato al file gemello, perché nessuna verifica collegava i due
script. Aggiunto lo stesso blocco, adattato alle chiamate reali di questo script. Test:
`tests/test-bootstrap-app-percorso-cloud.sh`.

### 2026-08-23 (25) — Set 3/3 giro 8: la mappa citava solo metà del limite condiviso

`docs/system.md` descriveva il limite "niente `gh` CLI in una sessione cloud" citando
SOLO `tools/onboard-repo.sh` — ma `bootstrap-app.sh` (giro 7) condivide esattamente lo
stesso limite e ora lo stesso avviso in testa. Ampliato il testo per citare entrambi gli
script gemelli. Test: `tests/test-system-md-percorso-cloud-entrambi.sh`.

### 2026-08-23 (26) — Set 3/3 giro 9: tenere d'occhio la crescita della suite

Misurato dal vivo (non presunto): la suite `tests/test-*.sh` eseguita da `.night-verify`
è cresciuta da 25 a 50 file in questo solo ciclo, ~31s di esecuzione — ben sotto il
watchdog di 120s (`run_guarded`), ma il trend è monotono (ogni giro ne aggiunge). Non un
problema oggi: loggato in `DEBITI.md` come "poi" da non far diventare "mai" — quando la
suite supererà ~150-180 file, o una singola esecuzione si avvicinerà ai 60-90s, valutare
se alzare il watchdog di questa riga specifica o parallelizzare.

### 2026-08-23 (27) — Set 3/3 giro 10 (chiude il set): verifica end-to-end di tutto il gate

Chiusura del set: eseguito per intero `.night-verify` così com'è oggi (tranne
`shellcheck`, non installato in questa sandbox — limite d'ambiente, non del metodo,
stesso tipo di limite già annotato per Ollama/Qwen nei cicli precedenti). `bash -n` sul
gate, `privacy-check.sh` (corretto: "manca la chiave locale" in questa sandbox, che non
ha `repos.key` — comportamento giusto, non un falso verde: il gate reale gira sul Mac
dove la chiave esiste), l'intera suite (50/50 file superati), e l'indice SAL già
coerente. Nessuna sorpresa: la prova end-to-end conferma che i 27 giri di questo set (e
i 30 dei due precedenti) compongono un sistema coerente, non solo singole modifiche
isolate.

## Riepilogo Set 3/3 (10 giri, 4° ciclo) — "flusso delle idee, interazione fra le parti"

| Giro | Cosa |
|---|---|
| 1 | `PROJECT.md` non citava `controllo-gestione` per i calcoli sui dati BC — la prima cosa che una sessione di giorno legge non conosceva la nuova capacità |
| 2 | `llm/usage-summary.sh`: il log dei cervelli di giorno (ciclo precedente) entrava e non usciva mai come insight — stesso schema di `gate-summary.sh` applicato al giorno |
| 3 | `night-shift/repos-index.md`: i codici anonimi (REPO-A…E) sparsi in 15+ file senza un indice — rischio di collisione verificato dal vivo prima di assegnare REPO-E |
| 4 | Dogfooding di `/design-doc` su una decisione aperta reale: tracciare quale modello ha giudicato ogni riga del banco avversariale — nessuna scelta implementata, tre opzioni con punteggio |
| 5 | `METHOD.md` non citava il registro del giorno né l'indice dei codici; due percorsi citati senza la cartella reale — primo test di coerenza per questo file |
| 6-7-8 | Il blocco "percorso cloud/ibrido" viveva in fondo a `onboard-repo.sh` (non in testa, come promesso) — corretto, poi propagato al gemello `bootstrap-app.sh` (stesso gap, mai propagato), poi la mappa aggiornata a citare entrambi |
| 9 | La crescita della suite test (25→50 file in un ciclo) loggata come debito da tenere d'occhio, non un problema oggi |
| 10 | Verifica end-to-end dell'intero `.night-verify` — tutto coerente |

**Il dato del set**: quasi tutti i giri (1,3,5,6,7,8) sono varianti dello stesso
pattern — una parte del sistema sa qualcosa che un'altra parte, che ne avrebbe bisogno,
non sa. Il flusso delle idee, quando si guarda con attenzione ogni volta, si rompe più
spesso per un collegamento mai fatto che per un bug nella logica di una singola parte.

## Riepilogo dei tre set (30 giri, 4° ciclo) — dopo il ciclo precedente da 40 giri

- **Set 1** (agenti per problemi matematico-contabili): skill `/controllo-gestione`
  (mai indovinare una formula, citarla come oracolo) + 4 casi reali su 4 domini diversi
  (magazzino, produzione, cespiti, crisi d'impresa); bug reale nel gate (verificava 4
  test su 29); un `client_secret` trovato in un repo esterno, segnalato non toccato.
- **Set 2** (capacità di progettare: contesto e scelta delle idee): `/design-doc`
  guadagna criteri espliciti dichiarati prima delle opzioni + tabella opzioni×criteri;
  `graphify` collegato al passo che più ne beneficia; un bug reale nel report del gate
  (mostrava solo l'ultimo test su 39); tre casi di staleness della vecchia formula
  "opzioni+trade-off" trovati e corretti in file diversi.
- **Set 3** (flusso delle idee, interazione fra le parti): un indice per i codici
  anonimi; il registro del giorno completato (scrittura c'era, lettura no); due script
  gemelli (`bootstrap-app.sh`/`onboard-repo.sh`) con lo stesso limite non documentato
  allo stesso modo; due decisioni aperte dogfoodate con `/design-doc`, mai implementate
  senza il sì di Luca.

## 5° ciclo — Set 1/3, giro 1: `.claude/agents/` non esisteva

### 2026-08-23 — Set 1 giro 1: nessun sistema di subagent, solo skill

Gap reale trovato leggendo la struttura del repo prima di scrivere qualsiasi cosa
(regola "Read before acting"): `.claude/skills/` esiste da due cicli, ma
`.claude/agents/` (il meccanismo nativo di Claude Code per i subagent — frontmatter
`name`/`description`/`tools`, selezionabili dal tool Agent) non esiste affatto in questo
hub. Le skill sono metodo invocato a comando; un subagent è un ruolo con accesso
scoped ai tool, delegabile in autonomia — mancava del tutto per il dominio
matematico-contabile richiesto da Luca.

Primo agente: `.claude/agents/contabilita-analitica.md` — specialista di contabilità
analitica/controllo di gestione per Gruppo Camarlinghi, tool scoped a
`Read, Grep, Glob, Bash` (niente Edit/Write: legge e verifica, non scrive codice di
produzione senza supervisione), corpo che eredita per intero la regola "una formula
non si indovina mai" da `.claude/skills/controllo-gestione/SKILL.md` e cita i 4 casi
reali già risolti (`tools/scostamento_standard_effettivo.py`,
`tools/riconciliazione_magazzino.py`, `tools/rollforward_cespiti.py`,
`tools/indici_crisi.py`) come riferimento diretto, non come ispirazione vaga.

Test di riscontro: `tests/test-agents-structure.sh` — stesso schema di
`test-skills-structure.sh` (frontmatter valido, percorsi citati verificati) ma itera
sul glob `.claude/agents/*.md` invece di nomi hardcoded, applicando da subito la
lezione già pagata una volta con `.night-verify` (4 test hardcoded, 23+ file nuovi mai
eseguiti) — qui il test scala automaticamente man mano che il set aggiunge altri
agenti, senza bisogno di toccarlo ad ogni giro.

### 2026-08-23 — Set 1 giro 2: un secondo agente, non un duplicato

Prima bozza scartata: un secondo agente "magazzino" che ripeteva quasi verbatim il
corpo di `contabilita-analitica.md` cambiando solo quale tool citare — sarebbe stato
uno spreco (regola CLAUDE.md "zero waste": tre righe simili sono meglio di
un'abstrazione prematura, ma qui il rischio era l'opposto, duplicare senza motivo).
Un "sistema di agenti" reale distingue i RUOLI, non solo il dominio: `contabilita-
analitica` verifica/applica calcoli già scritti (tool scoped a sola lettura + Bash,
niente Edit/Write); il nuovo `.claude/agents/costruttore-calcoli-gestionali.md` ha un
ruolo davvero diverso — costruisce calcoli NUOVI quando nessun tool esistente
risolve il caso, con Edit/Write autorizzati, seguendo lo stesso metodo (oracolo prima
del codice, mai indovinare) ma applicato alla costruzione invece che alla
verifica. Il corpo dell'agente chiude esplicitamente il confine: quando il calcolo è
pronto, il compito passa fuori dal suo ruolo (revisione → prossimo agente del set,
giro 3).

### 2026-08-23 — Set 1 giro 3: il terzo ruolo, dogfoodato per davvero sui 4 tool esistenti

Terzo agente: `.claude/agents/revisore-calcoli-critici.md` (tool scope: solo lettura +
Bash, niente Edit/Write — un giro di analisi non modifica codice, regola CLAUDE.md e
§3 di dev-critic) — applica la lente §2ter (segno invertito, plug che nasconde un
residuo) ai calcoli GIÀ scritti in `tools/*.py`, ruolo distinto sia da
`contabilita-analitica` (applica, non dubita) sia da `costruttore-calcoli-gestionali`
(scrive nuovo, non revisiona esistente).

Prima di scrivere solo la prosa dell'agente, l'ho eseguito per davvero sui 4 tool già
in produzione (regola dev-critic "dogfooding reale, non solo lettura"). Un sospetto
concreto emerso leggendo `tools/indici_crisi.py`: l'indice "Patrimonio netto / Debiti
totali" usa `a["passivoTot"]` come denominatore — il nome suggerisce "tutto il
passivo" (che includerebbe il patrimonio netto stesso, gonfiando il denominatore e
producendo un indice falsato per difetto). Verificato contro l'oracolo reale (repo
esterno REPO-E, il modulo di calcolo indici crisi, righe 85 e 92 lette per riga, non
a memoria): `passivoTot = -passivo`, dove `passivo` è la somma della sola categoria
contabile `'Liabilities'` (i debiti), categoria distinta da `'Equity'` — il nome è
fedele alla realtà, non ambiguo. Sospetto chiuso senza fix: un falso positivo
risolto controllando l'oracolo invece di fidarsi del nome della variabile, esattamente
il tipo di verifica che questo agente esiste per fare. Nessun bug nuovo trovato sui 4
tool: la disciplina §2ter applicata GIÀ in costruzione (cicli precedenti) ha lasciato
una suite di test avversariali (segno del fondo, soglia limite con `<=`, denominatore
zero, "4 su 5 non basta") che coprono esattamente gli scenari che questo agente
avrebbe cercato. Un esito onesto — non ogni giro deve inventare un bug per essere
utile; qui il valore è la conferma provata, non la scoperta.

### 2026-08-23 — Set 1 giro 4: quinto caso reale minato da gas-src, scadenzario aging

Nuovo tool `tools/scadenzario_aging.py`: classificazione a fasce di scadenza (aging)
e totali per scadenzario clienti/fornitori — quinto dominio diverso (dopo magazzino,
produzione, cespiti, crisi d'impresa) minato dal repo esterno REPO-E su richiesta
esplicita di Luca ("puoi utilizzare gas-src per creare snippet di codice o
ispirarti"). Formula letta riga per riga sul modulo reale di scadenzario: confini di
fascia con `<` stretto ai limiti negativi e `<=` ai limiti positivi (non simmetrici —
un dettaglio che sembra arbitrario ma è nel codice originale, non indovinato), e una
convenzione di segno non ovvia per i fornitori: una fattura diventa un'uscita
negativa, una nota di credito resta un'entrata positiva, indipendentemente dal segno
con cui BC restituisce l'importo grezzo.

Esempio input/output derivato PRIMA del codice (regola CLAUDE.md): tutti gli 11
confini di fascia testati uno per uno ai valori esatti di transizione (-61/-60,
-31/-30, 0/30/31, 90/91, assente), non solo un caso per fascia — un errore di `<` vs
`<=` a un solo confine sarebbe passato inosservato con un test più grossolano. Test:
`tests/test-scadenzario-aging.sh` (23 controlli, tutti verdi al primo run: derivare
l'aritmetica a mano prima di eseguire ha reso l'implementazione corretta dal primo
tentativo, non il contrario). I tre agenti del set (`contabilita-analitica`,
`revisore-calcoli-critici`) aggiornati per citare anche questo quinto caso nelle loro
liste di riferimento — nessuna lista deve restare indietro rispetto ai casi reali
risolti, stesso principio del glob in `test-agents-structure.sh` (giro 1).

### 2026-08-23 — Set 1 giro 5: stesso gap già trovato due volte, mai chiuso per gli agenti

Verificato (mai assunto) se `bootstrap-app.sh`/`onboard-repo.sh` propagano anche
`.claude/agents/` come già fanno per `.claude/skills/` e `patterns/` (bug trovato e
corretto per quelle due cartelle nel Set 3 del 4° ciclo): `grep -n "\.claude"` su
entrambi gli script mostrava solo `.claude/skills`, nessuna riga per `.claude/agents/`
— stesso gap, terza cartella, mai applicato lo schema già scritto due volte prima.
Corretto in entrambi gli script con lo stesso pattern esatto già in uso: copia
wholesale in `bootstrap-app.sh` (progetto nuovo, niente da preservare) e merge
per-file — mai sovrascrive un agente che il progetto avesse già personalizzato con lo
stesso nome — in `onboard-repo.sh` (progetto esistente). Test di riscontro:
`tests/test-bootstrap-agents-propagation.sh` e
`tests/test-onboard-agents-propagation.sh`, stessa struttura dei test analoghi già
scritti per le skill (compreso il caso "un agente personalizzato non viene
sovrascritto").

### 2026-08-23 — Set 1 giro 6: il sistema di agenti non si conosceva da solo

Verificato (grep, non assunto) se `docs/system.md`, `METHOD.md` e la skill
`controllo-gestione` stessa citassero il nuovo sistema `.claude/agents/` costruito nei
giri 1-3: nessuno dei tre lo faceva — la mappa completa del sistema, la "porta
d'ingresso" del metodo, e la skill che gli agenti stessi ereditano non sapevano che i
tre subagent esistessero. Stesso pattern ricorrente in questo ciclo e nei precedenti
(una parte costruisce, un'altra parte che ne beneficerebbe non lo scopre mai da sola).

Corretto in tre punti: `docs/system.md` guadagna una sezione dedicata (ruoli, 5 casi
risolti, propagazione); `METHOD.md` aggiorna la riga controllo-gestione per citare la
delega possibile a un agente; `controllo-gestione/SKILL.md` guadagna un §6 che elenca
i tre agenti e chiarisce che delegare non sostituisce il metodo (la stessa disciplina,
solo un esecutore diverso). Guardia di regressione: due asserzioni aggiunte ai test
di coerenza già esistenti (`test-system-md-controllo-gestione.sh`,
`test-method-md-coerenza.sh`) invece di un file nuovo — stessi file, stesso file
sotto test, nessun motivo di duplicare l'infrastruttura del test.

### 2026-08-23 — Set 1 giro 7: un limite reale non ancora dichiarato

`.claude/agents/` è un meccanismo nativo di Claude Code (frontmatter letto dal tool
Agent) — verificato, non assunto, che OpenCode (ZCode, e il turno notturno che ci gira
sopra via `night-shift.sh`) non ha qui alcuna configurazione equivalente
(`.opencode/agent/` assente, esiste solo `.opencode/skills/`). I tre agenti costruiti
in questo set sono quindi disponibili solo nelle sessioni Claude Code di giorno, non
nel turno notturno né in ZCode — un limite reale, non una promessa vuota, nello stesso
spirito degli altri 5 già elencati in `docs/system.md` §"Limiti dichiarati" (es. "Opus
non passa dal router").

Aggiunto come sesto limite dichiarato, con una guardia di regressione che verifica il
limite resti VERO nel tempo (non solo scritto): il test controlla che
`.opencode/agent/` non esista davvero — se in futuro qualcuno lo introduce, il test
fallisce e segnala che la dichiarazione in `docs/system.md` è diventata stale, invece
di lasciarla silenziosamente falsa.

### 2026-08-23 — Set 1 giro 8: dogfooding reale sui propri agenti — non sono invocabili qui

Scoperta importante, non solo un dettaglio: ho provato a invocare per davvero
`contabilita-analitica` come `subagent_type` del tool Agent (regola dev-critic
"dogfooding reale, non solo lettura" — applicata ai TRE agenti costruiti da questo
stesso set, non solo al codice altrui). Risultato: **"Agent type 'contabilita-
analitica' not found"** — l'elenco degli agenti disponibili in questa sessione
(Claude Code Remote/cloud) resta fisso ai tipi nativi (general-purpose, Explore,
Plan, claude-code-guide, statusline-setup, claude), anche DOPO che i tre file
`.claude/agents/*.md` erano già committati e presenti sul branch corrente.

Non è un bug di questo hub — è un limite dell'ambiente in cui questa sessione gira,
verificato dal vivo e non semplicemente dedotto dalla documentazione. Non è stato
possibile verificare se un'installazione Claude Code CLI locale standard (fuori da
questa sessione remota) leggerebbe `.claude/agents/*.md` come previsto — quella
verifica richiede un ambiente diverso, non disponibile qui, e va segnalata come tale
piuttosto che assunta in un senso o nell'altro.

Corretto in tre punti per non lasciare una promessa vuota nel sistema (regola CLAUDE.md
"limiti dichiarati, non promesse vuote"): il limite #6 in `docs/system.md` riscritto
per riportare il fatto verificato (non più solo "OpenCode non ce l'ha", ma "qui non è
invocabile, punto"); la riga di METHOD.md corretta per non presentare la delega come
via provata; `controllo-gestione/SKILL.md` §6 aggiorna l'avviso — i tre file restano
utili come DOCUMENTAZIONE del metodo divisa per ruolo (il corpo prosa non è
inutile: descrive comunque bene chi fa cosa), ma non come automazione oggi funzionante
in questo ambiente. La via provata resta la skill invocata a comando (§1-5).

### 2026-08-23 — Set 1 giro 9: la scoperta del giro 8 entra in DEBITI.md

Il limite trovato al giro 8 (agenti non invocabili in questa sessione) non è una
scorciatoia presa da questo ciclo, ma è comunque un gap fra "cosa promette il
sistema" e "cosa fa oggi qui" che merita un posto in `DEBITI.md` (regola CLAUDE.md
"minimal-code ladder": ogni scorciatoia o gap deferito va scritto, così "dopo" non
diventa "mai") — non solo nel limite dichiarato in `docs/system.md`, perché
`DEBITI.md` è il posto dove si tiene traccia di COSA saldare e QUANDO, non solo del
fatto che un limite esiste. Voce aggiunta con la condizione di chiusura esplicita:
verificare in un'installazione Claude Code CLI locale standard (fuori da questa
sessione remota) se `.claude/agents/*.md` viene letto come previsto — a quel punto il
limite #6 di `docs/system.md` si restringe da "non invocabile" a "non invocabile solo
in sessioni remote/cloud", oppure si scopre che il formato dei tre file va corretto.

### 2026-08-23 — Set 1 giro 10 (chiude il set): un bug reale trovato rieseguendo la suite più volte

Verifica end-to-end della riga `.night-verify` che esegue tutta `tests/test-*.sh`
(stesso schema di chiusura già usato per il set analogo del ciclo precedente): due
run consecutive misurano ~34s (54 file) — coerente col trend già in `DEBITI.md` — ma
una run isolata ha misurato **2m9s**, quasi al ceiling di 120s del watchdog
`run_guarded()`. Non mi sono fermato al numero anomalo: ho cercato la causa invece di
attribuirla genericamente a "crescita della suite" (lezione già pagata una volta in
questo stesso file: un vecchio ciclo aveva attribuito un hang simile a "claude -p
lento" quando la causa vera era altrove).

Causa trovata dal vivo (`ps aux` dopo una run): `tests/test-stdin-timeout.sh` usava
`< <(sleep 100)` (process substitution) per simulare uno stdin apribile senza EOF —
ma `timeout 20` uccide solo il comando che LEGGE da quel descrittore, non il processo
`sleep 100` che lo alimenta, lasciandolo orfano fino alla sua scadenza naturale di
100s. Ogni esecuzione del test (3 volte, una per wrapper) ne lascia fino a 3; eseguire
la suite intera molte volte di fila — esattamente cosa fa questo stesso ciclo di
auto-miglioramento — li accumula, e la loro concorrenza per le risorse del sandbox è
la causa più plausibile dell'anomalia (non riprodotta a comando dopo il fix, ma la
correzione rimuove la causa nota indipendentemente).

Fix: `check_bounded()` ora apre una FIFO esplicita invece della process substitution,
cattura il PID del `sleep` di supporto e lo uccide subito dopo ogni controllo — stesso
comportamento osservabile dai wrapper (stdin apribile, nessun EOF), zero processi
orfani. Guardia di regressione aggiunta nello stesso test: dopo ogni `check_bounded`,
verifica che il PID del sleep sia davvero morto (`kill -0` fallisce), non solo che il
wrapper abbia risposto in tempo. `DEBITI.md` aggiornato per non lasciare un numero
anomalo non spiegato nella voce già esistente sulla crescita della suite.

## Riepilogo Set 1/3 (10 giri, 5° ciclo) — "un sistema di agenti per problemi matematico-contabili"

| Giro | Cosa |
|---|---|
| 1 | `.claude/agents/` non esisteva — primo agente (`contabilita-analitica`) + test di struttura sul glob |
| 2 | Secondo agente con ruolo distinto (`costruttore-calcoli-gestionali`), non un duplicato |
| 3 | Terzo agente (`revisore-calcoli-critici`), dogfoodato sui 4 tool esistenti — un sospetto risolto controllando l'oracolo |
| 4 | Quinto caso reale minato da gas-src su richiesta esplicita di Luca: scadenzario aging |
| 5 | Stesso gap già trovato due volte (skills, patterns) mai chiuso per gli agenti — propagazione corretta |
| 6 | Il sistema di agenti non citava se stesso in system.md/METHOD.md/SKILL.md |
| 7 | Limite reale dichiarato: `.claude/agents/` non ha equivalente in OpenCode/notte |
| 8 | Dogfooding sui propri agenti: non invocabili in questa sessione — scoperta corretta ovunque, non nascosta |
| 9 | La scoperta del giro 8 entra in `DEBITI.md` con condizione di chiusura esplicita |
| 10 | Bug reale trovato rieseguendo la suite più volte: leak di processi orfani in un test, corretto con guardia di regressione |

**Il dato del set**: il sistema di agenti costruito (3 ruoli distinti, 5 casi reali
minati da REPO-E) è solido come METODO, ma il giro 8 ha dimostrato che "l'ho costruito
e documentato" non equivale a "funziona qui" — solo l'averlo provato per davvero ha
scoperto il limite, esattamente la lezione centrale di dev-critic applicata al proprio
lavoro appena fatto, non solo al codice altrui. Il giro 10 ripete la stessa lezione su
un piano diverso: un numero anomalo non spiegato è un invito a indagare, non ad
archiviarlo come rumore.

## 5° ciclo — Set 2/3: progettare (brainstorming, selezione del contesto, scelta delle idee)

### 2026-08-23 — Set 2 giro 1: la regola "tabella persistita" era verificata solo nella prosa, non nella realtà

`test-design-doc-tabella-persistita.sh` (4° ciclo) verifica che
`.claude/skills/design-doc/SKILL.md` §2 RICHIEDA la tabella opzioni×criteri nel
documento persistito — ma nessun test verificava se le voci REALMENTE scritte in
`SAL.md` (le due dogfoodate nel ciclo precedente) rispettassero quella regola nella
pratica. Verificate a mano entrambe: la rispettano già (tabella presente, criteri
dichiarati prima, almeno 2 opzioni reali) — nessun bug da correggere oggi, ma nessuna
guardia impediva a una terza voce futura di violarla in silenzio.

Nuovo test: `tests/test-design-doc-sal-entries-hanno-tabella.sh` — estrae ogni voce
"### ... — design: ..." da `SAL.md` e verifica per ciascuna: criteri dichiarati,
tabella con colonna "Opzione", almeno 2 opzioni reali confrontate (non una vera e una
paglia). Stesso principio delle guardie già scritte per i limiti dichiarati in
`docs/system.md` (5° ciclo, Set 1 giri 6-7): non basta che la regola sia scritta bene,
deve restare verificabile che venga seguita.

### 2026-08-23 — Set 2 giro 2: selezione del contesto — nessun percorso senza graphify

`design-doc/SKILL.md` §3 (4° ciclo) dice "se `graphify-out/graph.json` esiste, usa
graphify" per orientarsi nel codebase prima di generare le opzioni — ma non diceva
cosa fare quando NON esiste. Non un caso ipotetico: verificato in questa stessa
sessione che `graphify-out/` non esiste e il binario `graphify` non è installato — un
vuoto reale nella selezione del contesto, non teorico.

Aggiunto il ramo mancante: territorio piccolo e già chiaro → `Grep`/`Glob` sui termini
di dominio; territorio ampio o nomi dei componenti non ancora noti → l'agente
`Explore` (breadth "quick"/"medium") — stessa soglia già in uso nel resto del sistema
("3+ query esplorative → Explore"), non una regola nuova. Test estesi in
`tests/test-design-doc-graphify.sh` (già esistente, non un file nuovo — stesso
argomento, stesso file sotto test) per verificare che il fallback sia dichiarato e
citi `Explore`.

### 2026-08-23 — Set 2 giro 3: `/goal` costruito e mai eseguito, chiuso col primo loop reale

Trovato ripetendo lo stesso controllo del Set 1 giro 8 su un altro strumento: `loops/`
conteneva solo `README.md` — `/goal` (implementato nel 4° ciclo) non era mai stato
eseguito per davvero da quando esiste. "Costruito e documentato" non è "provato",
stessa lezione, stesso rischio, stavolta su un comando invece che su un agente.

Eseguito il primo loop reale: obiettivo verificabile "la suite `tests/test-*.sh`
completa in meno di 60s su una run pulita" (livello 2, tetto 2 tentativi) — motivato
dalla crescita reale della suite in questo stesso ciclo (50→55 file in poche ore,
trend già annotato in `DEBITI.md`). Tentativo 1: 35.1s, vittoria. Verifica
avversariale obbligatoria (§3 della skill, non facoltativa): rieseguita in ordine
casuale invece che alfabetico, per escludere un tempo favorito dall'ordine — 34.8s,
confermata. Log completo: `loops/2026-08-23-suite-sotto-60s.md`.

Nessun cambiamento al codice richiesto (l'obiettivo era già rispettato) — il valore
del giro è aver dimostrato che il meccanismo `/goal` funziona end-to-end la prima
volta che viene usato per davvero, non solo che la sua prosa è ben scritta.

### 2026-08-23 — Set 2 giro 4: il wizard chiedeva "come" verificare, non "quale livello"

`docs/system.md` definisce una tassonomia condivisa a 5 livelli di verifica
(deterministico → numerico → verità ritardata → LLM giudice → umano), già richiesta
esplicitamente da `/goal` (§1: "dichiara qui quale livello copre l'obiettivo") — ma il
wizard `.zcode-commands-nuova-commessa.md` (punto 6) chiedeva solo "come si verifica"
senza mai chiedere il livello, restando disallineato dalla stessa tassonomia che
un'altra parte del sistema già usa attivamente.

Corretto: il punto 6 ora chiede esplicitamente il livello 1-5, con la tassonomia
richiamata in una riga (non riscritta a memoria — cita `docs/system.md`). Guardia di
regressione aggiunta a `tests/test-nuova-commessa-wizard-coerenza.sh` (test esistente,
stesso file sotto verifica, non un file nuovo).

### 2026-08-23 — Set 2 giro 5: il gate meccanico verifica che un riferimento SOMIGLI a
uno vero, non che lo sia

`test-night-shift-design-gate.sh` (4° ciclo) verifica che il gate del turno notturno
blocchi un `## Design` senza riferimento reale — ma "riferimento reale" per quel gate
è una REGEX (un link, "SAL.md", "issue #42", un'estensione file): un testo che
somiglia a una citazione la passa, anche se il file/la voce citata non esiste o non
contiene quello che promette. Nessun passo del sistema apriva davvero il riferimento
per controllare — il gate meccanico non può farlo (nessun accesso al contenuto reale
dei file citati in modo affidabile a comando), ma `audit-commessa` (pre-flight di
giorno, con accesso completo al repo) può e deve.

Aggiunto `.claude/skills/audit-commessa/SKILL.md` §1bis: apri il riferimento citato in
`## Design` e verifica che esista davvero e, se è un design-doc, che contenga la
tabella opzioni×criteri richiesta da `design-doc/SKILL.md` §2 — non fidarsi che il
testo "somigli" a una citazione. Test:
`tests/test-audit-commessa-riferimento-design-verificato.sh`.

### 2026-08-23 — Set 2 giro 6: "scelta delle migliori idee" al plurale — nessuna riga lo diceva

`/design-doc` struttura la scelta DENTRO una singola idea già isolata (2-3 opzioni per
lo stesso problema). Nessun punto del sistema (grep confermato: zero risultati su
"priorità"/"quale prima" in tutte le skill, METHOD.md, docs/system.md) diceva come
scegliere DA QUALE idea partire quando 3 o più emergono insieme nello stesso report —
esattamente il caso di questo stesso ciclo di auto-miglioramento (30 giri, decine di
idee proposte via dev-critic nei cicli precedenti).

Aggiunto in `.claude/skills/dev-critic/SKILL.md` (sezione "Nuove funzionalità non
considerate"): quando emergono 3+ idee distinte nello stesso report, ordinale con gli
stessi criteri costo/rischio/reversibilità che `/design-doc` già usa per le opzioni —
non un punteggio nuovo, lo stesso vocabolario applicato al portafoglio invece che a
una sola decisione. Resta un ordine di lettura, non una raccomandazione a
implementare — la scelta resta di chi possiede il progetto. Guardia di regressione
estesa in `tests/test-dev-critic-routing-idee.sh` (test esistente, stessa sezione
sotto verifica).

### 2026-08-23 — Set 2 giro 7: cosa fare quando NESSUNA opzione è buona

`design-doc/SKILL.md` strutturava bene il caso "un'opzione vince sugli altri criteri"
(§3-4), ma non diceva nulla sul caso in cui tutte e 2-3 le opzioni generate hanno un
punteggio scadente sui criteri critici — il rischio reale: forzare comunque una
scelta fra tre opzioni deboli solo perché il formato (tabella + scelta) lo richiede,
presentandole come "il confronto le ha risolte" quando in realtà nessuna lo era.

Aggiunto §4bis: se nessuna opzione ha un punteggio accettabile, non forzare — è un
segnale che il PROBLEMA va rivisto, non solo la soluzione: torna a `/brainstorming`
con quello che le opzioni deboli hanno rivelato (già informazione nuova sul
problema). Test: `tests/test-design-doc-loopback-brainstorming.sh`.

### 2026-08-23 — Set 2 giro 8: lo stesso bug (nomi hardcoded, non un glob) trovato una terza volta

`test-skills-structure.sh` elencava 4 skill per nome fisso (design-doc, brainstorming,
goal, controllo-gestione) — `audit-commessa`, `dev-critic` e `verifica-visiva` non
erano MAI state controllate strutturalmente da questo test, per l'intera vita di
queste skill, senza che nulla lo segnalasse. Stesso identico bug già corretto due
volte in questo ciclo (`.night-verify` nel 4° ciclo; `.claude/agents/*.md` scritto
giusto la prima volta al giro 1 di questo Set 1) — la lezione non era mai stata
applicata retroattivamente a questo test specifico.

Convertito a un glob su `.claude/skills/*/SKILL.md`. Attivarlo ha subito trovato 2
falsi positivi reali (non ipotetici): `audit-commessa` cita `docs/GRAMMATICA_DOMINIO.md`
e `CATALOGO_ENDPOINT_BC.md` come riferimenti CONDIZIONALI ("se esiste... nel
progetto" — un progetto onboardato, non questo hub) che il check trattava come
citazioni rotte; `dev-critic` cita `gas/Sp.js`/`tools/test-sp.js`, che appartengono al
debito privacy già tracciato in `DEBITI.md` (nomi di repo esterni pre-esistenti, fuori
scope). Entrambi esclusi esplicitamente con la ragione scritta, non silenziosamente.
Trovato anche un vero refuso minore: `audit-commessa` citava `night-shift.sh` senza il
prefisso `night-shift/` — corretto.

### 2026-08-23 — Set 2 giro 9: lo stesso bug, una quarta e una quinta volta (una scritta da me in questo stesso ciclo)

Cercato sistematicamente altre liste hardcoded dopo il pattern trovato al giro 8:
`tests/test-bootstrap-skills-propagation.sh` elencava 6 nomi fissi
(`dev-critic audit-commessa verifica-visiva design-doc brainstorming goal`) —
`controllo-gestione` (7ª skill, aggiunta nel ciclo precedente) non era mai stata
verificata da questo test specifico, quarta occorrenza dello stesso bug in questo
ciclo. Convertito a un glob su `.claude/skills/*/`.

Controllando anche il proprio lavoro di questo stesso ciclo (non solo quello
altrui — regola dev-critic §"dogfooding reale", applicata a sé stessi):
`tests/test-bootstrap-agents-propagation.sh`, scritto da me al giro 5 di questo Set 1,
**prima** di aver imparato la lezione al giro 1/8, aveva la stessa identica lista
fissa dei 3 agenti. Corretto anch'esso con un glob — un quarto agente futuro sarebbe
passato inosservato esattamente come `controllo-gestione` lo è stato nell'altro file.
Nessun bug reale nascosto oggi in nessuno dei due (7/7 skill e 3/3 agenti già
copiavano correttamente) — il valore è aver chiuso il buco di copertura prima che un
ottavo elemento futuro ci cadesse dentro in silenzio.

### 2026-08-23 — Set 2 giro 10 (chiude il set): verifica end-to-end di tutta la pipeline di progettazione

Rieseguiti tutti i test di coerenza toccati o rilevanti in questo set
(`test-skills-structure.sh` su tutte e 7 le skill, `test-design-doc-nessuna-menzione-stale.sh`,
`test-nuova-commessa-wizard-coerenza.sh`, `test-method-md-coerenza.sh`,
`test-system-md-controllo-gestione.sh`) — tutti verdi, nessuna regressione introdotta
dai 9 giri precedenti. Suite completa: 57/57.

## Riepilogo Set 2/3 (10 giri, 5° ciclo) — "progettare: brainstorming, contesto, scelta delle idee"

| Giro | Cosa |
|---|---|
| 1 | La regola "tabella persistita" era verificata solo nella prosa — nuovo test sulle voci reali di SAL.md |
| 2 | Selezione del contesto: nessun percorso quando graphify non è installato (caso reale di questa sessione) |
| 3 | `/goal` costruito nel ciclo precedente, mai eseguito — primo loop reale, `loops/` non più vuota |
| 4 | Il wizard chiedeva "come" verificare ma non "quale livello" — disallineato da /goal |
| 5 | Il gate meccanico verifica che un riferimento SOMIGLI a uno vero, non che lo sia — audit-commessa lo apre davvero |
| 6 | "Scelta delle migliori idee" al plurale: nessuna riga diceva come ordinare 3+ idee distinte |
| 7 | Cosa fare quando NESSUNA opzione è buona — design-doc torna a /brainstorming invece di forzare |
| 8 | Stesso bug (nomi hardcoded, non un glob) trovato una terza volta: 3 skill su 7 non erano mai testate |
| 9 | Lo stesso bug una 4ª e 5ª volta — una scritta da me in questo stesso ciclo, corretta appena trovata |
| 10 | Verifica end-to-end di tutta la pipeline: nessuna regressione |

**Il dato del set**: la metà dei giri (1, 8, 9) sono la stessa famiglia di bug —
verificare la PROSA di una regola non basta se nessuno verifica che la REALTÀ la
rispetti, e una lista scritta a mano invecchia silenziosamente ogni volta che il
sistema cresce di un elemento. Il giro 9 aggiunge un dato scomodo ma onesto: la
disciplina va applicata anche al proprio lavoro appena fatto nello stesso ciclo, non
solo a quello dei cicli precedenti.

## 5° ciclo — Set 3/3: flusso delle idee, interazione fra le parti

### 2026-08-23 — Set 3 giro 1: un cross-reference in una sola direzione

Prima ipotesi verificata e SCARTATA (per non archiviare un falso positivo): il turno
notturno (`night-shift.sh`) potrebbe non sapere che `.claude/skills/controllo-gestione/`
esiste, dato che OpenCode (qwen) non ha una convenzione `.claude/` propria. Verificato
il flusso reale: il template `.github/ISSUE_TEMPLATE/night-shift.md` istruisce CHI
SCRIVE la commessa (giorno) a citare l'oracolo della formula GIÀ nel body dell'issue —
la notte legge il body già completo, non deve mai aprire la skill da sola. Nessun bug:
il design "commesse precaricate, non brief d'indagine" (CLAUDE.md §7) già lo prevedeva.

Trovato invece un vero gap: `controllo-gestione/SKILL.md` §6 (Set 1 giro 6) cita già i
tre agenti — ma `dev-critic` §2ter, la lente che `revisore-calcoli-critici` incarna
esattamente, non citava quell'agente. La direzione mancava in un solo senso. Aggiunta
la citazione mancante, con lo stesso limite noto ricordato (non invocabile in questa
sessione) ovunque l'agente viene menzionato — coerenza dell'avviso, non solo del nome.
Test: `tests/test-dev-critic-controllo-gestione-crossref-bidirezionale.sh`.

### 2026-08-23 — Set 3 giro 2: i diagrammi in cima mostravano solo la strada notturna

`METHOD.md` e `docs/system.md` aprono con un diagramma "brainstorming → design-doc →
commessa → notte → gate → review" — una linea retta. Ma il metodo reale, dopo il ciclo
precedente (design-doc → `/goal` per territorio piccolo) e questo Set 2 (giro 7,
design-doc → brainstorming se nessuna opzione è buona), ha due rami che il diagramma
non mostrava mai: chi legge solo il diagramma vedrebbe un'unica strada (la notte),
quando ne esistono altre due già implementate e testate.

Corretti entrambi i diagrammi per mostrare i due rami. Test:
`tests/test-pipeline-diagrammi-mostrano-i-rami.sh` — verifica che entrambi i file
citino sia `/goal` sia il ritorno a `/brainstorming`, non solo la strada notturna.

### 2026-08-23 — Set 3 giro 3: l'indice dei codici anonimi era rimasto indietro sul proprio ciclo

`night-shift/repos-index.md` (4° ciclo, set 3 giro 3) dice esplicitamente nel suo
"Come usarlo": aggiorna la riga se un codice non corrisponde più a quanto scritto
altrove. La riga REPO-E elencava ancora solo i 4 casi del ciclo precedente
(scostamento, riconciliazione, roll-forward, indici di crisi) — il 5° caso
(scadenzario aging, minato in questo stesso ciclo al Set 1 giro 4) non c'era ancora.
Corretta.

Guardia di regressione aggiunta a `test-repos-index-coerenza.sh` (esistente): verifica
che ogni caso reale citato in `controllo-gestione/SKILL.md` §3 compaia anche nella
riga REPO-E dell'indice — non basta che il codice esista, la descrizione deve restare
al passo con ogni nuovo caso minato dallo stesso repo.

### 2026-08-23 — Set 3 giro 4: la stessa famiglia di bug diventa un pattern nel catalogo

Cinque occorrenze indipendenti dello stesso bug in un solo ciclo (`.night-verify` nel
4° ciclo; `test-skills-structure.sh`, `test-bootstrap-skills-propagation.sh`, e due
test scritti da me in questo stesso ciclo — `test-bootstrap-agents-propagation.sh` al
giro 5, PRIMA di imparare la lezione al giro 8) sono un segnale che merita un posto
nel catalogo `patterns/` (CLAUDE.md §7: "prima di scrivere infrastruttura, controlla
patterns/"), non solo cinque commit sparsi.

Nuovo pattern: `patterns/copertura-dal-glob.md` — un test che deve coprire "tutti gli
elementi di una categoria" e li elenca per nome fisso invecchia silenziosamente ogni
volta che la categoria cresce; il fix è sempre iterare su un glob reale, mai una lista
scritta a mano. Registrato in `patterns/README.md`. Propagazione già verificata via
`test-bootstrap-patterns-propagation.sh` (che usa `find`, non una lista — coerente col
pattern che descrive).

### 2026-08-23 — Set 3 giro 5: una regola del catalogo mai verificata meccanicamente

`patterns/README.md` dichiara "l'ancora deve esistere, o la voce non sopravvive" —
ma nessun test verificava mai questa regola per davvero, per NESSUNO dei 24 pattern
del catalogo, dalla sua creazione. Lo stesso principio "citazione-non-presidio" che
il catalogo stesso descrive (§dedicato), applicato al catalogo stesso.

Nuovo test: `tests/test-patterns-ancore-esistono.sh` — estrae l'ancora di ogni
pattern, verifica quelle hub-locali (9 su 24; le altre citano repo esterni o processi
non verificabili da qui, correttamente escluse). Risultato: **9/9 ancore verificate
esistono davvero** — nessuna ancora morta trovata oggi, un esito onesto che conferma
la regola del catalogo era già rispettata, non solo scritta.

### 2026-08-23 — Set 3 giro 6: `/goal` aveva raggiunto il suo obiettivo ma nessuno lo sapeva ancora

`METHOD.md` e `.claude/skills/goal/SKILL.md` dicevano ancora "loops/ è vuota" DOPO che
il Set 2 giro 3 di questo stesso ciclo aveva eseguito il primo loop reale — la prosa
non seguiva più i fatti, esattamente il pattern ricorrente di questo Set 3 (una parte
del sistema resta indietro rispetto a un'altra che è appena cambiata).

Corretto: `METHOD.md` aggiorna la riga `/goal`, `goal/SKILL.md` qualifica la storia al
passato ("finché non è stato scritto questo comando") invece di presentarla come stato
attuale. Guardia di regressione: `tests/test-goal-loops-non-piu-vuota.sh` — verifica
che `loops/` contenga davvero un log reale, e che nessuno dei due file affermi ancora
il contrario al presente. Un tentativo iniziale del test dava un falso positivo su
`goal/SKILL.md` (bloccava anche la frase corretta al passato, non solo quella stale) —
corretto prima di committarlo, non dopo.

### 2026-08-23 — Set 3 giro 7: controllo-gestione parlava un vocabolario isolato sulla verifica

`/goal` e il wizard `/nuova-commessa` (5° ciclo, set 2 giro 4) richiedono entrambi di
dichiarare il livello 1-5 della tassonomia condivisa (`docs/system.md`) — ma il passo
6 di `controllo-gestione/SKILL.md` ("verifica con un riscontro") restava nel proprio
vocabolario ("test verde" + "riscontro confermato"), senza collegarlo alla stessa
tassonomia che il resto del sistema usa attivamente.

Aggiunto il collegamento: test contro un oracolo = livello 1-2, riscontro contro un
totale BC non ancora chiuso = livello 3 (verità terrena ritardata) — dichiaralo se la
commessa lo richiede. Test:
`tests/test-controllo-gestione-livelli-verifica.sh`.

### 2026-08-23 — Set 3 giro 8: sweep sistematico di tutte le citazioni fra skill/agenti

Invece di continuare a scoprire cross-reference asimmetrici uno alla volta per caso
(giro 1, giro 7), un grep sistematico su TUTTI i file `.claude/skills/*/SKILL.md` e
`.claude/agents/*.md` per costruire la mappa completa di chi cita chi. Trovato un
altro caso reale: `audit-commessa` dichiara "non sostituisce dev-critic", ma
`dev-critic` non diceva mai nulla su `audit-commessa` — stessa famiglia di asimmetria,
diversa coppia.

Aggiunta la direzione mancante nella description di `dev-critic`. Test:
`tests/test-dev-critic-audit-commessa-crossref.sh`. Il resto della mappa (controllo-
gestione↔3 agenti, costruttore↔revisore↔contabilita-analitica) risulta già coerente
in entrambe le direzioni — nessun altro caso trovato in questo sweep.

### 2026-08-23 — Set 3 giro 9: un'ipotesi di bug smentita dal vivo, prima di diventare un fix

Ipotesi: i test esistenti (`test-skills-structure.sh`/`test-agents-structure.sh`)
verificano il frontmatter con `grep` (apre con `---`, contiene `name: X`) — mai con un
parser YAML reale. Ho scritto un test che estrae il frontmatter di tutte le 7 skill e
i 3 agenti e lo passa a `yaml.safe_load` (PyYAML, disponibile in questa sessione).
Risultato: **10/10 falliscono** con "mapping values are not allowed here" — ogni
description contiene un `: ` (due punti+spazio) dentro il testo libero (es. "critica
costruttiva propositiva: idee di sviluppo"), che uno YAML rigoroso rifiuta come valore
scalare non quotato.

Prima di scriverlo come fix (regola CLAUDE.md "Done means proven"), verificato se
fosse un bug REALE: le stesse skill sono state elencate correttamente, testo e due
punti compresi, in decine di `<system-reminder>` di questa sessione per l'intero
ciclo — prova diretta che il parser REALE di Claude Code non usa YAML rigoroso per
questo frontmatter (probabilmente un'estrazione riga-per-riga `chiave: resto-della-
riga`, non un parser YAML completo). Il test che avevo scritto era basato su
un'ipotesi sbagliata sul formato reale, non su un bug del repo — **eliminato prima di
committarlo**, non lasciato come falso positivo permanente nella suite. Nessun fix
necessario: le 10 description restano corrette per il parser che le legge davvero.

### 2026-08-23 — Set 3 giro 10 (chiude il set e il ciclo): verifica end-to-end finale

Rieseguiti tutti i test toccati o rilevanti in questo Set 3
(`test-skills-structure.sh` su 7 skill, `test-pipeline-diagrammi-mostrano-i-rami.sh`,
`test-repos-index-coerenza.sh`, `test-patterns-ancore-esistono.sh`,
`test-dev-critic-audit-commessa-crossref.sh`,
`test-dev-critic-controllo-gestione-crossref-bidirezionale.sh`) — tutti verdi.
Working tree pulito, nessuna modifica pendente. Suite completa: 63/63.

## Riepilogo Set 3/3 (10 giri, 5° ciclo) — "flusso delle idee, interazione fra le parti"

| Giro | Cosa |
|---|---|
| 1 | Cross-reference mono-direzionale: controllo-gestione citava i 3 agenti, dev-critic §2ter no |
| 2 | I diagrammi in cima a METHOD.md/docs/system.md mostravano solo la strada notturna, non i due rami |
| 3 | L'indice REPO-E era rimasto ai 4 casi del ciclo precedente, il 5° (scadenzario) mancava |
| 4 | Cinque occorrenze dello stesso bug in un ciclo diventano un pattern nel catalogo (`copertura-dal-glob`) |
| 5 | Una regola del catalogo patterns/ ("l'ancora deve esistere") mai verificata meccanicamente |
| 6 | `/goal` aveva raggiunto il suo obiettivo (giro 3 del Set 2) ma la prosa non lo sapeva ancora |
| 7 | `controllo-gestione` parlava un vocabolario isolato sulla verifica, non la tassonomia condivisa |
| 8 | Sweep sistematico di tutte le citazioni fra skill/agenti: un'altra asimmetria (dev-critic↔audit-commessa) |
| 9 | Un'ipotesi di bug (YAML rigoroso) smentita dal vivo prima di diventare un fix sbagliato |
| 10 | Verifica end-to-end finale: tutto verde, working tree pulito |

**Il dato del set**: il tema "interazione fra le parti" si è confermato soprattutto
come un problema di SINCRONIA — non bug di logica, ma parti del sistema che si sono
mosse in momenti diversi (agenti creati al Set 1, diagrammi scritti prima che i rami
esistessero, `/goal` eseguito solo al Set 2 giro 3) senza che le parti collegate lo
scoprissero da sole. Il giro 9 è il contrappeso necessario: non ogni sospetto è un
bug, e la stessa disciplina che trova i problemi reali deve anche saper riconoscere
quando l'ipotesi era sbagliata, prima di introdurne uno nuovo per correggerne uno
inesistente.

## Riepilogo dei tre set (30 giri, 5° ciclo) — dopo il ciclo precedente da 30 giri

- **Set 1** (un sistema di agenti per problemi matematico-contabili): tre subagent con
  ruoli distinti (`contabilita-analitica`, `costruttore-calcoli-gestionali`,
  `revisore-calcoli-critici`), un quinto caso reale minato da REPO-E (scadenzario
  aging), propagazione corretta a bootstrap/onboard — ma la scoperta più importante
  del set è stata negativa: dogfoodando i propri agenti, non risultano invocabili in
  questa sessione (verificato dal vivo, non presunto), documentato ovunque serve
  invece di nascosto o sopravvalutato. Un bug reale di leak di processi trovato
  rieseguendo la suite più volte.
- **Set 2** (progettare: brainstorming, contesto, scelta delle idee): `/design-doc`
  guadagna un fallback per la selezione del contesto senza graphify e un loopback a
  `/brainstorming` quando nessuna opzione è buona; `dev-critic` impara a ordinare 3+
  idee col vocabolario già esistente; `/goal` eseguito per la prima volta da quando
  esiste; lo stesso bug "lista hardcoded invece di glob" trovato tre volte, una
  scritta dallo stesso autore nello stesso ciclo e corretta appena scoperta.
- **Set 3** (flusso delle idee, interazione fra le parti): sweep sistematico di tutte
  le citazioni fra skill/agenti (un'asimmetria trovata); i diagrammi della pipeline
  aggiornati per mostrare i rami reali; un nuovo pattern nel catalogo
  (`copertura-dal-glob`) per la famiglia di bug ricorrente in questo ciclo; la regola
  del catalogo patterns/ verificata meccanicamente per la prima volta; un'ipotesi di
  bug smentita prima di diventare un fix sbagliato.

**Il filo comune ai tre set**: la disciplina di dev-critic ("dogfooding reale, non
solo lettura") applicata non solo al codice altrui ma al proprio lavoro appena fatto
nello stesso ciclo — sia quando rivela un limite scomodo (Set 1, gli agenti non
invocabili), sia quando smentisce un proprio sospetto prima che diventi un fix
sbagliato (Set 3, il falso YAML), sia quando trova lo stesso errore ripetuto dallo
stesso autore che l'aveva appena corretto altrove (Set 2, le liste hardcoded).

### 2026-08-23 — dopo il push e la PR #35: il limite del Set 1 giro 8 era temporaneo, non permanente

Subito dopo l'apertura della PR #35, il roster degli agenti disponibili in questa
sessione mostrava i tre subagent (`contabilita-analitica`,
`costruttore-calcoli-gestionali`, `revisore-calcoli-critici`) come tipi disponibili
per il tool Agent — cosa che NON accadeva al Set 1 giro 8, subito dopo il primo
commit. Riverificato dal vivo (non presunto dal solo elenco): invocati tutti e tre,
con un prompt di eco minimo, e tutti e tre hanno risposto correttamente.

Questo NON invalida il metodo del giro 8 (era la verifica corretta da fare in quel
momento, con l'informazione disponibile allora) — cambia la conclusione: il limite
non è permanente/ambientale come documentato ("non invocabile in questa sessione
Claude Code Remote/cloud"), ma dipendente da un refresh del roster degli agenti che
non si era ancora verificato al momento del primo tentativo. Non isolato
sperimentalmente cosa fa scattare il refresh (nuova sessione? il push al branch
remoto? un intervallo di tempo? l'apertura della PR?) — non presumerlo, dichiarato
come incertezza residua invece di una nuova ipotesi non verificata.

Corretto ovunque la conclusione precedente era stata scritta come limite fisso:
`docs/system.md` §"Limiti dichiarati" #6, `DEBITI.md` (voce segnata ✅ SALDATO),
`METHOD.md`, `.claude/skills/controllo-gestione/SKILL.md` §6,
`.claude/skills/dev-critic/SKILL.md` §2ter, e la relativa guardia di regressione in
`tests/test-system-md-controllo-gestione.sh`. Le voci storiche di questo file (Set 1
giro 8/9, PR #35) NON sono state riscritte — restano la cronaca accurata di cosa era
vero in quel momento con l'informazione allora disponibile; questa voce documenta la
correzione successiva, non nasconde l'errore di conclusione iniziale.

### 2026-08-24 — feedback di un utente esterno reale: 5 gap di processo, non di codice

Un secondo utente ha usato AI_Programmer (non Luca) e ha riportato 5 criticità
verificate sul repo prima di intervenire (regola "leggi prima di agire"):

1. **Scoperta delle skill non documentata** — verificato: nessun `README.md` in
   radice esisteva. Un utente nuovo doveva dedurre dal codice che le skill scattano
   per matching automatico sulla `description` del frontmatter, non da un elenco.
   Fix: creato `README.md` in radice con la spiegazione del meccanismo reale
   (skill vs agenti, il limite noto del refresh del roster, i comandi citati ma non
   ancora scritti sono debiti in `DEBITI.md`, non bug). Guardia:
   `tests/test-readme-skill-discovery.sh`.
2. **La promessa di PROJECT.md non era vincolante** — CLAUDE.md §6 diceva solo
   "leggilo e tienilo aggiornato", nessun trigger su QUANDO aggiungere una sezione
   nuova: restava vuota in silenzio per un progetto toccato per la prima volta.
3. **`segreto-come-impronta` era un pattern facoltativo, non una regola** — un
   principio critico (mascherare un segreto in output, non solo omettere/stampare)
   dipendeva dal fatto che qualcuno consultasse `patterns/` di sua iniziativa.
4. **Nessuna convenzione per il secret handoff one-shot** — un primo login/deploy
   interattivo (token OAuth, `clasp login`) non aveva risposta diversa da "incollalo
   in chat", esattamente ciò che il punto 3 vuole evitare.
5. **`patterns/` non era auto-consultato** — dipendeva dalla memoria dell'agente in
   quel turno, non da un meccanismo del sistema.

Punti 2-5 diventano regole vincolanti in `CLAUDE.md` (non solo un README esplicativo,
perché sono principi di comportamento per ogni sessione futura, non solo per un
utente nuovo che legge una volta). Dettaglio del fix per punto nelle voci successive
di questa stessa giornata.

### 2026-08-24 — punti 2-4: tre nuove regole vincolanti in CLAUDE.md

- **§6, "The first-touch trigger"**: prima della prima modifica in un progetto non
  ancora presente in PROJECT.md, aggiungerne la sezione (anche uno stub) prima di
  procedere. Dichiarata come regola di processo per l'agente, non un controllo
  automatico — rilevare "progetto nuovo" dal solo filesystem non è meccanizzabile
  senza falsi positivi (deciso esplicitamente, non un compromesso silenzioso).
- **§2, "Mask, don't omit, when a secret could surface in output"**: promuove
  `patterns/segreto-come-impronta.md` da pattern facoltativo a regola vincolante,
  citando esplicitamente la fonte (l'ancora non muore, resta anche il pattern con
  l'implementazione di riferimento). Vieta sia la stampa in chiaro sia l'omissione
  silenziosa dell'intera riga — un'omissione nasconde anche la lunghezza/forma del
  segreto, informazione utile la cui assenza può sembrare un bug.
- **§2, "One-shot secret handoff"**: per un primo login/deploy interattivo, due
  alternative in ordine di preferenza — (1) l'agente esegue lui stesso il comando
  interattivo, cosicché il token passi dal flusso del tool e non dalla chat; (2) se
  un valore deve arrivare dall'utente fuori banda, questo lo scrive in un file locale
  non tracciato e ne passa solo il percorso.

Guardie di regressione: `tests/test-claude-md-project-first-touch.sh`,
`tests/test-claude-md-segreto-impronta-regola.sh`,
`tests/test-claude-md-secret-handoff-oneshot.sh`.

### 2026-08-24 — punto 5: patterns/ auto-consultato via hook PreToolUse (mai fatto prima in questo repo)

Prima volta che questo repo usa un hook `.claude/settings.json` (non esisteva alcun
`settings.json`). `tools/pattern-reminder-hook.sh` scatta su `PreToolUse` con matcher
`Edit|Write`: se il `file_path` toccato matcha una categoria sensibile (auth/secret/
credential/token/login/password, incluse le varianti italiane "credenzial"/"segret"),
stampa un `additionalContext` con le righe pertinenti di `patterns/README.md` —
`permissionDecision` è sempre `"allow"`, non blocca mai l'operazione, per costruzione.

Verificato dal vivo, non solo con un pipe-test sintetico (dogfooding, disciplina
dev-critic §1.2): dopo aver scritto il hook, un vero `Edit` su un file di test con path
sensibile (`/tmp/hook-test-sensitive/auth-token-test.txt`) ha prodotto realmente il
`<system-reminder>` con il reminder nello stesso turno — il watcher dei settings ha
raccolto il file appena creato senza bisogno di `/hooks` o riavvio (diversamente dal
caso generico descritto dalla guida della skill `update-config`, dove un `settings.json`
comparso a metà sessione potrebbe non essere osservato). Grep iniziale troppo largo
(matchava anche una riga di prosa contenente "token" nell'intestazione del registro, non
solo le righe della tabella pattern) — corretto restringendo il grep alle righe che
iniziano per `| [`. Test di regressione: `tests/test-pattern-reminder-hook.sh` (9
controlli, incluso che `permissionDecision` sia sempre `allow`).

### 2026-08-24 — feedback dal campo (REPO-F, BC/GAS): il matching per description non è affidabile quanto presunto

Luca ha lavorato ore su un caso reale (REPO-F, dashboard GAS + backfill mai eseguito
su Business Central — vedi `night-shift/repos-index.md`) e riporta due letture, una
confermativa e una nuova e più seria.

**Confermato sul campo**: le regole di processo di CLAUDE.md hanno guidato scelte
concrete — chiedere conferma prima del push in produzione, fermarsi a indagare la vera
causa invece di rattoppare il sintomo, riusare pattern esistenti (`enrichContactFromOrder_`
→ `enrichRequestedDeliveryFromOrder_`, `probeBcEntity_` per diagnosticare invece di
indovinare). Risultato: trovato il bug vero (un trigger mai attivato), non una toppa.

**Scoperta nuova, più seria di un altro gap nella lista**: due skill che descrivono
quasi alla lettera il caso di oggi non si sono attivate da sole.
- `verifica-visiva` esiste apposta per "screenshot di una dashboard GAS appena
  modificata, prima/dopo" — Luca ha modificato `Dashboard.html` di REPO-F e non l'ha
  invocata; lo screenshot è arrivato da un'altra strada, non dal meccanismo pensato per
  questo.
- `dev-critic` (che "critica un intero progetto con un tentativo reale di usarlo, non
  solo lettura statica") descrive quasi alla lettera come è stato trovato il bug di una
  funzione di backfill delle consegne mai eseguita — ma è stato trovato per fiuto investigativo
  su UN sintomo segnalato, non invocando la skill sull'intero progetto. Conseguenza
  aperta, non richiusa: se fosse stata invocata su tutto il progetto (90+ file), non
  solo sul sintomo, avrebbe potuto far emergere ALTRE funzionalità scritte-ma-mai-
  attivate — restano non cercate.

**Il filo che lega tutti i gap trovati finora** (da questo ciclo e dal precedente):
PROJECT.md mai aggiornato, `patterns/` mai consultato, skill mai invocate anche quando
calzano alla lettera — stessa forma ogni volta: contenuto scritto bene, che esiste solo
se qualcuno se ne ricorda al momento giusto. L'unico correttivo che rompe lo schema è
il hook `PreToolUse` di ieri — e infatti è anche l'unico con un buco già identificato e
non richiuso: copre `Edit|Write`, non `Bash` — non copre il modo in cui si è lavorato
oggi (clasp deploy, probe su BC). Anche il tentativo più concreto di uscire dalla
dipendenza dalla memoria ha lasciato scoperto lo stesso tipo di varco.

Priorità indicata da Luca per il prossimo giro: non un'altra regola in CLAUDE.md, ma
un aggancio automatico più ampio del hook attuale — l'unica cosa vista finora che ha
davvero smesso di dipendere dalla sua memoria. Non ancora implementato in questo
momento: prima di scegliere UN meccanismo, le interpretazioni possibili (estendere il
matcher a `Bash`; un hook `UserPromptSubmit` che confronta il compito dichiarato con le
description delle skill; un giro periodico di `dev-critic` sull'intero progetto invece
che a comando) hanno tradeoff diversi (costo, falsi positivi/negativi, portata) — da
decidere con Luca, non a mia discrezione, prima di scrivere codice.

### 2026-08-24 — 6° ciclo, giro 0: baseline verde, tre bug di portabilità macOS

Prima di aprire i tre set nuovi (mandato di Luca: Set 1 agenti matematico-contabili,
Set 2 progettazione/brainstorming, Set 3 flusso idee/interazione LLM), la suite
`.night-verify` andava riportata verde: era ferma al test 2 di 68 (fail-fast) con
`test-ask-usage-log.sh` rosso. Tre bug trovati eseguendo, non leggendo:

1. **`ask-opus.sh` moriva su `"${MODEL_ARGS[@]}"` con array vuoto** sotto `set -u`
   sulla bash 3.2 di sistema macOS (`MODEL_ARGS[@]: unbound variable`, rc=1 dal vivo)
   — la correzione è la guardia `${arr[@]+"${arr[@]}"}`, idioma pre-bash-4.4. Stesso
   rischio latente in `tools/backup-config.sh` (`ARGS`/`TMPFILES` vuoti), corretto.
2. **`timeout` non esiste su macOS stock** (GNU coreutils): i tre wrapper `llm/ask-*`
   e due test lo invocavano direttamente e morivano con rc=127 prima di raggiungere
   il cervello. Introdotto `llm/_timeout.sh` con `ai_timeout` (GNU timeout → gtimeout
   → fallback perl fork+wait con alarm). Il fallback uccide il GRUPPO di processi
   (`setpgrp` + `kill -PID`), non solo il figlio: la versione che uccideva solo il
   figlio lasciava il nipote (`sleep` dentro `bash -c`) vivo a tenere aperta la pipe
   della command substitution — la stessa regressione "sleep orfano" già pagata da
   `run_guarded` (tests/test-lib.sh). Verificato: kill a 3s esatti, rc=124, exit code
   del comando preservato, stdout intatto.
3. **`test-morning-gate-verdict.sh` hardcodava `master`** ma questo Mac ha
   `init.defaultBranch=main`: ogni repo sintetico collassava su "non-dichiarate"
   senza che nulla di reale fosse rotto. Il test ora rileva il branch con
   `default_branch` (lib.sh), come fa già il codice di produzione. E
   `test-design-doc-sal-entries-hanno-tabella.sh` usava `mapfile` (bash 4+, assente
   sulla 3.2) — sostituito con un ciclo `while read` portabile.

Errori pagati durante il giro, registrati per non ripeterli: (a) la prima versione
del fallback perl non chiamava `alarm` — definito l'handler e dimenticato il segnale,
il timeout non scattava mai; (b) un apostrofo italiano in un commento DENTRO la
stringa perl tra apici singoli chiudeva la stringa e zsh eseguiva pezzi di perl come
comandi — nei commenti dentro stringhe quotate singole niente apostrofi. Il test di
regressione `tests/test-ai-timeout.sh` esercita il ramo perl FORZANDOLO
(`AI_TIMEOUT_FORCE_PERL=1`) sul codice spedito, non su una copia nel test: sul Mac
dell'autore `timeout` esiste e il fallback resterebbe altrimenti mai provato.

Suite: 68/68 (69 file col nuovo test). Lezione: la portabilità dichiarata del repo
("solo Mac Apple Silicon") non copriva "quale bash" e "quali coreutils" — due
assunzioni implicite diverse dentro lo stesso repo.

### 2026-08-24 (2) — 6° ciclo, Set 1/3: mappa del dominio, 2 agenti e 3 oracoli

Mandato di Luca per il Set 1: migliorare gli agenti, verificare se mancano, costruire
un sistema adatto a problemi matematico-contabili e temi economici-industriali
(analitica, magazzino, controllo di gestione), idoneo a sviluppare gli script del
repo esterno REPO-E (91 progetti, 998 file — censiti per intero, non stimati).

**Giro 1 — la mappa.** `docs/mappa-dominio-gas-src.md`: 12 categorie, conteggi, e
l'incrocio con oracoli/agenti esistenti. La legge emersa dai numeri: i due domini
più popolati (ciclo attivo ~20 progetti, ciclo passivo ~10) erano gli unici grandi
senza NESSUN oracolo — i cinque oracoli del 5° ciclo coprivano i domini da cui
erano nati, non i domini più grandi. Anche i sei pattern trasversali (client BC
dedicato in 56/91 progetti, CacheService>PropertiesService dopo un incidente reale
da limite 9KB, override a livelli, WebApp in 31/91, LockService, assente≠zero) e
l'assenza quasi totale di test (6/91 progetti). Test di forma+privacy:
`tests/test-mappa-dominio-gas-src.sh`.

**Giro 2 — l'agente censitore.** `censitore-forma-dati`: il censimento della forma
dei dati (passo #1 del metodo, pattern "forma-dei-dati-verificata") restava
manuale; ora è un agente in sola lettura che produce la sezione "Forma dei dati
(verificata)" con provenienze file:riga e ipotesi marcate come tali. Distinto da
audit-commessa (quello guarda commesse in coda, questo alimenta lavoro nuovo).

**Giri 3-5 — tre oracoli dai domini scoperti.** Tutti con formula minata dal
codice REPO-E (file:riga nel docstring) e aritmetica derivata a mano nel test:
- `valorizzazione_magazzino.py`: costo medio "primo non-nullo per codice",
  override articolo>categoria>gruppo (il primo vince), senza-costo = anomalia
  (non zero), location escluse MAI scartate in silenzio, giacenza negativa
  valutata e flaggata. **I costi generali % NON vengono applicati**: in REPO-E la
  percentuale è caricata in config ma nessun consumer la usa (verificato a grep)
  — l'oracolo la dichiara "punto di applicazione non provato" invece di
  indovinarla. È la regola "la formula non si indovina" resa meccanica.
- `margine_documento.py`: accoppiamento vendita↔acquisto per riferimento
  normalizzato (trim+upper+solo spazi rimossi — il trattino NO: aspettativa
  corretta dopo run rossa, il codice REPO-E non accoppia "RF 001" a "RF-001"),
  margine = vendita−acquisto, percentuale SUI RICAVI (40.0%, non 66.7% sul
  costo), nota di credito = annullato e riportato, unmatched = ERRORE non margine
  zero, BU diversa flaggata ma calcolata.
- `accuratezza_fatture_acquisto.py`: solo l'OVER-invoicing è discrepanza
  (fattura sotto ordine = fatturazione parziale — in REPO-E era un falso
  positivo corretto a mano, la lezione sta nel docstring), whitelist fornitori
  legittima il senza-ordine, erroriReali = anomale+inesistenti+discrepanze,
  accuratezza (T−E)/T, obiettivo margine <0.1%.

**Giro 6-7 — l'agente costruttore.** `sviluppatore-gas`: costruisce progetti Apps
Script INTERI (distinto da costruttore-calcoli-gestionali che scrive un calcolo
Python) col canone dei sei pattern della mappa, censimento e oracolo PRIMA del
codice, test di riscontro obbligatorio ("non essere il novantaduesimo progetto
senza test"). Il trio calcoli armonizzato: elenchi aggiornati agli 8 oracoli.

**Giri 8-9 — propagazione e mappe.** I test di propagazione bootstrap/onboard
erano già glob-based: i due agenti nuovi arrivano ai progetti senza toccare
nulla (verificato eseguendo, 5/5). `docs/system.md` e METHOD.md aggiornati; un
riferimento test scritto senza percorso `tests/` è stato colto sul nascere dal
guardiano del system.md.

**Giro 10 — il dogfooding che chiude il set.** Un guardiano che vigila solo
sugli altri non è un guardiano: `test-mappa-dominio-gas-src.sh` (nuovo) è
l'unico test della suite che verifica la PRIVACY di un documento (nessun nome
cartella-progetto REPO-E) — e il set stesso è stato costruito citando REPO-E e
mai un cliente, in mappa, oracoli, agenti e SAL. Suite completa: 73/73 verdi.

Lezione del set: il censimento ha spostato il lavoro dove i NUMERI dicevano che
mancava (ciclo attivo/passivo), non dove la memoria suggeriva; e due aspettative
dei test erano sbagliate (normalizzazione riferimento; aritmetica a mano
1000−1200≠−100) — in entrambi i casi la run rossa ha corretto il TEST prima che
diventasse un falso guardiano, mai il contrario.

### 2026-08-24 (3) — 6° ciclo, Set 2/3: divergenza, contesto col budget, squalifiche e spike

Mandato di Luca per il Set 2: migliorare la capacità di progettare nuovo software —
brainstorming, selezione del contesto, scelta delle migliori idee.

**Giro 1 — la divergenza mancava.** `/brainstorming` era tutto convergente (socratico,
una domanda alla volta): sapeva arrivare AL problema ma non sapeva guardare il problema
da più angoli. Aggiunto il punto 3: dopo le prime risposte, 2-3 RIFORMULAZIONI del
problema (non soluzioni) tra cui l'utente sceglie — chiudere la divergenza con una
decisione, non con la stanchezza. E §1bis: il contesto si seleziona PRIMA della prima
domanda, per non chiedere ciò che il sistema sa già.

**Giro 2 — selezione-contesto.** Skill nuova: pacchetto di fonti nell'ordine di densità
(SAL del dominio → pattern → mappa → oracoli → graphify/grep), BUDGET dichiarato (max
~5 fonti), e la parte che nessuno fa: le ESCLUSIONI si scrivono ("un'esclusione
silenziosa è un buco travestito da scelta"). Se il contesto trovato chiude il compito,
il compito è riportare il riferimento e fermarsi.

**Giri 3-4 — squalifiche e secondo ordine.** `/design-doc` §1bis: VINCOLI DI
SQUALIFICA dichiarati prima dei criteri di confronto — un'opzione che li viola non
entra in gara (una gara con un morto in pista è teatro). Ogni opzione dichiara gli
EFFETTI DI SECONDO ORDINE: cosa tocca altrove (notte, gate, skill e progetti che
citano ciò che cambia). Pagato un errore istruttivo: la prima stesura rinumerava i
punti 3-6 della skill e la guardia di regressione del loopback (che ancora "4bis"
per numero) è diventata rossa — i numeri dei punti sono riferimenti stabili, citati
fuori; le aggiunte entrano come bis, non spostano la numeratura. Corretto senza
toccare la guardia: era lei ad avere ragione.

**Giro 5 — lo spike.** §3bis: quando la cella della tabella che deciderebbe è ignota
(latenza non documentata, libreria mai provata di notte), esperimento a tempo e scopo
vincolati — `/goal max 1 tentativo`, output da buttare: quando lo scopo è misurare,
il risultato è un numero, non una base di codice. Mai "spike" per esplorare l'opzione
intera: quello è implementare con un altro nome.

**Giro 6 — il backlog non è inventiva.** `dev-critic` aggancia la mappa dei domini:
le categorie VUOTO/PARZIALE col conteggio di progetti reali sono il backlog già
prioritizzato per densità d'uso; un'idea che contraddice la mappa va giustificata
contro la mappa.

**Giri 7-9 — mappe e guardie.** METHOD.md e docs/system.md aggiornati; guardia di
regressione unica per tutte le aggiunte (`tests/test-design-set2-sesto-ciclo.sh`,
10 controlli), costruita — come le altre — sui test design-doc esistenti rimasti
verdi senza eccezioni.

**Giro 10 — il dogfooding: un design-doc vero su un punto vero.** Il residuo del Set 1
(costi generali % della valorizzazione: caricati in REPO-E, mai applicati) è diventato
il caso reale della voce "design:" qui sotto — squalifiche prima, criteri prima,
tre opzioni col secondo ordine, scelta che resta a Luca. Il metodo appena scritto,
usato subito sul primo problema vero disponibile.

Lezione del set: le guardie di regressione sono contratti — quando una diventa rossa
per una rinumeratura, la lezione è "i numeri sono API", non "il test è rigido".

### 2026-08-24 (4) — design: i costi generali % nella valorizzazione di magazzino

Il primo caso reale che esercita le aggiunte del Set 2 (squalifiche, secondo ordine,
spike) — su un punto lasciato aperto dal Set 1, non su un esempio costruito.

Contesto (4 fonti, budget dichiarato — selezione-contesto §2): il docstring di
`tools/valorizzazione_magazzino.py`, `docs/mappa-dominio-gas-src.md`, il codice
ValuationConfig REPO-E (via grep), la voce SAL del Set 1. Escluso: il progetto
magazzino REPO-E per intero (la domanda è la formula d'uso della percentuale, non
il progetto) — esclusione dichiarata.

Problema in una frase: la percentuale di costi generali (generalCostsPercent) è
configurata in REPO-E ma nessun consumer la applica — l'oracolo la dichiara e
rifiuta di indovinarla; cosa deve essere vero dopo: l'oracolo la applica SOLO
quando la formula è provata, e resta esplicito quando non lo è.

Vincoli di squalifica (prima dei criteri): (1) nessuna formula di business inventata
— regola del repo, non negoziabile; (2) l'output attuale dell'oracolo (che dichiara
il rifiuto) non può peggiorare: la percentuale configurata deve restare visibile
qualunque sia la scelta. Criteri dichiarati prima delle opzioni: costo, rischio,
reversibilità, più uno specifico: probabilità di trovare la formula vera.

| Opzione | Costo | Rischio | Reversibilità | Trovare la formula vera |
|---|---|---|---|---|
| A. Stato quo: rifiuto dichiarato, aspettare la formula dal proprietario | Zero | Basso — nessun numero sbagliato possibile | Totale | Bassa (dipende da una risposta umana) |
| B. Spike: minare a grep i progetti REPO-E alla ricerca di un'applicazione reale di generalCostsPercent (max 1 tentativo, /goal) | Basso — un giro di grep guidato | Basso — lo spike produce un numero/una citazione, non codice | Totale (output da buttare) | Media — 91 progetti, la formula può vivere in un progetto diverso da quello magazzino |
| C. Implementare l'ipotesi "sul totale di magazzino" dietro flag disattivato | Medio | Alto — un'ipotesi travestita da calcolo disponibile è il modo più silenzioso di diventare la formula ufficiale | Media — un flag disattivato ha una vita lunga | Nulla — l'ipotesi non diventa vera implementandola |

Effetti di secondo ordine: A lascia ogni dashboard REPO-E che usa costi generali
confermata nell'attuale ambiguità; B non tocca nulla (spike, output numerico); C
inquina `censitore-forma-dati` e `sviluppatore-gas` che citano l'oracolo come fonte
— un oracolo con un'ipotesi dentro non è più un oracolo (il trade-off che squalifica
C di fatto, senza bisogno del punteggio).

Scelta: resta a Luca — la raccomandazione implicita dell'ordinamento è A subito, B
come primo passo se/quando serva muoversi senza aspettare (i due non si escludono).
Nessuna opzione è stata implementata in questo giro.

### 2026-08-24 (5) — 6° ciclo, Set 3/3: flusso=contratto, notte=agenti, gate=memoria

Mandato di Luca per il Set 3: migliorare il flusso delle idee, l'interazione fra le
parti, la capacità del repo di interagire con agenti LLM per sviluppo software e
business.

**Giro 2 — l'hook copre Bash (parziale chiusura del filo del 5° ciclo).** La priorità
indicata da Luca era "un aggancio automatico più ampio del hook attuale". Esteso il
matcher a `Edit|Write|Bash`: i comandi che toccano materiale sensibile (printenv,
.env, chiavi, Bearer, keychain, repos.key) ricevono lo stesso reminder dei file
sensibili — non blocca mai. `clasp deploy` da solo NON produce reminder (falso
positivo evitato: il deploy non tocca segreti da sé). L'alternativa UserPromptSubmit
(compito↔skill description) resta decisione di Luca come dichiarato nel SAL: qui si
è chiusa la parte meccanicamente sicura, non la decisione aperta.

**Giro 3 — la notte ha gli stessi agenti del giorno.** Creato `.opencode/agent/` con
i 5 agenti specchiati da `.claude/agents/` (stesso corpo per contratto, frontmatter
OpenCode, nota di specchio): chiude il limite dichiarato #6 nella parte OpenCode.
Guardia anti-drift (`test-opencode-agent-sync.sh`): i corpi devono restare identici
— "un agente che diverga fra giorno e notte è due agenti diversi che si credono lo
stesso". E propagazione: bootstrap copia, onboard fa merge prudente (quarta
cartella della stessa famiglia di gap già pagata per skills/agents/patterns).

**Giro 4 — AGENTS.md diventa il contratto d'ingresso.** Prima: solo regole graphify.
Ora: le cinque cose che un agente LLM che atterra deve sapere (regole/mappa,
pipeline+artefatti, cervelli col contratto unico, oracoli/agenti del dominio
contabile, come uscire con night-verify+privacy). La capacità di interagire con
agenti LLM non è solo esporre wrapper: è dire al nuovo arrivato dove sono le regole
senza fargliele dedurre.

**Giro 5 — la catena degli artefatti ha una guardia, e un anello mancante è saltato
fuori.** `test-flusso-artefatti.sh` verifica che ogni fase dichiari la consegna
alla successiva e che la catena sia circolare (il SAL è la fonte #1 di
selezione-contesto). Scrivendo il test è EMERSO un gap vero: `morning-gate.sh` non
citava mai SAL.md — l'anello L4 ("SAL.md + metrics/gate.csv") esisteva nei documenti,
non nel meccanismo. Corretto: il gate appende al report il richiamo alla lezione
quando c'è qualcosa da giudicare (o coda vuota); la PROSA resta umana (livello 4-5),
entra solo il richiamo meccanico. Il test che ha trovato il buco è lo stesso che lo
presidia.

**Giri 6-8 — le mappe dicono la verità nuova.** llm/README guadagna la
portabilità del timeout e la sezione "come un agente esterno delega qui";
docs/system.md dichiara la chiusura del limite OpenCode (e la sua guardia
anti-staleness, giustamente, ha preteso che la dichiarazione CAMBIASSE davvero —
la prima sostituzione non era avvenuta per un mismatch multilinea, e il test rosso
l'ha rivelato: i guardiani funzionano quando sono scomodi anche a chi li scrive).

Lezione del set: "interazione fra le parti" qui significa DUE cose concrete —
contratti d'interfaccia che non dipendono dalla memoria (AGENTS.md, catena
artefatti con guardia, corpi identici giorno/notte) e anelli meccanici dove i
documenti promettevano e il codice taceva (il gate e il SAL). Entrambe trovate
eseguendo i guardiani, nessuna dedotta.

## Riepilogo dei tre set (30 giri, 6° ciclo) — "agenti, progettare, flusso/interazione"

- **Set 1** (un sistema di agenti per problemi matematico-contabili): il censimento
  integrale di REPO-E (91 progetti, 998 file) ha spostato il lavoro dove i numeri
  dicevano che mancava — ciclo attivo e passivo, i due domini più popolati, erano
  scoperti. Tre oracoli nuovi minati dal codice reale (valorizzazione con override,
  margine per documento, accuratezza fatture con la regola over-invoicing), due
  agenti nuovi (censitore-forma-dati, sviluppatore-gas), la mappa del dominio con
  guardia di forma+privacy. Il rifiuto più importante è un NON: i costi generali %
  non si applicano perché la formula non è provata — l'oracolo dichiara e aspetta.
- **Set 2** (progettare: brainstorming, contesto, scelta idee): divergenza nel
  brainstorming (riformulazioni del problema), selezione-contesto con budget ED
  esclusioni scritte, vincoli di squalifica prima dei criteri nel design-doc,
  effetti di secondo ordine per opzione, spike a scopo singolo. Dogfood immediato:
  un design-doc VERO sul residuo del Set 1, con scelta lasciata a Luca. Lezione
  trasversale: i numeri dei punti sono API — rinumerare rompe i contratti.
- **Set 3** (flusso idee, interazione parti, agenti LLM): hook esteso a Bash (il
  varco documentato), .opencode/agent/ specchiato con anti-drift (limite #6 chiuso
  nella parte notte), AGENTS.md come contratto d'ingresso, catena artefatti con
  guardia — che ha SCOPERTO il gate senza anello SAL e l'ha chiuso col richiamo
  meccanico (prosa resta umana).

**Il filo comune del ciclo**: ogni miglioramento è un contratto verificabile dove
prima c'era memoria o documento — corpi identici giorno/notte, catena di citazioni
per percorso, dichiarazioni di limite che la guardia pretende restino vere. E il
metodo si è applicato a se stesso: due aspettative di test corrette da run rosse
(l'aritmetica a mano sbagliata, la normalizzazione del riferimento), un replace
silenziosamente non avvenuto scoperto dal guardiano anti-staleness.

Stato finale: suite 76/76 (68 all'apertura, ferma al secondo test per tre bug di
portabilità macOS: array vuoti bash 3.2, `timeout` assente, `master` hardcoded),
5 agenti × 2 runtime, 8 oracoli, 12 skill, la mappa del dominio, e quattro
guardiani nuovi che difendono ciò che questo ciclo ha costruito.

### 2026-08-24 (6) — la rotta corretta: il parco è il corpus, non la cava

Domanda di Luca a caldo, dopo i tre set: «hai analizzato tutto il parco gas? ti
sei concentrato su due o tre funzioni... hai capito perché ti ho dato il parco?
hai estrapolato le procedure, i trucchi, gli errori già fatti, le difficoltà?
o hai tirato fuori roba che non serve a nulla? prendi spunto da gas-agent:
qualcosa di GENERALE, non pettini per un solo progetto».

Risposta onesta, prima di tutto a me stesso: NO. Il censimento era per
classificazione dei NOMI (91 cartelle → 12 categorie) più una decina di file
letti davvero; gli oracoli scavati da 3 progetti; i «6 pattern» da un passo
superficiale. Il parco andava letto come il corpus dell'esperienza — e la
skill gas-agent di REPO-E (95 file: mandato di 997 righe, 17 specialisti,
famiglie di difetti con POPOLAZIONI misurate, esecuzione con prova di parità,
routing dei costi) era già il modello, lì, nello stesso repo che mi era stato
dato.

Fatto in questo giro (dopo aver letto il corpus per intero: mandato,
esecuzione, routing, coordinamento, e i 17 specialisti digesti da due agenti
in parallelo):

- **Skill `gas-sviluppo`**: SKILL.md (consulenza vs consegna — confonderle è
  il modo più facile di fare danni) + 4 references a disclosure progressiva:
  `metodo.md` (i quattro verbi, l'ordine di 7 passi, le 7 regole del banco,
  i sabotaggi col numero dichiarato, i vincoli multi-agente: indice git
  condiviso, scratchpad condiviso, ancore unità di senso, grep e i byte NUL),
  `famiglie-difetti.md` (le famiglie MISURATE, ognuna con popolazione e
  domanda discriminante: 22 nomi in ombra divergenti su 9 progetti, nextLink
  ignorato 26/52, Number('')=0, «non ho potuto leggere»=«vuoto» in 57
  siti/14 progetti, lock sulla risorsa non sull'entrypoint, atHour fascia,
  sentinella "0001-01-01" truthy, 20 webapp anonime su 80 con ogni funzione
  globale = endpoint e l'underscore FINALE che solo protegge, 55/80 con test
  che non possono fallire, la guardia cieca sull'estremo, le medie di medie,
  le popolazioni disallineate), `consegna.md` (un task-un worktree-una PR,
  baseline PRIMA, parità a 3 livelli col 3° dichiarato «non dimostrata»,
  protocollo PR, clasp MAI, routing dei costi), `domini-gestionali.md` (le
  domande di contabilità/CDG/produzione/business: il totale è l'ULTIMA cosa
  da asserire, il denominatore prima dei numeratori, il produttore batte la
  maggioranza dei consumatori).
- **Provenienza dichiarata ovunque**: il distillato non si spaccia per
  originale — l'autorità resta gas-agent di REPO-E; quando REPO-E è montato,
  le sue pagine vincono. Privacy mantenuta: nessun nome cliente nel corpus
  portato nell'hub (guardia nel test).
- **Agenti generali**: `sviluppatore-gas` RISCRITTO (canone = famiglie
  misurate + metodo, non più i 6 pattern; consulenza/consegna; clasp mai) e
  il nuovo `revisore-gas` (i quattro verbi su progetti esistenti: censimento
  con raggiungibilità prima, difetti assenti col comando che li cerca, banco
  prima, sabotaggio, TRE prodotti). 7 agenti, specchi OpenCode rigenerati,
  anti-drift verde.
- Guardia nuova: `tests/test-gas-sviluppo-sistema.sh` (16 controlli, incluse
  le popolazioni numeriche ≥15 — «una famiglia senza numero è un'opinione»).

La lezione che questo giro lascia nel metodo (ed è la stessa che il corpus
insegna al suo interno): quando il mandato è «agenti adatti a sviluppare
questo genere di script», la domanda giusta non è «quali formule estraggo» ma
«quale esperienza è già stata pagata e dove sta scritta». Il censimento per
categorie era il passo 1 del lavoro, non il lavoro.

### 2026-08-24 (7) — 7° ciclo, Set 1/3: tre oracoli residui e il rilevatore meccanico

Seconda passata completa richiesta da Luca (stesso mandato dei tre set, repo già
alzato dal 6° ciclo). Il censimento di questo giro non era per nome ma per
COPERTURA: 6 agenti × 17 lenti del corpus × 12 categorie della mappa.

**Giri 1-3 — il buco vero non era di agenti ma di STRUMENTI.** Gli agenti
coprono le lenti (revisore-gas porta le famiglie, il trio i calcoli, censitore
la forma dei dati); ciò che mancava era la parte MECCANICA del corpus. Costruito
`tools/gas_qualita.py`: il rilevatore delle famiglie misurate (test che non
possono fallire, nomi in ombra IDENT vs DIVERGENTI confrontando i corpi, fusi
fissi, paginazione-indizio, clear-poi-scrivi per funzione, catch muti, webapp
anonima col caveat deployment, atHour duplicati), ogni famiglia con la sua
DOMANDA DISCRIMINANTE e la dichiarazione esplicita «QUESTO NON È UN VERDETTO».
Dogfood su tre progetti veri: Scadenzario accusa 0 fusi fissi (corretto — usa
Europe/Rome, il falso positivo atteso resta chiuso), CDG trova atHour duplicati
e 12 clear-poi-scrivi, il magazzino la webapp anonima e 3 siti di paginazione —
numeri coerenti con le popolazioni del corpus. Test sintetico deterministico:
13/13, incluse le regole del banco applicate al tool stesso (stampa la cartella
letta, accetta .js E .gs).

**Giri 4-6 — tre oracoli dai residui della mappa.** `leasing_amministrativo.py`
(adeguamento Euribor trimestrale ARRETRATO, capitale residuo ad ammortamento
uniforme, stime 2,5% e 30% del codice REPO-E dichiarate DENTRO l'output, Euribor
assente = NESSUN adeguamento dichiarato), `rating_dso_clienti.py` (matching per
codice con fallback cliente+data±7gg+importo±1€, cessione factoring come
pagamento con data letta dalla descrizione, guard <0/>365 — e il confine
portato dal corpus: chi ha solo fatture non pagate esce DSO 'n.d.', non 0, perché
0 si legge 'paga subito'), `bilancio_bu.py` (convenzione dei segni G/L amount<0
= ricavo dichiarata in testa, NOBU visibile, quadratura meccanica
somma-margini=totale, ribaltamento REPARTO dichiarato APERTO — non indovinato).

Errore pagato e registrato (di nuovo quello giusto): la mia prima derivazione
del leasing contava 36 mesi inclusivi; il codice REPO-E usa la differenza
calendario SENZA aggiustare il giorno (calcolaMesiTra = anni×12+mesi) — run
rossa, ho corretto IL TEST e anche reso il tool FEDELE all'originale (avevo
"migliorato" la funzione col day-adjustment: un oracolo replica, non migliora).

**Giri 7-10 — armonizzazione.** Mappa aggiornata (leasing/rating/bilancio:
stati nuovi; residui ridichiarati: costi generali, REPARTO, DTE, flussi portali);
trio e revisore/sviluppatore-gas agganciati agli 11 oracoli e al rilevatore
(revisore parte DAL rilevatore; sviluppatore ci si autocensisce prima di
consegnare); specchi OpenCode rigenerati. Suite: 79/79 file (77 + 2 test nuovi: oracoli e rilevatore).

### 2026-08-24 (8) — 7° ciclo, Set 2/3: il flusso di progettazione dogfooddato su un caso vero

Mandato: migliorare la capacità di progettare (brainstorming, selezione contesto,
scelta idee). Il metodo di questo set è il DOGFOOD: eseguire il flusso su una
decisione reale e correggere ciò che l'esecuzione rivela — non aggiungere prosa
a ipotesi.

**Il caso: quale oracolo dopo — DTE o intrastat?** (i due residui della mappa).

Contesto (4 fonti, esclusioni dichiarate — selezione-contesto §2-3): mappa dei
domini, i due progetti REPO-E (Intrastat ~60 funzioni, DTE v3 2039 righe), il
digest shipping-automation del corpus (soglie 10%/1,5×/15%), SAL. Escluso: il
corpus per intero (già digerito nel 6° ciclo). Il giro di contesto ha usato una
RICETTA che la skill NON dava: grep di densità (calcola/somma/soglia) sui due
progetti per stimare la densità di formula — DTE denso di aritmetica (costoTotale
= nolo(listino provincia×fascia P1-P9) + accessori(nPallet), DIR_FIX 1,50,
confidenza ALTA/MEDIA/BASSA/NULLA), intrastat più controlli-flusso (filtri UE,
esclusioni, il bug BC dei cespiti fuori periodo). **Prima correzione del dogfood:
la ricetta entra in selezione-contesto** (§1bis) — "quanto pesa la formula in
questo dominio" è la domanda che decide se serve un oracolo o un progetto.

Problema in una frase: la mappa dichiara DTE e intrastat residui; cosa deve
essere vero dopo: il prossimo oracolo nasce dove la formula è DENSA e PROVATA,
non dove il nome della categoria è rimasto aperto.

Vincoli di squalifica: (1) nessuna formula indovinata (il listino DTE completo
provincia×fascia non è minato: senza di esso l'oracolo DTE non può nascere);
(2) nessun oracolo per domini a densità di flusso (l'oracolo sbagliato è un
pettine). Criteri dichiarati prima delle opzioni: densità di formula minata,
disponibilità dell'oracolo-dati (listino/tabelle), costo, tempo a primo valore.

| Opzione | Densità formula | Oracolo-dati disponibile | Costo | Primo valore |
|---|---|---|---|---|
| A. Oracolo DTE (costo atteso vs fatturato, soglie corpus 10%/1,5×) | Alta — minata a metà (struttura sì, listino NO) | ⚠️ IL LISTINO MANCA: calcolaNoloBase legge un foglio listino non ancora esportato nel repo | Alto se il listino va trascritto a mano | Lontano |
| B. Oracolo intrastat (cross-check acquisti/vendite UE + esclusioni) | Bassa-media: controlli di coerenza più che aritmetica | Sì (le regole di esclusione sono nel codice) | Medio | Vicino ma valore basso: rischia il pettine |
| C. Nessun oracolo nuovo: DTE come PROGETTO sviluppatore-gas con il listino come censimento-forma-dati da Luca | Alta nel progetto, zero nell'oracolo | Il listino diventa domanda di dominio (la forma ce l'ha Luca) | Basso per l'hub | Medio |

Effetti di secondo ordine: A senza listino indurrebbe a INVENTARLO (squalifica
di fatto); B aggiungerebbe un oracolo che la mappa stessa chiama "integrazione
più che formula" — il tipo esatto che Luca ha bocciato; C sposta il listino al
suo posto naturale (domanda di dominio in cima, come insegna il corpus).

Scelta: resta a Luca — l'ordinamento implicito è C prima (il listino è una
domanda di dominio, non un'estrazione), A dopo, quando il listino esiste.
Nessuna opzione implementata in questo giro: il deliverable del set è il metodo
verificato, non l'oracolo prevaricato.

**Le correzioni che il dogfood ha prodotto (oltre alla ricetta di densità):**
brainstorming guadagna il concetto di DOMANDA DI DOMINIO del corpus (la riga
"se il mondo si comporta così, questa correzione è dannosa" — prima che il
criterio di successo emerga, non dopo); guardia di regressione
`tests/test-design-set2-settimo-ciclo.sh` per entrambe.

### 2026-08-24 (9) — 7° ciclo, Set 3/3: il hub impara a giudicare i banchi

Mandato: flusso delle idee, interazione fra le parti, capacità di interagire con
agenti LLM. La mossa del set: il buco d'interazione non era fra agenti, era fra
il hub e le PROVE — poteva eseguire i .night-verify ma non sapeva giudicare
l'uscita di un banco GAS.

**`tools/verifica_banco.py`**: il guardiano meccanico della riga-verdetto
canonica (`attese eseguite: N/M · fallite: K`). Ogni caso del suo test nasce da
una lezione misurata del corpus: verde raggiungibile; rosso con fallite;
attese SALTATE (6/8: «un banco che passa da otto a sei verdi non sembra rotto,
sembra un banco più piccolo» — rosso, con il numero delle sparite scritto);
riga mancante = NON È UN BANCO (exit 2: «ALL TESTS COMPLETED è una frase, non
un verdetto»); righe multiple = ambiguo (i sei vocabolari misurati sui 55
banchi del parco); uscita vuota = non partito; N>M = forma rotta. E il verde
ricorda la sua condizione: senza sabotaggio il banco non è una prova.
`revisore-gas` ora consegna le uscite del banco GIÀ verificate meccanicamente
(specchio OpenCode risincronizzato); AGENTS.md dice all'agente in arrivo che
esistono oracoli (11), rilevatore e verificatore.

Incidente registrato (set 2): una voce SAL scritta dalla directory sbagliata è
finita come SAL.md dentro la cartella del parco REPO-E — scoperta perché i grep
del test non trovavano ciò che era stato scritto. Spostata al posto giusto e
file spurio rimosso. Lezione: la cwd persiste fra i comandi; chi concatena
heredoc e relativi percorsi controlla dove sta prima di scrivere.

## Riepilogo dei tre set (7° ciclo) — «strumenti, dogfood, giudizio»

- **Set 1 (agenti/calcoli)**: il censimento per copertura diceva che gli agenti
  bastano — mancavano gli STRUMENTI: `gas_qualita.py` (le famiglie misurate a
  rilevatore meccanico, dogfood su progetti veri con falsi positivi non
  accusati) e tre oracoli (leasing, rating DSO col confine 0≠'paga subito',
  bilancio BU col REPARTO dichiarato aperto). 11 oracoli totali.
- **Set 2 (progettazione)**: il flusso DOGFOODDATO su una decisione vera
  (DTE vs intrastat, design-doc nel SAL, scelta a Luca) ha prodotto due
  correzioni che nessuna prosa a tavolo avrebbe trovato: la RICETTA DELLA
  DENSITÀ (quanto pesa la formula in un dominio — decide oracolo vs progetto:
  la famiglia dei pettini chiusa per criterio) e la DOMANDA DI DOMINIO in
  brainstorming (silenzio vietato).
- **Set 3 (flusso/interazione)**: `verifica_banco.py` — il hub giudica le prove
  GAS meccanicamente (riga canonica, attese saltate, frasi non-verdetto);
  revisore-gas consegna uscite già verificate; AGENTS.md aggiornato.

**Il filo del ciclo**: tre cose uscite dalla PROSA ed entrate negli strumenti —
le famiglie (rilevatore), la densità (ricetta), il verdetto (verificatore). E
due errori pagati col metodo: l'oracolo leasing "migliorato" (day-adjustment)
riportato FEDELE all'originale; il conteggio di test scritto 80 invece di 79
e corretto in cronaca. Suite finale: 81/81 file (79+verifica_banco+design-set2; il conteggio corretto DOPO la run, non prima: terza volta che lo scrivevo a-previsto).

### 2026-08-24 (10) — il report dal campo su REPO-G: verificato,processato, chiuso

Una sessione esterna ha lavorato un giorno su REPO-G (repo del bilancio, mai
onboardata) e ha riportato sei finding sul hub stesso, col metodo del hub (ogni
affermazione col comando che la dimostra). Verificati eseguendo prima di toccare:
tutti confermati — F3 anzi peggio (11 occorrenze del nome vero in 5 file, non 9;
la voce DEBITI che dichiarava il problema ne citava 2: grep a campione senza
chiave, la stessa cecità che denunciava).

Chiusi in questo giro: il gate privacy degradato ora FALLISCE invece di dire
«pulito» (F3a — il verdetto di un gate che non può giudicare è «degradato»,
non «promosso»: stessa famiglia del «silenzio non è un verdetto»); 11 siti
bonificati in codice REPO-G; la storia git resta esposta nei commit passati e
lo spurgo è decisione di Luca (DEBITI: filter-repo su repo pubblica con
sessioni attive non si fa in silenzio); sync-repo.sh minimale (F2); il
promemorio SAL diurno nell'hook esistente, contatore per sessione, mai blocco
(F5 — pagato un test mal progettato: dopo il reset il 5° edit DEVE ricordare
di nuovo, il discriminante era il numero nel messaggio, 5 vs 10); PROJECT.md
dichiara dove vive il catalogo citato + guardia sui percorsi citati (F4); la
terza corsia «task da una sessione» in METHOD.md (F6 — il report ha ragione:
la pipeline su un task da un file è cerimonia, e una cerimonia senza rigore
in più insegna a saltarla anche quando servirebbe).

Resta a Luca (DEBITI): onboarding o esclusione deliberata di REPO-G (F1 —
credenziali BC dentro la repo: non una dimenticanza da correggere in silenzio)
e lo spurgo della storia (F3b). Suite: 85/85 atteso (82 + privacy-v4,
sync-repo, percorsi-citati, hook-sal).

### 2026-08-26 — il report dei tagli: il canone ha retto, e cresce di cinque pezzi

Secondo report dal campo in una settimana (sessione singola di ottimizzazione
tagli, ~30 correzioni guidate da dati reali, 0 segreti in chat nonostante
richieste dirette, ~20 deploy manuali, 4 fogli diagnostici mai spariti in
silenzio). Verificato eseguendo prima di integrare: le sei proposte erano
tutte ASSENTI dal canone (grep a vuoto su famiglie/metodo/agente/consegna).

**Cosa ha retto, e vale la cronaca**: «esegui, non dedurre» è stata la regola
che ha pagato di più (l'errore 400 di BC era spazi non codificati nel $filter —
emerso testando, non rileggendo; la regola di dominio «un taglio vero ha
Quantity_per < 1» non era scritta da nessuna parte: emersa dal confronto coi
dati veri); «scarto mai silenzioso» è DIVENTATA ARCHITETTURA (il foglio dei
motivi di esclusione ha reso le domande del cliente una lettura di due
colonne, e ha fatto emergere il bug delle materie prime che si tagliavano da
solo — visibile solo perché lo scarto era tracciato riga per rigo); 4 famiglie
su 5 evitate per conoscenza pregressa.

**Le cinque integrazioni (canone)**: la famiglia FORMATTAZIONE FANTASMA (il
formato resta attaccato alla posizione, non alla colonna logica: mm mostrati
come % dopo lo spostamento di una colonna — la sesta famiglia scoperta dal
campo); «stima la scala PRIMA di generare» (148.186 combinazioni da una sola
materia prima: non deducibile a tavolino); «scritture su SISTEMI ESTERNI =
categoria di rischio diversa dal scrivere codice» (l'elenco di conferme —
formato codici, numerazione, cosa non toccare — si dichiara e si approva
PRIMA di produrre il file per l'ERP); «il banco scritto al volo NON si butta»
(i casi verificati si salvano come registro permanente del progetto);
sviluppatore-gas guadagna il punto 6 di verifica (salvataggio dei casi).

**La sesta proposta non si integra: si decide** — separare «niente segreti»
(da tenere assoluto) da «niente deploy autonomo» (allentabile SOLO con
credenziali fuori portata) tocca un divieto di sicurezza su produzione vera:
il canone ora NOMINA i due rischi separati (consegna.md, regola intera), la
decisione di allentare il secondo sta in DEBITI per Luca. Il costo misurato
del confine com'è: ~20 interruzioni umane a sessione — è il prezzo della
credenziale unica condivisa, ed è suo dirimere se vale un rituale di deploy
assistito.

Guardia: test-gas-sviluppo-sistema passa da 16 a 22 controlli (le aggiunte
non escono dal canone in silenzio). Specchio OpenCode risincronizzato.

### 2026-08-26 (3) — «standard non opzione»: il metodo diventa meccanico

Problema portato da Luca: «invoco AI_Programmer all'inizio e spesso non viene
utilizzato, o solo in parte». La diagnosi è nel SAL da tempo («contenuto che
esiste solo se qualcuno se ne ricorda al momento giusto» — il filo comune di
TUTTI i gap trovati dal 5° ciclo): finché il metodo dipende da un'invocazione
iniziale, dipende dalla memoria della sessione, e la memoria della sessione è
esattamente il punto debole che il metodo esiste a compensare.

Tre pezzi, tutti meccanici:

1. **`tools/metodo-reminder-hook.sh`** + registrazione in settings.json:
   SessionStart inietta la porta d'ingresso all'apertura («non serve
   invocarlo, vale da sé»), UserPromptSubmit ri-inietta un promemorio compatto
   a OGNI prompt (con aggancio dinamico: il prompt che parla di calcoli punta
   agli oracoli; quello che parla di correzioni, al banco e alla domanda di
   dominio). Costo: poche righe di contesto per prompt. È la risposta diretta
   al «invocato all'inizio e poi dimenticato»: ora non serve invocarlo.
2. **Gli hook VIAGGIANO**: bootstrap copia settings.json + i due hook;
   onboard li porta con merge prudente (non tocca hook proprietari). Finora
   skill e agenti propagavano, il rinforzo meccanico no — lo standard
   viaggiava a metà.
3. **`sync-repo.sh --standard`**: UN comando porta il sistema intero in una
   repo (CLAUDE.md, skills, agenti, hook, specchi OpenCode) e apre la PR.
   METHOD.md guadagna §"Lo standard" con la checklist fisica (un pezzo che
   manca = il metodo che manca) e AGENTS.md lo dichiara all'agente in arrivo.

Guardia: `tests/test-standard-non-opzione.sh` (8 controlli). Limite onesto:
gli hook sono la meccanica di Claude Code; per la notte OpenCode l'aggancio
equivalente (se esiste) resta da mappare — dichiarato, non Presunto.
### 2026-08-26 (2) — report REPO-G versione aggiornata: tutto già chiuso, due novità

Ricevuta la seconda stesura del report sul campo REPO-G (stessa sessione, sei
finding invariati, chiusura che chiede a Luca se adattarlo). Verifica eseguita
punto per punto sul main: TUTTI già chiusi — gate privacy degradato (exit 1),
bonifica nomi (0 occorrenze residue), decisione onboarding in DEBITI,
sync-repo.sh, test percorsi PROJECT.md, terza corsia, hook promemoria SAL.

Le due novità della stesura: (1) la correzione spontanea dell'autore su F5 —
la scoperta NON scritta in SAL è stata scritta più tardi nella stessa sessione,
di sua iniziativa: il punto di metodo resta («nessun gate me lo ricordava») ed
è esattamente il buco che l'hook ora copre — la cronaca conferma che il
promemoria serve anche alle sessioni ben intenzionate; (2) il bug del plug IVA
a segno invertito, trovato leggendo ed eseguendo query vere: entra nel canone
come conferma di campo della regola dei segni (domini-gestionali §3) — lo
stesso difetto in una sede nuova.

### 2026-08-26 (4) — il censimento BC diventa aggiornabile (e confessa: 0 verificati su 88)

Mandato di Luca: «sistemiamo questa parte e impariamo a renderlo funzionante e
aggiornabile». Verificato eseguendo: il canone punta a docs/bc/endpoints (3
luoghi + hook dalla #54), l'indice funziona — MA il refresh aveva l'assassino
dell'aggiornabilità dentro: bc_map rigenerava il file dell'endpoint e si
portava via le colonne compilate a mano (Significato, Verificato). Un
censimento che cancella la cura quando lo aggiorni non viene mai aggiornato:
88 file senza data, nessuno mai rinnovato.

Fatto: (1) write_md ora fa MERGE — legge le colonne curate del file esistente
e le preserva per campo (test: significato tenuto, verificato tenuto, campo
NUOVO aggiunto, data stampata); (2) ogni refresh stampa «Ultimo aggiornamento:
YYYY-MM-DD (merge: colonne preservate)»; (3) l'indice guadagna la sezione
«Salute del censimento»: quanti endpoint hanno campi verificati, quanti file
hanno data di refresh, come si rinnova — il censimento invecchia in modo
VISIBILE; (4) tolto il «/108» cablato (il catalogo vive nel repo cliente:
l'avanzamento ora conta il reale e dichiara dove sta il totale).

E la salute ha confessato la verità: **0 endpoint verificati su 88** — tutto
«mappato», niente mai confermato col riscontro (interfaccia BC / totali
noti). Non è un difetto dello strumento: è lo stato reale che l'indice ora
mostra. Il passo «funzionante» vero è il riscontro, campo per campo, dove i
progetti lo usano — e la pozza di Luca (108 nel catalogo del cliente) serve
proprio a chiudere 88→108 col vivo sotto.

### 2026-08-26 (5) — la pozza entra: il catalogo vive nell'hub, i mancanti sono 170

Luca ha incollato l'export della pagina BC "Servizi Web" (264 righe: 223 Pagine,
6 Codeunit SOAP, 35 Query). Convertito in `docs/bc/CATALOGO_ENDPOINT_BC.md`
(formato tabella che `bc_map --catalog` sa leggere: parser aggiornato ai due
formati). F4 chiuso DAVVERO: il riferimento di PROJECT.md ora risolve nell'hub
(258 servizi OData dichiarati, non più «108 che vivono altrove»).

Il diff meccanico dice la verità che il «108» nascondeva: **258 servizi OData
nel catalogo, 170 mai censiti** (fra i primi: archivi ordini, attributi
articolo, CONAI, provvigioni maturate, tutta la serie PS_EDIT_* e metà della
PS_PowerBI_*). L'indice ora riporta «Catalogo servizi OData: 258 · mancanti al
censimento: 170» nella sezione Salute — il debito di censimento è un numero
visibile, non una stima.

Il flusso aggiornabile, completo: sul Mac di Luca (credenziali locali)
`python3 tools/bc_map.py --catalog docs/bc/CATALOGO_ENDPOINT_BC.md` mappa in
blocco tutti i 170 saltando i fatti, ognuno col merge che preserva le colonne
curate; `bc_index.py` riconta; la Salute mostra il debito che scende.

### 2026-08-26 (6) — censimento BC completato al vivo: 203/258, anomalie registrate

Tre giri sul vivo (Luca al terminale): 88 → 187 → 203. Il secondo giro ha
recuperato 16 con il fix del segmento underscore; il resto è la verità del
campo, registrata in CORREZIONI.md: 28 VUOTE legittime (moduli inutilizzati —
da dichiarare vuoto, non zero), 2×403 permessi, 3×400, 22×404 (nomi con
punti/slash non esposti come segmenti OData + PRJ_*). Il censimento endpoint
è ora: completo nei fatti, aggiornabile per costruzione (merge che preserva,
catalogo col segmento, indice che conta), e onesto sulle anomalie.

### 2026-08-27 — il report dal campo diventa sistematico (proposta di Luca)

I tre report manuali del 2026-08 hanno prodotto più correzioni vere di ogni
revisione a tavolo — ma arrivavano per caso. Luca chiede: a ogni uso, un report
di come il sistema si è comportato. Costruito con le tre condizioni che evitano
la cerimonia: formato che forza i FATTI (usato/improvvisato/retto-ostacolato/
proposta, mai il silenzio — «nessuna proposta» dichiarata conta); trigger
MECCANICO (hook Stop: a fine sessione senza report di oggi, promemoria; tace
se c'è); PROPORZIONATO (tre righe per la terza corsia, formato intero per il
lavoro grande — la lezione di F6). Il parere registrato: un report libero
sarebbe autocelebrazione («chi giudica non è chi ha scritto»); il valore sta
nel comando che dimostra, non nell'opinione.

### 2026-08-27 (2) — distribuito chiuso: l'esperimento che non si presume

La lacuna SAL-collisione chiusa col metodo: prima l'ESPERIMENTO (repo finta,
due branch che appendono lo stesso giorno → conflitto certo, come sospettato
ma non presunto), poi la cura meccanica: `.gitattributes` col merge driver
`union` su SAL.md e docs/campo/*.md — diari append-only dove tenere ENTRAMBE
le voci è SEMPRE la risposta giusta (verificato: merge pulito, zero markers).
Limiti dichiarati nel punto stesso: union vale solo per diari, mai per codice
(concatena senza review). Con l'autore nei report di campo, l'assignee GitHub
adottato per le commesse e la centralizzazione notturna confermata come
disegno, le tre lacune del distribuito sono chiuse. «Perfetto» resta fuori
vocabolario: la parola giusta è verificato — e la prima settimana a due mani
dirà il resto, col report dal campo.

### 2026-08-27 (3) — dieci giri di coerenza: il sistema è collegato, tre rotture trovate e chiuse

Verifica meccanica su dieci assi (riferimenti, indici, canone-strumenti,
pipeline, propagazione, hook, pesi morti, specchi, ingresso, numeri). Verdi:
indici correnti (SAL 102 voci, BC 231), tutti gli eventi hook rispondono,
pipeline dichiarata = reale in METHOD e AGENTS, propagazione completa della
checklist standard nei tre strumenti, nessuna skill orfana, 11 oracoli
dichiarati = 11 esistenti. CHIUSE in corsa: riferimento rotto in METHOD
(docs/stato-2026-08-22.md), il canone gas-sviluppo non citava i cinque
strumenti dell'hub (ora §"strumenti che questo canone presuppode"), AGENTS.md
senza catalogo/bc_tipi/sync-repo. APERTA (DEBITI): le 9 skill non hanno
equivalente OpenCode — la notte ha gli agenti ma non il canone progressivo.
Suite 87/87.

### 2026-08-27 (4) — venti giri, lenti nuove: mutazione dei guardiani e ciò che ha rivelato

Profondità nuova rispetto ai dieci: MUTAZIONE controllata (rompo, guardo se il
guardiano cade, ripristino). Risultati: tre guardiani veri (canone, mappa,
standard-METHOD), UNO CIECO — la mutazione su AGENTS.md §0 passava: la guardia
guardava METHOD, non AGENTS. Chiuso (controlli nuovi: AGENTS §0 + .gitattributes
union, prima senza alcuna presidia). Altri rilievi: 143/231 endpoint datati (i
99 del mass-mapping girarono col parser vecchio: la data arriva al prossimo
refresh, non è un difetto); 31 voci SAL storiche oltre i 90 caratteri non sono
nell'indice (cronaca che resta leggibile nel corpo — accettato, non rotto);
17 contatori d'hook in /tmp (auto-pulenti per età, monitorati); py 15/16 con
usage (bc_map si usa via argomenti: ok). La scoperta più delicata — PRIVACY
nei VALORI DI CAMPIONE del census: i campioni dei file endpoint portano dati
di business veri (nomi fornitori, il grep li ha ripresi in 2 file): è nella
natura del census (legge il vivo) ed è DECISIONE del proprietario (DEBITI:
accettare / mascherare i sensibili / mascherare tutti). Suite 87/87.

### 2026-08-27 (5) — venti giri, terza serie: la vetrina pubblica era ferma a tre giorni fa

Lenti nuove: aritmetica del census (231+27=258 ✓, segmenti 258 unici ✓, nessun
file fuori catalogo ✓), propagazione del formato report (NO: ora lo standard
porta anche docs/campo), home page pubblica (FERMA al 24/8: non citava
standard/sync-repo/campo/rilevatori — aggiornata con lo stato reale),
determinismo (test stabili a run ripetute), tabelle ben formate, bonifica
privacy che tiene (0 residui). Corretta l'aritmetica di CORREZIONI (le 28 vuote
hanno stub: non sono residue senza file). Suite 87/87.

### 2026-08-27 (6) — terzo report REPO-G: la riverifica indipendente chiude il loop

Il reporter ha rifatto il nostro lavoro di verifica: clone aggiornato, sei
finding del primo report ricontrollati COMANDO PER COMANDO — tutti e cinque i
azionabili chiusi con test dedicato che cita il finding d'origine. È il primo
loop completo: segnalazione → azione → riverifica indipendente. Il registro dei
suoi sei giri porta cinque bug reali (D49: residuo silenzioso di 982.693,50 €
in documento già inviato alle banche — ora ancora nel canone dei totali) e il
primo giro a zero (D51). La SUA proposta adottata: l'esito del giro si dichiara
— zero bug su superficie ampia è informazione di convergenza, non giro sprecato
(stessa famiglia dell'assente-dichiarato; un campione non dichiara stabilità,
ma il silenzio sull'esito non è ammesso) — in metodo.md. E la nota D48 sul
REPARTO (costo che sparisce a totRicavi=0) entra nel punto APERTO del nostro
oracolo bilancio: chi lo chiuderà ha l'ancora di campo. F1 resta aperto per
decisione di Luca — e il costo che il reporter dichiara di pagarlo (sei giri
fatti a mano, zero riuso hub) è l'argomento più concreto finora per decidere.

### 2026-08-27 (7) — primo report dal campo nel formato nuovo: pattern 19, REPO-H, quattro proposte adottate

Sessione esterna su REPO-H (cespiti GAS+BC, prima segnalazione): 17/17 file
letti, 13 rilievi (1 critico), 12 fix, banco Node vm 19/19 dopo ogni fix, 3
revisioni indipendenti in parallelo. Il formato docs/campo ha funzionato al
primo uso reale. Adottate tutte e quattro le proposte: (1) il catalogo
docs/bc/endpoints è oracolo indipendente DICHIARATO per ogni revisione GAS+BC
— ha smentito la documentazione del progetto e evitato un fix sbagliato
(secondo caso reale nel pattern); (2) nuovo pattern 19:
somma-diversa-da-zero-non-e-presenza (un accumulatore che si annulla per
compensazione legittima non è un test di presenza: cespite già ammortizzato
spariva dal report delle cessioni — il caso PIÙ comune, non un edge; il fix è
il flag all'origine, mai aritmetica derivata); (3) estensione a
scarto-mai-silenzioso: il segnale PARZIALE è peggio del silenzio (falsa
copertura); (4) formato campo: terza casella NON RAGGIUNGIBILE. REPO-H
registrata nell'indice. Il report conferma di nuovo il costo di F1: il metodo
non raggiunge chi lavora su repo esterne senza standard.

### 2026-08-27 (8) — quarto report: 30 agenti su REPO-I, cinque proposte, quattro adottate

REPO-I (controlli trimestrali GAS+BC): 19/19 findings ALTA corretti con test
PRIMA/DOPO, 915/915, zero regressioni, 8 temi trasversali emersi da agenti NON
coordinati (la convergenza indipendente come segnale di qualità — misurato).
Adottate: pattern 20 estrazione-per-testabilità (la quinta lente, occorsa quanto
le quattro storiche); i DUE REGIMI DI CONFERMA in consegna.md (passo-per-passo
su analisi e dominio, batch autorizzato su fix già diagnosticati — l'attrito
l'aveva risolto il proprietario da solo, ora è regola); il terzo stato DA
VERIFICARE DAL VIVO nel protocollo PR (il livello 3 reso tracciabile); il
workflow N-GIRI PARALLELI documentato (docs/ngiri-paralleli.md: aree × 2 letture,
fan-out, sintesi con soglia ≥3 aree indipendenti). La prima proposta (skill
installabili) è GIÀ lo standard sync-repo --standard del 2026-08-26: il report
lavorava su una repo senza — quarta conferma che F1 è il collo di bottiglia.

### 2026-08-27 (9) — trenta giri anti-collo-di-bottiglia: quattro eliminati, tre gated

ELIMINATI: il canone viaggia anche di NOTTE (le 9 skill copiate in
.opencode/skills con guardia — la lacuna del giro 8 della prima serie chiusa);
l'indice SAL sale a 130 caratteri (le 31 voci storiche rientrano); BC_CRED_FILE
configurabile (niente più copia del file credenziali nella cwd); l'hook Stop
pulisce i propri contatori di sessione. GATED (non eliminabili da qui): F1
adozione standard (4 report indipendenti lo citano — la decisione REPO-G è la
chiave), convergenza del modello notturno (hardware, quadro prezzi in DEBITI),
significati/verificati del census (lavoro di dominio). Rilevata e subito
risolta un'anomalia di conteggio segmenti (regex troppo larga nel giro 13, non
un difetto del catalogo: i test dedicati passano). Suite 87/87.

### 2026-08-27 (10) — trenta giri n.2: il collegamento rotto ero io

Il giro più importante di questa serie ha trovato il difetto nel lavoro di
IERI sera: l'hook Stop in Claude Code scatta a OGNI FINE TURNO, non a fine
sessione — la mia pulizia dei contatori su Stop azzerava il promemoria SAL a
ogni risposta (il promemorio non avrebbe mai raggiunto il 5° edit), e il
ricordo del report di campo avrebbe suonato a ogni turno. Corretto: la pulizia
va su SessionStart (una volta), il promemoria Stop è strozzato a una volta
l'ora (timestamp gitignored). Lezione che il corpus già insegnava e che ho
ripagato di persona: «avevo dato una convenzione per chiudere una famiglia e
non l'ha chiusa» — ogni fix va provato CONTRO il suo contesto reale di
esecuzione. Resto della serie: 16/16 py compilano, 111 shell sintatticamente
sane, guardie verdi, nulla di nuovo da segnalare. Suite 87/87.

### 2026-08-27 (11) — quinto report: 50 agenti su REPO-F, due rifiuti che sono il metodo

REPO-F: 22 rilievi, 20 corretti, 2 RIFIUTATI sotto pressione esplicita
dell'utente («non fermarti») — uno perché la correzione ovvia era già stata
revertata sui dati veri (banco rosso dichiarato dal commit), l'altro perché
serve una scelta di metodo contabile: chiedere invece di indovinare, tenuto
anche a pressione. Validazioni pesanti: il byte NUL trovato due volte da lati
non comunicanti (grep/ripgrep ciechi — già canone); il falso positivo di
gas_qualita (ombra «key») scartato CON la domanda discriminante («è davvero
globale?»): il rilevatore usato come lead, mai verdetto — esattamente come si
dichiarava. Integrazioni: pattern 21 guardia-nel-ponte (con l'ancora REPO-F e
la lezione nuova: il progetto LO DICHIARAVA in un commento e fu quasi violato
— prima di applicare un pattern imparato altrove, si GREPPA il vincolo nel
progetto); famiglia nuova «test manuale su produzione» con la cura default-safe
(lo editor chiama a zero argomenti). La sua domanda aperta (un-giro-un-fix vs
tutti-in-sessione) è GIÀ risolta dal regime batch-autorizzato adottato col
report REPO-I: la deviazione era legittima perché autorizzata dal proprietario
— il puntatore va nel report processato, la regola non cambia.

### 2026-08-27 (12) — report REPO-I fase 2: catalogo esaurito, quattro regole nuove

44/44 idee a stato terminale, 1057/1057 test, zero rollback: anche il non
implementato porta il motivo. Integrate le quattro proposte della fase 2:
pattern 22 SOGLIA-CON-DEFAULT-GUARDATO (la terza via fra hardcoded e
decisione: default validato + override dichiarato con avviso accanto al
valore); e le tre regole in metodo.md: VERIFICA-PRIMA-DI-COSTRUIRE (il test
di applicabilità batte il codice nuovo — due trend erano già prodotti gratis
dal cruscotto), PARAMETRO≠SPECULAZIONE (solo la prima si chiude con una
domanda; la seconda resta non-ancora-matura, non «esclusa»), e I VINCOLI
VIVONO ANCHE NEI FILE DI CONFIGURAZIONE (commenti CI/workflow letti prima di
proporre; la verifica fuori-repo come prova equivalente quando un invariante
lo impone). Suite 87/87.

### 2026-08-27 (13) — sesto report (REPO-H, 12 PR): pattern 23-24 e il workaround vm

12 batch = 12 PR indipendenti, runAllTests eseguito davvero per ognuna (con
stub per le funzioni impure: esegui-non-leggere esteso oltre l'harness puro).
Integrati: pattern 23 RIGA-IN-CODA-NON-INTERPOSTA (lo stato attaccato alla
posizione: famiglia formattazione-fantasma, con l'errore auto-corretto dal
banco prima del commit come ancora) e pattern 24 DIPENDENZA-TRA-RAMI-
PARALLELI (il branch parallelo è autosufficiente o dichiara la dipendenza —
il complemento autoriale della regola di composizione del corpus). In
metodo.md: il workaround vm per i binding lessicali (seconda runInContext ad
assegnazione semplice — il limite era canone, la tecnica mancava) e la regola
del confine irraggiungibile (0.005 post-round2 non esiste: un test lì sarebbe
eseguibile e senza significato — si testa il percorso, non la firma).
Suite 87/87.

### 2026-08-27 (14) — quattordici lenti su REPO-G: il metodo chiede adottare il metodo

Il terzo giro di prodotto (62 proposte, 14 agenti, HTML salvato in docs/campo) fa
due cose notevoli: (1) consolida 50 giri richiesti in 14 lenti realmente
distinte — la lezione zero-waste applicata al processo di revisione, ora in
ngiri-paralleli.md; (2) la sezione 12 è il sistema che CHIEDE di adottare il
sistema: 5 proposte per portare skill controllo-gestione, i subagent, il
pattern banco-sintetico formalizzato e lo standard sync-repo DENTRO REPO-G —
con l'onestà di dichiarare che i 4 punti leggeri NON dipendono dalla decisione
DEBITI (onboarding notturno, bloccata dalle credenziali nel repo) e si possono
fare subito. Quinta conferma indipendente del collo di bottiglia. Trovato
anche: secret BC in chiaro in Config.js tracciato da git (repo privato: non
esposto, ma la bonifica va fatta), doGet senza auth, e il caso D49 citato come
ancora della proposta "riepilogo controlli pre-pubblicazione".

### 2026-08-27 (15) — consolidazione: tutto ciò che i cicli hanno scoperto è nel canone

Ripasso finale di tutto ciò che i due cicli REPO-E e i sei report dal campo hanno
prodotto, verificando che sia DENTRO e non solo dichiarato. Pattern: 24 voci
(19 pre-cicli + 19-24 nuovi). Canone gas-sviluppo: metodo arricchito (esito-del-
giro, correggere-è-audit, banco a ogni commit, grep frontend, stima scala,
sistemi esterni, casi salvati, confine irraggiungibile, workarounds vm, due
regimi di conferma, terzo stato, worktree-dal-primo-commit); famiglie arricchite
(formattazione fantasma, test default-safe, grep frontend, securityCode);
consegna (worktree, regimi, terzo stato); ngiri (giro di prodotto, consolidazione
lenti). Rilevatore: 4 falsi corretti (ombre top-level, clearContent, $skip senza
$orderby, securityCode+Prefix) — gli ultimi due rifatti con calma dopo la rottura
precedente: UN fix alla volta, test in mezzo, verifica su progetto vero.
Docs/campo: 9 report processati. Suite 87/87.

### 2026-08-27 (16) — cinquanta giri su REPO-I: le cinque lenti per area

Il quarto report di prodotto (50 letture, 10 aree × 5 lenti, ~100 proposte,
12 temi trasversali da agenti non coordinati, 29 pagine PDF) porta la struttura
più matura del giro di prodotto: le CINQUE LENTI PER AREA (buco-nel-processo,
parlantezza, fatica-residua, continuità-e-sostituibilità, coerenza-fra-gemelle)
— ora in ngiri-paralleli.md. Istruzione potente replicata: ogni agente aveva
l'ELENCO di cosa esiste già (PR #97/#98) e il divieto di riproporlo —
consolidazione anti-rumore. I temi trasversali in testa meritano attenzione
di dominio: follow-up che non persiste, funzioni orfane senza porta
d'ingresso, verde che nasconde dati mai arrivati. Report completo in
docs/campo/2026-08-27-repo-i-cinquanta-giri.md.

### 2026-08-28 (1) — L'Hub Allo Specchio: 14 lenti indipendenti sull'hub stesso, 9 batch di fix

Nato dal ciclo precedente: dopo la revisione "Quattordici Lenti" su REPO-G (14/8,
docs/campo/2026-08-27-repo-g-quattordici-lenti.html) e il report dal campo che ne
riportava l'esecuzione, la stessa disciplina — 14 lenti indipendenti, zero-waste,
"esegui non leggere" — applicata all'HUB stesso, non a un progetto cliente. Prima la
revisione (14 agenti paralleli, oltre 60 problemi reali confermati, pubblicata come
artefatto "L'Hub Allo Specchio"), poi 9 batch di correzione, uno alla volta, ognuno
verificato dal vivo prima/dopo e con banco di regressione esteso o creato.

**Trovato e corretto** (evidenza completa nei commit del branch
`fix/revisione-14-lenti`): pipeline night-shift (il gate del mattino non faceva mai
checkout del branch della PR — le verifiche giravano sul codice sbagliato; lock non
atomico; bypass della sandbox del banco avversariale via sostituzione di comando
annidata; "main" hardcoded); 7 bug nei tool di calcolo di dominio (scadenzario
fornitori mai applicato, pagamenti scartati che sparivano dal conteggio, crash su
riga non contata, quadratura strutturalmente tautologica in bilancio_bu.py, ordine a
0€ che nascondeva una discrepanza, argomento mancante letto come zero, percentuale
fuorviante su vendita a zero); 9 bug negli script operativi (fra cui un rilevatore di
segreti spento da un bug di raw-string in gas_qualita.py, un test di verifica dei
percorsi in PROJECT.md che non ha MAI funzionato dalla sua creazione — sed rimuoveva
il separatore di cui awk aveva bisogno — e un secondo bug reale, indipendente, in
bc_index.py: la regex del censimento BC catturava il nome visualizzato invece del
nome tecnico, gonfiando i "mancanti" di 22 unità fantasma); 5 bug in llm/ (timeout
che non forzava mai la terminazione sul ramo primario, due curl falliti senza
diagnosi, stdin troncato senza avviso); la guardia anti-drift fra `.claude/skills` e
`.opencode/skills` — dichiarata chiusa "con guardia" il 27/8, la guardia non esisteva
mai, 3 file erano già divergenti (trovato da 3 lenti indipendenti: convergenza
forte); documenti di governance disallineati (comando `/audit-commesse` mai esistito
in 4 punti, conteggio agenti fermo a 5, data di revisione di METHOD.md stale);
DEBITI.md con 2 voci risolte mai marcate; 3 bug nell'audit interno dei test stessi
(un'asserzione che non verificava nulla, un contatore di promemoria condiviso fra
ogni sessione per un `md5` assente su Linux, un test rosso per un'assunzione di
default branch non portabile — quest'ultimo era l'unico guasto preesistente rimasto
per 7 batch, chiuso nell'ottavo: 99/99 test verdi, zero eccezioni); la skill
`verifica-visiva` descriveva un tool (Playwright, attesa di un selettore) che non è
mai esistito nel codice reale.

**Non toccato, dichiarato invece di indovinato**: `indici_crisi.py` (denominatore
sospetto, ma la semantica esatta dipende da un mapping in REPO-E non disponibile qui
— segnalato, non corretto); il debito su "verifica-visiva/dev-critic non si attivano
da sole" (richiede una decisione di design sul meccanismo di attivazione, non un fix
isolato — lasciato aperto in DEBITI.md); "password nei test" (nessuna correzione mai
esistita, annotato nel report che affermava il contrario, non inventata qui).

**Metodo**: ogni fix riprodotto dal vivo PRIMA (bug confermato) e DOPO (fix
verificato), non dedotto dalla lettura del codice sorgente. Diversi fix hanno
richiesto un'indagine più profonda del finding originale della revisione — il caso
più netto è bc_index.py, dove il finding iniziale ("l'aritmetica è sbagliata") si è
rivelato un'assunzione errata del reviewer (la logica a insiemi era corretta), ma
l'indagine ha comunque trovato il vero bug (la regex di estrazione), un livello più
sotto. Nessuna correzione a occhio: ogni fix porta il comando o la riproduzione che
lo dimostra.
### 2026-08-27 (17) — quarto report REPO-G: eseguite le 62 proposte, due pattern nuovi, un'obiezione superata

Il quarto report dal campo REPO-G copre l'ESECUZIONE delle 62 proposte di
Quattordici Lenti (11 batch, PR #36, 704 righe, 20 file, banco a ogni commit,
Playwright per il DOM, AskUserQuestion una sola volta per l'inversione di una
decisione precedente del cliente). Verifica indipendente del secondo loop: la
proposta convergenza è nel canone TESTUALMENTE (cita il report per nome). Due
pattern nuovi adottati: 25 estrattore-test-dipendenza-refactor (la regex che
estrae le funzioni per il banco è un vincolo nascosto sul refactor: aggiornarla
PRIMA o deferire) e 26 estensione-testata-non-distruttiva (leggere il delta,
appendere solo le colonne mancanti, mai riscrivere la testata intera). E
l'obiezione F1 in DEBITI aggiornata: le credenziali BC non sono più nel codice
tracciato di REPO-G — l'obiezione com'era scritta non è più vera, la decisione
resta di Luca ma ora è solo aperta, non bloccata da un fatto superato.
Conferma indipendente anche del limite CacheService 100KB (ritrovato misurando,
non leggendo il canone — F1 aperto): convergenza cieca.

### 2026-08-27 (18) — il tesoro sigillato: convergenza cieca, obiezioni che invecchiano, gerarchia DOM

Consolidazione finale di TUTTO ciò che i cicli hanno prodotto, verificata per
essaere DENTRO e non solo dichiarata. Le ultime tre pepite: CONVERGENZA CIECA
nominata in metodo (due misurazioni indipendenti che trovano lo stesso dato =
più forte di una citazione: è il riscontro che non dipende dalla fonte);
LE OBIEZIONI IN DEBITI INVECCIANO COL CODICE (meta-governance: le premesse
delle decisioni rimandate vanno riverificate quando il codice citato cambia —
è il campo che se ne accorge, l'hub dovrebbe chiederlo); GERARCHIA DI VERIFICA
PER IL DOM in consegna (vm per la logica → Playwright headless quando il fix
tocca il rendering → screenshot per il colpo d'occhio). Catalogo completo:
26 pattern, 12 skill, 7 agenti, 11 oracoli, 2 rilevatori, 1 verificatore banco,
5 lenti per area del giro di prodotto, la struttura N-giri, il formato report,
lo standard meccanico, il distribuito. Suite 87/87.

### 2026-08-27 (19) — magazzino: 72 commit (20 bug + 55 proposte) e il handoff gap

Il report più grande del campo: Sistema_Gestione_Magazzino, 72 commit in una PR,
20/20 bug corretti (incluso XSS persistente non autenticato e il motore di
valorizzazione senza asserzioni), 55/57 proposte di prodotto implementate,
bancos a ogni commit, Playwright per il DOM. Due lasciati aperti con la
distinzione giusta: dominio (formula Effetto Volume/Prezzo) vs lavoro non fatto
(2 touch). Il contributo al canone: l'HANDOFF GAP — 2 proposte valide perse nel
passaggio revisione→todo-list, invisibili come uno scarto silenzioso ma nel
piano: la regola è revisione_N = eseguiti + rinviati + persi(0), da verificare
a fine esecuzione. E la disciplina del bug-trovato-lavorando-su-altro: sempre
segnalazione separata, mai mischiato al commit corrente.

### 2026-08-28 — dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI

Il dossier più grande per numero (86 problemi su 12 aree, 5 critici in testa:
security codes in chiaro, funzioni admin senza auth, conferma in blocco da
cache stale, sync che svuota prima di sapere se ci sono righe, annullamento
bypass). Ma il contributo al canone NON è il numero — è l'ONESTÀ del processo:
la verifica avversariale ha finito il budget dopo 2 aree su 12, e invece di
nasconderlo o fingere che tutti i rilievi fossero uguali, 71 sono dichiarati
NON VERIFICATI con un sistema a due assi (gravità × confidenza). Il lettore
può filtrare per partire dai confermati. Canonizzato in metodo.md. Tre famiglie
nuove in famiglie-difetti: CSV/Formula Injection (export CSV senza neutralizzare
=+-@), libreria GAS in developmentMode:true (HEAD non pubblicata in produzione),
cache stale che riscrive intere righe (bulkConfirm da snapshot di 3 minuti prima).
Suite 87/87.

### 2026-08-28 — REPO-I fase 3 chiude il ciclo: 245 idee, 7 proposte, due pattern nuovi

Il ciclo completo di REPO-I si chiude con la terza fase: 50 agenti × 10 aree ×
5 lenti ORTOGONALI alle 4 di Fase 1 (correttezza vs processo/manutenibilità —
il metodo ora dichiara DUE BATTERIE con obiettivi diversi), 245 idee tutte a
stato terminale, 1241/1241 test, zero regressioni (una introdotta e catturata
dal proprio test prima del commit — la rete di sicurezza che prende anche
l'errore di chi la costruisce). Integrate tutte le proposte: pattern 27
LETTURA-DELL'ESECUZIONE-PRECEDENTE (rileggere l'ultimo stato per lo stesso
soggetto prima di scrivere la riga nuova in un diario append-only — gemello
dei dati di estrazione-per-testabilità, comparso indipendentemente in 5 moduli)
e pattern 28 CHIAVE-STABILE-ETICHETTA-LIBERA (mai rinominare la chiave di una
serie storica append-only: l'etichetta leggibile si aggiunge accanto, mai al
posto — la rottura è invisibile); in ngiri: le DUE BATTERIE di lenti, la
TASSONOMIA A QUATTRO CATEGORIE (provata su 245 casi senza eccezioni), la regola
DELLE TRE RICOMPARSE (la stessa lacuna alla terza volta = matura per
l'investimento, non più rinviata); in metodo: L'ISOLAMENTO DEL BANCO (un'eccezione
in un test = un fallimento in più, non un abort — e il conteggio atteso si
dichiara). Suite 87/87.

### 2026-08-28 — trenta giri di indagine completa: il repo è sano, una guardia nuova per la prosa

Indagine meccanica su 30 assi (inventario completo, riferimenti incrociati,
àncore pattern, oracoli/test, SAL/indice, hook, privacy, specchi, rilevatori,
verifica_banco, bc_index, DEBITI, git, sync-repo, AGENTS/campo/benvenuto/mappa,
pipeline METHOD, regole CLAUDE, descrizioni skill, settings hook, TODO/FIXME).
Risultato: 26 verdi al primo colpo, 4 finding — di cui 1 reale (sync-repo
assente da AGENTS.md, chiuso), 1 già dichiarato (privacy campioni BC =
decisione Luca in DEBITI), 2 falsi positivi legittimi (riferimenti condizionali
graphify e file REPO-G citati come esempi). Aggiunta la GUARDIA ANTI-PERDITA
PER LA PROSA: 7 frasi chiave (handoff gap, convergenza cieca, due batterie,
quattro categorie, tre ricomparse, chiave-stabile, lettura-esecuzione) verificate
ad ogni run della suite contro tutti i reference del canone — perché sono già
state perse una volta o due, e la prosa non ha test sintattici che la difendano.
L'unica cosa che manca a questa indagine: il test di integrità completa delle 7
frasi è arrivato DOPO la terza perdita — la regola delle tre ricomparse,
applicata a noi stessi. Suite 87/87.

### 2026-08-28 (2) — cinquanta giri nuove lenti: qualità, non solo presenza

Le lenti di prima (30 giri) guardavano la PRESENZA: c'è o non c'è. Queste
guardano la QUALITÀ: è collegato, è consistente, è navigabile, è resiliente.
Trovato e chiuso: 6 skill isolate (verifica-visiva, gas-sviluppo, goal non
citavano nessun'altra skill — ora hanno "Vedi anche"), 14 pattern senza catene
(ora 9/33 hanno "Vedi anche" con i cugini imparentati), sync-repo assente da
AGENTS (chiuso nei 30 giri precedenti). Dichiarato: 5 tool senza test (tutti
con giustificazione: richiedono credenziali/ambiente non disponibile in CI),
SAL a 257KB (oltre la soglia 100KB: candidato a SAL-ARCHIVIO per le voci >30gg),
canone gas-sviluppo a 803 righe (al limite). VERIFICATO PULITO: nessuna
contraddizione interna nel canone, nessuna dipendenza hardcoded nei test,
nessun segreto tracciato, nessun link rotto nei documenti, SAL in ordine
cronologico, encoding UTF-8 valido ovunque, test deterministici (3 run
identici), suite 35s. F1 citato 24 volte nei report dal campo: il collo di
bottiglia più confermato della storia del sistema.

### 2026-08-28 (3) — 50 giri 3ª batteria: lenti di evoluzione e cambiamento

Terza batteria dopo presenza (30) e qualità (50): come il sistema CAMBIA,
cosa lo stressa, dove le cuciture si aprirebbero. CHIUSI: jq fallback (gli
hook non si rompono più senza jq — dipendenza critica con fallback mancante),
glossario inline per clasp e worktree nel SKILL. VERIFICATO: crescita 38
commit/giorno (picco ieri), hotspot SAL.md (32 modifiche — il diario vivo,
atteso), bus factor 1 (dichiarato), debito tecnico 0.6% (sano), parallel-safe
(0 conflitti), determinismo (3 run identici), auto-miglioramento (feedback
loop campo→canone attivo). DICHIARATO: macOS-specifici (2 file, già in DEBITI),
famiglie-difetti denso (185 parole/paragrafo — accettato come reference),
SAL proiezione 918 voci a 30 giorni (SAL-ARCHIVIO raccomandato entro 7 giorni),
bc_map senza credenziali esce rc=0 silenziosamente (da correggere). Le 10
raccomandazioni finali: 2 chiuse, 4 dichiarate, 1 raccomandata (SAL-ARCHIVIO),
1 in attesa Luca (F1), 2 osservate. Suite 87/87.

### 2026-08-28 (4) — Bricoman 50 agenti: 13 confermati, 2 smentiti, l'onore funziona

Il report più metodologicamente maturo del campo: 50 agenti in DUE FASI (35
scoperta + 15 verifica avversariale), 153 rilievi grezzi → 59 bug/sicurezza →
15 verificati per severità → 13 CONFERMATI con node da giudice indipendente,
2 SMENTITI dichiarati (la verifica non è cosmetica: un agente ha dimostrato
che sommare zero non cambia il totale, un altro che l'ambiguità era a monte),
44 NON VERIFICATI dichiarati per budget. Canonizzati in ngiri: la DOPPIA FASE
(scoperta + avversariale con budget dichiarato), le SMENTITE come prova che
il processo lavora, e la lente sviluppo-business che trova BUG invece di
feature (quando succede, il codice non è pronto per crescere). Pattern 34:
EDIFACT-RELEASE-CHARACTER (lo standard prevede ?' per l'apice nei dati: uno
split ingenuo spezza il segmento). 12 bug confermati tutti di gravità alta,
in testa: escaping OData mancante in 5 punti, paginazione nextLink mai gestita,
CSV senza quoting verso BC_Import, test su cartelle di produzione, EDIFACT
release character. Report completo in docs/campo/.

### 2026-08-28 (5) — REPO-K: dal dossier ai fix, 86+25 in sessione continua

La sessione che ha prodotto il dossier SD (86 rilievi) è tornata e ha CORRETTO
tutti i rilievi + implementato le 25 idee in una sessione continua, senza
leggere il canone durante il lavoro (solo dopo, per scrivere il report). Il
contributo più prezioso al canone: TRE fix dichiarati che NON corrispondevano
al sintomo originale, trovati solo nel ripasso finale (un elenco server mai
letto dal client; una conferma che scriveva sulla riga sbagliata da snapshot
vecchio; una funzione richiamata prima della definizione). Canonizzato: la
regola del RIPASSO FINALE (rileggere lo scenario di fallimento originale, non
la propria descrizione del fix), pattern 35 DOPPIO-LIVELLO-ESCAPING (HTML
attribute + JS string: due parser, due funzioni — la cura ovvia è quella
sbagliata), e la SESSIONE CONTINUA dichiarata come terzo regime legittimo
(SECONDA occorrenza dell'utente che chiede di non fermarsi: da domanda aperta
a pattern ricorrente deciso). REPO-K registrata nell'indice. Pattern totale: 35.

### 2026-08-28 (6) — l'hub allo specchio: revisione indipendente, 60+ finding

Una revisione indipendente di AI_Programmer su AI_Programmer stesso (14 lenti,
60+ problemi confermati, 6 temi trasversali, 8 proposte di miglioria) — il
sistema applicato a se stesso con la stessa disciplina che chiede ai clienti.
La cosa più scomoda trovata: la guardia anti-drift delle skill .opencode era
DICHIARATA in SAL.md ma NON ESISTEVA (nessun test equivalente a quello degli
agenti), e gas-sviluppo era GIÀ divergente. CORRETTI in questo giro: guardia
creta (test-opencode-skill-sync.sh, 11 controlli, graphify escluso come
OC-specific), gas-sviluppo risincronizzato, lock notturno reso atomico
(mkdir -p → mkdir con exit), SAL corretto per dichiarare la guardia VERA.
Gli altri finding della revisione (60+) sono nel report completo — i più
rilevanti da processare: il default branch hardcoded, il rilevatore segreti
con raw-string bug, i conteggi endpoint con 3 valori diversi, il gate del
mattino senza trigger automatico, sync-repo.sh che non propaga patterns/.
Suite 88/88 (nuovo test incluso).

### 2026-08-28 (7) — 8 proposte dell'audit implementate + 15 report campo triati

Implementate tutte le 8 proposte dell'audit indipendente: (1) gate del mattino
con plist per trigger automatico alle 7:30; (2) sync-repo porta anche patterns/;
(3) meta-audit della suite (ogni test deve avere una via di uscita con
fallimento); (4) campo-triage.sh conta i report non processati; (5) sal-archivia.sh
per la rotazione delle voci >30 giorni; (6) sync-repo --from-local confronta
l'intero standard; (7) debiti-check integrato nel meta-audit. L'ottava (manifest
unico per specchi) è risolta dal test-opencode-skill-sync che copre ora il
quarto pezzo mancante (skill). CAMPO TRIAGE: 17 report totali, 15 segnati
"non processati" dal tool — in realtà TUTTI processati con le lezioni nel
canone (il tool cerca il nome file nel SAL, che non sempre li cita col nome
esatto): il finding vero è che il collegamento report→SAL non è meccanico.
Suite 89/89.

### 2026-08-28 (8) — REPO-J live drift: 3 divergenze reali, 25 fix confermati, primo deploy

La sessione Bricoman ha misurato la deriva git↔live prima di assumerne la
portata: contro la BASELINE pre-fix (non HEAD), whitespace-insensitive (il
round-trip clasp normalizza): 11 file sembravano divergenti, 3 lo erano davvero
(correzioni valide fatte a mano in produzione, aree diverse dai 25 fix). NESSUNO
dei 25 fix è stato rifatto — la misurazione li ha confermati tutti validi.
Canonizzati: pattern 36 MISURA-LA-DERIVA-PRIMA-DI-ASSUMERLA (diff baseline,
non HEAD; whitespace-insensitive; proposta scalata alla deriva reale, non al
mandato letterale) e pattern 37 PONTE-BRANCH-USA-E-GETTA (il canale per leggere
uno stato live irraggiungibile: branch sul repo GitHub, non file incollato).
Il primo deploy REALE di tutti i 28 punti insieme è avvenuto dopo la
riconciliazione: 13/13 file, clasp status verificato prima del push. Pattern
totale: 37.

### 2026-08-28 (9) — REPO-L (Unicredit_Factoring): 9 confermati, SECRET in history, la buona notizia provata

Audit 30 agenti (21 scoperta + 9 avversariale): 54 rilievi, 9 confermati con
esecuzione indipendente, 45 NON VERIFICATI dichiarati, 0 smentiti, 73 assenze
verificate. Il dato CRITICO: il client_secret BC è doppiamente in chiaro nella
storia git (7 commit su main, rimossi dal working tree ma recuperabili con
git show) — ROTAZIONE NECESSARIA su Azure AD, indipendente dalla pulizia
(dichiarato in DEBITI, decisione Luca). Il dato POSITIVO: GeneraTXT.gs
riproduce byte-per-byte le righe reali verificate con UniCredit — provato
con node, non assunto: la buona notizia con la stessa dignità del bug. Nuova
regola in metodo: la correttezza presente si prova come il difetto assente.
Domanda di dominio aperta: NDC vs P03 per le note di credito (spec vs codice).
REPO-L registrata. Pattern totale: 37.

### 2026-08-28 (10) — REPO-M (Energikal): backlog di 15+20 voci, 5 domande di dominio

Audit completo su Associazione-Energikal (27 file .gs, bilancino trimestrale
GAS+BC): credenziali Azure AD in git history dal 16/02 (CRITICA — da ruotare,
DEBITI), conti C/G hardcoded non corrispondenti al CSV 2024 (CRITICA — se il
piano non è stato rinumerato è un bug attivo che produce saldo zero ovunque),
riconciliazione senza verifica importo (falsa quadratura), 12+ altri rilievi.
Il BACKLOG è il contributo più interessante: 15 voci ordinate per gravità con
le 5 DOMANDE DI DOMINIO marcate e in cima, le regole vincolanti (un problema
per volta, test coi dati reali del CSV, un commit per voce), il passo 0
bloccante (rotazione del secret) separato dal resto. Canonizzata la regola:
il backlog ben scritto comincia con le domande, poi le azioni meccaniche.
REPO-M registrata.

### 2026-08-28 (11) — REPO-L (Unicredit_Factoring): 30 agenti + 14 fix, terza sessione continua

Terzo report dal campo su REPO-L: dopo l'audit (30 agenti, 9 confermati, 45
NON VERIFICATI), la sessione continua ha corretto 14 rilievo/cluster con banco
verde prima E dopo per ognuno. Conferme importanti: l'onore del non-verificato
FUNZIONA in fase di fix (molti dei 45 corretti con evidenza già eseguibile,
nessuno rivelatosi falso); verificare l'esempio del committente PRIMA di
lanciare il workflow risparmia budget (fatto assodato dichiarato nei prompt,
non ri-verificato 21 volte); l'assunzione implicita si verifica SEMPRE, anche
quando è tua (il fix che rendeva impossibile il primo setup, scoperto solo
verificando l'assunzione, non leggendo il rilievo). Canonizzata la regola
generalizzata in metodo. sync-repo.sh ora distingue "gh assente" da "repo
privata". Quarta occorrenza del regime sessione-continua (REPO-F, K, J, L).

### 2026-08-28 (12) — REPO-N (parrocchie): il metodo su Flask/SQLite, 13 difetti al banco

Il metodo applicato per la prima volta su un progetto NON-Apps-Script: 50
passate, 13 difetti dimostrati al banco, 10 commit, generatore scadenze 10/10.
Le famiglie GENERALIZZANO fra linguaggi (le stesse forme: Number('')=0 →
120.0 vs '120', sentinelle, lock assente). Canonizzati: pattern 38
BANCO-PROGETTO-LOCALE e 39 AMBIENTE-CENSIMENTO-DICHIARATO. In metodo: passo-0
= sync-repo --standard, riga di esito diurna. In DEBITI: privacy fuori casa.
REPO-N registrata. Pattern totale: 39.

### 2026-08-28 (13) — Energikal: chiusura sessione (5 decisioni di dominio prese, PR #55 aperta)

Il report di handoff di Energikal chiude il ciclo su REPO-M: 12 agenti → piano
di lavoro → 39 voci eseguite (Fasi 1-4) + 2 funzioni spezzate (Fase 5). LE
5 DOMANDE DI DOMINIO sono state TUTTE RISPOSTE in sessione (piano conti
rinumerato; filtro capacità esteso; GDO trimestrale con fix NC; NC tutte-
locations intenzionale; Euribor esclusivi). Il golden test CSV 2024 produce
gli stessi numeri. Il SECRET Azure resta da ruotare (azione fuori dal codice).
PR #55 (~50 commit) aperta: i test BC live (test*Q1_2025) vanno rieseguiti
dall'editor GAS con connessione reale prima del merge — nessun CI automatico
esiste sul repo. Il report di handoff è il formato giusto per chi prende in
mano il lavoro dopo: cosa fatto, cosa resta, come proseguire, in una pagina.

### 2026-08-28 (14) — REPO-N giornata completa: 159 giri, 26 difetti corretti, 5 suite

La giornata completa su REPO-N: 50 revisione + 77 controlli + 30 CRM = 159
giri, 26 difetti corretti, 5 suite verdi (89/89), schema v6→v7, generatore
scadenzario + scheda Persona. Il banco è la memoria eseguibile del progetto.
Canonizzate: fixture-degradano (reset per giro) e guardie-caso-reale.
