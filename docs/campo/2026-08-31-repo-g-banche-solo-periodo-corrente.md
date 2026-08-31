# 2026-08-31 — REPO-G: prospetto banche solo con il periodo corrente

**Autore**: sessione ZCode (GLM-5.3-Flash) su richiesta di Luca

## Esito — giro CHIUSO (2026-08-31)
Conferma del dominio dopo `git pull` + `clasp push` + reload `?v=banche`: *"perfetto tutto
ha funzionato bene"*. La regola _"Done means proven and confirmed"_ è soddisfata su entrambi
i versi: prova meccanica (7 banchi verdi + conteggio celle con funzioni vere estratte via `vm`)
**e** conferma del proprietario del dominio. Registrate in `SAL.md` (D69, log §10): la voce
passa da "da validare" a "validato lato cliente".

## Cosa ho usato
- `CLAUDE.md` del hub (metodo) + `CLAUDE.md`/`PROJECT.md` del repo target (REPO-G, che porta i suoi file di metodo): read-before-acting, only-what-is-asked, living docs.
- I banchi di regressione esistenti del repo (`npm test`, 7 banchi) come criterio di verifica dichiarato prima della modifica.
- Prova di rendering con funzioni vere estratte via `vm` + stub DOM minimo (conto celle thead/righe in modalità banche vs interna) — stessa tecnica dei banchi del repo (`tools/test-ce-banca.js`), usata fuori repo perché la verifica visiva vera spetta al cliente dopo `clasp push`.

## Cosa ho improvvisato
- Nulla di strutturale. Unica scelta di interpreted scope: "prospetto delle banche" = l'intero documento pubblicato (CE **e** SP), quindi via la colonna "Anno prec." anche nello SP, non solo nel CE — dichiarato nella risposta, reversibile, dati anno precedente lasciati nello snapshot perché servono alla quadratura.

## Cosa ha retto / ostacolato
- **Ha retto**: il commento vivo nel codice (REPO-G `gas/dashboard.html`, const `COLS`, nota "(Anno prec. e Δ restano colonne a sé, invariate — vedi buildThead)") che documenta *perché* le colonne c'erano: la modifica ha dovuto solo aggiornare quel contratto, zero sorprese nel motore di calcolo.
- **Ha retto**: `spTableHtml_(d, prev)` aveva già `prev` opzionale con percorso `null` provato — una riga di chiamata, zero nuovo codice (scala minima del codice). Conferma a posteriori dal cliente: il risultato visivo è esatto al primo `clasp push`, nessuna iterazione.
- **Ha retto**: dichiarare la verifica PRIMA del lavoro (`npm test` come criterio + conteggio celle) ha reso la conferma del cliente una formalità, non una speranza.
- **Attrito minore**: l'indice `night-shift/repos-index.md` ha una riga duplicata REPO-J (due volte) — già fatalError-free ma confonde chi assegna codici nuovi.

## Proposta al canone
- Il trigger first-touch di `PROJECT.md` dice "aggiungi la sezione del progetto prima di toccare"; per REPO-G l'onboarding è decisione **aperta dichiarata** (indice codici) e la sessione precedente sullo stesso repo non l'ha aggiunta: ho seguito il precedente (report dal campo sì, sezione no). Vale la pena scrivere nel canone che la sezione first-touch NON sostituisce l'onboarding decisionato, per non mettere un agente futuro davanti a due regole in conflitto.
