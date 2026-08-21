# Il turno di notte — il metodo (v2, generalizzato)

> Il metodo nato su AI_Develop (tre notti di test veri, 2026-08-18/21) e promosso a sistema.
> Ogni regola porta accanto **il fatto misurato che l'ha imposta** — non la motivazione teorica.

## Il principio

Il modello locale **non è un secondo cervello**: è capacità di calcolo a costo marginale zero,
privacy totale e nessun rate limit. La qualità dei cervelli cloud resta superiore. Perciò:

```
GIORNO (cervelli): ZCode/GLM · Claude Code/Opus · OpenCode via Wayfinder → Qwen
                   pianificano, correggono, giudicano
NOTTE (braccia):   night-shift 23:00 → issue `night-shift` → OpenCode → Qwen locale
                   commesse meccaniche → PR BOZZA, mai push su main
MATTINA (giudizio): morning-gate → verifiche dichiarate + banco avversariale →
                    proposte correttive (il sì è sempre umano)
```

## Le regole vincolanti

| Regola | Il fatto che l'ha imposta |
|---|---|
| **L'issue è una commessa precaricata** (snippet, righe, grep pronti) | tre notti: il modello capisce ma a ~4 tok/s non converge se deve esplorare 4.300 righe per giudicare |
| **Nessun limite di tempo per issue** (Luca, 2026-08-21) | il watchdog da 90 min ha interrotto l'agente «a un passo dalla fine» tre volte di fila |
| **PR sempre BOZZA su branch `night/issue-N`** | la review del mattino è parte del metodo |
| **Mai scrivere in cartelle specchio/sola lettura** | `gas-src/` in AI_Develop: regola fondativa del repo ospite |
| **Idempotenza completa** | PR aperta → skip; PR fusa → chiude l'issue dimenticata (la keyword italiana non auto-chiudeva) |
| **Sonda di salute del server + un modello per turno** | dopo scambi di modelli a caldo, errori Metal con risposte vuote silenziose |
| **Config reale fuori dal repo pubblico** | `repos.conf` gitignored: i nomi delle repo private non si pubblicano |
| **Loop su array, bash 3.2, `cd` nel subshell, `git clean` per issue** | i quattro difetti d'infrastruttura trovati nelle notti di test |

## I numeri che scelgono il modello (MacBook Air M5, 24 GB, misurati 2026-08-18)

| Quant | Velocità | Esito |
|---|---|---|
| Q4_K_M MTP 17,1 GB | 3,7-5,9 tok/s | **operativa** (parità 4/4 con Q5 nella batteria di qualità) |
| Q5_K_M 19,8 GB | 2,5 tok/s | opzione fedeltà one-shot |
| Q5_K_XL 21 GB | 0,23 tok/s | thrashing — inusabile |

Server: flash attention, KV q8_0, contesto 16K, thinking off per il batch.

## Come si usa

```bash
night-shift/night-shift.sh                # tutte le repo in repos.conf
night-shift/night-shift.sh owner/repo     # una repo
night-shift/morning-gate.sh               # il giudizio del mattino
```

Mettere in coda: issue con label `night-shift`, scritta come commessa. Il turno parte da solo
alle 23:00 (LaunchAgent). Il Mac: alimentatore, coperchio aperto, app pesanti chiuse
(è la differenza fra 1 e 4 tok/s).

## Il gate del mattino (`morning-gate.sh`)

1. **Verifiche dichiarate**: la repo dichiara i comandi in `.night-verify` (una riga per comando)
2. **Banco avversariale**: il modello locale prova a smentire la PR (metodo del Supervisore)
3. **Report** in `~/morning-gate-report.md` + riga in `metrics/gate.csv`
4. **Il correttore**: i fallimenti diventano proposte di commesse correttive da incollare —
   nessun sì, nessuna commessa (regola _"Done means proven and confirmed"_)

## Checklist review umana

- [ ] Le verifiche dichiarate passano sul branch
- [ ] Il diff tocca SOLO ciò che l'issue chiedeva
- [ ] Il banco avversariale non ha prodotto smentite valide
- [ ] I valori attesi nei test non sono stati «adattati» per farli passare
