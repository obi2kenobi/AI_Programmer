# METODO-MINI — il metodo di programmazione su Mac mini 64GB
(Primo metallo, deciso il 13/11/2026. Fonte: la maratona 12-13/11 — 13 modelli,
9 prove, 3 repo veri.)

## LA MACCHINA
Mac mini M5 Pro 64GB (~2.500€): 307 GB/s di banda, always-on, ventola,
launchd nativo. Non è il maxi: è il CASTELLO DEL METODO.

## I CERVELLI (regola: uno forte alla volta + il remoto per i grossi)
- LOCALE quotidiano: qwen3-coder-next 80B-A3B in quant lean (IQ4_XS ~42GB,
  16-24k contesto, ~30-45 tok/s) — il collega di coppia. Giorno-1: esame
  col runner prima del fidanzamento (il pieno via API ha vinto la gara;
  la quant va verificata: quality loss possibile)
- LOCALE utility (solo con quant IQ3, da misurare): mistral-small
- REMOTO (OpenRouter): coder-next pieno e glm-5.3-flash per i compiti
  >30k token di contesto e l'1% bestiale — con cancello privacy per il
  codice aziendale
- Ollama locale + OpenClaw: l'agente, con provider remoto già configurato
  (flip a locale = 1 riga di config)

## IL CICLO DIURNO (col metodo dentro OpenClaw — già installato)
apertura:  caccia-miglioria in miniatura → 3 candidati max (il backlog
           nasce dai fatti, non dalle voglie)
durante:   graphify query prima di leggere a caso · diff approvato prima
           di toccare · budget 120s per richiesta (richiesta ibernata =
           si dichiara e si spezza)
chiusura:  caccia-lente sul diff del giorno + digest 3 righe in
           MIGLIORAMENTI.md (fatto/sospeso/lezione)

## LA NOTTE (l'harness, sul mini sempre acceso — la sua casa naturale)
- source profiles/mini.sh → night-shift con il cervello locale lean
- grafo semantico notturno: sul mini gira davvero (sull'Air ibernava)
- censore + guardie + digest del mattino: invariati, il mini li regge 24/7
- rianima_ollama via launchd: già scritto, finalmente su una macchina che
  non chiude il coperchio

## I CANCELLI PERMANENTI (eredità della maratona)
1. L'arbitro non si delega: diff, banco, verifica su disco — sempre
2. La formula non si indovina: si chiede (il metodo ha già corretto
   l'audit umana una volta: va bene, è il sistema che funziona)
3. Ogni cervello nuovo (o quant nuova) sostiene l'esame del runner
   prima di entrare in turno

## GIORNO-1 SUL MINI (mezz'ora)
1. ollama pull della quant lean di coder-next (tag da verificare: ufficiale
   o Unsloth IQ4_XS community)
2. flip del primary OpenClaw: openrouter/... → ollama/...
3. esame: runner-esame.mjs --base http://localhost:11434/v1 --model <tag>
   --tasks "TASK-3-ONESTA.txt,GIORNO-R1.txt,TASK-2-BUG.txt"
4. se 3/3 → collega ufficiale; se no → IQ3 o resta remoto (dichiarato)
5. source profiles/mini.sh && prima notte di prova

## APRILE (se il grande arriverà)
Il metodo NON cambia: cambia il primary e il budget di contesto. Il mini
resta: server dell'harness notturno o scrivania secondaria. Nessun lavoro
perso.
