# Studio: JEV / System One Models — il classificatore che non genera testo

(competitore: TypeSafe AI; open: SemIf ex OpenJev, jevlike; ex-OpenAI Diogo Almeida,
co-inventore dell'RLHF, 2 anni stealth)

## Cos'e' — in una frase

Un modello che prende (stato + istruzioni + opzioni) e risponde SOLO con
decisioni tipizzate: booleano con probabilita', score numerico, o una scelta
fra le opzioni date — in UNA forward pass, senza generare un token di testo.

## Perche' e' diverso da un LLM

| | LLM (decoder-only) | JEV (System 1) |
|---|---|---|
| Output | testo token-per-token (anche JSON = testo) | probabilita' su opzioni tipizzate |
| Velocita' | ~5s per un JSON di classificazione | ~0.1s (una forward pass) |
| Costo | $ per token generato | ~zero a output (non genera) |
| Interfaccia | chat: gli parli | funzione: lo chiami da codice |
| Allucinazioni | si' (inventa fatti) | sbaglia con PROBABILITA' (calibrata) |
| Addestramento | RLHF (piacere all'umano) | RLCD (calibrare le probabilita') |

## L'architettura (da SemIf e jevlike, ricreate open-source)

1. Parti da un encoder esistente (Qwen3.5-4B, MiniCPM5-2B, o da zero byte-embeddings)
2. Tagli via la testa del vocabolario (i logits per i token)
3. Aggiungi UNA testa di attenzione per opzione: ogni opzione diventa un
   query vector che guarda il contesto → un context vector per opzione
4. Un dot-product condiviso trasforma (opzione, contesto) in uno score
5. Softmax sulle opzioni → probabilita' che sommano a 1 (choice)
   Sigmoid su una singola opzione → booleano con confidenza
   Regressione lineare → score numerico
6. INPUT a 3 canali: stato (testo libero) + opzioni (lista) + istruzioni (linguaggio naturale)

## La chiave: RLCD (Reinforcement Learning for Calibrated Decisions)

Dopo SFT (10-50k esempi sintetici), il reinforcement learning non premia il
"piacere all'umano" ma la CALIBRAZIONE: se il modello dice 90% su A, allora
A deve essere vero il 90% delle volte. Questo risolve l'overconfidence dei
modelli RLHF e rende le probabilita' UTILIZZABILI come threshold:

```
if confidence > 0.9: agisci automaticamente
elif confidence > 0.5: agisci ma logga
else: passa all'umano (o al modello grande)
```

## I numeri veri (da SemIf, misurati su RTX 3090)

- 21 domande booleane sullo stesso stato: 1.023s con logits diretti
  vs 5.332s con generazione JSON → 5.2x piu' veloce, zero token generati
- Con prefix-caching dello stato condiviso: 20 decisions/secondo
- Su OpenRouter: $0.042/million input, $0 output

## Il problema "zero allucinazioni": marketing, non verita'

Il video lo dimostra: chiedi a JEV "quanti anni ha Simone Rizzo" con opzioni
di eta' e risponde 31-100 anni al 76% (lui ne ha 28). JEV allucina — in modo
diverso (distribuzione di probabilita' su una scelta sbagliata invece di
testo inventato), ma allucina. La soluzione pratica: AGGIUNGI SEMPRE la
classe "non lo so" alle opzioni — il modello ce l'ha al 90% quando non sa.

## Per AI_Programmer: cosa rubiamo

### 1. Il censore come JEV-like (futuro)

Il nostro revisore chiede al modello "APPROVA o RIGETTA?" e riceve JSON.
Potrebbe invece chiedere con probabilita' calibrata: quando la confidenza
e' alta (>0.9) decide da solo; quando e' bassa rinvia al mattino. Questo
e' esattamente il nostro pattern "ASPETTA IL GIORNO" ma con NUMERI invece
di soglie fisse.

### 2. Il routing delle lenti (futuro)

Quale lente gira questo ciclo? Oggi: rotazione fissa. Con un JEV-like:
score su ogni lente data la salute corrente → la piu' promettente prima.
Costo: una forward pass invece di zero (la rotazione e' gratis), quindi
utile solo se le lenti sono >10.

### 3. Il principio: probabilita' calibrata > soglia fissa

La lezione piu' generale: il nostro sistema usa soglie fisse (240s, 40 righe,
5 PR/giorno). Un sistema JEV-like userebbe probabilita' calibrate per decidere
quando una soglia va alzata o abbassata. Per ora: dichiarato come principio.

### 4. SemIf gira su Apple Silicon (MLX)

Il nostro Mac ha 24GB: SemIf con Qwen3.5-4B via MLX (backend nativo Apple
Silicon) potrebbe girare in locale per decisioni veloci. Da provare quando
il turno e' stabile.

## Cosa NON prendiamo

- Il modello stesso: il nostro turno e' guidato da LLM perche' deve GENERARE
  codice (edit, write). JEV non genera: e' un classificatore. Servono tutti
  e due: JEV per le micro-decisioni, LLM per il lavoro.
- L'addestramento RLCD: il nostro modello locale e' pre-trained, non lo
  riaddestriamo. SemIf dimostra che puoi FINTARE il JEV con un LLM frozen +
  lettura dei logits: questo e' quello che potremmo fare.
