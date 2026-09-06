# 2026-09-06 — REPO-E: le sette risposte di dominio, e il deploy che ha misurato sé stesso

**Autore**: sessione Claude Code (remota) sul repo REPO-E, con il proprietario del dominio al
terminale per la parte di deploy. Seguito del ciclo a 20 lenti dello stesso giorno.

**Perimetro misurato**: 8 commit (7 risposte di dominio + documenti), 12 sabotaggi mirati tutti
rossi, gate del progetto da 26 a 28 controlli, rilascio in produzione della versione 78, due
gesti umani eseguiti dall'editor con i loro numeri.

---

## Cosa ho usato

- **`esegui-non-dedurre`**, fino dentro il deploy: nessuna affermazione di questo report viene da
  una lettura, tutte da un comando.
- **Banco prima della correzione**: 7 decisioni su 7 col banco scritto prima e **visto rosso**.
- **Il sabotaggio come presidio del presidio**: 12 sabotaggi mirati, ognuno verificato che
  colpisse *quella* attesa e non un'altra.
- **`assente ≠ zero`**: la famiglia che continua a rendere più di ogni altra su questo parco.
- **`scarto-mai-silenzioso`**: la forma di ogni WARNING aggiunto.
- **`clasp-block-hook`** (il cancello umano sul deploy): ha funzionato per come è disegnato — il
  rilascio l'ha eseguito il proprietario, comando per comando, e io ho potuto solo dettarli.
- **`docs/campo/README.md`**: questo formato.

**Cosa ho voluto usare e non c'era**: un modo praticabile di confrontarsi col vivo prima di
sovrascriverlo. Il runbook del progetto diceva «diff file per file»: su un delta di 9.759 righe è
illeggibile, e una procedura illeggibile si salta. L'ho improvvisato (sotto), ed è la prima
proposta.

---

## Cosa ho improvvisato

**1. Il test «il vivo è già in git».** La domanda utile prima di sovrascrivere non è «cosa è
diverso» ma «il vivo contiene qualcosa che git non ha mai visto» — binaria, e git la risponde con
`hash-object` + `cat-file -e`. Esito: **18 file su 18 già in git**, e i 12 che `diff` dichiarava
«diversi» assolti (erano la distanza fra la produzione e `main`). → `patterns/vivo-gia-in-git.md`.

**2. «Misura prima di toccare» come forma di consegna.** Due risposte su sette non erano
correzioni ma decisioni. Il canone ha il banco prima della correzione e il cancello umano, ma non
aveva un nome per il caso in cui la correzione *è* una decisione del dominio.
→ `patterns/misura-prima-di-toccare.md`.

**3. La sequenza di attivazione in tre passi**, ricostruita dai verbali di una sessione
precedente perché il runbook aveva il push ma non l'attivazione.
→ addendum a `patterns/clasp-push-non-e-produzione.md`.

---

## Cosa ha retto / ostacolato

### Ha retto

**`assente ≠ zero`, e si è pagata da sola.** La diagnostica consegnata per la domanda 6, eseguita
sul vivo su 200 articoli: i due campi contesi **sono** serviti dal sistema esterno e la richiesta
esplicita viene **accettata** (il rifiuto temuto non esiste); i casi «assente» sono **0**, quindi
il fallback cambierebbe zero cifre — ramo morto ma innocuo. E il numero che nessuno cercava: i
casi «zero vero» sono **47**. Il fix di cinque giorni prima che sostituì `||` con `??` era stato
scritto ragionando su un ramo di cui non si sapeva se fosse vivo; oggi si sa che **protegge 47
articoli reali**. Se fosse ancora `||` e qualcuno aggiungesse quel campo alla richiesta — la
"miglioria" ovvia, quella che un audit propone senza pensarci — 47 zeri veri verrebbero
rimpiazzati dal costo standard, in silenzio.

Lo strumento consegnato per rendere decidibile una domanda **ha risposto a una domanda diversa e
più utile di quella che gli era stata fatta**. Non «il fallback va acceso?» ma «il fix di cinque
giorni fa serviva a qualcosa?».

*(Limite dichiarato perché il 47 non diventi folklore: 200 su ~2581, senza ordinamento stabile —
campione, non censimento.)*

**La domanda al proprietario del dominio non sceglie fra i rimedi che hai preparato.** Su una
delle sette avevo proposto una colonna su un foglio come alternativa a un'euristica. La risposta
non ha scelto: ha mostrato che **il foglio è esattamente ciò che può essere svuotato**, quindi il
fatto doveva vivere fuori dal foglio. Il rimedio giusto è nato dalla risposta, non era fra le
opzioni.

**Il cancello umano sul deploy non è attrito.** I due errori della serata li ha intercettati il
proprietario in tempo reale. Un agente che avesse potuto pubblicare da solo li avrebbe pubblicati.

### Ha ostacolato — e tre volte su cinque l'ostacolo ero io

**(a) Comandi con commenti inline `#` incollati in zsh**, che li tratta come argomenti. Il
progetto documenta *quel* gotcha **e la sua cura**, e io l'avevo letto. Quarta ripetizione in un
solo ciclo di «una lezione scritta non è una guardia».

**(b) Un ATTESO dichiarato all'umano e preso dalla fonte sbagliata**: il titolo servito da una
webapp, letto dal tag HTML quando la fonte vera era una chiamata nel codice server che vince sul
tag. Esito innocuo — l'atteso vero era una prova migliore — ma un atteso sbagliato insegna a
diffidare dei controlli.

**(c) Un pavimento di attese scritto per previsione**: 46 quando erano 45, e il banco è uscito
NON GIUDICABILE sul proprio pavimento inventato.

**(d) Il numero di testa del report precedente non era riproducibile**: «798 attese» non tornava,
e solo per tentativi ho ricostruito la convenzione di conteggio.

**(e) `clasp-block-hook` blocca anche lo SCRIVERE di un push, non solo il farlo.** Misurato tre
volte in questa sessione: un `cat > file <<EOF` il cui *testo* conteneva la stringa del comando
proibito è stato negato, e così un `grep` che la cercava nella documentazione. Il blocco è
corretto nel verso che conta (nessun deploy è partito da qui) e non ha prodotto nessun falso
verde — ma ha imposto tre giri a vuoto per riformulare, e la cura ovvia (scrivere quei file con
uno strumento diverso da Bash) non è documentata da nessuna parte. **Non l'ho toccato**: allargare
la maglia di un hook di sicurezza per comodità mia è esattamente il tipo di modifica che va
decisa da chi possiede il sistema, non proposta da chi ne è ostacolato. È qui perché la frizione
sia visibile, non perché vada rimossa.

---

## Proposta al canone

Sette, tutte già applicate in questa PR tranne dove indicato.

1. **`patterns/vivo-gia-in-git.md`** (nuovo) — il test binario prima di sovrascrivere un vivo.
   Sostituisce «confronta col diff» come *primo* passo; il diff resta, solo sui file che il test
   dichiara `NON IN GIT`. Costo: sei righe di shell.
2. **`patterns/misura-prima-di-toccare.md`** (nuovo) — quando la correzione è una decisione del
   dominio, il deliverable è lo strumento che la rende decidibile: sola lettura, comportamento
   invariato, consegnabile senza il permesso di nessuno.
3. **`patterns/numero-col-suo-comando.md`** (nuovo) — un numero dichiarato porta il comando che
   lo produce, a partire dai numeri del canone stesso.
4. **`CLAUDE.md` §3, regola nuova** — *ciò che consegni a un umano da eseguire è codice*: niente
   commenti inline, e l'ATTESO che dichiari si cita come il codice. Le proposte 4 e 5 del report
   di REPO-E sono la stessa regola vista da due lati, ed entrano come una sola voce.
5. **Addendum a `patterns/confronto-non-vuoto.md`** — il pavimento delle attese si scrive dopo
   aver eseguito il banco, mai per previsione.
6. **Addendum a `patterns/clasp-push-non-e-produzione.md`** — la sequenza in tre passi con
   l'`N+1` letto, e la nota che `Requested entity was not found` **nomina l'entità sbagliata**.
7. **Non applicata, dichiarata**: la frizione di `clasp-block-hook` sul *testo* dei comandi (punto
   (e) qui sopra). Se e come allentarla è una decisione di chi possiede il sistema; io ho solo
   misurato il costo.

---

## Cosa resta aperto su REPO-E (lavoro, non proposte)

- Una domanda di dominio si chiude da sola coi log del primo trigger dopo il deploy: la riga che
  dichiara quale ramo della paginazione ha girato in produzione.
- Un campo scritto e mai letto (il terzo trovato su quel progetto): domanda di dominio, **non
  corretto**, dichiarato.
- La review visiva della dashboard sul vivo: uno stato nuovo del pannello salute che nessuno ha
  ancora visto a schermo.
