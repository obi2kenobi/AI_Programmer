# Studio: Superpowers (obra) + GSD Pi (open-gsd) — cosa rubiamo

## SUPERPOWERS (obra) — 15 skill composable, 4.9k stelle

### Cos'e'
Una metodologia completa per agenti di coding: 15 skill che si attivano
AUTOMATICAMENTE (l'agente non le invoca: le riconosce dal contesto) e lo
guidano attraverso: brainstorming → spec → plan → TDD → subagent → verification.

### Le 5 skill oro (per noi)

**1. systematic-debugging** — "The Iron Law: NO FIXES WITHOUT ROOT CAUSE
INVESTIGATION FIRST". Tre fasi obbligatorie prima di toccare codice.
→ RUBIAMO: la nostra caccia potrebbe usare questa disciplina quando un
verifica è rossa: prima la diagnosi (perché è rossa?), poi il fix.
Oggi il turno prova a fixare senza capire (auto-fix).

**2. verification-before-completion** — "Evidence before claims, always.
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE". Se non hai
eseguito il comando di verifica in QUESTO messaggio, non puoi dichiarare
che passa. Skip = "lying, not verifying".
→ RUBIAMO: il nostro E-039 dice la stessa cosa ma come PROSA nel canone.
Qui è una SKILL con un HARD-GATE: "Before taking any implementation action,
including invoking an implementation skill..." — rendiamo il nostro
verify-the-world un hard gate strutturale nel prompt dell'agente, non solo
una regola del canone.

**3. brainstorming** — "MUST use before any creative work". Classifica il
processo necessario, esplora l'intento, scrive la comprensione, chiede
approvazione. L'HARD-GATE blocca l'implementazione fino a design approvato.
→ RUBIAMO: il nostro issue di GitHub ha già la sezione ## Design. Ma non
c'e' un HARD-GATE che blocca la caccia dal lavorare su issue senza design.
Le issue senza Design vengono gia' saltate (SKIPPED_DESIGN) — ma la caccia
che si trova lavoro da sola (categorie morto/docs/semplice) non ha questo
gate. Un "brainstorming-lite" per la caccia: prima di migliorare un file,
l'agente scrive cosa sta per fare e perche' — e se non lo sa, non lo fa.

**4. writing-skills** — come scrivere skill che l'agente usa DAVVERO.
I principi: skill brevi, self-contained, con trigger chiari.
→ RUBIAMO: le nostre lenti (ciclo-vivo, giri-ignoranti, banco-passaggio)
sono "skill" nello spirito ma non hanno la struttura di una skill.
La disciplina di writing-skills potrebbe renderle più consistenti.

**5. using-git-worktrees** — isolamento per feature branch.
→ GIÀ NOSTRO in forma diversa (branch per caccia, PR per issue).

### Cosa NON prendiamo

Il software stesso: e' un plugin per Claude Code/Codex/etc., il nostro
sistema è bash+Ollama. Ma le 15 skill come CANONE per il nostro agente
notturno: il cervello-notturno.md potrebbe incorporare le 3 regole d'oro
(root cause, evidence-before-claims, brainstorming gate).

---

## GSD PI (open-gsd) — agente locale-first con database SQLite

### Cos'e'
Un agente CLI autonomo con: workflow a milestone/slice/task, auto-mode
(stato machine su database), git worktree-aware, tracking costi/token,
routing dinamico dei modelli, e valutazione delle eval.

### I 5 concetti oro (per noi)

**1. Auto-mode come state machine su DATABASE** — "derives the next unit
of work from the authoritative SQLite state, creates a fresh agent session,
injects a focused prompt with all relevant context pre-inlined".
Il turno non decide cosa fare: LO LEGGE dal database. Lo stato è la fonte.
→ RUBIAMO: il nostro turno ha repos.conf + caccia-registro + goals, ma
non c'e' un DATABASE che dice "il prossimo passo è X". Il nostro è più
emergente (la caccia trova), GSD è più pianificato (il DB dice). Un
ibrido: un file di stato per-repo che dice "questa repo è al passo N
della roadmap X" e la caccia onora quel passo.

**2. Dynamic Model Routing** — "downgrade-only: classifica il lavoro in
light/standard/heavy e usa il modello più economico che PUO' farcela".
→ RUBIAMO: oggi usiamo un solo modello (iq3s). Ma le lenti deterministiche
(grep, conteggi) potrebbero essere "light", la caccia "standard", il
censore "heavy". Con un solo modello non serve — ma se un giorno avessimo
un SemIf-like locale per le micro-decisioni, il routing diventa essenziale.

**3. Eval-review come audit post-ship** — "audit a slice's AI evaluation
strategy after it ships. Scores the implemented eval coverage and
infrastructure, identifies gaps with cited evidence."
→ RUBIAMO: dopo che il censore fonde una PR, un eval-review potrebbe
verificare che la PR include la sua prova. Non il codice: la PROVA del
codice. "Questa PR dichiara di aver aggiunto un test: il test esiste?
E fallisce senza il fix?"

**4. Cost tracking per unit** — ogni unit dispatchata traccia token,
costo, durata, tool call. Dashboard con budget ceiling.
→ RUBIAMO: la dashboard ha il funnel ma non il COSTO per deliverable.
Con Ollama locale il costo è GPU-time: "questa PR è costata 45s di GPU
e 3 chiamate al modello". Fattibile: aggiungere un contatore nel turno.

**5. Idempotent milestone completion** — "an exact retry returns the stored
database receipt without appending another completion event."
→ GIÀ NOSTRO in forma diversa: il censore ha il budget-giorno, la caccia
ha il one-attempt-per-site. Ma l'idea del "receipt" per operazioni
idempotenti è potente: ogni azione del turno porta un receipt che
prevede il retry-esattamente-uguale = no-op.

### Cosa NON prendiamo

Il software: è TypeScript/Node, il nostro è bash. Il database SQLite:
il nostro stato in file è più trasparente e già funziona. Il TUI:
abbiamo la dashboard web.

---

## La lista della spesa finale (6 furti)

1. HARD-GATE verify-the-world nel prompt dell'agente (da superpowers)
2. Root-cause-first quando una verifica è rossa (da superpowers)
3. Brainstorming-lite per la caccia: cosa sto per fare e perche' (da superpowers)
4. Roadmap per-repo: il turno onora il passo N della roadmap X (da gsd-pi)
5. Eval-review post-merge: la PR include la sua prova? (da gsd-pi)
6. Cost-per-PR nel funnel della dashboard (da gsd-pi)
