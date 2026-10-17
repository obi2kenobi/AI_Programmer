# 2026-10-15 — deploy-gas.sh: esito di clasp e byte del backup
**Autore**: sessione claude/fervent-dirac-f4y7ku, su richiesta di Luca

**Usato**: banco prima della correzione (`tests/test-deploy-gas-esito.sh`, clasp finto in PATH, ID finti), sabotaggio dichiarato di entrambe le correzioni. **Improvvisato**: nulla. **Non raggiungibile**: shellcheck (assente in questo container, il gate `.night-verify` non e' stato eseguito qui); `tests/test-gas-target.sh` e' rosso 6/9 gia' prima del cambiamento perche' qui manca `clasp` (verificato con git stash).
**Trovato in passando, NON corretto (fuori richiesta)**: `tools/deploy-gas.sh:44-45` — `LEN=$(...; true)` poi `LEN_RC=$?` vale sempre 0, quindi il passo «2. lente» dice PULITA anche con rilievi o DEGRADATA: stesso difetto di mascheramento dell'esito.
**Proposta al canone**: nessuna.
