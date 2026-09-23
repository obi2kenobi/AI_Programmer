# Il turno di notte — il metodo (v2, generalizzato)

> Il metodo nato su REPO-A (tre notti di test veri, 2026-08-18/21) e promosso a sistema.
> Ogni regola porta accanto **il fatto misurato che l'ha imposta** — non la motivazione teorica.

## Il principio

Il modello locale **non è un secondo cervello**: è capacità di calcolo a costo marginale zero,
privacy totale e nessun rate limit. La qualità dei cervelli cloud resta superiore. Perciò:

```
GIORNO (cervelli): ZCode/GLM · Claude Code/Opus · OpenCode via Wayfinder → Qwen
                   pianificano, correggono, giudicano
NOTTE (braccia):   night-shift 23:00 → issue `night-shift` → OpenCode → Qwen locale
                   commesse meccaniche → PR BOZZA, mai push su main
MATTINA (giudizio): morning-gate → verifiche dichiarate + banco avversariale →
                    proposte correttive (il sì è del censore, il VETO resta umano — patto del 2026-09-18)
```

## Le regole vincolanti

| Regola | Il fatto che l'ha imposta |
|---|---|
| **L'issue è una commessa precaricata** (snippet, righe, grep pronti) | tre notti: il modello capisce ma a ~4 tok/s non converge se deve esplorare 4.300 righe per giudicare |
| **Limite di tempo per issue: watchdog a 240 min** (dal 2026-09-20; il no-limit del 2026-08-21 costava 3 notti: cicli persi su commesse senza fine — `NIGHT_SHIFT_TIMEOUT` per cambiarlo) | il no-limit assoluto e il watchdog da 90 min hanno entrambi fallito: 240 min e' la misura presente |
| **PR sempre BOZZA su branch `night/issue-N`** | la review del mattino è parte del metodo |
| **Mai scrivere in cartelle specchio/sola lettura** | `gas-src/` in REPO-A: regola fondativa del repo ospite |
| **Idempotenza completa** | PR aperta → skip; PR fusa → chiude l'issue dimenticata (la keyword italiana non auto-chiudeva) |
| **Sonda di salute del server + un modello per turno** | dopo scambi di modelli a caldo, errori Metal con risposte vuote silenziose |
| **Config reale fuori dal repo pubblico** | `night-shift/repos.conf` gitignored: i nomi delle repo possono comparire (dominio 2026-09-23), l'ACCESSO mai |
| **Loop su array, bash 3.2, `cd` nel subshell, `git clean` per issue** | i quattro difetti d'infrastruttura trovati nelle notti di test |

## I numeri che scelgono il modello (MacBook Air M5, 24 GB, misurati 2026-08-18)

| Quant | Velocità | Esito |
|---|---|---|
| Q4_K_M MTP 17,1 GB | 3,7-5,9 tok/s | **operativa** (parità 4/4 con Q5 nella batteria di qualità) |
| Q5_K_M 19,8 GB | 2,5 tok/s | opzione fedeltà one-shot |
| Q5_K_XL 21 GB | 0,23 tok/s | thrashing — inusabile |

Server: flash attention, KV q8_0, contesto 16K, thinking off per il batch.

## Come si usa

```bash
night-shift/night-shift.sh                # tutte le repo in repos.conf
night-shift/night-shift.sh owner/repo     # una repo
night-shift/morning-gate.sh               # il giudizio del mattino
```

Mettere in coda: issue con label `night-shift`, scritta come commessa. Il turno parte da solo
alle 23:00 (LaunchAgent). Il Mac: alimentatore, coperchio aperto, app pesanti chiuse
(è la differenza fra 1 e 4 tok/s).

## Il gate del mattino (`night-shift/morning-gate.sh`)

1. **Verifiche dichiarate**: la repo dichiara i comandi in `.night-verify` (una riga per comando).
   Se non esiste: `non-dichiarate`. Se esiste ma non contiene nessun comando reale (solo
   commenti — capita facile, è il default di `bootstrap-app.sh`): `verifiche-vuote`, non un
   falso `verifiche-ok` (set 2 2026-08-22, bug reale corretto). Se la repo non ha NESSUN modo
   di verificare in automatico (es. GAS-only, la verifica passa dal deploy umano), dichiaralo
   con una riga `# NON-VERIFICABILE: <motivo>` — verdetto `non-verificabile`, distinto da
   "dimenticato" (proposta #2 di `docs/test-processo-2026-08-21.md`, mai implementata prima)
2. **Banco avversariale**: il modello locale prova a smentire la PR (metodo del Supervisore)
3. **Report** in `~/morning-gate-report.md` + riga in `metrics/gate.csv`
4. **Il correttore**: i fallimenti diventano proposte di commesse correttive da incollare —
   nessun sì, nessuna commessa (regola _"Done means proven and confirmed"_)

## Checklist review umana

- [ ] Le verifiche dichiarate passano sul branch
- [ ] Il diff tocca SOLO ciò che l'issue chiedeva
- [ ] Il banco avversariale non ha prodotto smentite valide
- [ ] I valori attesi nei test non sono stati «adattati» per farli passare

## La commessa si costruis col grafo (dal 2026-08-21)

Il collo di bottiglia misurato dell'agente notturno è LEGGERE file (issue #363: 4.300 righe a
chunk di 80). Da oggi due regole:

1. **Il cervello di giorno costruisce la commessa interrogando il grafo**: `graphify query
   "<dove sta X>"` → file:riga esatti da incollare nell'issue. La commessa precaricata diventa
   chirurgica perché la navigazione è già fatta.
2. **L'agente notturno naviga col grafo, non legge**: la skill graphify (`.opencode/skills/`,
   installata con `graphify install --platform opencode --project`) insegna il fast-path —
   se `graphify-out/graph.json` esiste, si interroga prima di leggere.

Grafi da costruire: `graphify extract . --code-only` (deterministico, 0 LLM, 0 token).
Versione pinata 0.9.48; regole del grafo nel SAL (orientarsi sì, oracolo no; `calls` non risolti).

## I cinque livelli di verifica (tassonomia 2026-08-21)

Ogni verifica del sistema si dichiara col suo livello — la tassonomia completa e la mappa
loop-engineering del sistema: `docs/system.md`.

| Livello | Qui |
|---|---|
| 1 · deterministico | `.night-verify` (exit code), test-motore |
| 2 · vincoli numerici | soglie, conteggi, metriche del gate |
| 3 · verità terrena ritardata | il "riscontro" BC (Verificato ☐ che matura), esiti deploy |
| 4 · LLM giudice | banco avversariale (variante forte: smentisce, non si autovaluta) |
| 5 · checkpoint umano | review di Luca — chiude ogni ciclo |

## Il giudizio umano della PR

`gate-esito.sh <owner/repo> <n-PR> <merge|chiusura|commessa>` — registra nella colonna `esito`
di `metrics/gate.csv` cosa ne è stato della PR giudicata dal gate del mattino. Senza questo
passaggio il livello memoria resta vuoto (review 2026-08-21). `gate-summary.sh [giorni]` ne
legge il riepilogo (lo usa `morning-digest`).

## Gli altri comandi del turno

- `night-shift.sh [owner/repo ...]` — il turno: senza argomenti legge `night-shift/repos.conf`; self-pull
  dell'hub prima di partire; PR BOZZA mai su main; le proposte non applicabili finiscono come
  commento nell'issue (una per issue), non come PR.
- `risolvi-issue.sh <dir> <issue.md>` — il risolutore senza agente: chiama Ollama in locale
  (`qwen3.8-27b:iq3s`), il modello scrive il codice, lo script lo applica e lo verifica
  (`node --check`, rollback). Exit: 0 applicato · 1 fallito · 2 uso · 3 proposta non applicabile.
- `night-shift/morning-gate.sh` / `night-shift/morning-digest.sh` — il giudizio del mattino e il riepilogo che lo legge.
- `night-shift/install.sh` — installazione: symlink, LaunchAgent 23:00 + Ollama always-on. Verifica che il
  job caricato punti davvero all'HUB installato (E-019).
- `night-shift/lib.sh` — le funzioni condivise (log, rotazione, default branch).

## L'agente nostro

`night-shift/agente.sh` <dir> <prompt> — il ciclo multi-turno bash ↔ Ollama che
opencode non chiudeva. Il modello chiede azioni con JSON nel contenuto, lo script
le esegue (read/write/run con confinamento e denylist), e rimanda il risultato.
Tre sfide superate: bug fix, nuova funzione, ciclo di miglioramento con verifica.

## La caccia intelligente

- `night-shift/caccia-lente.sh` — la caccia che USA gli strumenti dell'hub:
  le sonde, il health, il banco, il ciclo-vivo e il registro girano, e il modello
  locale INTERPRETA il loro output decidendo se ci sono problemi.
  Cinque lenti in rotazione automatica, una per ciclo.
- (rimossa il 2026-09-23, audit: era la caccia precedente, sostituita da
  caccia-lente — 119 righe morte che nessuno chiamava più)

## Il saldatore deterministico (E-002 si salda senza modello)

`tools/salda-e002.sh` — il fix cattura-prima della famiglia E-002 e' una
TRASFORMAZIONE, non un'opinione: il trasformatore riscrive la riga esatta
(forme `if PROD | grep ...` e condizioni composte), verifica la sintassi e
ripristina se qualcosa non torna. Nella caccia-miglioria viene PRIMA
dell'agente: i debiti E-002 si saldano senza chiedere permesso a un modello,
e l'agente resta per le forme non riconosciute. («Chiudi ora», 2026-09-20:
dieci debiti provati dal 14b, zero saldati — la via meccanica li chiude.)

## L'allineamento dello standard (il drift si dichiara)

Le repo di destinazione portano una COPIA dello standard, sincronizzata al
momento dell'onboarding: da lì divergono in silenzio mentre l'hub aggiorna
(domanda di Luca, 2026-09-19: «le installazioni fatte mesi fa danno
problemi?» — sì: il CLAUDE.md del Magazzino distava 37 righe). Il turno
misura il drift a ogni ciclo con `tools/sync-repo.sh` (modalita' verifica)
e lo dichiara insieme a salute e debiti; se divergente e senza PR aperta,
apre UNA PR di riallineo (`--standard`: CLAUDE.md, skill, agenti, hook —
mai push su main). Il CLAUDE.md e' il canarino del drift.

## Il revisore (il censore delle PR)

`night-shift/revisore.sh` — chi scrive non giudica... ma con UN solo
cervello (storia: 2026-09-19 il 14b batte' il 27b di allora; dal 2026-09-21
gira qwen3.8-27b:iq3s — quantizzato 3.5bpw, 12GB, bencina 3/3 in 48s con
think:false — vedi cervello/decisione-modello-unico.md). Le miglioria le
scrive il modello di turno e la
PR bozza night/* in quarantena (>=20 min) passa al censore: stesso
modello, PERSONA diversa (prompt avversario, onere della prova sulla PR,
contesto fresco) — e le tre guardie deterministiche restano l'argine
vero: diff, verifiche dichiarate, banco avversario allowlistato.

Tre livelli, in ordine di autorita' (un solo no e' no):
guardie deterministiche (diff <=60 righe, <=3 file, ASCII, budget <=5/giorno) →
prove deterministiche (verifiche dichiarate + comando avversario del banco con
allowlist) → giudizio del censore (JSON: APPROVA/RIGETTA + motivi).
APPROVA → squash-merge con certificato in commento. RIGETTA → chiusa con i
motivi scritti. Tutto il resto → rinvio al giorno.

Patto aggiornato (dichiarato, 2026-09-18): «il si' e' sempre umano» diventa
«il si' e' del censore, il VETO resta umano» — ogni deliberazione nel log e
revertabile al mattino.

## La caccia che migliora (2026-09-17)

- `night-shift/caccia-miglioria.sh` — la caccia che MIGLORA il codice, non lo
  verifica: le lenti dicono «tutto bene», qui l'agente SCRIVE una miglioria.
  Un file, una categoria (codice morto · documentazione · semplificazione ·
  letterali ripetuti), un prompt focused. Il GATE decide cosa merita diventare
  PR: diff ≤ 40 righe, max 2 file, sintassi valida, solo ASCII. Se non c'è
  niente da migliorare lo DICE (marker 6h): inventare lavoro è peggio che non
  trovarlo. Rotazione file/categoria in .git/miglioria/, mai committata.

## La caccia del registro (il censimento dei debiti)

`tools/caccia-registro.sh` — la caccia che legge il REGISTRO DEGLI ERRORI e
cerca le famiglie di bug dove davvero si nascondono (domanda di Luca
2026-09-18: «come fa a essere sempre tutto in salute?»). Le cacce per
categoria guardano un file alla volta; i bug veri (E-028..E-032) erano tutti
d'integrazione: contratti, stdin condiviso, fixture nel repo vivo. Questa
caccia censisece quel debito su TUTTO il repo ogni ciclo — deterministica,
solo grep. Ogni «repository in salute» porta con se' il censimento: la
salute si dichiara insieme ai debiti o non e' onesta. Il delta tra censimenti
urla quando il debito cresce. E il debito si SALDA: ogni finestra di caccia
preleva il prossimo sito (`--prossimo`), l'agente applica il fix del canone
(cattura-prima per E-002, quarantena per E-032), il gate decide la PR — e il
sito passa tra i saldati. Un tentativo per sito: fallire rinvia, non
martella. Il censimento scende, il delta lo urla, il cerchio si chiude.

## La dashboard (finestra di osservazione)

- `tools/dashboard.py` — pagina HTML che si aggiorna ogni 10 secondi: cicli,
  PR, fix, cacce, errori, verifiche, attività recente. Serve su localhost:8787.
- Avvio: `dashboard` (da qualsiasi directory) oppure `python3 tools/dashboard.py`
- Si ferma con Ctrl+C. Se la porta è occupata, riavvia la vecchia istanza.
- Comando globale installato in ~/.local/bin/dashboard (symlink).
