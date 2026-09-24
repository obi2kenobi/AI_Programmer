# Quarto ventaglio — consolidamento (2026-09-24)

Brief: `docs/giri/2026-09-24-quarto/00-BRIEF.md`. Cinque lenti, un giro ciascuna, ognuno in un clone:
- Q1: il primo giorno;
- Q2: il guasto;
- Q3: i contratti d'uscita;
- Q4: il grafo come navigazione;
- Q5: i ganci visti da un avversario.

I rapporti grezzi sono in `grezzi/`, ignorata da git (skill n-giri §2). Dettagli di ogni cura nel SAL,
voce 18°.

## Esito

- **30 rilievi**, 6 per giro. Tutti provati eseguendo, tranne due dichiarati «non provato»: Q1 R5
  (launchctl) e Q4 R6 (in parte).
- **Curati**: 28, di cui 3 solo in parte (Q5 R4, R5, R6: il resto è dichiarato). Ognuno ha banco rosso
  prima e sabotaggio rosso dopo. Due eccezioni:
  - la cura di Q2 R6 (mktemp) non è stata sabotata, perché il sabotaggio riscriverebbe `/CLAUDE.md`;
  - i rilievi di Q4 sono curati nei documenti, con una guardia sul testo.
- **Esclusi** (domande di dominio, in DEBITI): Q1 R3 (repo pubblica di default, già aperta) e Q1 R5 (da
  dove nasce `luca.ollama`).
- **Smentite**: nessuna. Due miei conteggi di verifica erano però sbagliati e sono stati rifatti:
  - SHAPES spezzata sulle `|`: 4 falsi positivi nella storia;
  - un `pgrep` inquinato dalla mia stessa riga di comando.

## Temi trasversali

1. **Il muto letto come sano** (Q2, Q3; già V1#6 nel terzo ventaglio). Casi:
   - la risposta vuota del modello era «completato»;
   - la lente muta e lo strumento senza uscita erano «sana»;
   - la coda illeggibile era «0 issue»;
   - il timestamp illeggibile era «cicla»;
   - senza jq, un Ollama sano era «wedged»;
   - uno swap non misurato era verde.

   Un terzo esito, «non so», distinto dal verde, ora esiste in ogni punto dove il giro l'ha cercato.
2. **Il guardiano che si aggira per errore** (Q5; E-047 nel terzo). Il cancello di clasp cedeva a 20
   forme normali. L'allowlist cedeva all'a capo. Le forme di segreto non avevano un dente di giorno, e i
   nomi sfuggivano fuori dai `.md`. Scoperto curando: **un gancio che muore lascia passare tutto**, e ora
   nega in modo prudente.
3. **L'ingresso non detto** (Q1, Q4). Mancavano:
   - un «primo giorno» (guardiani del commit spenti, identità git, prerequisiti, i rossi attesi);
   - i limiti del grafo: i chiamanti dentro `"$(…)"` sono invisibili, e `lente_pr` sembrava morta.

## Tassonomia

**Implementata**
- Q1: R1 (identità git: suite e bootstrap), R2 (il primo giorno in AGENTS.md), R4 (le pulizie che
  uccidevano la shell dell'agente), R6 (system-health fuori dal Mac).
- Q2: R1 (sync-repo senza jq), R2 (dipendenze del turno e dell'agente), R3 (digest senza il report del
  gate), R4 (login e label nel bootstrap, forma owner/repo), R5 (la coda illeggibile), R6 (mktemp e
  motivo del push).
- Q3: R1-R2 (i muti: agente, caccia-lente, rc 2 nel turno), R3 (suite su una cartella sbagliata), R4-R5
  (i codici d'uscita), R6 (turno-vivo «non so»).
- Q4: R1-R6, nella regola di AGENTS.md e nella riga d'avvio della spina. La proposta per CLAUDE.md §7 non
  è applicata.
- Q5:
  - R1: l'allowlist (a capo, `..` ricomposto dalla shell, jq env);
  - R2: le forme al commit e le credenziali nella storia;
  - R3-R4-R6: il cancello di clasp (runner, catene, sottocartelle, shell, eval, virgolette, Monitor) e
    il gancio che muore;
  - R5: i nomi in ogni file di testo e senza badare alle maiuscole.

**Esclusa** (domanda di dominio)
- Q1 R3: il default pubblico del bootstrap (DEBITI, già aperta).
- Q1 R5: il job `luca.ollama`, che nessun installatore crea.

**Rinviata**
- Q5 R5, resto:
  - `tests/` escluso dalle forme (due banchi portano forme sintetiche per esteso);
  - il segreto spezzato su due righe (forma da aggressore);
  - la chiave riconosciuta per contenuto (dopo la domanda «nomi sì»).
- Q5 R6: le forme da aggressore del cancello di clasp, dichiarate per nome nel limite.
- Q2, sotto il tetto: `ask-glm` che stampa «None» su `content: null`, e `ask-*` senza python3 che escono
  127. I chiamanti veri li trattano già come DEGRADATA.
- Tutto ciò che solo il Mac prova: DEBITI, riga ⏳, voci (g) mail e (h) nomi.

**Già coperta**
- Nessuna.

## Da fare a mano (non potevo)

- `rm -f /CLAUDE.md /claude-satellite.md` nel container di questa sessione. Li ha scritti il giro Q2
  provando sync-repo con un TMPDIR inesistente, da root. È proprio il difetto di Q2 R6, ora curato. Il
  controllo di sicurezza di Claude Code ha negato la rimozione a me: solo una persona può approvarla.

## Errori miei in questo ventaglio

- Il primo tentativo sul cancello di clasp aveva una variabile non inizializzata. Il gancio moriva, e
  morendo lasciava passare tutto; il banco H7 l'ha preso prima del commit. Da lì il tema 2.
- Cinque prime stesure prese dai banchi prima della consegna:
  - A7 cercava «completato» e prendeva «NON completato»;
  - il controllo d'identità con `git config` non vedeva l'ambiente e rompeva l'e2e;
  - il controllo delle dipendenze stava prima dell'export del PATH;
  - `grep -Iq` in pipe era E-002;
  - un fixture della catena era nell'ordine che un solo giro risolveva.
