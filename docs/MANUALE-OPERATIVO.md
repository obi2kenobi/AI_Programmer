# Manuale operativo — AI_Programmer

> Come si usa il sistema giorno per giorno. Per il metodo: METHOD.md. Per il perché
> di ogni scelta: SAL.md. Questo è il COME, in ordine di frequenza.

## Ogni mattina (2 min)

```bash
bash night-shift/morning-gate.sh          # il giudizio: verifiche + banco + minimità
bash night-shift/gate-summary.sh          # i numeri: cosa funziona, cosa invecchia
# registra i tuoi verdetti:
bash night-shift/gate-esito.sh <repo> <pr> merge|chiusura|commessa
```

Poi apri le PR bozza su GitHub, fondi le buone, chiudi le cattive.

## Ogni sera (5 min)

```bash
bash tools/system-health.sh               # il polso: tutto vivo?
/audit-commesse                           # verifica le commesse di stanotte (Claude o ZCode)
```

## Quando vuoi delegare (giorno)

```bash
/qwen "riassumi questo file"              # cervello locale (gratis, privato)
/goal "ottimizza X | max 8 tentativi"    # loop con verifica dichiarata
/brainstorming <idea>                     # raffina i requisiti prima del codice
/nuova-commessa <descrizione>             # wizard per la notte
```

## Quando costruisci qualcosa di nuovo

```bash
bash tools/bootstrap-app.sh <nome>        # repo nuova col sistema pre-cablato
bash tools/onboard-repo.sh owner/repo    # repo esistente nel sistema
```

## Settimanale

```bash
bash tools/backup-config.sh              # config critica su gist segreto
bash tools/verify-patterns.sh            # le ancore dei pattern vivono ancora?
bash tools/status-page.sh                # vista d'insieme (o quando vuoi)
```

## Se qualcosa non funziona

```bash
bash tools/system-health.sh               # dice cosa è giù
launchctl kickstart -k gui/$(id -u)/luca.ollama   # il motore si resuscita così
pkill -f "opencode run"                   # un agente impantanato si libera così
tail -5 ~/night-shift.log                 # il turno dice cosa sta facendo
```

## Configurazione (una volta sola)

- `night-shift/repos.conf` — la coda: `repo tipo cadenza`
- `night-shift/repos.key` — i codici anonimi (+ PERSONA=, TERMINI=, DIGEST_EMAIL=)
- `~/.config/wayfinder-router/` — il router
- `~/.config/opencode/opencode.json` — l'harness notturno
