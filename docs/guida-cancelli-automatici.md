# Guida ai cancelli automatici (fondi e deploy-gas) — per chi non l'ha mai fatto

I cancelli umani non si tolgono: il sistema li apre soltanto quando le prove
richieste dalla policy valgono sull'artefatto esatto che sta per scrivere.

## FONDI — auto-merge opzionale, spento di default
`tools/fondi.sh <dir-repo> <n-pr>` esce 2 senza toccare la PR finché non viene
attivato con `FONDI_AUTO=1`. La consegna di `tools/giorno.sh` lo chiama soltanto se
anche `GIORNO_FONDI=1`; il default resta spento.

Se attivo, il wrapper non si fida di un commento storico né del working tree.
Per ogni richiesta esegue una REVIEW FRESCA tramite `night-shift/revisore.sh`:
1. PR aperta e fondibile, in una corsia ammessa;
2. checkout del `headRefOid` e banco letto dal ramo di default, in sandbox;
3. lente sicurezza pulita sullo stesso commit;
4. censore approva e il parere viene pubblicato nella PR con `Commit revisto:
   <SHA>`. Se il commento non si pubblica, non c'e' approvazione utilizzabile.

Solo dopo queste prove la bozza viene promossa e il merge usa
`--match-head-commit <SHA>`: se la PR e' avanzata, GitHub rifiuta e la catena
ricomincia. Dopo il merge il banco sul ramo di default resta obbligatorio;
un rosso post-merge va gestito subito dal cancelliere, non nascosto.

Un satellite senza il revisore dell'hub non ha un fallback piu' debole:
`fondi` si ferma. Il riallineo automatico (`RIALLINEO_AUTO=1`) verifica prima
il commit standard con sync-repo, poi passa dalla STESSA via; non esegue un
`gh pr merge` proprio.

## DEPLOY-GAS — clasp soltanto col protocollo
`tools/deploy-gas.sh <dir-progetto-clasp>` richiede banco verde, lente pulita,
target approvato, backup isolato non vuoto e MANIFEST con rollback. Senza una
di queste condizioni si ferma. La produzione e il test visivo restano regole
L3: il successo di `clasp push` non e' da solo una prova di produzione.

## Le regole per chi arriva nuovo
- Un NO non e' un errore: dice quale prova manca.
- Non si aggira una guardia: si corregge con test e motivo scritto.
- L'override `PRE_PUSH_FAILOPEN=1` e' una tantum e va dichiarato; non e' una
  configurazione permanente.
- Il log nomina sempre il commit e l'esito reale; un comando tentato non e' un
  comando riuscito.
