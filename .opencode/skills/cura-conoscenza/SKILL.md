---
name: cura-conoscenza
description: La procedura per tenere VIVA la conoscenza documentale di un repo — quando l'utente chiede di sistemare la documentazione, mettere in ordine i documenti/analisi, rifare il README o l'indice, verificare che i documenti dicano la verità sul codice, o su repo dove i .md superano i file di codice. Nata dai morsi misurati: il report fossile citato 31 giorni dopo la pensione, i 6 grezzi morti in /tmp (E-044), il campo promesso-mai-scritto (PR #168). Completata dal ruolo curatore-conoscenza (il canone); questa è la procedura operativa.
---

# cura-conoscenza — i documenti raggiungibili, datati, coerenti

Ruolo di riferimento: `curatore-conoscenza` (il canone: data e stato, indice
prima del volume, la menzione non è l'uso, vince git). Qui la procedura in
quattro passi, replicabile su qualunque repo.

## 1. Il censimento (un comando per repo)

```bash
find . -name '*.md' -not -path './.git/*' -not -path './node_modules/*' \
  -exec stat -f '%Sm %N' -t '%F' {} \; | sort
```

Per ogni documento DUE date: quella del filesystem (ultima modifica) e
quella DICHIARATA (nel nome o in testa). La tabella:

| Documento | Data fs | Data dichiarata | Stato | Raggiungibile da |
|---|---|---|---|---|
| docs/analisi-metodo.md | 2026-08-14 | — | ? | nessun link |

La colonna «Raggiungibile da» si riempie cercando il nome del file nei link
degli altri .md (grep). «Nessun link» è una porta murata: rilievo.

## 2. Lo stato (VIVO / OBSOLETO / STORICO)

Regola di decisione, in ordine:

- **VIVO**: descrive il presente (il codice che c'è, il metodo attivo).
- **STORICO**: racconta un passato che serve tenere (report di campo,
  post-mortem) — si marca e si DATA, non si corregge.
- **OBSOLETO**: contraddetto dal presente (il sistema è cambiato) — si
  marca in testa («OBSOLETO dal <data>: vedi <documento nuovo>») MAI si
  cancella in silenzio: il prossimo lettore deve sapere che esisteva.

Lo stato si scrive in testa al file, una riga: `> Stato: VIVO · aggiornato
2026-10-03`. Un documento senza riga di stato È il rilievo.

## 3. La verifica dei claim (la menzione non è l'uso)

I documenti che affermano comportamenti del codice si campionano: 1 claim su
3, minimo 5. Per ogni claim campione:

1. Estrai l'affermazione verificabile («il foglio X viene scritto dalla
   funzione Y», «il campo Z esiste»).
2. Verifica nel codice (grep/funzione/file).
3. Esito: VERIFICA (con file:riga) · MENTITA (con la divergenza) ·
   NON VERIFICABILE (col perché).

Le MENTITE sono rilievi di gravità alta: un documento che mente è peggio di
uno mancante, perché ha l'autorevolezza della carta. La cura: correggere il
documento OPPURE aprire il debito nel codice (se il documento descriveva
l'intenzione) — mai lasciarle divergere in silenzio.

## 4. La cura e la consegna

- Data+stato dove mancano, link dove sono murati, correzione dove mentono,
  indice (README o docs/README.md) dove non c'è.
- **Una cura per documento, un commit per passo** (la storia deve poter
  raccontare cosa è cambiato).
- La consegna è l'INDICE aggiornato: la prova che chi entra adesso trova
  tutto. Nell'uscita: la tabella del censimento PRIMA e DOPO (quante porte
  murate aperte, quanti fossili datati, quante menzogne corrette, quanti
  claim verificati su quanti campionati).

## I limiti (dichiarati, non taciute)

Il contenuto tecnico si verifica CONTRO il codice, mai si inventa; le cifre
di trading passano dall'analista-trading (skill backtest-onesto); i documenti
d'opinione dell'operatore si datano e si linkano, il contenuto resta suo.
