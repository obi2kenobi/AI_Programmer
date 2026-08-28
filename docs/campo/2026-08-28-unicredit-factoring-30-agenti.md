# Revisione approfondita — Unicredit_Factoring (30 agenti: 21 scoperta + 9 verifica avversariale)

Metodo: `revisore-gas` / `gas-sviluppo` di [AI_Programmer](https://github.com/obi2kenobi/AI_Programmer) — censimento, lenti di difetto misurate su Business Central/GAS, esecuzione reale (node) invece di deduzione, verifica avversariale sui rilievi più severi.

Sola analisi: nessun fix è stato applicato automaticamente (eccetto la rimozione di `credenziali BC.rtf`, già fatta separatamente e segnalata a parte). Ogni correzione va decisa e applicata una alla volta.

**Risultato**: 54 rilievi grezzi → 9 confermati con verifica avversariale (esecuzione indipendente, ri-eseguita da zero) → 45 non ancora verificati per budget (dichiarati con l'"onore del non verificato": probabili, da rileggere prima di agire, non promossi a confermati) → 0 smentiti. 60 migliorie progettate, 8 funzionalità nuove proposte, 73 assenze verificate (cose cercate e NON trovate).

---

## 0. Aggiornamento critico sui segreti (scoperto durante questa revisione)

La rimozione di `credenziali BC.rtf` (fatta prima di lanciare le 30 passate) **non basta**: lo stesso client_secret/tenant_id/client_id di Business Central è presente ANCHE in `src/TestConnessioneBC.js`/`.gs`, in **7 commit sul branch `main`** (`9cd0daf`, `04b012b`, `a0e8fda`, `5aa4b6f`, `d470ac7`, `6b4309e`, `84a3313`) prima di essere rimosso in `f65f933` — verificato da me con `git show 9cd0daf:src/TestConnessioneBC.js` (confermo: stesso `client_secret` di BC.rtf, non un secondo segreto diverso).

**Il secret è quindi doppiamente in chiaro nella storia di `main`**, recuperabile da chiunque abbia accesso al repo con un semplice `git show`. Indipendentemente da qualunque pulizia del repo, **va ruotato su Azure AD / Business Central** — questa sessione non ha accesso a quel portale per farlo.
Ripulire la cronologia (rimuovere i blob da tutti i commit) richiede riscrivere la history (`git filter-repo`/BFG) + force-push coordinato: un'operazione distruttiva che non eseguo senza tua esplicita richiesta.

---

## 1. Bug confermati con verifica avversariale (agire con fiducia alta)

Ognuno riletto e ri-eseguito da zero da un secondo agente che ha cercato di smentirlo, non di confermarlo.

| # | Titolo | File | Severità |
|---|---|---|---|
| 1.1 | `saveToDrive` riesce ma `sendNotifica` fallisce: nessuna compensazione — un rilancio rischia doppia cessione delle stesse fatture | `src/Main.gs:22-58` | alta |
| 1.2 | Token OAuth2 riusato per l'intera paginazione: se scade a metà, il fetch abortisce senza refresh, i documenti già accumulati sono persi | `src/FetchBC.gs:9-51`, `src/Http.gs:11` | alta |
| 1.3 | `mapDocumentType_` scarta silenziosamente i tipi documento non mappati (es. "Finance Charge Memo"), zero log | `src/FetchBC.gs:37-38,56-60` | alta |
| 1.4 | `setupSecrets_()` sovrascrive incondizionatamente segreti già configurati con stringhe vuote, senza guardia né conferma | `src/Config.gs:53-59` | alta |
| 1.5 | `toYYYYMMDD` (ramo stringa): nessuna validazione formato/calendario, propaga date malformate nel campo fixed-width | `src/Helpers.gs:17-20` | alta |
| 1.6 | `toYYYYMMDD` (ramo Date): `null`→`19700101` silenzioso, `undefined`/Date invalida→`"NaNNaNNaN"` (9 char invece di 8) | `src/Helpers.gs:21-24` | alta |
| 1.7 | Overflow silenzioso del campo importo a 17 cifre in `formatImporto` (imprecisione IEEE754 su importi molto grandi) | `src/Helpers.gs:6-9` | alta |
| 1.8 | Il troncamento a 12 char del numero documento è applicato SOLO in `FetchBC.gs`, non in `GeneraTXT.gs` (nessuna difesa in profondità) | `src/GeneraTXT.gs:58,70` | alta |
| 1.9 | `deploy.sh`: `git pull` + `clasp push -f` senza controllare un working tree sporco — modifiche locali non committate finiscono in produzione | `deploy.sh:8-14` | alta |

Dettaglio completo (evidenza, comando eseguito, scenario) per ciascuno nel journal del workflow — disponibile su richiesta.

## 2. Buona notizia verificata (non un bug)

`GeneraTXT.gs` (record 010/020/030) riproduce **byte-per-byte** le righe reali "verificate con UniCredit" citate in `PROMPT_ClaudeCode_BVI_Generator.md` — verificato con `node`, non dedotto, prima di lanciare le 30 passate.

## 3. Domanda di dominio aperta (non risolvibile leggendo il codice)

**Tipo partita per le note di credito**: la spec dice `NDC`, il codice (`CONFIG.TIPO_PARTITA_NCC`) usa `P03`. Nessun esempio reale di riga NCC verificato con UniCredit esiste nel repo per dirimere quale sia corretto — **serve una tua conferma** prima di toccare questo campo.

## 4. Rilievi NON ancora verificati (45 — "l'onore del non verificato": probabili, da rileggere prima di agire)

Per severità (i più concreti/rischiosi in cima):

**Alta**
- `Remaining_Amount` nullo da BC → `Math.abs(null)===0`, un importo mancante diventa uno zero contabile silenzioso (`FetchBC.gs:46`)
- `Document_Date`/`Due_Date` nullo → `new Date(null)` è valida (epoca 1970), non `Invalid Date`: data falsa silenziosa (`Helpers.gs:17-25`)
- **Secondo segreto in git history** (`TestConnessioneBC.js/.gs`, sezione 0 sopra)
- `http.test.js` testa la resa dopo `HTTP_MAX_RETRIES` solo per HTTP 5xx, mai per errori di rete — un retry infinito su errore di rete persistente non verrebbe rilevato da nessun test
- Pagina OData con HTTP 200 ma senza `value` → `TypeError` generico, perde tutti i documenti già accumulati e il messaggio d'errore OData originale (`FetchBC.gs:34-48`)

**Media** (16 rilievi) — tra i più concreti:
- Lock occupato → uscita silenziosa, nessun alert che l'esecuzione schedulata è saltata (`Main.gs:5-11`)
- 401 su BC mai ritentato, token in cache non invalidato (`Http.gs:9-11`, `Auth.gs`)
- Nessun budget di tempo aggregato nella paginazione OData vs limite 6 min di GAS
- Il tenant id BC finisce nei log ad ogni retry HTTP (`Http.gs:21`)
- Un CR/LF letterale nel numero documento romperebbe la struttura fixed-width del file
- `deploy.sh` non verifica il branch corrente prima di forzare il push sull'unico scriptId di produzione
- Log su Spreadsheet richiesto dalla spec originale ma completamente assente

**Bassa** (24 rilievi) — soprattutto edge case di `formatImporto`/`toYYYYMMDD` non raggiungibili nel flusso attuale (importi negativi, arrotondamento IEEE754 a 3 decimali, encoding ASCII vs ISO-8859-1) e cosmetici (`-0,00` nell'email).

Elenco completo con evidenza per ognuno nel journal del workflow.

## 5. Migliorie progettate (60)

Raggruppate per tema — elenco completo su richiesta:
- **Idempotenza/resilienza**: tracciare i documenti già esportati, isolare il fallimento di `sendNotifica` da `saveToDrive`, alert quando il lock è occupato, dead-man's switch per rilevare la mancata esecuzione del job
- **Business Central**: riautenticazione automatica su 401, guardia di tempo residuo nella paginazione, validare la forma della risposta OData prima di iterarla, non loggare l'URL completo (contiene il tenant id)
- **Qualità dati**: validazione esplicita in `toYYYYMMDD`, guardia di overflow in `formatImporto`, troncamento difensivo di `f.nr` anche in `GeneraTXT.gs`
- **Deploy**: guardia di working tree pulito e di branch in `deploy.sh`
- **Test**: coprire con test i casi limite dimostrati in questa revisione, incorporare il dataset reale "verificato con UniCredit" in un test automatico
- **Sicurezza**: ripulire la history git dai segreti residui, sanificare i campi BC-sourced prima di scriverli nel file

## 6. Funzionalità nuove proposte (8)

- Persistenza dei log strutturati oltre l'execution log di Stackdriver
- Registro cessioni su Google Sheet (storico esportazioni) — richiesto anche dalla spec originale, mai implementato
- Prevenire la ri-cessione della stessa fattura in invii successivi
- Avviso di avvicinamento al plafond della linea di credito factoring (**domanda di dominio**: serve un parametro tuo per il plafond)
- Gestione differenziata delle fatture scadute (insoluti) al momento della cessione (**domanda di dominio**)
- Healthcheck schedulato separato da `main()`
- Email di conferma/allerta distinta se il file viene rigenerato più volte nello stesso giorno

## 7. Cose cercate e NON trovate (73 assenze verificate — buone notizie)

Tra le principali: nessun altro entry point raggiungibile oltre `main()` (niente webapp/doGet/doPost), nessun altro segreto in chiaro nei sorgenti `src/*.gs` oltre ai due già noti, i valori hardcoded in `CONFIG` coincidono con gli esempi verificati con UniCredit, `fixedWidth`/`generateTXT` corretti sui casi standard, nessun test automatico copre `Auth.gs`/`Config.gs`/`Main.gs` (gap dichiarato, non un bug in sé).

---

*Report generato da un workflow di 30 agenti (21 scoperta + 9 verifica avversariale, ~1.9M token, 414 tool call) il 2026-08-28. Nessun file del repo è stato modificato da questo workflow.*
