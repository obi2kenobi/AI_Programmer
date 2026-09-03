# 2026-09-03 — REPO-S: caccia errori su un monorepo TypeScript (87 reperti, 14 correzioni)
**Autore**: sessione Claude Code (cloud, remota) su mandato di Luca — «puntare AI_Programmer
su questo repo alla caccia di problemi, difetti, errori silenziosi, bug, errori di logica con
tutti gli agenti», col dubbio esplicito: *«il sistema non è un GAS ma un sito vero e proprio,
non so se AI_Programmer sia adatto»*.

**Target**: REPO-S — monorepo TypeScript privato (configuratore prodotto su misura + back-office
multi-tenant; motore geometrico, cascata prezzi, Postgres/Prisma, React). `app/` = 272 file
`.ts/.tsx`, 66.345 righe, 78 file di test. Perimetro dichiarato: **solo `app/`**; il legacy PHP
del progetto è stato escluso perché già coperto da tre suoi documenti.

**Esito in una riga**: 87 reperti (3 P0 · 17 P1 · 67 P2) + 38 bandiere di dominio; 14 correzioni
applicate con banco; suite del target da 748 a 769 test, `lint` da rosso a verde.

---

## Cosa ho usato

**Usato per davvero**
- **`dev-critic`** — la lente portante. Le due sottolenti hanno prodotto **tutti e tre i P0**:
  §2bis sicurezza (tetto per-email assente su un invio di email) e §2ter formule
  matematico-finanziarie (un prezzo calcolato nel browser e mai persistito; una tabella di
  lookup interrogata senza la sua chiave di fascia).
- **`polilivello`** — livelli struttura/meccanica/**storia**. Il livello storia (churn × dimensione)
  ha indirizzato le corsie sui file giusti: i 2 file più modificati in 90 giorni sono anche 2 dei
  5 più grandi.
- **`selezione-contesto`** — decisivo in negativo: il target aveva **già 6 cacce errori** e 2 audit
  precedenti. Senza budget ed esclusioni dichiarate avrei riscoperto a costo pieno. Ogni corsia
  aveva l'obbligo di dire «già noto (doc NN)» o «nuovo», e **21 reperti** sono risultati già noti
  e ancora aperti — informazione più utile di un reperto nuovo.
- **`patterns/`** — 6 voci hanno fatto da lenti operative: `esegui-non-leggere`,
  `oracolo-indipendente`, `scarto-mai-silenzioso`, `somma-diversa-da-zero-non-e-presenza`,
  `soglia-con-default-guardato`, `regola-provata-non-assunta`.
- **Gli hook** — installati nel target (`.claude/hooks/`, non in `tools/` per non invadere la
  `tools/` del progetto) e **hanno sparato a ogni turno**: la riga «metodo attivo:
  esegui-non-dedurre · oracolo prima della formula · banco prima della correzione · SAL prima
  del passo successivo» è comparsa in tutto il resto della sessione. Provati a mano sui 4 casi,
  incluso quello che deve **tacere** e quello che deve **degradare**.

**Voluto e NON c'era**
- Un modo di **contare la copertura**: nessun `vitest.config.*` né `@vitest/coverage-*` nel target,
  e l'hub non ha un pattern su «come si stabilisce la copertura quando il progetto non la misura».
  Ho dovuto ripiegare su «ha test? per import verificato», che è più debole e l'ho dichiarato.
- Un **`privacy-check` eseguibile in cloud**: `tools/privacy-check.sh` esige `night-shift/repos.key`,
  che per disegno non esiste qui → gate **DEGRADATO** (esce 1 e lo dice, correttamente). Questo
  report è stato anonimizzato **a mano**, senza poter provare l'anonimizzazione col vostro strumento.
- Una regola su **chi assegna il codice repo**: ho dovuto dedurre il primo libero leggendo
  `night-shift/repos-index.md` e poi tutto il repo (REPO-R era già preso nell'indice, e T/X/Z
  compaiono altrove senza riga d'indice).

**NON RAGGIUNGIBILE** (la terza casella, 2026-08-27)
- **I 6 agenti di `.claude/agents/`**: 6 su 6 fuori bersaglio. `sviluppatore-gas`, `revisore-gas`,
  `contabilita-analitica`, `costruttore-calcoli-gestionali`, `censitore-forma-dati` parlano di
  `SpreadsheetApp`, `clasp`, quote Apps Script, endpoint BC. Il solo concettualmente vicino,
  `revisore-calcoli-critici`, è legato agli oracoli Python dell'hub. **Su TypeScript il roster
  non ha morso: zero invocazioni.**
- **Le skill non sono state invocate COME skill**: ho applicato le loro lenti dentro il brief di
  7 subagenti paralleli. Le skill dell'hub sono scritte per essere *lette da chi lavora*, non per
  essere *distribuite a corsie parallele* — vedi §Proposta 3.

---

## Cosa ho improvvisato

1. **Le 7 corsie parallele.** L'hub ha `/goal` (loop diurno con tetto) e il turno notturno
   (commessa unica, nessun tetto). Non ha **il ventaglio**: N lenti indipendenti sullo stesso
   bersaglio nello stesso momento, con perimetri disgiunti per non pestarsi. L'ho costruito a
   mano: motore · prezzi/corriere · API · persistenza · web · sicurezza · tenuta dei test, ognuna
   in **sola lettura**, ognuna obbligata a portare `file:riga` + scenario + **il comando che lo
   dimostra**, e a marcare ogni reperto `nuovo | già noto doc NN`.
2. **Il contratto di corsia.** Ogni brief chiudeva con tre sezioni obbligatorie: (a) cosa ho
   verificato **PULITO** (così si misura la copertura, non solo i difetti), (b) le bandiere di
   dominio, (c) **cosa non ho potuto verificare e perché**. La (c) è quella che ha reso il report
   utilizzabile: 7 corsie × limiti dichiarati = si sa dove NON guardare due volte.
3. **La verifica avversariale contro i reperti stessi.** Non prevista da nessuna skill: ho
   ri-provato di persona i P0 e ho **falsificato** roba mia e delle corsie (vedi sotto).
4. **L'anonimizzazione manuale** di questo report, col gate privacy non eseguibile.

---

## Cosa ha retto / ostacolato

### Ha retto

- **«Esegui, non dedurre» ha pagato tre volte, contro di me.**
  1. Avevo scritto a Luca e nel corpo della PR: *«CI in pausa dal 18-07, 50 commit da allora»*.
     **Falso.** 50 era la **profondità del clone shallow**, non la storia. `git rev-parse
     --is-shallow-repository` → `true`; dopo `git fetch --depth=1000`: 1611 commit dal 2025-11-19,
     pausa il **28-07**, **122 commit** dopo. → pattern `clone-shallow-mente-sulla-storia`.
  2. Una corsia ha concluso «il file CI non è mai esistito in forma attiva»: **stesso artefatto**,
     stessa causa. Falsificato e riscritto.
  3. Il mio primo test di regressione asseriva `faccia × giri ≤ parete`. Sbagliato: il ledger del
     motore dice che i giri pieni sono `giri−1`. **L'aspettativa si deriva** dal codice, non a
     memoria — e valeva anche per il codice di prova, esattamente come nel report REPO-N.
- **«Il guardiano si prova quando deve fallire»**, applicato in entrambi i versi: il banco del
  P0 motore è stato scritto **prima** ed era **rosso** (4 fallimenti, incluso un travaso inverso
  che non avevo previsto); per il tetto per-email ho rimesso il tetto a 0 e il test è tornato
  rosso. Senza questo passo avrei consegnato due fix "verdi per costruzione".
- **La prima versione del fix del motore ha rotto 2 test esistenti** che non c'entravano
  (una fascia diversa). Li ho letti e ho ristretto il fix. È il caso migliore possibile: la suite
  del target ha fatto da guardia contro di me.
- **`selezione-contesto`**: su 87 reperti, 21 erano già scritti nei doc del target. Dichiararlo ha
  evitato di rivendere il vecchio come nuovo.

### Ha ostacolato

- **Il testo iniettato dagli hook è GAS-centrico.** Ogni turno il target riceveva «oracolo in
  `tools/*.py`», «clasp MAI», «famiglie-difetti.md» — **tre riferimenti a file che in quel repo
  non esistono**. Copiato **verbatim** per non creare drift con l'hub (scelta dichiarata a Luca e
  nel report), ma è attrito a ogni prompt e insegna al modello a cercare cose assenti.
  → §Proposta 1.
- **`patterns/` non arriva con lo standard in modo utile.** `sync-repo.sh --standard` copia
  `patterns/`, ma io ho installato solo `.claude/` (mandato: non toccare altro) e il
  `pattern-reminder-hook.sh` è degradato a messaggio generico perché cerca
  `$HERE/patterns/README.md`. Il presidio esiste, l'ancora no. Provato: file sensibile →
  «nessun pattern specifico trovato nel registro».
- **Il roster agenti**: vedi NON RAGGIUNGIBILE. Non è un difetto dell'hub — è il confine del suo
  dominio, ma va **scritto**, perché il mandato «con tutti gli agenti» è nato dall'aspettativa
  opposta.
- **Il vostro gate è ROSSO su HEAD, e non per causa mia.** `bash .night-verify` si ferma a
  **26/122** su `tests/test-ciclo-vivo.sh` («FAIL verdetto assente», 5 OK / 1 FAIL). Provato che è
  **preesistente**: ho messo da parte le mie modifiche (`git stash -u`, albero pulito verificato) e
  lo stesso test dà lo stesso esito su HEAD. Inoltre `shellcheck` non è installato in questo
  ambiente (prima riga del gate) e `privacy-check` esce 1 per `repos.key` assente — quest'ultimo
  è **corretto per disegno** (v4: «un gate che non può giudicare non dice pulito: dice degradato»).
  Il risultato pratico però è che in cloud il gate **non può mai** essere verde, quindi non
  distingue «rotto» da «non giudicabile»: chi arriva da fuori non ha modo di sapere se ha rotto
  qualcosa. → §Proposta 7.
- **`repos-index.md` ha una discrepanza reale**, contro la sua stessa regola d'uso:
  **REPO-Q compare due volte** (`grep -c "^| REPO-Q"` → 2) con due descrizioni diverse, e la
  tabella si interrompe: `## REPO-CR` è un titolo di sezione, dopo il quale ripartono righe di
  tabella (REPO-O, REPO-P, REPO-Q) fuori dall'intestazione. Inoltre **REPO-T, REPO-X, REPO-Z**
  sono citati nel repo senza riga d'indice — cioè il rischio che l'indice era nato per chiudere
  («una sessione futura rischia di riusare una lettera già in uso») è **ancora aperto**.

---

## Proposta al canone

1. **Il testo degli hook va parametrizzato per repo, o l'adozione insegna il falso.**
   Oggi `metodo-reminder-hook.sh` inietta stringhe fisse col vocabolario GAS/BC. Proposta minima e
   verificabile: il digest cita `tools/*.py`, «clasp», `famiglie-difetti.md` **solo se quei
   percorsi esistono** nel repo che ospita l'hook (`[ -e ... ]` prima di comporre la riga);
   altrimenti resta il nucleo agnostico (esegui-non-dedurre · banco prima della correzione ·
   SAL prima del passo successivo · assente ≠ zero). Costo: 4 righe di guardia. Beneficio: lo
   standard diventa adottabile fuori dal GAS **senza mentire**.

2. **`sync-repo.sh --standard` deve installare `patterns/` insieme all'hook che lo cerca, o
   dichiarare il degrado.** Oggi si può finire (come qui) con `pattern-reminder-hook.sh` attivo e
   `patterns/` assente: il presidio risponde, ma vuoto. Coerente con `citazione-non-presidio`: un
   hook senza il suo registro è una citazione, non un presidio. Minimo: se `patterns/README.md`
   manca, il messaggio lo **dica** («registro assente: presidio degradato»), invece di suonare
   come «nessun pattern pertinente».

3. **Manca la corsia parallela nel canone** (`/ventaglio`, o una sezione di `dev-critic`).
   Il ventaglio N-lenti-in-parallelo ha prodotto qui 87 reperti in una sessione, ma tutto ciò che
   lo rende sicuro l'ho improvvisato: perimetri **disgiunti** (due corsie sugli stessi file si
   pestano), **sola lettura** obbligatoria, contratto (a)/(b)/(c) di chiusura, e la
   **verifica avversariale dei reperti dopo** la consegna delle corsie. Senza le tre sezioni
   obbligatorie un ventaglio produce un mucchio, non un report. Vale la pena scriverlo: è la
   differenza fra 7 agenti utili e 7 agenti che si contraddicono.

4. **Sei pattern nuovi**, tutti nati o confermati qui, tutti con ancora (file allegati a questa PR):
   `clone-shallow-mente-sulla-storia` · `la-riga-di-default-e-il-caso-peggiore` ·
   `oracolo-dal-sistema-vecchio` · `autorita-di-dominio-batte-oracolo` ·
   `test-che-certifica-il-bug` · `presidio-senza-consumatori`.

5. **`repos-index.md` da riparare** (REPO-Q doppio, tabella spezzata dopo REPO-CR, T/X/Z senza
   riga). Qui aggiungo solo la riga REPO-S e **non** tocco il resto: la riparazione è un lavoro
   dell'hub, non mio, e mescolarla a questo report renderebbe illeggibile il diff.
   La mappatura REPO-S → nome reale va aggiunta a `night-shift/repos.key` **da chi possiede la
   chiave**: questa sessione non può scriverci (regola dell'indice).

7. **Il gate deve distinguere «rotto» da «non giudicabile».** Oggi `.night-verify` in cloud
   fallisce per tre motivi diversi mescolati: un test rosso **vero** su HEAD
   (`tests/test-ciclo-vivo.sh`), uno strumento **assente** (`shellcheck`) e un gate
   **degradato per disegno** (`privacy-check` senza `repos.key`). Sono tre stati distinti e
   vanno separati nel verdetto finale — per esempio una riga di chiusura
   `attese eseguite: N/M · fallite: K · degradate: D · strumenti assenti: S`, che è già la forma
   che `tools/verifica_banco.py` pretende dagli altri banchi. Senza, la prima cosa che una
   sessione esterna impara è che il gate è rosso comunque, e smette di guardarlo — che è il
   contrario di un presidio (`citazione-non-presidio`).

8. **Conferma, non scoperta** — e va detto: il report REPO-N (2026-08-28, Flask/SQLite) aveva già
   concluso che «le famiglie di difetti del corpus generalizzano fra linguaggi». Questa sessione
   **conferma su un secondo linguaggio** (TypeScript/React/Prisma) e aggiunge la misura di
   *quanto*: il **metodo** e i **pattern** hanno morso su tutto; gli **agenti** e le **skill
   GAS-specifiche** (`gas-sviluppo`, `verifica-visiva`, `allineamento-fork`, `controllo-gestione`)
   e i tool Python (`gas_qualita.py`, `verifica_banco.py`) **zero**. La linea di frattura non è il
   linguaggio: è quanto una voce del canone è ancorata all'ambiente Apps Script.

---

## Appendice — i tre P0, per chi vuole il riscontro tecnico

- **Tabella di lookup interrogata senza la sua chiave di fascia.** Una mappa legacy indicizzata
  **solo sull'altezza** conteneva le altezze di **due** cataloghi con passo diverso (104,5 e
  137 mm). I valori **travasavano** fra cataloghi, in entrambi i versi. Il caso peggiore era il
  **valore di default** dell'interfaccia: al minimo dello slider una configurazione grande montava
  18 giri da 137 mm = **2466 mm** di materiale su una parete di **1929 mm** (+36%), e il flag
  «misura speciale» restava `false`, quindi l'ordine **non veniva bloccato**. Peso e volume
  alimentano il costo di trasporto, che entra **dentro** il prezzo: il difetto muoveva soldi.
  Provato con probe indipendente: giri `13 → 18 → 14 → 19 → 15` al crescere dell'altezza.
  → pattern `la-riga-di-default-e-il-caso-peggiore`.
- **Prezzo al cliente calcolato nel browser e mai persistito.** Il fattore
  (ricarico × IVA) viveva **duplicato in due componenti** del front-end e finiva stampato come
  «Totale · IVA compresa» su un **documento vincolante**, mentre il server salvava `0` e uno
  snapshot prezzo **vuoto**: nessun prezzo di record, e il totale di un documento già consegnato
  si **ri-derivava dal listino live** ad ogni riapertura. Corretto senza toccare il modello di
  prezzo (che è dominio): regola in un solo file, calcolo e **persistenza** lato server, e
  listino non risolvibile → totale **assente dichiarato**, mai `0` silenzioso.
- **Seed di demo che gira sul DB live.** Con una variabile d'ambiente attiva, l'entrypoint del
  container esegue il seed a ogni deploy: il suo ramo `update` **riporta la password admin al
  default committato** e `mustChangePassword: false`, e due update incondizionati rimettono
  l'embed a token e domini di demo. Classificato **P0 latente, non P0 confermato**: dipende da una
  env del pannello di hosting **non ispezionabile dal repo**. Primo passo dichiarato: *guardare
  il pannello, non scrivere una patch*.

**Verifica finale del target** (eseguita, non ricordata): `lint` ✅ · `typecheck` ✅ (5 progetti) ·
`test` ✅ **769/769** · `build` ✅. E il fatto di processo che spiega il resto: la CI del target è
**ferma da 5 settimane** (fatturazione del provider), **122 commit** entrati senza un solo
controllo automatico mentre l'hosting pubblica il branch principale in auto-deploy — il compenso
dichiarato dentro il file CI («lint/typecheck/test in locale prima di ogni merge») era
**falsificato dal lint rosso** già presente nel branch principale.
