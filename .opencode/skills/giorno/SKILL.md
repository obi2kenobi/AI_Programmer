---
name: giorno
description: L'harness del GIORNO — chi programma con AI_Programmer di giorno consegna attraverso gli stessi cancelli della notte. Comandi: tools/giorno.sh consegna (working tree → ramo giorno/* → cancello segreti → push → PR → lente sicurezza automatica), lente (il rapporto su un diff senza consegnare), parere (il censore giudica una PR: parere, mai fusione), bilancino (il conto del giorno per repo). Usalo SEMPRE prima di aprire una PR a mano di giorno: la consegna a mano bypassa il cancello dei segreti e la lente. LLM-agnostic: bash + il modello del turno.
---

# giorno — il turno di chi programma alla luce

La notte ha il suo turno con i cancelli; il giorno aveva solo la buona volontà.
Da ora la consegna del giorno passa dalla stessa pipeline (`night-shift/lib.sh` —
le funzioni sono UNA copia sola): lente sicurezza, forme di segreto prima del
push, file nuovi solo se dichiarati, trailer del turno, commento lente sulla PR.

## I comandi (tutti da runnare dalla radice dell'hub o con percorsi assoluti)

```
tools/giorno.sh consegna <dir-repo> "messaggio della consegna"
tools/giorno.sh lente <dir-repo> [base]        # default: origin/<default>...HEAD
tools/giorno.sh parere <dir-repo> <n-pr>       # il censore, a comando
tools/giorno.sh annota <dir-repo> <n-pr>       # righe errorformat → annotazioni SULLA RIGA della PR
tools/giorno.sh bilancino [data]               # default: oggi
```

## consegna — quando e come

- Quando: il lavoro del giorno è pronto (working tree sporco di modifiche volute).
- Cosa fa: ramo `giorno/<ts>` (mai commit sul ramo di partenza), i file NUOVI
  non dichiarati restano FUORI dal commit (spostati in `.git/consegna-fuori/` —
  dichiarali come argomento se sono della consegna), commit col trailer
  `Turno: giorno`, cancello dei segreti, push, PR bozza, commento della lente.
- Se il cancello boccia: commit sciolto con reset SOFT — il lavoro resta
  nell'albero (quello di una persona non si distrugge; diversamente dalla notte,
  dove il lavoro lo rigenera il modello). Sistemare e rilanciare.
- La fusione resta UMANA: il censore si consulta (`parere`) ma non fonde mai (D10).

## lente — prima di consegnare, se vuoi vedere

Il rapporto completo (strato 1 deterministico + cervello) sul diff corrente.
Uscita 0 PULITA · 1 RILIEVI · 2 DEGRADATA. `LENTE_STUB` passa attraverso (test).

## parere — il secondo occhio

Il censore (revisore) guarda la PR e lascia il suo parere coi motivi. Da usare
quando una PR del giorno o della notte merita un giudizio prima del merge.

## osserva — il ciclo stretto (salvi, il banco riparte)

`giorno.sh osserva <dir> [comando]` (furto da watchexec/entr): a ogni modifica
del repo gira il suo `.night-verify` (o il comando che dici). Ctrl-C per uscire.
Senza watchexec: skip dichiarato.

## l'ergonomia della macchina (installata, LLM-agnostic)

- `gh dash` — il cruscotto PR/issue del parco (colonne Notte/Giorno/Handoff).
- `git df` — difftastic: diff SINTATTICO (alberi, non righe). Opt-in: `git diff`
  resta testuale perche' gli script lo parsano — mai diff.external.
- `git absorb --and-rebase` — le correzioni della review si assorbono nei commit
  giusti: stadi i fix, lui li piega nei commit che li hanno introdotti.
- `vale` — la lente documenti (regola AsciiSolo di casa).

## bilancino — il giorno misurato

Ogni azione scrive una riga in `~/giorno.log`; il bilancino le conta per repo.
Il digest del mattino riporta «GIORNO DI IERI» dallo stesso log: il giorno non
è più invisibile al sistema.

## Il pre-push (automatico, non serve memory)

`.githooks/pre-push` gira a OGNI push (anche a mano): forme di segreto nel diff
= push fermato, zero GPU. Se ti trova a spingere un segreto, NON aggirare il
gancio: il segreto va rimosso, non nascosto.
