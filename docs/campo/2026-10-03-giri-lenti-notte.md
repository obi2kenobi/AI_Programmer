# 2026-10-03 — giri lenti di notte su Registrazione_Fatture_Acquisto
**Autore**: sessione Claude (cloud), mandato di Luca «decidi da solo, 50 giri lenti, non fare domande»; PR #355–#363 nel repo del progetto, #178 qui.

## Cosa ho usato
Agenti di lettura (lente A difetti, lente B mutazioni) in batch, gli script locali che riempiono le liste dei sabotaggi, `tools/gate.sh`, `tools/verifica_banco.py`. Mancava: un modo per far girare più agenti sullo stesso worktree senza copie (ho usato snapshot in scratchpad).

## Cosa ho improvvisato
Ambiente del banco con sequenza di risposte alla POST (`sequenzaRegistra`); una lista condivisa fra le esecuzioni dei sabotaggi si svuotava e dava 475 liste sbagliate: ambiente fresco per ogni esecuzione.

## Cosa ha retto / ostacolato
Ha retto: banco prima della correzione e sabotaggio per ogni correzione (ha scoperto il test che passava per caso, G253c: 100,05−100 in virgola mobile è sotto 0,05). Ostacolato: Lo script che riempie le liste con banco rotto scrive liste sbagliate in silenzio.

## Proposta al canone
Lo script deve rifiutarsi se il banco normale non è verde (oggi lo verifica solo chi si ricorda). Domande di dominio aperte per Luca: README §42.124–§42.125.

**Aggiunta (giro lente B aree 20-25)**: il gancio `tools/clasp-block-hook.sh` lasciava passare `clasp create-deployment` e `update-deployment` (nomi di clasp 3.x che deployano, dal README di `@google/clasp`; non ho eseguito clasp): ora li nega, con `tests/test-clasp-hook-comandi3x.sh` (22 attese, 10 rosse prima). Aperto per Luca: `undeploy`/`delete-deployment` e `run`/`run-function` passano ancora il gancio; quale versione di clasp usi? Aperto anche lo script locale che riparte da main: scarta commit locali non pushati dicendo «niente lasciato indietro».

**Decisione presa da sola (mandato «rispondi tu, in modo logico»)**: il gancio nega ora anche `clasp undeploy`, `delete-deployment`, `run-function` e `run` (agiscono sul progetto in produzione); `tests/test-clasp-hook-comandi3x.sh` a 30 attese. Da confermare con Luca: la versione di clasp installata.
