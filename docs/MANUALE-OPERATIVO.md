# Manuale operativo — AI_Programmer

> Come si usa il sistema giorno per giorno. Per il metodo: METHOD.md. Per il perché
> di ogni scelta: SAL.md. Questo è il COME, in ordine di frequenza.
>
> I blocchi `bash` si incollano nel terminale così come sono: niente commenti inline,
> la spiegazione sta nella riga sopra (CLAUDE.md §3 — su zsh senza `interactive_comments`
> un `#` diventa un argomento). I comandi che iniziano con `/` si scrivono in una sessione
> Claude Code (o ZCode), non nel terminale. (Revisione 10 giri, 2026-09-23: prima i blocchi
> mescolavano le due cose, e portavano i commenti inline.)

## Ogni mattina (2 min)

Il giudizio del mattino arriva da solo: il **digest autonomo** (`night-shift/morning-digest.sh`,
launchd dal plist `night-shift/plist/com.luca.morningdigest.plist`, 7:30) manda per email le lezioni da approvare, i sospesi e il
resoconto della notte. Il morning-gate è **in pensione** dal 2026-09-23 (decisione di dominio,
`cervello/decisione-dominio-2026-09-23.md`): le PR notturne le delibera il censore
(`night-shift/revisore.sh`); il gate resta invocabile a mano.

I numeri — cosa funziona, cosa invecchia:

```bash
bash night-shift/gate-summary.sh
```

I tuoi verdetti sulle PR, uno per PR (`merge`, `chiusura` o `commessa`):

```bash
bash night-shift/gate-esito.sh <repo> <pr> merge
```

Poi apri le PR bozza su GitHub, fondi le buone, chiudi le cattive.

## Ogni sera (5 min)

Il polso — tutto vivo?

```bash
bash tools/system-health.sh
```

In Claude Code (o ZCode): `/audit-commessa` verifica le commesse di stanotte.

## Quando vuoi delegare (giorno)

In Claude Code:
- `/qwen "riassumi questo file"` — cervello locale (gratis, privato)
- `/goal "ottimizza X | max 8 tentativi"` — loop con verifica dichiarata
- `/brainstorming <idea>` — raffina i requisiti prima del codice
- `/nuova-commessa <descrizione>` — wizard per la notte

## Quando costruisci qualcosa di nuovo

Una repo nuova col sistema pre-cablato, oppure una repo esistente portata nel sistema:

```bash
bash tools/bootstrap-app.sh <nome>
bash tools/onboard-repo.sh owner/repo
```

## Settimanale

La config critica su gist segreto; le ancore dei pattern vivono ancora? (qui fino al
2026-09-23 comandava uno script fantasma); la vista d'insieme (anche quando vuoi):

```bash
bash tools/backup-config.sh
bash tests/test-patterns-ancore-esistono.sh
bash tools/status-page.sh
```

## Se qualcosa non funziona

Nell'ordine: cosa è giù; il motore si resuscita così; un agente impantanato si libera così;
il turno dice cosa sta facendo.

```bash
bash tools/system-health.sh
launchctl kickstart -k gui/$(id -u)/luca.ollama
pkill -f "opencode run"
tail -5 ~/night-shift.log
```

## Configurazione (una volta sola)

- `night-shift/repos.conf` — la coda: `repo tipo cadenza`
- `night-shift/repos.key` — PERSONA=, TERMINI=, DIGEST_EMAIL= (i codici anonimi che ospitava
  sono ritirati dal 2026-09-23)
- `~/.config/wayfinder-router/` — il router
- `~/.config/opencode/opencode.json` — l'harness notturno
