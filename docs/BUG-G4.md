# BUG-G4 — AI_Programmer (M-031.1b)

NON TROVATO: bug gravi confermati nell'arco delle verifiche di questo mandato.

## File letti
- llm/_timeout.sh, llm/_usage.sh, llm/usage-summary.sh, llm/ask-glm.sh, llm/ask-opus.sh, llm/ask-qwen.sh, llm/claude-local.sh
- night-shift/gate-esito.sh, night-shift/gate-summary.sh, night-shift/lib.sh (sezioni mask_secrets/impronta_righe)
- profiles/mini.sh, profiles/max.sh, .opencode/plugins/graphify.js

## Ricerche fatte
- grep TODO/FIXME/HACK/XXX in *.sh/*.js/*.py (nessuna marcatore reale)
- grep rm -rf/eval/sudo/:(){} in sorgenti (documentati, non bug attivi)
- lettura sorgenti principali (non solo README): ask-*.sh, lib.sh, gate-*.sh, usage-summary.sh
- ispezione percorsi mktemp, trap, status/exit-code

Conclusione: il codice è già molto curato (bug storici documentati e corretti nelle sezioni di commento). Nessun bug grave nuovo confermato; nulla da correggere. Nessun bug inventato.
