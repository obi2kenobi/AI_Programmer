# 2026-11-01 — riordino-legno: pianificazione, fusione della catena di PR, 35 decisioni
**Autore**: sessione Claude coordinatrice per Luca (repo Riordino-legno, cartelle `acquisti/`, `tests/`, `docs/progetto-acquisti/`). Fusioni fatte in sessione solo su parola di Luca.

## Cosa ho usato
- Agenti `sviluppatore-gas` / `curatore-conoscenza` per le onde (F4, L2, versione 0.105.1, disegno pagina esterna rappresentanti).
- `AskUserQuestion` una domanda alla volta, con alternativa e risposta raccomandata: 35 decisioni raccolte in `docs/progetto-acquisti/RISPOSTE-LUCA-28-10.md`, piano in `PIANO-ONDE-28-10.md`.
- GitHub MCP per stato e fusioni (metodo "merge", `expectedHeadSha` a 40 caratteri); prove di merge locali per misurare i conflitti veri.
- Banchi `tests/banco-acq-*.js` e giudice di mutazioni (`MUT_SOLO=prefisso`) come cancello di ogni PR.
- Non c'era: un modo per far sopravvivere i worktree in `/tmp` ai riavvii del contenitore; un'autorità di fusione per una routine non presidiata (il classificatore l'ha negata, giustamente).

## Cosa ho improvvisato
- Lo stato "clean" di GitHub era vecchio dopo la fusione di #188: la prova locale ha mostrato 7 PR in conflitto. Ho fatto un'unica PR di integrazione (#197, 0.102.0) invece di risolverle una a una.
- Regressione di versione (#203 fusa con 0.104.1 su main a 0.105.0): ho riparato con #204 (0.105.1) e aggiunto un test che fallisce se la versione in Config è sotto la più alta voce di VERSIONI (sabotaggi VRS-1..3).
- Un agente ha costruito L3 (fattore da BC) prima che il piano esistesse: ramo tenuto separato (`claude/listini-l3-fattore-da-bc`), non fuso, in attesa della sonda di Luca.
- Routine di fusione autonoma: negata dal classificatore, impostata senza fusione, poi disabilitata.

## Cosa ha retto / ostacolato
- Ha retto: banco + giudice di mutazioni (il test di versione è nato da un morso reale); domande singole con default raccomandato (35 risposte in una sessione); prova di merge locale contro lo stato GitHub.
- Ostacolato: limite di spesa 429 (mensile, riparte il 2 nov 15:00 UTC) ha fermato tre agenti (R4, Statistiche, D39); nel frattempo Luca e Sara hanno fuso direttamente R4/D43-D44/R5/R7/L6/D47 (main 0.115.0), quindi il lavoro in sospeso era superato. Worktree in `/tmp` e `~/riordino-legno` persi ai riavvii; una catena `cd … && …` fallita ha fatto girare comandi nel repo sbagliato (scoperto da `fatal: path 'acquisti/Config.gs' does not exist`). Notifiche duplicate della routine.

## Proposta al canone
- Una routine o un agente che parte da un piano scritto deve prima confrontarlo con `main`: il lavoro già fatto a mano da altri non si rifà.
- Il test "versione in Config ≥ ultima voce di VERSIONI" va nel banco struttura di ogni progetto GAS con VERSIONI.
- Nessuno stato dei worktree in `/tmp` tra i riavvii: ogni agente riparte da `git fetch` + checkout e lo dichiara.
