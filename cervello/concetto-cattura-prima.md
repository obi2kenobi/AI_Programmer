---
tipo: concetto
data: 2026-09-21
titolo: Cattura-prima: cattura, poi interroga
---
Il pattern che sana E-002: prima si cattura tutto l'output in una variabile,
poi si interroga la variabile.

  LISTA=$(ls . | grep -q patriarca && echo si)      # il tubo che uccide
  LISTA=$(ls .)                                      # cattura
  LISTA=$(echo "$LISTA" | grep -q patriarca && echo si)   # poi interroga

Fuori dal pipefail la pipe SIGPIPE non puo' piu' bociare il produttore.
La prima PR autonoma del sistema (#100, fusa il 2026-09-21) era una cattura-prima.

Famiglia d'origine: [[famiglia-e002-tubi]].
