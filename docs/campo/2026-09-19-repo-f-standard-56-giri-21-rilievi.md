# 2026-09-19 — REPO-F: dallo standard adottato a 21 rilievi chiusi
**Autore**: sessione Claude Code remota (cloud), su mandato del proprietario del progetto.
> **PRONTO PER L'HUB.** Questo file e' gia' anonimizzato secondo CLAUDE.md §"Public repo,
> private work": nessun nome di persona, di azienda, di repo, nessun ID di file Drive o
> di libreria. Si puo' copiare in `docs/campo/` dell'hub cosi' com'e'.
>
> **Il codice REPO-F non e' stato assegnato da me, e' stato RICONOSCIUTO.** `night-shift/repos-index.md`
> descrive REPO-F come «progetto GAS/BC reale con una dashboard web (`Dashboard.html`) —
> bug reale: una funzione di backfill mai attivata da un trigger», e
> famiglie-difetti.md (references dello standard) cita REPO-F per «TEST MANUALE che scrive su produzione
> senza foglio di scratch». Questo progetto ha entrambe le cose: una funzione di backfill
> che nessun trigger chiama, e due `test*` che creavano file veri nella cartella di
> produzione. **Prima di pubblicare, conferma la corrispondenza in `night-shift/repos.key`**
> (locale, gitignored: da qui non e' leggibile). Se non corrisponde, il codice va cambiato —
> riusarne uno altrui e' il rischio che quell'indice esiste per evitare.
>
> **Il report precedente della stessa sessione** (`2026-09-18`, i 56 giri) e' scritto coi
> NOMI VERI perche' vive in una repo privata: va bonificato prima di portarlo nell'hub.
> E' esattamente l'incidente E-025 gia' registrato per un'altra repo.
**Il lavoro**: adottare lo standard AI_Programmer in un progetto GAS+BC che non lo aveva
(~200 KB di `.gs`, 115 funzioni, controllo mensile di accuratezza fatture di acquisto con
webapp), poi 56 giri di verifica, poi correggere. Esito: **21 rilievi su 21 affrontati**,
20 chiusi, 1 parziale dichiarato. Piu' 5 difetti trovati **nell'hub stesso**.
---
## Cosa ho usato
- **famiglie-difetti.md** (references dello standard installato) — e' stato *lo* strumento, e va detto con un numero:
  la lista delle famiglie con popolazione e domanda discriminante e' diventata
  letteralmente l'elenco dei 56 giri. Tre rilievi sono comparsi **identici** a quelli di
  un'altra repo del parco (valuta estera trattata come euro; `|| []` che trasforma un
  errore in array vuoto; test che non provano). La frase del canone — *«quando arrivi su
  uno stack nuovo, la prima cosa da cercare sono le famiglie GIA' pagate altrove»* — si e'
  verificata alla lettera.
- **consegna.md** (references dello standard installato) per la fase di correzione: baseline PRIMA, un rilievo per
  commit, livello di parita' dichiarato, `clasp` mai. La regola *«senza l'output di prima
  la parita' non e' dimostrabile dopo»* ha retto venti commit: alla fine `stat.normale` e
  `odata.buona` erano ancora byte per byte quelli del primo giorno.
- **Le tre lenti dello standard** — `cita-verifica.sh` ha trovato 2 citazioni morte vere
  nel documento di revisione del progetto, poi ha morso il mio stesso report, poi mi ha
  fatto scoprire che le mie correzioni avevano ucciso le mie ancore.
- **«Il guardiano si prova quando deve fallire»** — applicata a ogni lente costruita. Ha
  pagato due volte (sotto).
- **La skill `dataviz`** per i grafici riscritti: il passo 7, *«render it and look at it»*,
  ha trovato due difetti che il banco non poteva vedere.
- **Quello che ho voluto e NON c'era**: `tools/gas_qualita.py` — lo strumento dell'hub che
  misura le famiglie in modo meccanico. **`sync-repo.sh --standard` non lo copia.** Lo
  strumento che misura le famiglie non viaggia con le famiglie: 56 giri fatti a `grep` e
  lettura.
---
## Cosa ho improvvisato
1. **L'installazione stessa.** `sync-repo.sh --standard` chiama `gh`, che in cloud non
   esiste. Replicata a mano la lista di file del blocco `--standard`.
2. **gas_sintassi.py** (costruito sul posto) — il canone prescrive il controllo sintattico ESEGUITO su
   `.gs` e `<script>` inline e non lo implementa da nessuna parte. Il gotcha che costa
   dieci minuti a chiunque: `node --check` rifiuta `.gs` con `ERR_UNKNOWN_FILE_EXTENSION`,
   serve un `.js` temporaneo.
3. **Un banco di logica pura che estrae le funzioni DAL FILE VERO** (`tools/banco/`) e
   muore se un'ancora non esiste piu', invece di girare su codice fantasma.
4. **Uno strumento per la dipendenza di libreria nel manifest**, che la gestisce da un'unica
   fonte che ne conosce la forma (pin a versione / rimozione / ripristino).
---
## Cosa ha retto / ostacolato
### Ha retto
- **La sequenza domanda-discriminante → grep → lettura del PRODUTTORE → verdetto** ha
  impedito 18 falsi positivi su 38 famiglie provate. Il canone e' tarato bene: quasi ogni
  famiglia aveva una forma legittima che somigliava al difetto.
- **«La regola del produttore batte la maggioranza dei consumatori»** ha trasformato un
  rilievo che sembrava stilistico in un difetto vero: la classificazione dei fornitori
  decideva l'appartenenza alla whitelist **per codice**, e il calcolo dell'accuratezza
  leggeva quella stessa lista **per nome**. Due meta' dello stesso calcolo, due chiavi.
  Misurato: sullo stesso caso, vecchio 50%, nuovo 75%.
- **«Il grep del frontend prima di privatizzare»** ha trasformato «69 globali esposte» in
  una correzione monotona restrittiva di **una sola** funzione — quella che consegnava il
  token dell'ERP. Le altre 68 sono il toolkit che l'operatore lancia dall'editor, e
  privatizzarle in massa sarebbe stato l'esito peggiore di entrambe le alternative,
  esattamente come il canone avverte.
- **«Distingui i difetti del sistema dagli errori dei tuoi appunti»** — ho sbagliato tre
  volte e le tre sono annotate come mie, non come difetti dell'hub.
### Ha ostacolato
- **Lo standard non e' installabile per intero da una sessione cloud in auto mode.** I due
  pilastri che *sono* il metodo — il `CLAUDE.md` dell'hub e il `settings.json` con gli hook
  — sono esattamente cio' che il classificatore di sicurezza blocca come auto-modifica.
  Skill, agenti, pattern, lenti e hook-script passano; le regole e i cancelli no.
- **Falsi rossi il giorno zero**: appena installato, `cita-verifica.sh` dava 10 rossi sui
  file **dello standard appena copiato**.
---
## Proposta al canone
### 1. «Non mitigabile» non vuol dire «non correggibile» — famiglia di ragionamento
Avevo archiviato un rilievo (CDN di terze parti senza `integrity`) come **non
correggibile**, e la motivazione era solida: quel loader carica altro codice a runtime, e'
documentato come incompatibile con SRI, e appuntarne l'impronta lo romperebbe al primo
aggiornamento a monte. Tutto vero — **e irrilevante**, perche' riguardava solo la
*mitigazione standard*. La domanda che non mi ero fatto e': **la dipendenza e'
necessaria?** Non lo era: i due grafici avevano una serie sola e riscriverli in SVG inline
era lavoro limitato. Ora la pagina non esce verso nessuno.
Vale come **famiglia di ragionamento** per il registro degli errori: *quando la cura
standard di un rilievo e' bloccata, prima di dichiararlo chiuso verifica se la COSA da
curare sia essa stessa opzionale.* Il difetto non era nella mia analisi tecnica: era
nell'aver scambiato «la strada che conosco e' chiusa» per «non c'e' strada».
Lo stesso schema ha poi chiuso altri due rilievi: la libreria esterna che portava
`developmentMode: true` **e** la configurazione manifest-libreria-in-progetto-con-webapp e'
stata **disinstallata** invece che pinnata. Dava logging esterno e in cambio portava due
difetti: il conto non tornava. Domanda generale, buona per il decision tree:
*questa dipendenza sta pagando il suo affitto?*
### 2. Il terzo stato fra «corretto» e «bloccato»: RENDERE VISIBILE
Quattro rilievi erano bloccati sulla stessa cosa — una risposta di dominio che la sessione
non poteva dare senza indovinare. Il canone oggi conosce «corretto» e «da verificare dal
vivo», ma non la mossa che li ha chiusi tutti e quattro, che e' una sola e si ripete:
| Rilievo | Cosa NON ho deciso | Cosa ho reso visibile |
|---|---|---|
| Valuta mai gestita | il tasso, la valuta documento vs locale | due importi in valute diverse non si sottraggono: finiscono in un bucket dichiarato |
| `\|\| 0` sugli importi | se uno zero da ERP sia legittimo | «non letto» diventa `null`, distinto dallo zero contabile vero |
| Nessuna guardia sui 6 minuti | il p95, che non esiste ancora | si misura per fase e si avvisa sopra soglia, **senza tagliare** |
| Libreria in `developmentMode` | il numero di versione pubblicata | un'impronta della libreria confrontata a ogni run, che spara quando cambia |
La regola: **quando un rilievo e' bloccato su un dato di dominio, la cura non e' aspettare
ne' indovinare — e' rendere l'ignoto visibile invece di lasciarlo passare per noto.** Uno
zero che vuol dire «non lo so» non si vede, perche' zero e' un valore legittimo: il lavoro
dell'agente e' togliergli il travestimento, non scegliere al posto del padrone del dominio.
Proposta concreta: una casella **«RESO VISIBILE»** accanto a «corretto» / «da verificare
dal vivo» / «non raggiungibile», col campo obbligatorio *«la domanda che resta, e a chi»*.
### 3. Conta le RISORSE, non i siti di chiamata
Un rilievo diceva «il lock sta sull'entrypoint, 43 siti di scrittura non lo prendono».
Quel 43 era il numero dei *consumatori*, non del rischio: il censimento ha mostrato **due**
risorse davvero contese (un foglio di configurazione persistente e uno storico), perche' il
terzo foglio scritto e' **creato nuovo a ogni esecuzione** e non e' conteso da nessuno.
Un rilievo di concorrenza va misurato sulle risorse condivise, o il suo numero spaventa
senza informare — e porta a un refactor di 43 punti dove ne bastano 9.
### 4. Il lock rientrante e' una trappola specifica di GAS, e va scritta
Aggiungere un lock sulla risorsa a un progetto che ha gia' un lock sull'entrypoint **non e'
additivo**. In Apps Script il lock appartiene all'ESECUZIONE: il `tryLock` annidato riesce,
e il `finally` interno rilascia cio' che l'esterno crede ancora di avere. Servono due cose,
entrambe non ovvie:
1. un **contatore di profondita'**, perche' a rilasciare sia solo l'uscita piu' esterna;
2. instradare nel contatore **anche il lock a mano preesistente** — lasciarlo creerebbe due
   lock diversi e il problema tornerebbe dalla porta di servizio.
Terza cosa, che ho quasi sbagliato: il lock nuovo **solleva** quando la risorsa e'
occupata, mentre il vecchio **saltava in silenzio**. Su un trigger mensile che puo'
collidere con un run manuale, farne una mail d'errore insegna a ignorare le mail d'errore.
La parita' va preservata anche sul comportamento in caso di contesa, non solo sul successo.
### 5. Un banco verde sul codice NON corretto: successo davvero, due volte
Il canone ha «il guardiano si prova quando deve fallire». Aggiungo le due forme concrete in
cui mi e' successo in un giorno solo, perche' sono entrambe insidiose:
- **Il banco DOM era VERDE sulla pagina vulnerabile al primo tentativo.** Due cause:
  `addInitScript` di Playwright non gira con `page.setContent` (serve una navigazione vera,
  quindi `page.route` su un'origine finta), e la pagina caricava davvero il loader esterno,
  che sovrascriveva lo stub. Un banco che non ha nemmeno *esercitato* il percorso dice
  «non bucato» per il motivo sbagliato: e' il «successo su risultato vuoto» travestito.
  Da qui una guardia nel banco stesso: **se la tabella non ha reso nessuna riga, esci 2**,
  non 0.
- **La baseline mentiva sul difetto che doveva provare**: `JSON.stringify(NaN)` vale
  `null`. L'artefatto di parita' stampava `null` dove il codice produceva `NaN` — cioe'
  proprio il valore del rilievo piu' grave. Regola: **un artefatto che serializza va
  controllato per i valori che serializzano in qualcos'altro** (`NaN`, `Infinity`,
  `undefined`, le date).
### 6. Il tuo stesso fix uccide le tue stesse ancore
Dopo le correzioni, `cita-verifica.sh` e' passato da 12 a **17** rossi: le righe si erano
spostate e il documento dei rilievi citava il vecchio albero. Due conseguenze per il canone:
- **Il riferimento durevole e' il commit, non il numero di riga.** Un registro di rilievi
  vuole una tabella rilievo → stato → commit, in testa, e una riga che dica che le ancore
  nel corpo si riferiscono all'albero PRIMA dei fix.
- **Una citazione morta non deve conservare la FORMA di un'ancora viva.** Due riferimenti
  puntavano a righe di un file che non esisteva piu' da un refactor: non li ho riscritti con
  numeri nuovi (il codice citato non esiste piu' da nessuna parte, un numero nuovo sarebbe
  un bersaglio inventato) — li ho tolti dalla forma `file:riga` e messi in prosa. Un numero
  scritto come ancora invita ad andarci a guardare.
### 7. I cinque difetti dell'hub (dal report del 18/09), e uno ora MISURATO
Il report precedente ne proponeva sette. Su uno posso ora portare il numero invece della
proposta:
- **`--standard` copia la lente `cita-verifica.sh` e NON copia `tools/.file-del-target`**,
  la sua lista di esclusioni. Misurato all'adozione: **10 rossi il giorno zero**, tutti su
  file dell'hub citati dalle skill e dai pattern appena installati. Ho applicato la cura
  localmente — creato quel file nel progetto — e la lente e' passata da **17 rossi a 0**.
  La proposta non e' piu' un'ipotesi: e' una riga da aggiungere al ciclo delle lenti.
- **`--standard` non crea MAI `.night-verify`**: il blocco vive dentro il ramo «non e'
  cambiato niente» (quindi l'adozione vera lo salta) e nel ramo raggiungibile scriverebbe
  in `"$DEST/.night-verify"` con `DEST` vuoto, cioe' nella radice del filesystem. Il
  commento sopra quel blocco cita il report dal campo che lo chiedeva: **la correzione e'
  stata scritta e non ha mai girato.**
- **`fixture-provenienza.sh` si accusa da sola**: `find -name 'fixture-*'` cattura
  `tools/fixture-provenienza.sh`. In qualunque repo che adotta lo standard stampa
  «1 fixture su 1 senza provenienza» ed esce 1, senza che esista una sola fixture.
- **`cita-verifica.sh` senza argomenti esce 0 in silenzio** — «successo su risultato
  vuoto», una delle sette prove-che-non-provano, dentro una lente del canone. Ci sono
  cascato al primo colpo.
- **Manca la casella «adozione PARZIALE»**: qui skill, agenti, pattern e lenti sono
  arrivati, regole e hook no, e nessun comando risponde dall'interno alla domanda «questa
  repo e' a standard?». `tools/garante-standard.sh` esiste nell'hub e **`--standard` non lo
  copia**: dovrebbe viaggiare ed essere una riga di `.night-verify` nella destinazione.
### 8. Nota di merito, che non e' una proposta
Il progetto ha retto su **18 famiglie su 38** provate: paginazione OData, fuso orario,
`toISOString`, cache del token con `expires_in`, `Invalid Date`, quota email, upsert per
identita', formattazione fantasma, bucket che partizionano. Diverse portano in commento
**il perche'** della scelta.
Lo dico perche' i report dal campo tendono a registrare solo cio' che si rompe, e una
popolazione di soli difetti tara male il canone: le famiglie vanno pesate anche su quante
volte NON scattano.
---
## I numeri, per chi tara il metodo
| | |
|---|---|
| Giri di verifica | 56 |
| Rilievi trovati / affrontati / chiusi | 21 / 21 / 20 (1 parziale dichiarato) |
| Ipotesi confutate eseguendo | 18 |
| Famiglie provate / scattate | 38 / 20 |
| Apparato di verifica prima → dopo | 0 cancelli → 4 (sintassi+sabotaggio, logica pura, DOM, citazioni) |
| `test*` che potevano fallire | 0 su 9 → 3 su 9 |
| Funzioni globali esposte come endpoint | 69 → 68 (quella che consegnava il token) |
| Script di terze parti nella webapp | 1 → 0 |
| Citazioni `file:riga` rotte | 17 → 0 |
| Difetti trovati NELL'HUB | 5 |
## Cosa resta al proprietario del progetto
Nessuna di queste e' codice: il `clasp push` (cancello umano mai attraversato), la storia
di git da cui togliere un file di credenziali (distruttivo, va coordinato), la conferma dal
vivo che la webapp risponda ora da sessione autenticata, e gli attesi di valore per 6 test
su 9 — che sono conoscenza di dominio, e fingerli sarebbe peggio di non averli.
