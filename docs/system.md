# La mappa del sistema — AI_Programmer come base di sviluppo globale

> Assemblato il 2026-08-21. Ogni vincolo porta la sua provenienza: cosa è misurato,
> cosa è deciso, cosa è un limite dichiarato di strumenti di terzi. Niente promesse vuote.

```
┌───────────────────── AI_Programmer (hub, PUBBLICO) ─────────────────────┐
│ L0 BASE      CLAUDE.md (regole Karpathy §1-6 + §7 delega) · PROJECT.md  │
│              multi-progetto · conoscenza docs/bc · SAL.md · fabbrica    │
│ L1 CERVELLI  llm/ask-qwen (locale) · ask-opus (claude -p) · ask-glm    │
│              (API opzionale) — contratto unico, matrice in llm/README  │
│              router/ WayfinderRouter: tessuto per OpenCode, route       │
│              nominate @route/night @route/digest                       │
│ L2 LAVORO    giorno: sessioni dirette + deleghe llm/ask-*              │
│              notte: night-shift 23:00 multi-repo (repos.conf LOCALE)   │
│ L3 GIUDIZIO  morning-gate: verifiche dichiarate + banco avversariale   │
│              + proposte correttive (sì umano obbligatorio)             │
│ L4 MEMORIA   SAL.md + metrics/gate.csv → le decisioni future le        │
│              decidono i dati accumulati, non le opinioni               │
└─────────────────────────────────────────────────────────────────────────┘
```

## Chi fa cosa, e perché

| Ruolo | Chi | Provenienza della scelta |
|---|---|---|
| Cervello giorno primario | ZCode / GLM 5.3 | sessione diretta |
| Cervello giorno profondo | Claude Code / Opus 5 | **Limite verificato**: Wayfinder non implementa l'outbound Anthropic (letto nei sorgenti, non presunto) — Opus resta diretto, `ask-opus` via `claude -p` (auth nel Keychain SUL MAC: funziona da terminale utente e launchd, non da shell sandbox locale; **una sessione cloud ha auth propria e risponde davvero** — verificato 2026-08-22, vedi `llm/ask-opus.sh`) |
| Braccia notturne | Qwen3.8-27B Q4_K_M via Ollama | batteria qualità 4/4 pari alla Q5, 3,7-5,9 tok/s, margine RAM (misure 2026-08-18) |
| Tessuto di routing | WayfinderRouter 2026.8.0 | solo-locale per scelta (Luca 2026-08-21); il turno notturno NON dipende dal router — garanzia «nessun punto di failure singolo» |
| Giudice/censore/correttore | REPO-A + morning-gate | il metodo del Supervisore (banco che smentisce) applicato alle PR del sistema |
| Memoria | SAL.md + metrics/gate.csv | regola del repo: ciò che un giro insegna si scrive prima del giro successivo |

## Limiti dichiarati (cosa il sistema NON fa, oggi)

1. **Opus non passa dal router** — outbound Anthropic assente in Wayfinder (2026-08)
2. **ask-glm** richiede `ZHIPUAI_API_KEY`; endpoint non testato né da Wayfinder né da noi.
   Via naturale: sessione ZCode
3. **Apple Foundation Models**: rimandato — superficie sperimentale (2026-08)
4. **Il modello locale non converge sui giudizi**: tre notti di prove (#363 su REPO-A).
   Le indagini restano ai cervelli di giorno
5. **Le repo private non si nominano nel repo pubblico**: `repos.conf` è locale e gitignored

## La fabbrica

- `tools/bootstrap-app.sh <nome>` — repo nuova col sistema pre-cablato
  (regole ereditate, PROJECT.md stub, label night-shift, `.night-verify` dichiarato)
- `tools/onboard-repo.sh <owner/repo>` — repo esistente dentro il sistema
  (label, repos.conf, `.night-verify` da riempire)

## Il ciclo completo (come si chiude)

```
commessa (issue night-shift) → notte (PR bozza) → gate (verifiche + smentita)
   → esito: merge (tuo sì) | chiusura | commessa correttiva (da approvare)
   → lezione scritta in SAL.md + riga in metrics/gate.csv → il ciclo migliora
```

---

## Il ciclo come loop engineering (2026-08-21)

Il sistema pratica **loop engineering** da prima di conoscere il nome: trigger che avviano un
harness, verifica, memoria su file, ciclo che riparte. Il vocabolario pubblico (Boris Cherny —
"non scrivo più prompt, disegno loop"; Peter Steinberger; Karpathy col suo AutoResearch — le sue
quattro regole sono in CLAUDE.md dal principio) arriva dopo e formalizza.

| Loop engineering | Qui |
|---|---|
| Trigger (evento o orario) | issue `night-shift` + launchd 23:00 |
| Harness (subtask, stato su file, contesto fresco per step) | CLAUDE.md + SAL + grafo + commesse precaricate |
| Verifica | `.night-verify` + morning-gate col banco |
| Memoria persistente (file system come estensione del contesto) | SAL.md + metrics/gate.csv + lezioni |
| Loop sul loop | commessa → notte → gate → correttore → notte |

**I cinque livelli di verifica** (tassonomia assorbita, i nostri nomi):

| Livello | Qui |
|---|---|
| 1 · deterministico (booleano) | `.night-verify`: exit code, test-motore |
| 2 · regole e vincoli numerici | soglie, conteggi asserzioni, metriche del gate |
| 3 · verità terrena ritardata | **il "riscontro" BC**: Verificato ☐ che matura quando i dati veri arrivano; esiti deploy |
| 4 · LLM giudice | banco avversariale — variante POTENZIATA: un modello che prova a smentire batte un modello che si autovaluta |
| 5 · checkpoint umano | la review di Luca — mai saltato, chiude ogni ciclo |

Comando per i loop diurni iterativi: **`/goal`** (obiettivo verificabile + tetto di tentativi,
log di ogni tentativo in `loops/`). Tensione dichiarata e voluta: la notte non ha limite di
tempo (decisione del 2026-08-21, guardia = review del mattino); i loop `/goal` diurni hanno
sempre un tetto — commessa unica e lunga vs ottimizzazione iterativa: contesti diversi,
regole diverse, entrambe giuste.

## Plugin adottati nel tessuto (2026-08-21)

| Plugin | Dove | Cosa porta | Cosa NON abbiamo preso |
|---|---|---|---|
| **ponytail** (107k ⭐) | OpenCode (notte) + Claude Code | scala minimale in §2, notte minimalista, DEBITI.md, minimità nel gate | ultra, mcp |
| **superpowers** (275k ⭐) | Claude Code | guardrail tre-strike §5, /brainstorming ZCode | subagent-review, execute-plan, skill-writing |

Flusso giorno: **/brainstorming → /goal → (notte minimalista) → gate a tre controlli**.

## Percorso cloud/ibrido (da review 2026-08-21 §4.1)

Una sessione cloud/remota (es. Claude Code nel container) NON ha `gh` CLI né accesso a
`night-shift/repos.conf` (locale del Mac per design). Cosa può fare da sola: commit di file
(es. `.night-verify`) via tool MCP GitHub. Cosa resta manuale sul Mac del proprietario: creare
la label `night-shift` (i tool MCP disponibili non la creano) e aggiungere la repo a
`repos.conf`. Un agente cloud che esegue l'onboarding O il bootstrap di un progetto nuovo
deve dirlo all'utente, non tacere i passi rimasti (dettaglio operativo in testa sia a
`tools/onboard-repo.sh` che a `tools/bootstrap-app.sh` — stesso limite, due script
gemelli, entrambi chiamano `gh` direttamente; 4° ciclo, set 3, giro 8, 2026-08-23: prima
citava solo "l'onboarding", non il bootstrap).

## Il ciclo guadagna la fase di audit (2026-08-21, sera)

```
/brainstorming → design-doc → commessa → /audit-commesse (il giorno verifica le assunzioni
sul codice PRIMA della notte) → notte → gate (night/* E claude/*: due occhi) → review di Luca
```

- **`/audit-commesse <repo>`** (Claude e ZCode): audita le commesse in coda contro il codice
  reale, corregge i body, compila la "Forma dei dati (verificata)". Nato dall'A/B: la commessa
  con l'assunzione sbagliata costa alla notte ore, al giorno una lettura
- **`/design-doc <feature>`** (Claude e ZCode): 2-3 opzioni confrontate su criteri
  espliciti (costo/rischio/reversibilità + criteri specifici alla decisione, dichiarati
  PRIMA delle opzioni, in una tabella opzioni×criteri — 4° ciclo, set 2, 2026-08-23: non
  più un trade-off narrativo libero), senza implementare — la scelta resta di Luca. È il
  passo /brainstorming che diventa documento. Implementato come skill Claude in
  `.claude/skills/design-doc/SKILL.md` (set 2 2026-08-22: prima citato qui senza esistere
  — stesso debito già chiuso per `/audit-commesse`)
- **Il gate guarda anche i branch `claude/*`**: il lavoro del giorno passa le stesse verifiche
  dichiarate e lo stesso banco avversariale di quello notturno

## Il ciclo guadagna il controllo di gestione (4° ciclo, set 1 "agenti", 2026-08-23)

- **`/controllo-gestione`** (Claude e ZCode): ancora un calcolo contabile/gestionale
  reale (contabilità analitica, di magazzino, controllo di gestione, margini, cespiti) a
  una formula esistente citata come oracolo (mai indovinata) — generalizza per questo
  dominio lo schema censimento+riscontro già in uso ad-hoc per Business Central
  (`PROJECT.md`). Implementato come skill Claude in
  `.claude/skills/controllo-gestione/SKILL.md`. Nato da un censimento di un repo esterno
  (codice anonimo **REPO-E**, regola "Public repo, private work": questo hub è pubblico,
  mai nomi reali) che ha trovato ~10 calcoli di controllo di gestione reali già
  implementati ma nessun metodo condiviso per affrontarne uno nuovo senza indovinare la
  formula. Primo caso risolto: `tools/riconciliazione_magazzino.py`.
- Citata anche nel template `.github/ISSUE_TEMPLATE/night-shift.md` (sezione
  "## Forma dei dati") e propagata ai progetti nuovi/esistenti come le altre skill
  (`tools/bootstrap-app.sh`, `tools/onboard-repo.sh` — copia wholesale di
  `.claude/skills/`, nessuna riga dedicata necessaria).
