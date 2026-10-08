# 2026-10-08 — risposte di Luca applicate su due repo e prova sul foglio vero
**Autore**: sessione Claude (Sonnet 5.5) per Luca — Registrazione_Fatture_Acquisto e Magazzino_Treviso

## Cosa ho usato
Agenti `sviluppatore-gas` (due, uno per repo, rami nuovi da `main`; quello di Treviso ripreso più volte con `SendMessage` perché conservava il contesto). Il gate di Registrazione e il cancello di Treviso li ho rilanciati io, a sorgente fermo, a ogni consegna. Le domande di dominio (14) le ho poste a Luca con scelte chiuse (`AskUserQuestion`) dopo che «una per volta» in testo libero era diventato troppo lungo.
Mi è mancato: playwright-core nel cancello (verde DEGRADATO a ogni giro: i banchi browser li ho lanciati a parte con `PW_CORE`).

## Cosa ho improvvisato
- **Una cura verde offline che non reggeva sul vivo.** La #207 (scritture oltre la griglia) era verde, con banco e sabotaggi, e l'ho presentata come «curata». La prova su un foglio vero (lanciata da Luca) ha detto il contrario: il foglio finto non riproduceva `appendRow`, che riconverte il valore e perde il formato testo anche con `@` già imposto, anche DENTRO la griglia. Servono tre giri: prova, diagnosi con tre varianti in un solo lancio, cura (`setValues` sotto lock, #210), conferma sul vivo.
- **Una prova che non misurava la cura**: la prima funzione usava `appendRow` grezzo di proposito e avrebbe dato «NON ereditato» con o senza cura; io avevo detto a Luca che dopo il deploy avrebbe detto «ereditato». Corretto con la seconda funzione sul percorso di produzione.
- **Un `git checkout` malformato** dell'agente ha staccato per qualche minuto il suo worktree su `main`: due prove «122/122» erano di `main`. L'ha dichiarato lui.
- **Un errore GitHub 500 al push** (ripetuto, poi passato): ritentato con attesa crescente; il remoto suggeriva il nome con le maiuscole.
- **Il cancello di `main` era già rosso** (`@300` in `.night-verify` non capito da `tools/gate.sh`, uscita 127): curato nella PR del giorno stesso.

## Cosa ha retto / ostacolato
- **Ha retto:** la regola «la prova la lancia chi ha il vivo» (Luca ha eseguito tre volte funzioni da editor e i log hanno corretto me, non il contrario); il banco rosso prima della cura; i sabotaggi con cadute misurate; il diario dei debiti con la lente di coerenza (ha preso una voce SAL che diceva «chiuso» a debito aperto).
- **Ostacolato:** un foglio finto troppo ottimista (ha fatto passare per verdi 12 banchi che assumevano un `appendRow` non fedele); il verde degradato del cancello come stato normale; la mail del limite Gmail del 6/10: letta nel codice, non posso vedere trigger e quota dall'esterno.

## Proposta al canone
1. Un modello finto di un servizio esterno (foglio, Gmail, BC) va confrontato con UNA misura sul servizio vero prima di fidarsi dei banchi che lo usano; il banco verde sul finto non dice «curato», dice «coerente col finto». Fino alla misura il debito resta aperto.
2. Una funzione di prova «dal vivo» dichiara cosa misura e cosa NON misura (la cornice, il percorso scritto): evita l'affermazione «dopo il deploy dirà X» su una prova che non passa dal percorso curato.
3. Il cancello dovrebbe cercare playwright-core dove i worktree lo hanno già (o dire come), per non lasciare il verde degradato come stato permanente.
