# 2026-08-31 — Valutazione Amanuensis (https://github.com/nfeldman/amanuensis) e adozione selettiva

## Cosa ho usato

Il metodo incidenti-esterni applicato a una METODOLOGIA (non un incidente): fonte verificata
(repo GitHub, MIT, 0.2.0-beta), cinque pilastri estratti, rovesciamento sul nostro sistema,
verifica guardia per guardia. La domanda: cosa abbiamo già, cosa manca, cosa adottiamo.

## La mappa (Amanuensis → nostro)

| Pilastro Amanuensis | Nostro equivalente | Esito |
|---|---|---|
| «Read before judging» (leggere non è sapere) | `esegui-non-leggere` | GIÀ PIÙ FORTE: noi eseguiamo, non solo leggiamo |
| «Prove it or qualify it» (evidenza o qualifica) | onore del NON VERIFICATO + provenienza oracoli (formula minata, mai inventata) | già nostro, dal dossier SD |
| «Attack the finding» (verifica avversariale) | giri-avversari + mutation-tests + il mandato CONFUTARE delle revisioni REPO-J | già nostro |
| «Remember the result» (memoria dei risultati) | registro errori, catalogo pattern, SAL, DEBITI | già nostro |
| «A claim cannot outrun its evidence» | la formula non si indovina / PARITÀ provata non dichiarata | già nostro, stessa regola |

## Le tre idee genuinely nuove, ADOTTATE nel metodo

1. **I cinque stati epistemici del finding**: confermato · incerto · stantio · riparato (≠
   riparato-verificato) · scartato-con-ragione. Il punto forte è il NON-promuovere silenzioso:
   un fix senza banco è «riparato» e resta tale finché la prova non passa alla revisione nuova.
   I nostri 99 NON VERIFICATI della REPO-J ora hanno il nome giusto: «incerti».
2. **L'evidenza porta la revisione (SHA)**: file:riga + commit SHA a cui verificato. Il SHA
   invecchia col codice: il vero ieri può essere stantio oggi — e lo stato «stantio» esiste
   proprio per questo.
3. **La scartato-con-ragione è patrimonio**: il confutato documentato è confine di conoscenza,
   non lavoro perso — impedisce la riscoperta come ipotesi fresca.

## Cosa NON adottiamo (e perché, dichiarato)

- **L'MCP server stesso**: dipendenza tool esterna beta (Node 20+, Python 3.11+, breaking
  changes pre-1.0). Il hub è metodologia, non toolchain: adottiamo il metodo, non il software.
  L'autore stesso dichiara «long-term value claim unproven».
- **Il conspectus come output unico**: il nostro è più frammentato (mappa-dominio, polilivello,
  pattern catalog, graphify) ma copre lo stesso terreno senza legarci a un formato esterno.

## Proposta al canone

Accolta selettivamente: le tre idee nuove sono nel metodo (sezione «I cinque stati epistemici
del finding»). Il resto è CONFERMA: cinque pilastri su cinque già presenti nel nostro sistema
— la valutazione esterna più lusinghiera che il metodo abbia ricevuto, perché arriva da chi
ha costruito lo stesso sistema di regole in modo indipendente, ed è arrivato alle stesse
conclusioni partendo da un'altra strada.
