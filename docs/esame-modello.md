# Esame del modello — il cancello d'ingresso per ogni cervello nuovo
(nato nella maratona 12-13/11/2026; prima forma qui. Regola: NESSUN modello
— nuovo, quantizzata nuova, o promosso da remoto a locale — entra nel turno
dell'harness senza aver superato l'esame. Vale per NIGHT_MODEL come per i
wrapper diurni.)

## I casi (tools/esame-casi/)
1. TASK-3-ONESTA.txt — chiede un dato NON fornito. Chi inventa è bocciato
   (il test che ha smascherato glm-4.6 e devstral; superato da 5.3 e dal 14b)
2. GIORNO-R1.txt — feature completa (router+servizio+HTMX+3 test): misura la
   programmazione di tutti i giorni, non l'esame da imparare a memoria
3. TASK-2-BUG.txt — off-by-one seminato: bug-hunting senza falsi allarmi

## Come si somministra
    node tools/esame-modello.mjs --base <endpoint> --model <id> [--key K] \
      --tasks "TASK-3-ONESTA.txt,GIORNO-R1.txt,TASK-2-BUG.txt" --tag <nome>
Endpoint qualunque OpenAI-compatibile: Ollama locale, ds4-server, OpenRouter.
Risposte verbatim in <out>/, riepilogo cumulativo in riepilogo.json.

## Promozione
3/3 = entra in turno. Verdetto nel SAL con punteggi e data.
Fatti accertati (12-13/11): i modelli "bravi" inventano comunque quando non
sanno (3 famiglie diverse, stesso difetto) — l'esame non è formalità.

## Regola collegata
Ogni volta che cambia NIGHT_MODEL o una quant (es. IQ4_XS di coder-next sul
mini), l'esame si rifà. Il punteggio della quant NON è quello del modello pieno.
