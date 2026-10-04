---
name: backtest-onesto
description: La procedura per VERIFICARE un backtest o un'analisi di trading — quando l'utente chiede se un backtest è affidabile, se una strategia regge, di controllare rendimenti/Sharpe/drawdown, o in un repo trading prima di fidarsi dei numeri. Nata dal parco (Trading-Short: 7 .py contro 70 .md di analisi — i numeri citati nei documenti non erano mai ricalcolati). Non è una skill di previsione: verifica il rigore del metodo, mai la fortuna del risultato.
---

# backtest-onesto — il passato si prova, non si racconta

Ruolo di riferimento: `analista-trading`. Qui sta la PROCEDURA; là il canone e
i confini (mai consigli, mai chiavi exchange, il campione povero si dichiara).

## 1. Il censimento del metodo

Prima di ogni numero: DOVE sta il metodo? Per ogni file che calcola rendimenti:

- l'ORIGINE dei dati (serie, periodo, fonte, granularità) è dichiarata nel codice?
- lo SPLIT train/test esiste ed è visibile, o tutto ottimizza su tutto?
- i COSTI (commissione, spread, slippage) sono nel codice o dichiarati assenti?
- l'ESECUZIONE: il segnale calcolato sulla barra T viene eseguito a T o a T+1?

L'assenza di una delle quattro non è un rilievo stilistico: è il rilievo.

## 2. La caccia al lookahead (per costruzione, non per lettura)

Il lookahead non si vede leggendo: si cerca nello schema. Le domande, in ordine:

1. `shift`/`rolling` con finestra che INCLUDE la riga corrente? (media mobile
   che conta la barra di oggi per decidere su oggi).
2. Il segnale usa `close` di oggi e l'esecuzione è a `close` di oggi?
   (fisicamente impossibile: si esegue dopo).
3. Normalizzazioni/stazioni calcolate su TUTTA la serie (media e deviazione
   standard del dataset completo: il futuro normalizza il passato).
4. Filtri costruiti su colonne derivate dal futuro (crescita futura, massimi
   a fine periodo).

## 3. Il ricalcolo (il rilievo si PROVA)

I numeri citati nei documenti si ricalcolano con codice PROPRIO, minimo:

```bash
python3 - <<'PY'
import pandas as pd  # o puro csv se il repo non usa pandas
# carica la STESSA serie del backtest, ricalcola UNA metrica citata
# (es. rendimento cumulato finale), stampa con 4 decimali
PY
```

- Torna uguale → il claim è VERIFICATO (si dichiara il comando).
- Non torna → il claim è UNA MENTIRA con l'autorevolezza della carta: rilievo
  massimo, si cerca la causa della divergenza (dati diversi? formula diversa?
  periodo diverso?).
- Non si può ricalcolare (dati mancanti, sorgente morta) → si dichiara NON
  VERIFICABILE: non è colpa tua, è un limite del metodo del repo.

## 4. Le metriche con nome e periodo

Ogni metrica dell'uscita: nome, periodo, ipotesi. «Sharpe 1.2» senza periodo
e senza risk-free non è una metrica. L'uscita le elenca in una tabella:

| Metrica | Valore | Periodo | Ipotesi |
|---|---|---|---|
| CAGR | 12.4% | 2019-2024 | reinvestimento totale |
| Max drawdown | -18.2% | 2022 | su curva equity giornaliera |

Le metriche ASSENTI che il metodo implica (es. profit factor se ci sono stop)
si dichiarano assenti, non si riempiono a occhio.

## 5. Il verdetto

Tre voci, mai due: **ciò che è verificato** (col comando), **ciò che non
torna** (con la divergenza misurata), **ciò che non si può verificare** (col
perché). Un backtest onesto può restare tale anche con metriche modeste; uno
disonesto non si cura con risultati migliori.
