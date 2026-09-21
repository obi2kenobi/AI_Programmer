---
tipo: decisione
data: 2026-09-21
titolo: Il modello unico: qwen3.8-27b:iq3s
---
Preso il 2026-09-21, decisione di Luca dopo la bencina pulita: 3/3 in 48s
(chirurgo 23s, bugfix 7s, censore 18s) contro 1/3 in 22s del qwen2.5-coder:14b.
Il chirurgo — il compito che il 14b sovra-consegnava — ora passa col diff minimo.

Tre condizioni non negoziabili, valgono per OGNI futuro cambio modello:
1. think:false in ogni payload: col reasoning attivo brucia 3 minuti a compito
2. i controlli su `ollama list` con grep -qi: Ollama canonizza i nomi in maiuscolo
3. probe a 240s e keep_alive:-1: 12GB a freddo superano i 120s e la sonda
   ammazzava un server sano a meta' caricamento

Pesa 12GB su 24GB di RAM unificata: ci sta comodo, e resta residente per sempre.
Vedi [[famiglia-wedge-ollama]] per perche' i 19-21GB dei Q5 erano la radice dei
wedge. Come si misura un candidato: [[concetto-bencina]].
