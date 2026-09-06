# 2026-09-06 — REPO-E: le sette risposte di dominio, e il deploy della v78

**Autore**: sessione Claude Code (remota), branch `claude/ai-programmer-quality-checks-01r90t`.
Seguito diretto di `2026-09-06-repo-e-audit-20-lenti.md`: quello racconta i venti giri, questo la coda
— le sette domande che erano rimaste aperte, il rilascio in produzione, e cosa il metodo
dovrebbe portarsi via.

**Perimetro misurato**: 8 commit (7 risposte + i documenti), 12 sabotaggi mirati tutti rossi,
gate da 26 a 28 controlli, deploy **v78** sulla URL storica, due gesti umani eseguiti
dall'editor con i loro numeri.

---

## Cosa ho usato

- **`esegui-non-dedurre`** — a ogni passo, incluso il deploy: nessuna delle affermazioni di
  questo report viene da una lettura, tutte da un comando.
- **`banco prima della correzione`** — 7 decisioni su 7 hanno avuto il banco scritto prima e
  **visto rosso** prima della correzione (`banco-festivita-origine.js` a 7 FAIL, BC-6 a 3 FAIL,
  BC-7 con la funzione inesistente, il controllo 23 a 33/31).
- **Il sabotaggio come presidio del presidio** — 12 sabotaggi mirati nella fase delle risposte,
  tutti rossi sulla loro attesa, ognuno verificato che colpisse *quella* attesa e non un'altra.
- **`assente ≠ zero`** — la famiglia che continua a rendere più di ogni altra su questo parco
  (vedi «cosa ha retto»).
- **`scarto mai silenzioso`** — la forma di ogni WARNING aggiunto (registro illeggibile, tab non
  migrato, `$select` rifiutato da BC).
- **Il cancello umano su `clasp`** — negato tecnicamente alla sessione. Ha funzionato: il deploy
  l'ha fatto Luca, comando per comando, e io ho potuto solo dettarli.
- **`docs/campo/README.md`** — questo formato.

**Cosa ho voluto usare e non c'era**: un modo praticabile di *confrontarsi col vivo* prima del
push. `SAL.md` §13.4 dice «diff file per file»: su un delta di 9.759 righe è illeggibile, e una
procedura illeggibile si salta. L'ho improvvisata (sotto).

**NON RAGGIUNGIBILE**: il repo `AI_Programmer` non è nello scope GitHub di questa sessione —
questo report vive qui e va portato là a mano. Lo dichiaro perché pesa: le proposte qui sotto
non entrano nel canone da sole.

---

## Cosa ho improvvisato

### 1. Il test «il vivo è già in git», al posto del diff

Il metodo dice *il vivo è definitivo, si legge, non si immagina*. Ma la domanda operativa prima
di un push non è «cosa è diverso» — su un delta grande la risposta è un muro di righe — bensì
**«il vivo contiene qualcosa che git non ha mai visto?»**. Quella è binaria, e git sa
risponderla senza leggere niente:

```bash
clasp pull
for f in *.js Dashboard.html BCInvestigationDialog.html appsscript.json; do
  h=$(git hash-object "$f")
  git cat-file -e "$h" 2>/dev/null && echo "GIA IN GIT:  $f" || echo "NON IN GIT:  $f"
done
```

`hash-object` calcola lo sha del contenuto scaricato, `cat-file -e` dice se quell'oggetto esiste
nel database del repo. Se esiste, quel contenuto è stato committato: il vivo non ha nulla di non
versionato. Se non esiste, **quel file ha dentro qualcosa che nessuno ha mai messo in git**, e il
push lo cancellerebbe in silenzio.

Esito di questa sessione: **18 file su 18 `GIA IN GIT`**. Il «leggi il vivo prima di scriverci»
ha smesso di essere una regola ed è diventato un numero — e nel farlo ha assolto anche i 12 file
che `diff` dichiarava «diversi» (erano la distanza fra la v77 e `main`, non una deriva).

### 2. «Misura prima di toccare» come forma di consegna

Due risposte su sette (la 6 e la 7) non erano correzioni: erano **decisioni**. Il canone ha il
banco prima della correzione e il cancello umano, ma non ha un nome per il caso in cui la
correzione *è* una decisione del proprietario del dominio. Ho consegnato, per entrambe, codice
che non cambia una virgola del comportamento e fa **dire** al sistema ciò che già fa:

- una riga di log che dichiara con quale dei due rami la paginazione BC ha chiuso la sequenza —
  e dichiara anche quando *nessuno dei due* è stato esercitato, invece di inventare una risposta;
- una diagnostica di sola lettura che chiede a BC se quei campi esistono e conta i casi che
  cambierebbero cifra.

Il punto che la rende una proposta e non un aneddoto: **quello strumento è consegnabile subito e
non richiede il permesso di nessuno**, perché non tocca il comportamento. La domanda resta del
proprietario; la sua decidibilità no.

### 3. Il runbook di deploy con la sequenza non invertibile

`SAL.md` §13 aveva il push ma non l'attivazione. La sequenza che funziona, e che ho dovuto
ricostruire dai verbali del 2026-09-02:

```
list-versions          leggi N (non assumerlo)
create-version "..."   crea N+1, e leggi il numero che stampa
update-deployment -V <N+1> <ID-produzione>
```

---

## Cosa ha retto / ostacolato

### Ha retto

**`assente ≠ zero` è la lente più redditizia di questo parco, e oggi si è pagata da sola.** La
diagnostica della domanda 6, eseguita sul vivo: `Standard_Cost` e `Blocked` **sono** serviti da
BC, il `$select` esplicito viene **accettato** (il 400 temuto non esiste), e `Unit_Cost` assente
è **0** — il fallback cambierebbe zero valorizzazioni. Ma il numero che nessuno cercava è l'altro:
**`Unit_Cost` zero su 47 articoli**. Il fix del 2026-09-01 che sostituì `||` con `??` era stato
fatto ragionando su un ramo di cui non si sapeva se fosse vivo; oggi si sa che **protegge 47
articoli reali**. Se fosse ancora `||` e qualcuno mettesse `Standard_Cost` nel `$select` — la
"miglioria" ovvia, quella che un audit propone senza pensarci — quei 47 zeri veri verrebbero
rimpiazzati dal costo standard, in silenzio.

Lo strumento consegnato per rendere decidibile una domanda **ha risposto a una domanda diversa e
più utile di quella che gli era stata fatta**. Non «il fallback va acceso?» ma «il fix di cinque
giorni fa serviva a qualcosa?».

*(Limite dichiarato, perché il 47 non diventi folklore: campione di 200 su ~2581 articoli, e
senza `$orderby` sono i primi che BC restituisce, non un campione casuale.)*

**La domanda al proprietario del dominio non sceglie fra i rimedi che hai preparato.** Sulla
domanda 4 avevo proposto una colonna `Origine` sul tab come alternativa all'euristica. La
risposta — «sì, un anno in cui si lavora a tutte e dodici capita» — non ha scelto: ha mostrato
che **il tab è esattamente ciò che può essere svuotato**, quindi il fatto doveva vivere fuori dal
tab (registro nelle Script Properties). La colonna è rimasta, ma per un altro mestiere: non serve
al codice, serve a chi apre il foglio fra due anni.

**Il cancello umano su `clasp` non è attrito.** Il deploy è stato eseguito da chi possiede il
sistema, con me che dettavo; e i due errori della serata (sotto) sono stati intercettati da lui
in tempo reale. Un agente che avesse potuto pubblicare da solo li avrebbe pubblicati.

### Ha ostacolato — e tre volte l'ostacolo ero io

**(a) Ho incollato comandi con i commenti inline `#`, e zsh li ha trattati come argomenti.**
`SAL.md` §13.0 documenta *questo esatto gotcha e la sua cura* (`setopt interactive_comments`).
È la quarta ripetizione in questo ciclo di «una lezione scritta non è una guardia» — stavolta su
una lezione scritta **nel progetto su cui stavo lavorando**, che avevo letto.

**(b) Ho dichiarato all'umano un ATTESO preso dalla fonte sbagliata.** Gli ho detto di aspettarsi
il titolo `Dashboard Magazzino`, letto dal `<title>` di `Dashboard.html:7`. Il titolo servito è
`Dashboard Magazzino — [titolo col nome del gruppo]`, che viene da `setTitle()` in
`WebAppDashboard.gs:38` e vince sul tag. Esito innocuo — anzi, l'atteso vero era una prova
*migliore*, perché dimostra che gira il `.gs`. Ma un atteso sbagliato insegna a diffidare dei
controlli, ed è esattamente ciò che un gate non può permettersi.

**(c) Ho scritto un pavimento di attese per previsione invece che per misura.**
`ATTESE_MINIME = 46` quando erano 45: il banco è uscito `NON GIUDICABILE` (exit 2) sul proprio
pavimento inventato.

**(d) Il numero di testa del report precedente non era riproducibile.** «798 attese» non
tornava: ricontando ne trovavo 689. Solo per tentativi ho ricostruito la convenzione (righe di
verdetto + 93 di `banco-override`, che stampa in un altro formato + i 16 `.gs`). Il report
predica, per le dimensioni, *«citare il COMANDO che le misura, invece del risultato di ieri»* —
e non lo applicava al proprio numero principale.

**(e) Un errore mio del giorno prima, corretto oggi.** Il report di campo del 2026-09-03
elencava fra i gesti umani due diagnostiche «dall'editor» che **nessuno poteva eseguire** (il
trattino finale le nasconde anche al menu a tendina). Annotato in calce a quel report come errore
delle *nostre note*, non difetto del sistema — la distinzione che il canone chiede di non
confondere, applicata a sé stessi.

---

## Proposta al canone

1. **`patterns/vivo-gia-in-git.md`** — il test binario del §1 di «cosa ho improvvisato», ancorato
   a questa sessione (18/18). Sostituisce «confronta col vivo con un diff» come *primo* passo:
   il diff resta, ma solo sui file che il test dichiara `NON IN GIT`. Costo: sei righe di shell.
   Motivo: una procedura illeggibile viene saltata, e saltarla significa cancellare in silenzio
   il lavoro di chi ha toccato l'editor.

2. **Nominare la consegna «misura prima di toccare».** Quando la correzione è una decisione del
   dominio e non un fix, il deliverable non è né il fix né l'attesa: è **lo strumento che rende
   la domanda decidibile** — sola lettura, comportamento invariato, consegnabile subito senza il
   permesso di nessuno. Due casi su sette in questa sessione, e uno dei due ha prodotto il dato
   più utile della giornata (il 47).

3. **Un numero dichiarato porta il comando che lo produce — a partire dai numeri del canone
   stesso.** La regola c'è già per le dimensioni; va estesa senza eccezioni ai numeri di testa
   dei report e dei gate. In questo repo: `bash .night-verify | grep -oE 'attese eseguite: +[0-9]+'`
   più le due voci fuori formato, scritto accanto al numero.

4. **I blocchi di comandi consegnati a un terminale umano non portano commenti inline.** Regola
   meccanica, costo zero, e chiude una famiglia (zsh senza `interactive_comments`) che ha già
   morso. Corollario: quando la cura è documentata nel progetto, si consegna *prima* la cura
   (`setopt interactive_comments`), non dopo l'errore.

5. **L'ATTESO che dichiari a un umano è un'affermazione, e si cita come il codice.** «Aspettati
   X» va accompagnato da `file:riga` della fonte, o non va scritto. Un atteso sbagliato non è un
   dettaglio di stile: è un controllo che insegna a essere ignorato.

6. **Il pavimento delle attese si scrive dopo aver eseguito il banco.** Mai per previsione. È il
   caso degenere di «done means proven»: anche il numero che presidia le prove è una prova.

7. **Runbook: `list-versions` → `create-version` → `update-deployment`, con l'`N+1` letto.** E
   una nota sull'errore: saltare `create-version` fa rispondere `Requested entity was not found`
   — un messaggio che **nomina l'entità sbagliata**. Suona come «il deployment non esiste», e la
   mossa naturale è dubitare dell'ID, cioè dell'unica cosa che era giusta.

---

## Cosa resta aperto (non proposte: lavoro)

- **La domanda 7** si chiude da sola coi log del primo trigger dopo il deploy: la riga
  `INFO: /ItemLedgerEntries: N righe in M pagine, via …` dirà se il ramo `$skip` senza `$orderby`
  gira in produzione o non è mai stato esercitato.
- **`metadata.blocked`** è scritto in `InventoryModels.gs:80` e non letto da nessuna parte
  (grep su tutti i `.gs` e `Dashboard.html`): terzo campo scritto-e-mai-letto dopo
  `generalCostsPercent`. Domanda di dominio, non fix sicuro — **non corretto**, dichiarato.
- **La review visiva** della dashboard sul vivo: lo stato `ILLEGGIBILE` (ambra) del pannello
  salute non l'ha ancora visto nessuno a schermo.
- **30 guardie difensive non presidiate** (`tools/setaccio-guardie.sh`), col limite già
  dichiarato: il numero è un pavimento del debito, non un conteggio.
