# 2026-09-30 — riordino-legno-adozione-cloud
**Autore**: sessione cloud claude/funny-hamilton-q6tov6 (per Luca). Lavoro ancora in corso: manca la lettura di `Index.html`, il report si aggiorna alla chiusura.

## Cosa ho usato
`tools/installa-citati.sh --solo-mancanti` e `tools/copia-hook.sh --elenco`, lanciati a mano su un clone locale (funzionano senza `gh`); `tools/gas-gate.sh` sul repo di destinazione (verde); `tools/bc_index.py` e `docs/bc/endpoints/` per confrontare i campi usati con la forma dei dati; quattro sotto-agenti `revisore-gas` in sola lettura, uno per area, con la skill gas-agent (Security Engineer) per la lente sicurezza. Non c'era: un percorso cloud eseguibile di `tools/onboard-repo.sh`.

## Cosa ho improvvisato
L'onboarding in cloud: `onboard-repo.sh` richiede `gh` (`tools/onboard-repo.sh:6-17`), quindi ho ricopiato a mano skill, agenti, pattern, hook, template e settings con lo stesso criterio (solo i mancanti). Ho scritto io la sezione del progetto in `PROJECT.md` (lo stub non basta al first-touch) e ho tolto un riferimento a un debito che non avevo registrato.

## Cosa ha retto / ostacolato
Ha retto: il censimento BC (ha mostrato `Document_Type` = "Quote" nella testata, la sentinella `0001-01-01`, `Unit_of_Measure_Code` sulle fatture, un servizio `Vendor` non censito) e la regola «esegui, non dedurre» (un agente ha provato in `vm` che `getAccessToken` è chiamabile dal browser). Ostacolato: `tools/gas_qualita.py` dà 0 su «segreti hardcoded» e «webapp anonima» in un progetto che ha il segreto in `Code.gs` e accesso ANYONE (falsi negativi segnalati dall'agente); il clone è superficiale, quindi la storia git non si può giudicare. Ostacolo esterno: due risposte della sessione sono state fermate da un controllo automatico senza motivo leggibile; ho dovuto ripartire da un piano più piccolo.

## Proposta al canone
1. Uno script `tools/onboard-cloud.sh` che faccia il percorso cloud (copia dei mancanti su un clone, senza `gh`) invece di lasciarlo all'improvvisazione.
2. Le lenti di `gas_qualita.py` per segreto nel sorgente (`BC_CLIENT_SECRET = '` con valore) e per `access: ANYONE` nel manifest, con un banco che le veda rosse su `riordino-legno`.
