# Grafo a costo zero — cosa cambia quando la semantica è gratis
(decisione D1 attuata: mini 64GB, pass semantici con Ollama locale. 13/11/2026)

## Cosa sblocca il costo zero (in ordine di valore)

1. PASS SEMANTICI PIÙ FREQUENTI DELLA NOTTE
   Oggi: una volta a notte (marker, PR night/grafo-*). Con costo zero:
   rinfresco incrementale A OGNI COMMIT (la cache graphify-out/cache rende
   il delta quasi istantaneo) — il grafo smette di essere "fresco di stanotte"
   e diventa "fresco dell'ultima modifica". Il merge-driver gia' unisce i rami.

2. SEMANTICA ANCHE SUL CODICE (.gs), NON SOLO SUI .md
   Il buco vero scoperto oggi: graphify query non trovava gli hotspot .gs
   (l'agente e' caduto su grep, degradazione dichiarata). Con budget zero:
   pass semantico per FUNZIONE (cosa fa, in linguaggio naturale) — il grafo
   diventa indice semantico del codice: "chi tocca UrlFetchApp" diventa una
   query, non un grep. E' la scala che porta a llmwiki.

3. GUARDIA DI SALUTE DEL GRAFO (il grafo si guasta in silenzio)
   Nuovo test nel turno: graphify query "UrlFetchApp" DEVE restituire >= N
   file di codice; sotto soglia = grafo DEGRADATO dichiarato (non grep alla
   cieca senza saperlo, come oggi). Stesso stile del privacy-check: il degrado
   si dichiara da solo.

4. MISURARE IL RENDIMENTO, NON SOLO IL COSTO
   Il mini rende misurabile anche il valore: A/B nel turno — stesso compito
   con graphify query vs grep, tempi e qualita' a confronto. Se il grafo non
   paga, lo si sa coi numeri; se paga, il metodo lo prescrive.

## Giorno-1 sul mini (debiti che si saldano insieme)
- D-V3-2: misurare la durata del PRIMO pass semantico (soglia = 3x quella).
  Quel numero calibra la cadenza: se un pass full dura 20 minuti, il
  rinfresco per-commit e' gratuito; se dura 3 ore, resta notturno col delta.
- Ricostruire il grafo con semantica-codice attiva e verificarla con la
  guardia di salute (punto 3).
- Il catalogo dei modelli per i pass: il cervello notturno del profilo
  (profiles/mini.sh) e' anche il semantico: un solo residente, due mestieri.

## Cosa NON cambia
Il metodo: selezione-contesto col grafo resta la porta d'ingresso dei turni;
la guardia verifica-diff resta il cancello d'uscita. Il grafo migliore e'
quello che l'agente USA — per questo il punto 4 (misurare) precede ogni
entusiasmo sul punto 2 (estendere).
