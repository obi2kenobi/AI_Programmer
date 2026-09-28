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

Sulle PR delle issue (`night/issue-N`) trovi il **parere** del censore come commento: la fusione
è tua.

I numeri del gate sono **storici**: `metrics/gate.csv` lo scriveva solo il morning-gate, e
l'ultima riga è del 2026-08-21. I due comandi servono se rilanci il gate a mano:

```bash
bash night-shift/gate-summary.sh
```

```bash
bash night-shift/gate-esito.sh <repo> <pr> merge
```

(`gate-esito` registra il tuo verdetto su una PR giudicata dal gate: `merge`, `chiusura` o
`commessa`; `gate-summary` dice anche da quanti giorni il registro non ha righe.)

Poi apri le PR bozza su GitHub, fondi le buone, chiudi le cattive.

## Ogni sera (5 min)

Il polso — tutto vivo?

```bash
bash tools/system-health.sh
```

In Claude Code (o ZCode): `/audit-commessa` verifica le commesse di stanotte.

## Quando vuoi delegare (giorno)

In Claude Code:
- `llm/ask-qwen.sh "riassumi questo file" < file` — cervello locale (gratis, privato)
- `/goal "ottimizza X | max 8 tentativi"` — loop con verifica dichiarata
- `/brainstorming <idea>` — raffina i requisiti prima del codice
- una commessa per la notte: in ZCode il wizard `/nuova-commessa` (`.zcode-commands-nuova-commessa.md`),
  altrimenti l'issue dal template `.github/ISSUE_TEMPLATE/night-shift.md`

(2026-09-24, T4: qui c'era `/qwen`, che nel repo non esiste — né in `.claude/commands/` né in
`.claude/skills/`; il comando vero è `llm/ask-qwen.sh`. [Correzione, E-045: avevo scritto il contrario
anche di `/nuova-commessa`, che invece c'è: è il wizard di ZCode, `.zcode-commands-nuova-commessa.md`, col suo banco
`tests/test-nuova-commessa-wizard-coerenza.sh`. Claude Code non lo vede come comando slash.])

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
il turno dice cosa sta facendo. La pulizia scrive `[o]pencode run` e non `opencode run`: la classe trova il
processo ma non la riga di comando che la contiene, così un agente che la esegue alla lettera non uccide
la propria shell (provato con pgrep, 2026-09-24, Q1 R4). Ollama si rianima col gesto del turno, `rianima_ollama`
(`night-shift/lib.sh`): trova il custode launchd per nome, qualunque sia (Ollama.app o un plist), e senza custode avvia
un'istanza propria. I comandi vanno lanciati dalla radice dell'hub.

```bash
bash tools/system-health.sh
bash -c 'source night-shift/lib.sh && rianima_ollama'
pkill -f "[o]pencode run"
tail -5 ~/night-shift.log
```

## Configurazione (una volta sola)

- `night-shift/repos.conf` — la coda: `repo tipo cadenza`
- `night-shift/repos.key` — PERSONA=, TERMINI=, DIGEST_EMAIL= (i codici anonimi che ospitava
  sono ritirati dal 2026-09-23)
- `~/.config/wayfinder-router/` — il router
- `~/.config/opencode/opencode.json` — OpenCode, usato di giorno (via Wayfinder): il turno non lo lancia piu' (D8)
- graphify: `pipx install --python python3.12 graphifyy==0.9.66` — pip e' rifiutato su tutti e due i python del Mac (3.9 di sistema, e Homebrew con PEP 668), e la
  versione e' quella che l'hub prova (D41). gh si aggiorna liberamente: la riga d'ambiente del turno dice quale gira
