# BUG-G5 — AI_Programmer (M-032.1b)

NON TROVATO: bug gravi confermati nell'arco delle verifiche di questo mandato.

## File letti
- llm/_timeout.sh, llm/_usage.sh, llm/usage-summary.sh, llm/ask-glm.sh, llm/ask-opus.sh, llm/claude-local.sh
- night-shift/gate-esito.sh, night-shift/lib.sh (pattern rm -rf/eval/allowlist), .opencode/plugins/graphify.js, profiles/mini.sh, profiles/max.sh

## Ricerche fatte
- grep TODO/FIXME/HACK/XXX, rm -rf, eval, curl | sh, chmod 777, xargs rm (documentati, non bug attivi)
- verifica exit-code e trap EXIT dei wrapper llm/, conteggio campi e parsing CSV di gate-esito.sh
- ispezione timeout perl/GNU e comando di verifica esistenti

## Conclusione
Il codice è già molto curato (bug storici documentati e corretti con prove nel commento: _timeout.sh, ask-glm.sh, ask-opus.sh, gate-esito.sh). Nessun bug grave nuovo confermato; nulla da correggere. Nessun bug inventato.
