# 2026-09-19 — REPO-I: adozione dello standard, 50 giri, 7 correzioni

**Autore**: sessione cloud (Claude Code, remote) — una sessione sola, a cavallo di mezzanotte.
**Mandato**, in due tempi: «installa AI_Programmer e fai almeno 50 giri accurati di verifica,
alla fine un report per AI_Programmer stesso per migliorare»; poi, a giri finiti, «fai le altre
correzioni che puoi fare» — perimetro scelto dal dominio, non da me, dopo aver chiesto invece
di indovinare (la frase aveva tre letture possibili).

**Esito**: 50 giri (33 scoperta + 17 avversariali), ~250 rilievi ancorati a `file:riga`,
7 correzioni col banco davanti, PR mergiata. **Banco: `PASS 1307 ok` → `PASS 1352 ok`,
zero attese preesistenti perse.**

> REPO-I è a indice come «controlli trimestrali di bilancio GAS+BC (97 file)».
> Misura di oggi: **110 file in `src/`, 108 `.gs`, 32.820 righe, 1.103 funzioni globali**.
> L'indice ha 13 file di ritardo — v. **P10**.

---

## Cosa ho usato

**Ha prodotto i rilievi**: `.claude/skills/gas-sviluppo/references/famiglie-difetti.md`.
Le convergenze indipendenti più forti dei 33 giri cadono tutte su famiglie già NOMINATE lì —
«il verde su un dataset mai letto», «la sentinella che dice non-so con un valore del dominio»,
«la prova che non può fallire», «un nome di cartella non è una chiave», «`Number('')` = 0».
Non è inventiva: è il catalogo che funziona, e si vede dal fatto che i giri che hanno reso
di più sono quelli che applicavano una famiglia, non quelli che guardavano in giro.

Poi: `docs/ngiri-paralleli.md` (protocollo delle due fasi, regola di consolidazione),
`patterns/` — `citazione-non-presidio`, `presidio-senza-consumatori`, `regola-provata-non-assunta`
usati come lenti dirette — i tre hook **provati eseguendoli**, e `tools/sync-repo.sh --from-local`
per la verifica finale (→ ALLINEATO).

**Voluto e NON c'era**, nella repo di destinazione dopo `--standard`: `METHOD.md`, `DEBITI.md`,
`docs/errori/REGISTRO.md`, `tools/debiti-riapertura.sh`, `tools/privacy-check.sh`,
`tests/test-errori.sh`, `docs/mappa-dominio-gas-src.md`, `docs/system.md`, e
**`docs/ngiri-paralleli.md` stesso** — il documento che descrive il lavoro che mi era stato
chiesto di fare non fa parte di ciò che l'installatore installa. L'ho letto dal clone dell'hub.

**Non raggiungibile** (terza casella, dal campo REPO-H): `gh` assente nella sessione cloud →
`--standard` non eseguibile. E il GAS vivo + BC non sono raggiungibili: **tutti i rilievi e
tutte le correzioni restano nello stato «da verificare dal vivo»**.

## Cosa ho improvvisato

1. **L'installazione a mano** — nove gruppi di copia replicati comando per comando + i tre
   hook via `copia-hook.sh`, poi `--from-local` per la verifica. Percorso che nessun documento
   descrive (**P5**).
2. **Il prompt avversariale** — prescritto nel numero (15 giri), non nella forma. È il pezzo
   che decide l'esito (**P1**).
3. **La persistenza fuori contesto** — con ~50 relazioni da 4-6k token, ognuna condensata su
   disco all'arrivo con gli ancoraggi interi. Il protocollo prescrive il fan-out ma non dice
   che **il committente non entra in un contesto**.
4. **Il criterio per fermarsi** — su un rilievo la correzione sarebbe stata meccanica se la
   mappatura dei campi BC fosse stata un oracolo. Non lo era, e la prova stava nella sua
   intestazione (**P14**).

---

## Cosa ha retto

- **Il `CLAUDE.md` dell'hub è un SUPERSET ESATTO** di quello che la repo aveva:
  `1 file changed, 159 insertions(+)`, **zero deletions**. Nessuna regola del progetto persa.
  Vale la pena dichiararlo nella documentazione dell'installatore: *l'adozione non è distruttiva*.
- **Gli hook funzionano** nella repo di destinazione, provati eseguendoli.
- **Il metodo ha accusato sé stesso due volte**: l'hook Stop ha segnalato il file lasciato
  sporco dall'hook del metodo (**H1**), e il giro che confrontava documenti e codice ha trovato
  il buco nel cancello del metodo (**H7**). Un sistema che si rompe in modo visibile funziona.
- **Il banco scritto prima ha preso due miei ATTESI sbagliati** su sette correzioni (**P12**).

## Cosa ha ostacolato

### H1 [ALTA] — l'installatore copia l'hook, non la riga che ne nasconde il residuo
`tools/metodo-reminder-hook.sh:25` scrive `$PWD/.campo-rem`. L'hub **ha** `.campo-rem` nel
proprio `.gitignore` (riga 5). `--standard` copia l'hook — via `copia-hook.sh`, che **deriva**
la lista da `settings.json`, cioè la disciplina giusta — ma non la riga che lo ignora. Ogni
repo portata a standard resta con l'albero git sporco per sempre. → **P4**

### H2 [ALTA] — lo standard installa 43 citazioni su 62 che puntano al nulla
Misurato, riproducibile dalla repo di destinazione:
```
grep -ohE '(docs|tools|tests|patterns|night-shift|llm|loops|\.claude)/[A-Za-z0-9_./-]+|\b(METHOD|DEBITI|SAL|PROJECT|FORK-STATO)\.md\b' \
  CLAUDE.md tools/*.sh .claude/skills/*/SKILL.md | sed 's/[.,:)]*$//' | sort -u \
  | while read p; do [ -e "$p" ] || echo "ASSENTE: $p"; done
```
→ **CITATI 62 · ASSENTI 43 (69%).** (Misurato due volte con regex diverse: 40/59 e 43/62 —
la proporzione è stabile al 68-69%.)

Non è prosa: sono citazioni che un agente **segue**, perché gli hook gliele ripetono. Misurato
in questa sessione: l'hook `UserPromptSubmit` mi ha ripetuto **a ogni singolo turno** «prima gli
oracoli in `tools/*.py` (`docs/mappa-dominio-gas-src.md`)» per un file che non esiste. E
`CLAUDE.md` apre col settimo patto — «i debiti aperti si contano (`bash tools/debiti-riapertura.sh`)»
— dove né lo script né `DEBITI.md` esistono.

Il caso che decide, e il motivo per cui questo è il primo rilievo:
> `CLAUDE.md` §5: «Il registro: `docs/errori/REGISTRO.md`. **La lente `tests/test-errori.sh`
> pretende che ogni guardia citata esista.**»

**La lente che pretende che le citazioni esistano è essa stessa una citazione che non esiste.**

È la famiglia che l'hub nomina in `patterns/citazione-non-presidio.md` e
`patterns/presidio-senza-consumatori.md`, ed è la regola scritta in `patterns/README.md`
(«l'ancora deve esistere, o la voce non sopravvive — lo snippet non ancorato è folklore»).
**Lo strumento che installa il metodo viola il pattern che il metodo insegna.** Il costo non
è estetico: un promemoria che cita il nulla insegna a ignorare i promemoria, e `CLAUDE.md` §3
lo dice già — *«il costo di un falso positivo è la fiducia»*. → **P3**

### H3 [MEDIA] — nessun cammino senza `gh`
`sync-repo.sh:42` usa `gh api`; `:65` e `:126` `gh repo clone`; `:119` e `:133` `gh pr create`.
`--from-local` esiste (`:13`) ma il commento lo dichiara «per i test» e confronta **solo
`CLAUDE.md`**, non lo standard intero. REPO-V c'è già passato il 2026-09-03: **seconda
ricomparsa**. → **P5**

### H4 [MEDIA] — le 9 proposte del report REPO-I del 2026-08-27: 5 recepite, 3 no, 1 contraddittoria
Verificato eseguendo, contro `docs/campo/2026-08-27-controlli-trimestrali.md`.

**Recepite**: P1 pacchetto installabile (`sync-repo.sh --standard`) · P2 workflow N giri
(`docs/ngiri-paralleli.md`) · P3 pattern `estrazione-per-testabilità` · P6 «verifica se un
meccanismo esistente la copre già» (categoria «Già coperta») · P8 pattern
`soglia-con-default-guardato`.

**Non recepite**: P4 regime «batch autorizzato» · P5 terzo stato «da verificare dal vivo» ·
P9 vincoli dei file di CI fra i controlli pre-implementazione (grep a vuoto).

Due note che valgono più dell'elenco:

- **P4 è matura per la regola dell'hub stesso.** `ngiri-paralleli.md` la registra come «PATTERN
  RICORRENTE» alla **seconda** ricomparsa (REPO-F, poi REPO-K) e dice «dichiararlo nel canone
  come terzo regime legittimo». Ma REPO-I l'aveva già proposta il 2026-08-27 (riga 115) e
  REPO-I fase 3 il 2026-08-28 (riga 97): **è la terza e la quarta ricomparsa.** Per *la regola
  delle tre ricomparse* — «non è più rinviata: è MATURA PER L'INVESTIMENTO» — il canone deve
  accoglierla. **L'hub applica la regola ai progetti e non a sé.** → **P8**
- **P5 è lo stato in cui si trovano oggi TUTTI i ~250 rilievi di questo giro**, e tutte e sette
  le correzioni. «Dal vivo» ricorre nei documenti dell'hub come prosa, mai come stato
  tracciabile. Terza ricomparsa anche questa. → **P8**
- **P7 — la contraddizione è dentro un solo file.** `ngiri-paralleli.md` dichiara una tassonomia
  a **quattro** categorie «provata su 245 casi senza eccezioni (mai una quinta necessaria)», e
  trenta righe più sotto usa **«non-ancora-matura»** come quinta categoria. → **P9**

### H5 [MEDIA] — il metodo prescrive 50 agenti e non dichiara quanto costano
`ngiri-paralleli.md` prescrive «50 agenti in DUE FASI» e «batch da 10 per limiti di concorrenza»,
e non dice il costo. **Misurato qui**: i primi 20 agenti hanno esaurito il limite di sessione a
metà del secondo batch — due agenti morti su HTTP 429, con il report già consegnato ma
terminazione sporca. Il giro completo su 32.820 righe è costato **oltre 2 milioni di token di
subagente** e circa sette ore, con un'interruzione per limite di utilizzo. → **P7**

### H7 [ALTA] — il cancello tecnico dell'hub non copre i comandi che i documenti insegnano
Verificato **eseguendo l'hook** sui quattro comandi:
```
NEGATO      npx clasp push
CONSENTITO  npm run push       →  package.json:10        →  clasp push
CONSENTITO  npm run deploy     →  scripts/deploy.sh:25   →  clasp push --force  ( + :51 clasp deploy -i )
CONSENTITO  bash scripts/deploy.sh
```
`tools/clasp-block-hook.sh:38-40` riconosce solo `npx|bunx|npm exec|pnpm dlx|yarn dlx` davanti
a `clasp`: **`npm run push` non contiene la stringa `clasp` e passa.**

Ciò che rende il difetto grave non è il buco: è la frase che il guardiano dice di sé
(`clasp-block-hook.sh:2-11`):
> «`clasp push` e `clasp deploy` vengono NEGATI davvero… è l'unica regola del sistema che da
> oggi **NON DIPENDE DALLA MEMORIA DELL'AGENTE**.»

Chi la legge smette di chiedersi se un deploy possa partire da solo. E **la via documentata è
proprio quella non presidiata**: in REPO-I, `DEPLOY.md:39` insegna `npm run push` e
`PROJECT.md:34` insegna `npm run deploy`; solo `PROJECT.md:33` usa `npx clasp push --force`,
che è **l'unica forma negata**.

**Rovescio della medaglia, misurato lo stesso giorno**: due `grep` in sola lettura sono stati
**negati** perché la loro *stringa di ricerca* conteneva la forma vietata dopo un `|` —
esattamente il falso positivo che il commento `:21-26` dà per risolto dall'ancora `SEP`.
**Il cancello è permissivo dove dovrebbe negare e restrittivo dove non dovrebbe.** → **P6**

**Nota di metodo, la più importante di questo report**: questo difetto l'ha trovato un giro che
confrontava **documenti e codice** — non uno che leggeva il cancello. La lente «l'affermazione
smentita dal codice», applicata **agli strumenti del metodo stesso**, è il giro che l'hub non
prescrive e che ha reso di più. → **P2**

---

## I due numeri che l'hub non ha ancora

### 1. Quanto rende la fase avversariale

`ngiri-paralleli.md` riporta l'esito di REPO-J (13 confermati, 2 smentiti): dice *se* la
verifica è cosmetica, non *cosa* cambia. Qui è contato su **21 affermazioni** in 17 giri:

| Esito | N |
|---|---|
| **SMENTITO in pieno** | 1 |
| **RIDIMENSIONATO** (severità o portata) | 13 |
| **CONFERMATO** | 7 |
| **AGGRAVATO** | 3 |
| **Rilievi NUOVI prodotti dalla fase B** | 3, tutti ALTA |

Il dato che conta di più non è nessuna di queste righe:

> **In 7 casi su 21 la fase avversariale ha corretto un NUMERO del rilievo**, non la sua
> sostanza. «9 mesi su 12» → **72 giorni l'anno** (fattore 2,5). «3 moduli su 13 scoperti» →
> **1 su 10**, ed *entrambi* i numeri di partenza erano sbagliati. «27.000 € mai visti» →
> **visti nell'aggregato, mai attribuiti**. «40 righe di scarto» → quarto sito non censito.

E il modo è sempre lo stesso: **eseguendo**. La mappa dei trimestri girata su tutti i 365
giorni dell'anno. Il codice di produzione caricato in un `vm` node con fixture costruite a
mano, per vedere uscire `esito: OK | valore: 0 conti` su 30 conti nuovi da 900 €. L'hook del
cancello lanciato sui comandi veri.

**Lo smentito merita una riga a sé**, perché il modo in cui è morto è il modo in cui il metodo
sbaglia: il giro di scoperta aveva letto il nome `mastrinoNumeri`, dedotto «numeri massimi», e
scritto un rilievo ALTA. È un **parser di importi**. *Il giro di scoperta ha fatto esattamente
ciò che il metodo vieta: dedurre da un nome.*

### 2. Dove stava la cura

Su 7 correzioni, **in 4 la cura era già in casa** — e sempre a distanza di lettura:

| Difetto | Gemello sano | Dove |
|---|---|---|
| cache assegnata prima della verifica | `_caricaFattureClienti` | 20 righe sotto |
| schedula letta per posizione | `_riscontiLeggiMatrice` | stesso file |
| scarti non contati (ISA 450) | `_verificaCoperturaScritturaTfr` | altro modulo, col commento che è la tesi del rilievo |
| follow-up appeso alla riga sbagliata | `_superaEsecuzioneMastrino` | modulo gemello |

→ **P13**

---

## Proposta al canone

**P1 — Il prompt avversariale entri in `ngiri-paralleli.md` come FORMA, non solo come conteggio.**
Quattro elementi, tutti necessari, misurati qui:
1. *«Il tuo compito NON è confermare: è provare a SMENTIRE»* — l'inversione esplicita.
2. *Le linee d'attacco elencate una per una*, con l'ordine in cui provarle.
3. *Quattro verdetti ammessi*: SMENTITO / RIDIMENSIONATO / CONFERMATO / AGGRAVATO. Senza
   «RIDIMENSIONATO» l'agente sceglie fra due estremi e conferma quasi sempre — 13 esiti su 21
   sono caduti lì.
4. *«SMENTITO è un esito pienamente accettabile e prezioso»*, detto a chiare lettere.

Corollario, che vale da solo: **i numeri del rilievo sono un bersaglio, non un dato.**
«Ricontali» in ogni prompt avversariale — 7 correzioni su 21 vengono da lì.

**P2 — Una lente obbligatoria: «gli strumenti del metodo, contro ciò che dicono di sé».**
H2 e H7 vengono entrambi da lì e sono i due rilievi ALTA di questo report. Il metodo prescrive
di applicare `regola-provata-non-assunta` al codice del cliente e non ai propri hook.

**P3 — `--standard` deve censire le proprie citazioni** e non stampare «GIÀ A STANDARD» finché
il 69% punta al nulla. ≈15 righe, comando già scritto sopra. Tre uscite possibili: fallire;
emettere un `CLAUDE.md` con le sezioni che citano infrastruttura assente marcate «non
disponibile in questa repo»; oppure copiare anche gli strumenti citati. Oggi non fa nessuna
delle tre.

**P4 — `copia-hook.sh` derivi anche le righe di `.gitignore`** degli artefatti che gli hook
scrivono. La lista si deriva dai path che gli hook scrivono: è la disciplina già applicata,
estesa al residuo.

**P5 — `--from-local <dir> --standard`**: copia intera + censimento P3, senza rete e senza `gh`.
Seconda ricomparsa (REPO-V, REPO-I).

**P6 — Il cancello `clasp` risolva gli script di `package.json`** (leggere `scripts` e verificare
se il target contiene `clasp`) e copra l'esecuzione diretta di uno script di deploy. Oppure, più
robusto e più coerente col metodo: **spostare il cancello da PreToolUse-sulla-stringa a un blocco
nel progetto** — uno script di deploy che rifiuta se non trova un lasciapassare esplicito.
E la sua testata smetta di promettere ciò che non mantiene, finché non lo mantiene: *una guardia
che si dichiara infallibile e non lo è costa più di una guardia assente.*

**P7 — `ngiri-paralleli.md` porti il costo di un giro** accanto al numero di agenti. Le famiglie
di difetti portano la POPOLAZIONE, i pattern portano l'ANCORA: il costo di un giro merita lo
stesso trattamento. Una riga basta.

**P8 — Il canone accolga «batch autorizzato» e «da verificare dal vivo».** Entrambe a tre
ricomparse o più. *La regola delle tre ricomparse vale anche per l'hub.*

**P9 — `ngiri-paralleli.md` sani la propria contraddizione interna**: o la tassonomia è a quattro
categorie, o «non-ancora-matura» è la quinta. Non entrambe nello stesso file.

**P10 — `repos-index.md` porti la data accanto a ogni misura.** REPO-I vi risulta di 97 file;
oggi ne ha 110. Un indice senza data invecchia in silenzio — stessa famiglia di H2.

**P11 — Il pavimento delle attese prende la RIMOZIONE, non la MANCATA AGGIUNTA.**
Ho costruito il presidio in REPO-I (`PAVIMENTO_ATTESE` + `attese eseguite: N/M` nella
riga-verdetto) e l'ho verificato col sabotaggio: tolto un gruppo, `FAIL — 1320 ok, 0 falliti`,
exit 1. Poi, **due correzioni dopo, ci sono caduto lo stesso**: un gruppo di attese nuove
veniva SALTATO in silenzio (toccava `SpreadsheetApp` attraverso una funzione di configurazione)
e la suite usciva `PASS 1328/1328`, perché il conteggio non era *sceso* — era solo non *salito*.
Il presidio che avevo appena costruito non copriva il caso in cui ero appena caduto.
**Cura minima: un gruppo nuovo che finisce fra i SALTATI va trattato come rosso al primo giro**,
o «ho scritto la prova» e «la prova gira» restano due fatti diversi che nessuno distingue.

**P12 — L'ATTESO si sbaglia, e il banco scritto prima lo prende.** Due volte su sette ho scritto
un atteso inventato invece che letto dalla fonte: `'1 su 3'` dove l'uscita vera diceva
`'su 1 dei 3'`, e un nome di campo che il costruttore dei risultati non usa. In entrambi i casi
il rosso era mio, non del codice, e l'ho corretto dalla parte giusta. È `CLAUDE.md` §3
(«l'ATTESO che dichiari è un'affermazione, e si cita come il codice») **misurata su chi la
applica**: scrivere il banco prima non evita di sbagliare l'atteso, ma costringe a scoprirlo
prima di toccare il codice — che è tutta la differenza fra correggere l'attesa e piegare il
programma.

**P13 — La scala del codice minimo dica di cercare il gemello sano per PROSSIMITÀ.**
Il gradino 2 («già nel codebase? riusalo») l'ho soddisfatto ogni volta guardando *la funzione
accanto che fa la stessa cosa bene* — 4 volte su 7, sempre nello stesso file o in quello
adiacente (tabella sopra). Cercarlo lì per primo è un ordine, non un caso.
E vale come **lente di scoperta**: dove esistono due funzioni che fanno la stessa cosa e una
sola ha la guardia, l'altra è un rilievo. Tre dei sette difetti corretti sono stati trovati
così.

**P14 — Il canone dica COME SI RICONOSCE che un documento del progetto NON è un oracolo.**
La regola «oracolo prima della formula» c'è. Manca il gradino prima. Su un rilievo la correzione
sarebbe stata meccanica se la mappatura dei campi remoti fosse stata autorevole: la prova che
non lo era stava nella sua **intestazione** — «Righe campione lette: 3», stato «da verificare
con riscontro» — due righe sopra la tabella che tutti leggono. Un documento generato per
campionamento non è un censimento, e la differenza decide se una correzione è una traduzione
o una decisione di dominio. Qui ha deciso di fermarmi, ed era la scelta giusta.

**P15 — In una pipeline `$?` è l'ultimo comando, e il canone dovrebbe dirlo dove fa danno.**
Due volte in questa sessione ho letto l'esito di un gate da `cmd | grep ...; echo $?` o
`cmd | tail; echo rc=$?` — cioè l'uscita di `grep`/`tail`, non del gate. La prima volta è
costata solo un controllo in più. La seconda stavo per **scrivere in questo report un rilievo
falso** sul gate della privacy dell'hub («si dichiara degradato ed esce 0»): rifatto come
`cmd >/dev/null 2>&1; echo $?`, l'uscita vera è **1**, il gate fa il suo lavoro.
Non è una finezza di shell: «esegui, non dedurre» dice di eseguire e non dice **quale numero
guardare**, e un gate giudicato dal codice di uscita di `tail` è un gate giudicato a caso.
Cura, una riga nel canone: *l'esito di un comando si legge dal comando, mai da una pipeline —
`cmd >/dev/null 2>&1; echo $?`, oppure `set -o pipefail`.* Il costo di sbagliarlo è un falso
positivo su un presidio, che è il costo che la fiducia non regge.

---

## I numeri di questo giro

```
giri totali                   50  (33 scoperta + 17 avversariali)
rilievi grezzi              ~250  ancorati a file:riga
affermazioni verificate       21  in fase B
  smentite in pieno            1
  ridimensionate              13
  confermate                   7
  aggravate                    3
  rilievi NUOVI dalla fase B   3  (tutti ALTA)
correzioni a un NUMERO         7  su 21
rilievi sull'hub stesso        7  (H1-H7), di cui 3 ALTA
proposte al canone            15  (P1-P15)
correzioni consegnate          7  una per commit, banco scritto PRIMA e visto rosso
  di cui con la cura in casa   4
banco                       1307 -> 1352 attese, 0 preesistenti perse
costo                       >2M token di subagente, ~7 ore, 1 interruzione per limite
```

**Tutti i rilievi E tutte le correzioni sono nello stato «da verificare dal vivo».** Nessuno è
stato validato contro il sistema vivo o il gestionale, perché non sono raggiungibili da una
sessione cloud. Dove un giro dice «eseguito» significa *codice di produzione caricato in un `vm`
node con una fixture costruita a mano*: prova forte sul comportamento, non sui dati veri.
È dichiarato qui perché non lo dichiara nessun campo di nessun registro — ed è la proposta P5
del 2026-08-27, ancora aperta tre settimane dopo.
