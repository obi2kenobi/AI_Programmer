# 2026-10-01 — riordino-legno-analisi-quattro-letture
**Autore**: sessione cloud claude/funny-hamilton-q6tov6 (per Luca). Completa il report del 2026-09-30 (`2026-09-30-riordino-legno-adozione-cloud.md`), che diceva «manca la lettura di Index.html».

## Cosa ho usato
Quattro `revisore-gas` in parallelo, sola lettura, una per area (strato dati BC, logica e uscite di `Code.gs`, `Index.html`, sicurezza e deploy), con le famiglie di `gas-sviluppo/references/famiglie-difetti.md`; prove in locale con `node` (contesto `vm`, finti `UrlFetchApp`/`MailApp`/`SpreadsheetApp`) e Chromium con Playwright su una copia servita in locale; `docs/bc/endpoints/` per confrontare i campi con la forma dei dati. Risultato: 55 rilievi in totale (11 + 15 + 17 + 12 per area, con qualche duplicato tra letture), buona parte provati eseguendo; gli agenti hanno dichiarato ciò che restava ipotesi (comportamento reale di BC, deploy vivo, storia git su clone superficiale).

## Cosa ho improvvisato
Il consolidamento: nessuno strumento fonde i report di più letture in un elenco unico per gravità. L'ho fatto a mano, riscontrando io nel codice i rilievi più pesanti non letti direttamente, e ho scelto la prima domanda di dominio (chi usa la dashboard) perché sblocca la parte più grave.

## Cosa ha retto / ostacolato
Ha retto: dichiarare PRIMA i confini (niente BC, niente deploy vivo, segreti mascherati) e chiedere a ogni agente «VERIFICATO ESEGUENDO o LETTO»; due letture hanno trovato lo stesso difetto (date vuote `0001-01-01`) da angoli diversi, e il censimento BC lo ha confermato sulla testata. Ostacolato: `tools/gas_qualita.py` dà 0 su «segreti hardcoded» e «webapp aperta» in un progetto che ha entrambi (segnalato da tre agenti su quattro); un controllo automatico ha fermato due risposte della sessione senza dire perché.

## Proposta al canone
1. Lente in `gas_qualita.py` per `BC_CLIENT_SECRET = '<valore>'` nel sorgente e per `access: ANYONE` nel manifest, con un banco che le veda rosse su `riordino-legno`.
2. La famiglia sull'underscore finale esiste già (`famiglie-difetti.md:182`); manca il controllo meccanico che la applichi: elencare le funzioni globali senza underscore finale che restituiscono un token o leggono `client_secret`, come primo passo del censimento (qui `getAccessToken()` lo consegnava al browser).
