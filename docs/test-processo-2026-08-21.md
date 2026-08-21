# Test del processo end-to-end — sviluppare una feature nuova con AI_Programmer

> 2026-08-21, ore 17-18. Mandato di Luca: usare il sistema per sviluppare una NUOVA funzionalità
> su una repo reale (Bilancio_di_Massa_PEFC), capire **dove fallisce e dove migliorare**.
> Questo documento è il deliverable del test: l'analisi del processo con i fatti, non le opinioni.

## Com'è andato il processo (la cronaca onesta)

| Fase | Esito | Il fatto |
|---|---|---|
| Onboarding con pre-scan | ⚠️→✅ | il pre-scan gitleaks era ROTTO (girava prima del clone: finding #1) — ma il metodo manuale ha intercettato segreti veri (1 valore Azure + rtf in 3 commit, storia scrub-bata, zero leak finale) |
| Fase di design | ❌→✅ | il primo tentativo è stato **pattern-matching, non progettazione** (bottone gemello invece di domanda di dominio): l'operatore ha saltato /brainstorming. Redo con 3 agenti in parallelo → gap analysis col SAL del progetto → scelta socratica → design |
| Commessa chirurgica | ✅ | issue #11 con punti esatti, regex validata dal banco, regole oneste (non-classificato mai nascosto) |
| Turno | ⚠️→✅ | prima esecuzione FALLITA: self-healing gareggiava col LaunchAgent per la porta (finding #4, corretto: kickstart a launchd, non doppio-avvio) |
| Giudizio | ⏳ | gate a tre controlli + summary domattina |

## I cinque findings (tutti con correzione)

1. **Pre-scan onboarding rotto** — posizionato prima del clone, tre esiti confusi in un `||`. Fix: dopo il clone, tre esiti distinti (pulito / ⛔ segreti / ⛔ non installato)
2. **Il processo si può saltare** — la fase di design non è OBBLIGATA da nulla: è disciplina dell'operatore. Il sistema non difende il proprio metodo
3. **Zombie opencode** — processi orfani vivono ore e rubano il modello. Fix: pulizia nel preflight
4. **Doppio proprietario del server** — script vs launchd KeepAlive: gara persa da entrambi. Fix: kickstart al proprietario legittimo. Regola generale: ogni risorsa ha UN proprietario dichiarato
5. **Turni sovrapposti** — manuale e 23:00 sulla stessa repo = caos. Fix: lock per repo con scadenza

## Le debolezze strutturali (non ancora chiuse)

- **Le repo GAS non hanno verifiche eseguibili**: metà del parco viene giudicata solo col banco avversariale + review umana. Il banco Python esisterebbe (valida_consumo) ma serve-le credenziali, che il clone notturno non ha e non deve avere. **Limite dichiarato, non bug**: la verifica di livello 1-2 per le repo GAS passa dal deploy, che è mano umana
- **Ogni fix richiede un giro umano**: la catena di correzione (review Opus → fix → dev-critic → fix → test → fix) funziona ma è seriale. Il `.night-verify` del hub (shellcheck) è il primo passo verso regressione automatica: i fix di STANNO avendo test solo ora
- **Il fallimento notturno non attiva il giorno**: quando la notte non converge, il commento dice "riproverò" — e riprova uguale. Il gate propone commesse correttive, ma il salto di qualità (passarla al cervello di giorno) resta una decisione umana da prendere al mattino

## Le proposte di miglioramento (in ordine di ritorno)

1. **Template issue `night-shift` con sezione DESIGN obbligatoria** — un'issue senza "design: <link o ratio>" non parte: il processo smette di dipendere dalla disciplina dell'operatore. Piccolo, concreto, chiude il finding #2 alla radice
2. **Il gate dichiara la categoria "repo non-verificabile"** — non il generico "non-dichiarate": quando la repo è GAS-only il report lo dice col motivo, e la review umana sa che è L'UNICA verifica
3. **gate-summary conta anche i finding di processo** (bug di sistema trovati per settimana, per fonte: review/critic/test) — il meta-apprendimento diventa misurato, nonaneddotico
4. **Il turno scrive nel log l'esito-fase** (design-linked: sì/no) — il dato per misurare se il miglioramento 1 funziona
5. **Regressione per i fix del sistema**: ogni fix d'ora in poi porta il comando che lo dimostra nel `.night-verify` del hub quando possibile (iniziato con shellcheck; estendere ai bug di logica con mini test)

## Il dato che conta

Il sistema ha un giorno di vita e ha già: 3 PR fuse, segreti veri trovati e ripuliti in due repo,
5 bug d'infrastruttura trovati da TRE fonti indipendenti (review Opus, dev-critic, questo test)
e corretti in giornata. **Il metodo della catena di giudizio funziona**: il sistema migliora
perché qualcuno lo usa sul serio e ogni attrizione diventa una riga scritta. Il limite
strutturale resta quello misurato alla nascita: il modello locale capisce ma non converge
dove serve giudizio — e per questo il design è roba da giorno, con gli agenti evocati.
