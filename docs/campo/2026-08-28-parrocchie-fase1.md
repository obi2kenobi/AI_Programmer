# AI_Programmer in azione su un progetto esterno — Report di fase 1

**Data:** 28/08/2026
**Target:** `frazu2003-lab/gestionale-parrocchie` (Flask + SQLite, ~7.000 righe, archivio amministrativo di parrocchie, dati personali reali, repo privato)
**Mandato:** verifica col metodo AI_Programmer, 50 giri di revisione, errori + migliorie; poi correzioni e primo sviluppo.
**Regime:** sessione diurna ZCode/GLM su clone locale. Nessuna commessa, nessuna notte, nessun gate: terza corsia "allargata" — la prima volta che il metodo lavora su un repo non nato da lui.

---

## 1. Cosa del metodo è stato usato davvero

| Elemento del metodo | Usato? | Come |
|---|---|---|
| «Esegui, non leggere» | **sì, col banco** | ogni difetto ad alta gravità dimostrato eseguendo su archivio sandbox (13 verifiche eseguite) |
| Territorio dichiarato | sì | ~7.000 righe, territorio medio-grande, lettura integrale dichiarata prima di iniziare |
| Forma dei dati verificata | sì | assunzioni su tabelle/campi verificate su `schema.sql` + migrazioni (v2-6) prima di giudicare l'app |
| Censimento con lenti | sì, ad hoc | 4 subagenti in parallelo, 26 passate a lenti (logica, silenziosi, dati, privacy, doc-vs-codice) |
| Il guardiano si prova quando deve fallire | sì | banco mantenuto come caso noto-difettoso: dopo le correzioni nessun difetto è più dimostrabile |
| L'aspettativa si deriva a mano | sì | aritmetica del banco contata a mano (attese precise per data/fenomeno) prima di girarlo |
| Design prima della feature | sì | generatore scadenze: 3 opzioni con trade-off, scelta all'utente, poi implementazione |
| Memoria viva | sì | SAL.md (revisione + M10 passo 1) e DEBITI.md (+14 voci con condizione di saldo) chiusi nel giro stesso |
| Privacy come presidio | **sì, in modalità degradata** | controllo lanciato a ogni invio: cieco senza `.riservato.txt`, fallisce come promesso (vedi F6) |
| Standard (CLAUDE.md+skills+agents+hooks+.night-verify) | **no** | il target non lo ha; `sync-repo.sh --standard` non è stato lanciato (vedi F1) |
| Notte / morning-gate / gate.csv / /goal | no | lavoro di giorno su progetto esterno: nessun gate equivalente (vedi F4) |
| Oracoli GAS, gas-sviluppo, revisore-gas | no | dominio non-Apps Script; le *famiglie di difetti* però hanno generalizzato (§3) |

## 2. I numeri della fase

- **50 passate documentate**: 3 preparazione (studio hub + mappa target), 7 lettura integrale del nucleo, 26 passate a lenti dei 4 subagenti, 13 verifiche al banco, 1 censimento di chiusura.
- **~60 difetti** catalogati; **13 dimostrati al banco**; **1 falso positivo smentito** (query riprodotta alla lettera invece che parafrasata); 2 riclassificati (semantica, non difetto).
- **10 commit di correzione** (uno per tema, messaggio con il perché) + **1 commit di sviluppo** (`genera_scadenze.py`, M10 passo 1), tutti pushati su `main`.
- Banco post-correzione: **9/9 difetti non più dimostrabili**; giro di fumo **19/19 pagine 200**.
- Collaudo del generatore: **10/10** su archivio di prova (propose, conferma, idempotenza, catene di ricorrenze, sostituzione dichiarata).
- Difetto nuovo trovato *durante* il collaudo e corretto prima del commit: le catene di ricorrenze si chiudevano fra loro; semantica riscritta a «chiusure dichiarate nel foglio».

## 3. Cosa ha funzionato (le lezioni che reggono)

1. **Il banco è il vero metodo.** La revisione a lenti ha prodotto ~60 sospetti; il banco ne ha promossi 13 come difetti reali, smentito 1 falso positivo (l'agente aveva parafrasato la query di `da_recuperare.py`: riprodotta alla lettera, il difetto c'era — ma con un meccanismo diverso da quello descritto) e costretto a 2 riclassificazioni oneste. Il verdetto «fatto» è arrivato solo dal ribaltamento del banco, non dalla lettura.
2. **Le famiglie di difetti del corpus generalizzano fra linguaggi.** Il corpus è nato su Apps Script/GAS e qui il target era Python/SQLite, eppure le stesse famiglie sono ricomparse misurate: tipo/normalizzazione (`Number('')=0` → qui `120.0` vs `'120'` = modifiche fantasma; importi `1000.50` → ×100), «non letto» vs «vuoto» (sentinella `0000-00-00`, `letta=True` per PDF vuoti), guardiano cieco dove dichiara di vedere, lock/risorsa assente in scrittura multi-fase (file spostati prima del commit). La domanda discriminante per famiglia ha guidato le lenti dei subagenti.
3. **La memoria viva del target è più ricca di quella tipica** e il metodo la ha rispettata invece di sostituirla: SAL/DEBITI/DECISIONI/DA-VERIFICARE del progetto sono stati aggiornati nei loro formati, non riscritti.
4. **Due metodi in una sessione, senza conflitto.** Il target ha un proprio CLAUDE.md (10 regole) più severo del metodo hub su «l'utente decide»: la fusione ha funzionato — opzioni esposte e scelta all'utente per la feature, autonomia sui difetti già autorizzati. Il §10 «fuori ambito» del target ha contenuto la lista migliorie: è la «selezione del contesto» che lì era già scritta.

## 4. Cosa non ha funzionato (le anomalie vere — F1..F7)

- **F1 — Lo standard non viaggia da solo.** Il target ha CLAUDE.md e hook propri ma niente `.claude/skills/`, niente `.claude/agents/`, niente `.night-verify`. Tutto il metodo è stato applicato *manualmente*, leggendo METHOD.md in sessione. Il passo 0 dichiarato «verifica di un repo esterno» dovrebbe essere `tools/sync-repo.sh <repo> --standard` (o almeno il drift check) — non è stato fatto finché non si è letta la sezione «Lo standard».
- **F2 — Il banco si è costruito a mano, e ha prodotto difetti suoi.** Nessun harness riutilizzabile: ho riscritto i percorsi dati monkeypatchando `comune` prima dell'import, seminato fixture, esercitato rotte Flask e CLI. Il mio stesso script demo ha fatto **3 errori di binding SQL** prima di girare: la regola «l'aspettativa si deriva a mano» andava applicata anche al codice di prova. Da distillare in `patterns/`: *banco di progetto locale* (riscrivi i percorsi → semina fixture marcata → esercita rotte/CLI → asserisci → il banco resta e diventa `.night-verify` eseguibile).
- **F3 — L'ambiente del censimento ha falsificato l'audit git.** Il clone era `--depth 1`: l'audit «documenti vs storia» ha visto **1 commit** dove il repo ne ha **41**, producendo una conclusione falsa (storia «squashata», debito «incoerente») finché il fetch completo non ha corretto. Regola nuova da scrivere: *l'ambiente del censimento va dichiarato* (depth, remote, branch) e i giudizi sulla storia git richiedono clone completo.
- **F4 — 50 giri senza loop.** Le passate sono state documentate in un diario ma non erano un loop ingegnerizzato: niente `/goal | max N`, niente gate, **nessuna riga in `metrics/gate.csv`**. Il lavoro di giorno su progetto esterno non ha chiusura L4/L5: la review umana c'è stata (l'utente ha approvato e pushato), ma la memoria numerica del hub non cresce.
- **F5 — L'iniezione del metodo esiste solo per Claude Code.** In ZCode niente SessionStart/UserPromptSubmit del hub: METHOD.md è stato letto a mano all'inizio. Senza disciplina dell'agente, il metodo non c'è. O si estende l'hook, o si dichiara limite (oggi è implicito).
- **F6 — Il guardiano della privacy è corretto ma degradato per costruzione fuori casa.** `.riservato.txt` è locale: su un clone qualunque **ogni invio è cieco**, e il controllo fallisce dicendolo (giusto), ma la conseguenza pratica è che una sessione esterna consegna sempre con presidio degradato + verifica manuale. Serve una via portatile dichiarata (seed minimale non riservato nel repo? hash delle parole? istruzione di consegna obbligatoria: «rilancia il controllo dalla macchina che ha la lista»).
- **F7 — Governance della consegna.** Le correzioni sono andate direttamente in `main` del progetto (autorizzato in sessione dall'utente) ma l'autore del progetto non le ha rirevisionate. Raccomandazione consegnata: l'autore rilanci banco + controllo riservatezza dalla sua macchina prima dell'uso su dati veri; e resta aperta la decisione privacy già in DEBITI (nomi nella storia: 41 commit) + la località citata in DA-VERIFICARE.md.

## 5. Sul progetto «anomalo» (una riga per il fascicolo)

Non è anomalo per disordine: è anomalo perché **è un altro metodo completo**, nato fuori dall'hub, con memoria viva più ricca (7 documenti governativi), dati personali reali sul disco e un pubblico di uno. Il metodo ha funzionato meglio proprio dove il progetto era già method-led: le regole si sono innestate, non sostituite. Il rischio residuo non è tecnico ma di presidio: privacy degradata fuori dalla macchina dell'autore (F6) e consegna senza revisione dell'autore (F7).

## 6. Proposte per l'hub (da valutare, non decise)

1. Distillare il **pattern «banco di progetto locale»** in `patterns/` (riscrittura percorsi + fixture + rotte/CLI + asserzioni + riuso come `.night-verify`).
2. Rendere **`sync-repo.sh --standard` il passo 0** dichiarato del flusso «verifica commessa esterna» (o del dogfooding su repo estranei).
3. Aggiungere ai controlli doc-vs-codice la **regola dell'ambiente**: depth/remote/branch del clone dichiarati nel censimento; giudizi sulla storia vietati su clone shallow.
4. Estendere l'**iniezione del metodo** ai cervelli non-Claude, o dichiararla limite nella matrice dei cervelli.
5. Prevedere una **riga di esito diurna** (comme `gate.csv`) per il lavoro fuori-notte: data, target, difetti dimostrati, commit, banco.

## 7. Stato di consegna (fase 1)

- Repository: `main` a `599d9b4` — 11 commit (9 correzioni per tema, 1 SAL/DEBITI, 1 feature M10).
- Banco e esiti: `banco-avversariale.py`, `esiti-banco.txt`, `esiti-banco-post-fix.txt`, collaudo scadenze 10/10.
- App demo avviata in modalità dati di prova (fascia rossa) con dati finti marcati; archivio vero non toccato (inexistsente su questa macchina).
- Aperto verso fase 2: conferma dei preavvisi voce per voce (dodici righe che solo il proprietario può compilare), scadenze delle bollette (bloccate su 8 contatori mancanti), decisione privacy sulla storia (F7).
