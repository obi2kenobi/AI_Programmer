# Protocollo di scelta del modello notturno — 10 test per modello

## Il problema
Qwen 3.8 27B (generale) loopa sull'issue #12 da 4 notti consecutive (59h, 10h, 10h, 4h col
watchdog). Il comportamento: rilegge le stesse finestre dello stesso file (offset=655 letto
21 volte), riformula lo stesso piano 491 volte, non scrive MAI una riga di codice.

## L'ipotesi
Il problema non è la dimensione (27B è sufficiente) ma la SPECIALIZZAZIONE: un modello
generale in un contesto di coding agentico tende a "riflettere" invece di "agire". Un
modello specializzato per coding agentico convergerebbe dove il generale loopa.

## I candidati (Mac 24GB RAM, 255GB disco)
| Modello | Taglia | Specializzazione | Note |
|---|---|---|---|
| qwen3.8:27b (attuale) | 17GB Q4 | GENERALE | Loopa su task complessi |
| qwen2.5-coder:14b | 9GB | CODING | Metà dimensione, specializzato |
| devstral:24b | 14GB | AGENT CODING | Progettato per agenti che scrivono codice |

## Il test
Mini-issue GAS identica per tutti: aggiungere una colonna a una tabella PDF in un file
con la tabella già presente in un'altra funzione dello stesso file. È il problema in
miniatura di #12: leggere dove intervenire, capire il pattern esistente, scrivere.

10 esecuzioni per modello, ognuna con timeout 120 secondi e banco resettato.
Prompt identico a quello del turno (comportamentale anti-loop incluso).

## Le misure
1. **Convergenza**: ha modificato il file? (sì/no)
2. **Correttezza**: node --check passa + contiene la colonna aggiunta
3. **Letture**: quante volte ha letto il file prima di scrivere
4. **Tempo**: quanto ha impiegato

## Il criterio di scelta
Il modello che converge di più su 10 test vince. A parità di convergenza, vince quello
con meno letture medie (segno che "legge quanto basta e scrive" invece di "rilegge").
