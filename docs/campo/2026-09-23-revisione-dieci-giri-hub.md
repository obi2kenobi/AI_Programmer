# 2026-09-23 — revisione dell'hub in dieci giri (sessione cloud)
**Autore**: sessione Claude Code (cloud), mandato di Luca — PR #123

## Cosa ho usato
- `tools/debiti-riapertura.sh` (settimo patto) prima del lavoro: aveva lui stesso un difetto
  (giudicava per sezione) — curato per primo, giro 0.
- Tre lenti in sola lettura in parallelo (riferimenti, codice vs commenti, test finti): 67
  rilievi, OGNUNO rieseguito da me prima della cura.
- Gli oracoli (`tools/valorizzazione_magazzino.py`, `tools/bilancio_bu.py`) per ricavare a
  mano le attese di un test che non poteva fallire: le attese scritte erano sbagliate.
- I guardiani del commit (`git config core.hooksPath .githooks`): mi hanno fermato quattro
  volte, sempre a ragione.
- NON RAGGIUNGIBILE: il Mac (Ollama, launchd, `gh` autenticato), il GAS vivo. Cio' che ne
  dipende e' ⏳ in DEBITI.

## Cosa ho improvvisato
- Il sabotaggio in un CLONE va fatto copiandoci lo strumento curato: il clone parte dal
  commit, non dal working tree (una volta l'ho dimenticato e il sabotaggio non valeva).
- Il codice Python dentro `python3 -c '…'` di bash non puo' contenere apostrofi: `\x27`.

## Cosa ha retto / ostacolato
- Ha retto: «banco prima della correzione» — quasi ogni cura e' nata da un test rosso sul
  difetto, e due volte il banco ha smentito la MIA attesa (20 caratteri, non 24).
- Ha retto: il cancello clasp, anche contro di me — la sua cura ha negato il commit del diario
  che la documentava (backtick su piu' righe): curato il falso positivo.
- Ostacolo: la guardia commit-msg leggeva ogni «N test» come il totale della suite
  (`tools/pre-commit.sh`) — curata.

## Proposta al canone
1. Una famiglia nuova nel registro: **«verde senza verdetto»** — un test che esce 0 senza aver
   asserito (lib che esce, zero asserzioni, `ko` in una subshell, `python -c "espr"` che non
   asserisce). Il runner ora pretende la riga «N OK, 0 FAIL» (`tools/suite.sh`).
2. **«Promessa nel commento, assente nel codice»** misurata sei volte in un giorno (48h della
   scopa, 24h dei rami notte, «accodata», «600s», «pull --ff-only», «degradato a proposta»):
   ogni soglia o garanzia scritta in un commento deve avere il suo test.
3. Proposte che toccano le regole (non applicate, a Luca): hook di `settings.json` con
   `$CLAUDE_PROJECT_DIR` (il cancello clasp fallisce aperto da una sottocartella); in CLAUDE.md
   §4 la convenzione dei prefissi cita il morning-gate, che e' in pensione.
