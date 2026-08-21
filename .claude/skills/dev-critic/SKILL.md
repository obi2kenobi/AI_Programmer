---
name: dev-critic
description: Trova punti deboli, debito tecnico e nuove funzionalità non considerate in uno script, uno strumento o un intero progetto — nel hub AI_Programmer o in un progetto onboardato (es. CDG_Costi_Diretti) — combinando lettura critica del codice con un tentativo REALE di usarlo (dogfooding), non solo ispezione statica. Fa anche critica costruttiva propositiva: idee di sviluppo non ancora coperte, confrontando lo scope dichiarato (PROJECT.md/SAL.md/README) con quello implementato. Usa quando l'utente chiede di trovare nuove idee o funzionalità mancanti, criticare o revisionare uno script/progetto in modo approfondito, capire cosa manca prima di svilupparlo oltre, o invoca /dev-critic esplicitamente. Non sostituisce code-review (bug nel diff corrente) né simplify (pulizia del codice cambiato): questo guarda l'intero target, comprese le funzionalità che NON esistono ancora.
---

# dev-critic — critico e scopritore di sviluppo

Trova ciò che l'ispezione superficiale non trova: usa lo strumento davvero, non solo leggerlo.
Nasce da una lezione pagata in questa stessa sessione: la sola lettura degli script di
AI_Programmer non aveva mostrato i gap reali — l'onboarding vero di un progetto esistente
(CDG_Costi_Diretti) sì (percorso cloud non documentato, drift di CLAUDE.md, credenziali
committate). Questa skill istituzionalizza quel metodo.

## 0. Target

Chiedi, se non specificato, su cosa lavorare: un percorso/script preciso, un intero repo, o
"il hub + un progetto onboardato" per un confronto tra i due. Senza un target chiaro non
procedere a indovinare (regola del progetto: "se qualcosa è poco chiaro, chiedi").

## 1. Metodo — due fasi, in ordine, mai saltare la seconda

1. **Lettura critica.** Leggi per intero (non solo i punti "notabili") il codice del target E i
   suoi documenti dichiarati (README, PROJECT.md, CLAUDE.md, SAL.md/CHANGELOG). Segna ogni punto
   dove documentazione e codice non coincidono — è quasi sempre lì che si nasconde un gap.
2. **Dogfooding reale.** Quando l'ambiente lo permette, prova a usare davvero lo strumento o la
   funzionalità su un caso concreto — non ipotetico (esegui lo script, fai l'onboarding vero,
   chiama l'endpoint, apri il flusso che descrivi). Solo l'uso reale rivela i gap di processo che
   la lettura statica non mostra. Se non puoi eseguire davvero (permessi, ambiente, dati
   mancanti), dillo esplicitamente — non fingere di averlo fatto.

## 2. Categorie di output (sempre con file:riga, mai generiche)

- **Bug confermati** — comportamento sbagliato verificabile nel codice attuale.
- **Punti deboli/sicurezza** — dove un input o un errore ragionevole rompe qualcosa in modo
  silenzioso o rischioso.
- **Debito tecnico non tracciato** — scorciatoie prese ma non scritte in DEBITI.md o equivalente.
- **Gap di processo** — emersi solo provando a usare lo strumento, non dalla lettura del codice.
- **Nuove funzionalità non considerate** — confronta lo scope DICHIARATO (cosa i documenti
  dicono che il progetto fa o farà) con quello IMPLEMENTATO: cosa è promesso ma assente, cosa un
  caso d'uso reale richiederebbe e oggi non c'è. Proponi, non implementare senza conferma.

Per ogni finding: severità, perché conta, un suggerimento concreto (non vago) e — se è una
scelta di design con impatto (sicurezza, breaking change, costo) — dillo esplicitamente e non
procedere senza il sì del proprietario.

## 3. Regole non negoziabili (eredità da CLAUDE.md del hub)

- Questo è un giro di analisi, non di correzione: non modificare codice durante questa fase. Se
  l'utente chiede anche il fix, trattalo come step separato ed esplicito, dopo aver mostrato i
  findings.
- Ogni proposta ha un trade-off dichiarato — niente "miglioramenti" senza costo o rischio
  indicato ("Only what is asked", "Surface interpretations and tradeoffs").
- Se il target ha una documentazione viva propria (SAL.md, DEBITI.md, CORREZIONI.md), suggerisci
  di scrivere lì le scoperte — non lasciarle solo in chat ("Keep living documentation").
- Le idee di nuove funzionalità si propongono, non si scrivono, finché non è chiesto
  esplicitamente ("Only what is asked").

## 4. Output

Un report strutturato nell'ordine: bug → sicurezza → gap di processo → debito tracciato →
nuove idee. Riferimenti file:riga verificabili in ogni punto. Se l'utente deve passarlo ad altri
(umano o altro LLM), scrivilo come file autosufficiente — leggibile senza il contesto di questa
conversazione — non solo come testo in chat.
