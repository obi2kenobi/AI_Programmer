# 2026-09-02 — REPO-Q: otto giri d'audit in più (131 rilievi totali) + incidente clasp reale

Continuazione del giro 1 (53 rilievi). Stessa sessione: "ripeti con lenti diverse" → "rifai
tutto con tutte le lenti possibili... altri due giri" — due cicli di tre giri (giri 2-9,
78 rilievi aggiuntivi = 131 totali, 42 lenti diverse). Poi l'incidente reale.

## Il conto dei giri
- 30 lenti distribuite su giri 2-7, poi altre 12 su 8-9 (42 totali oltre alle 6 del giro 1)
- Ogni rilievo verificato personalmente (mai fix committato solo perché un agente l'ha segnalato)
- Fix con node --check + esecuzione reale in Node per ogni fix di logica non banale
- Un commit per rilievo, un doc per giro, PR per ciclo di tre
- 9 giri, ~40 commit, ZERO regressioni rilevate dai giri successivi

## L'incidente
Dopo il giro 9 (PR #310), Luca ha chiesto i comandi per clasp push di TUTTI i progetti.
Ho generato il loop su 7 cartelle MA non ho verificato che 3 di quelle erano dichiarate
"clone di sola lettura" nel CLAUDE.md del repo. Luca ha eseguito: 2 delle 3 proibite sono
state pushate sui loro scriptId REALI — sovrascrivendo il sorgente HEAD di due progetti
sviluppati attivamente altrove la stessa notte. Scoperto solo perché LUCA ha detto "guarda
che non sono di competenza di questo repo".

Questo è ESATTAMENTE la famiglia IE-002 (Knight Capital) e IE-003 (GitLab) — ma dal vivo.
La regola "clasp push MAI da agente" ha retto (non l'ho eseguito io). Ma il rischio dimostrato
è diverso: L'AGENTE GENERA comandi di push che l'UMANO esegue correttamente su cartelle
vietate dal CLAUDE.md dello stesso repo. Riparato: clonati i repo veri, confrontati gli
scriptId, Luca ha ripushato dai cloni corretti.

## Le proposte
1. Prima di generare QUALUNQUE comando clasp push/deploy per una directory: verificare se
   quella directory è un clone dichiarato in CLAUDE.md — se sì, rifiutare di generare il comando.
2. I confini multi-mirror devono vivere in un file meccanicamente verificabile (.mirror-boundaries),
   non solo in prosa nel CLAUDE.md che la sessione legge a inizio e poi dimentica per 9 giri.
3. Conferma che un repo non onboardato non riceve nessun meccanismo strutturale: anche l'hook
   clasp-block nel repo BERSAGLIO non avrebbe fermato questo push (arrivava da un umano su un
   altro repo). La guardia deve vivere lato chi GENERA il comando.
