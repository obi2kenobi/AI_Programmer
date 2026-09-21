---
tipo: famiglia
data: 2026-09-21
titolo: E-002: il tubo che uccide grep sotto pipefail
---
La forma: `produttore | grep -q pattern` sotto set -o pipefail. grep esce al
match, il produttore prende SIGPIPE, la verifica boccia un sistema sano.
4 ricorrenze prima di capirla; 57 siti ancora da pagare (2026-09-21, censite
da caccia-registro.sh).

La cura deterministica: tools/salda-e002.sh — riconosce le due forme (semplice
e condizione composta), riscrive in cattura-prima, verifica la sintassi e
ripristina se fallisce. Gira PRIMA dell'agente: 63 dei 67 debiti erano suoi.

Il pattern che produce: [[concetto-cattura-prima]]. Il metodo: [[concetto-vaccino]].
