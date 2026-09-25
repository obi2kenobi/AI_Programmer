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
