# 2026-09-25 — i rinviati del sesto ventaglio e l'apertura del settimo (hub AI_Programmer)
**Autore**: sessione cloud di Claude Code, stesso mandato notturno di Luca. Seguito di `docs/campo/2026-09-24-notte-dei-giri.md`.

## Cosa ho usato
- La skill `n-giri` (brief `docs/giri/2026-09-25-settimo/00-BRIEF.md`, cinque giri in un clone ciascuno, in corso).
- Banco rosso prima e sabotaggio rosso dopo per ogni cura. Una misura nuova: tutta la suite da un clone dell'hub
  con spazio e apice nel percorso e un `TMPDIR` ostile (188/188 dopo le cure; cadevano otto banchi).

## Cosa ho improvvisato
- Il censimento «ogni banco da solo, senza fermarsi al primo rosso» è uno script di scratchpad, non uno strumento
  dell'hub: `tools/suite.sh` si ferma al primo rosso. Rifarlo ogni notte costa una seconda suite intera, e il tempo
  della notte è di Luca: resta a mano.

## Cosa ha retto / ostacolato
- Ha retto il pre-commit. Bloccando la mia riga del SAL, che citava «-n.md» come esempio, ha scoperto un secondo
  difetto: `grep` senza `--` nel controllo delle citazioni. Il cancello ha morso proprio fra scrivere e committare
  (quinto patto).
- Ha ostacolato me: una nota del SAL diceva «muto con rc 0» di un banco che la suite avrebbe preso. L'ho corretta
  come errore mio, non del sistema. Guardando meglio è venuto fuori il difetto vero: `gate_banchi` non aveva la
  regola della suite.

## Proposta al canone
- CLAUDE.md §2 «Respect existing patterns»: quando la stessa regola vive in due giudici (suite e gate del fixer),
  una delle due copie diverge. Proposta: una regola, una funzione, citata da entrambi. Non applicata: la lente V1
  del settimo ventaglio la sta misurando.

## Aggiornamento (2026-09-25, settimo ventaglio chiuso, fino alle 05Z)
- Usato: cinque lenti (due giudici, il codice d'uscita, il calendario, la codifica, il budget). Consolidamento in
  `docs/giri/2026-09-25-settimo/99-CONSOLIDAMENTO.md`: 29 rilievi, 26 curati (2 in parte), 3 rinviati, 11 domande di
  dominio nuove in DEBITI. Un mio errore nel REGISTRO (E-049, con guardia).
- Ha retto: le guardie di stanotte hanno morso le mie prime stesure nella stessa notte. La sonda dei caratteri non
  ASCII ha preso tre mie righe nuove, il pre-commit un mio letterale di banco. La lettura del verdetto invece dell'rc
  ha fatto emergere un attacco (A20) che non aveva mai visto niente.
- Ha ostacolato: la suite di consegna gira con l'albero sporco, e lì la batteria delle mutazioni si ferma per disegno.
  Le mie consegne non l'hanno mai eseguita: l'ho provata a parte in un clone. Anche una mia misura del budget ne è
  stata falsata, ed è rifatta in un clone pulito.
- Proposte al canone (non applicate):
  - CLAUDE.md §4: il tipo di commit `perf` non c'è, e l'ho usato (`7e426c9`). O la lista si allarga, o il pre-commit
    rifiuta un tipo che non è nella lista: oggi nessuno lo controlla.
  - CLAUDE.md §2 «Respect existing patterns», già proposta sopra: una regola applicata da due giudici vive in una
    funzione sola. Stanotte cinque casi (consolidamento, tema 1).

## Aggiornamento (2026-09-25, ottavo ventaglio chiuso)
- Usato: cinque lenti nuove. Due trattano come avversari il modello e GitHub; le altre guardano la crescita, le
  versioni degli strumenti e le azioni esterne ripetute. Consolidamento in
  `docs/giri/2026-09-25-ottavo/99-CONSOLIDAMENTO.md`: 29 rilievi, 20 curati, 1 già coperto, 8 rinviati, 11 domande
  nuove in DEBITI. A fine ventaglio ho rifatto in un worktree pulito i sabotaggi delle ultime nove cure: tutti rossi.
- Ha retto: il gh vero a rete chiusa come oracolo delle forme. Arriva all'errore di rete solo se i flag sono giusti, e
  ha smascherato tre strumenti che non avevano mai funzionato con la suite verde (O4 R1, R2, R3).
- Ha ostacolato: il gh finto dei banchi era più indulgente del vero, e accettava flag che il vero rifiuta. Poi i miei
  soliti scivoloni: quattro `$NOME` davanti a «», presi dalla sonda. E una cura (O3 R4) scritta prima del banco,
  rimediata subito dopo e dichiarata.
- Proposte al canone (non applicate):
  - CLAUDE.md §1 «Goal-driven execution»: un finto di un comando esterno è severo almeno quanto il vero. Rifiuta i flag
    che il vero rifiuta, o il banco prova solo il finto. Oggi il finto del bootstrap lo fa; gli altri no.
  - Un banco che passa ogni forma di `gh` usata dall'hub al gh vero, a rete chiusa (O4, tema trasversale). Quello che
    oggi ho fatto a mano per tre forme diventa una sonda.
  - CLAUDE.md §3 «Report problems immediately»: una lettura esterna fallita non vale «vuoto». Una sentinella per «non
    so», e la scrittura che ne dipende si salta (tema 1 del consolidamento, sette casi da tre lenti).
