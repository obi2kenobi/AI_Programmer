---
tipo: decisione
data: 2026-09-21
titolo: CHI SCRIVE NON GIUDICA: il censore
---
Ogni PR del sistema passa dal revisore: guardie deterministiche (diff <=60
righe, <=3 file, ASCII, quarantena >=20 min, budget 5 PR/giorno), verifiche
dichiarate, banco avversario (allowlist grep/cat/diff/git), poi il giudizio.

Il giudice e' lo STESSO modello dello scrittore (un modello solo dal 2026-09-19,
confermato da [[decisione-modello-unico]]) ma in processo separato, senza
memoria, con persona avversaria. L'onesto rinvio ('le verifiche dichiarate sono
rosse: al giorno') e' un verdetto, non un fallimento — la PR #100 e' stata
rinviata per la suite rossa e fusa quando e' tornata verde.

Il perche' sta in [[concetto-teatro]]: chi scrive non puo' certificare se stesso.

Aggiornamento (2026-09-24, R1 R2 del quinto ventaglio): «ogni PR» non e' piu' vero. Il censore
delibera, e puo' fondere, solo le bozze su `night/` col titolo `caccia:`; per le altre
`night-shift/revisore.sh` logga «non mio». Sulle PR delle issue lascia solo un parere (D10,
decisione di Luca del 2026-09-23, in DEBITI.md). Le PR su `claude/` e `glm/` non hanno un giudice
automatico (CLAUDE.md §4).
