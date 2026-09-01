# 2026-09-01 — Golilla: due campagne di audit, "decidi tu su tutto", incidente Dashboard e post-mortem

6 agenti revisore-gas paralleli hanno trovato indipendentemente lo stesso pattern sistemico
su ~9 endpoint (webapp che si fida del payload client). Un controllo di copertura post-hoc
ha trovato un file mai assegnato, recuperato con un bug reale. La delega esplicita "decidi
tu su tutto" ha richiesto un criterio di triage non coperto da nessuna skill esistente.

Un fix (nota HTML con apostrofo non escaped in stringa JS) ha rotto l'INTERO script della
Dashboard in produzione — scoperto solo dopo il deploy, non prima del merge. Post-mortem
completo in SAL.md §91 del repo Golilla, guardia verificata (node --check riproduce il
crash sul commit rotto).

## Cosa ho usato
Skill gas-sviluppo (famiglie-difetti come lente, letta via Read diretto). 6 istanze
revisore-gas in parallelo per dominio. Skill post-mortem in forma RIDOTTA (docs/errori/
REGISTRO.md non esiste in Golilla, dichiarato). Nessun oracolo per le formule di
riconciliazione: dove serviva inventare una soglia finanziaria, rifiutato esplicitamente.

## Cosa ho improvvisato
- Partizione manuale in 6 gruppi per dominio per l'audit parallelo.
- "Decidi tu su tutto": triage caso per caso — implementato se difesa-in-profondità e
  reversibile; dichiarato bloccato-sui-dati se serviva un valore reale; RIFIUTATO se
  richiedeva indovinare una formula di business.
- Codice condiviso per azioni sensibili: esteso il pattern CODICE_SBLOCCO già esistente.
- Verifica di copertura post-hoc (diff file assegnati vs file reali): trovato un file mai
  assegnato, NON morto, con un bug reale.

## L'incidente
Apostrofo non escaped in literal JS a apici singoli nell'HTML → SyntaxError che ha
invalidato l'INTERO script inline → Dashboard in produzione ferma subito dopo il deploy.
NESSUNA verifica l'ha preso (l'avversariale leggeva il diff per la LOGICA, non eseguiva
il JavaScript). Scoperto solo perché l'utente ha incollato l'errore di console dopo il
deploy. Fix a un carattere, ma il tempo-a-scoperta è stato "dopo il deploy in produzione".

## Proposte al canone
1. Per OGNI consegna che tocca un .html con script inline: controllo sintattico ESEGUITO
   (node --check sullo script estratto), non solo lettura del diff. Un umano legge il
   SENSO della frase, non conta gli apici.
2. L'agente revisore-gas promette "diff con prova di parità" ma non ha il tool Edit.
3. "Decidi tu su tutto" come pattern non coperto: serve il criterio di triage scritto.
