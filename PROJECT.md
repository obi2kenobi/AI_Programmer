# PROJECT.md — Project-Specific Context

Concrete, project-specific instructions. The universal behavioral rules live in `CLAUDE.md`; this file instantiates them for each project — one section per project.

---

## Motore (`app/engine`) — porting del legacy

### Circuito di validazione → scoperte sempre persistite (deciso con Luca 2026-05-31)
Costruire il **motore nuovo** (`app/engine`) significa riprodurre il **motore legacy reale** al millimetro
(banco `tools/motore-test/`). In questo processo emergono scoperte e si trovano errori — di **due tipi distinti**:
- **bug del vecchio** (es. MC-*) → si correggono nel vecchio e diventano *requisito* del nuovo (`docs/47`, `docs/48`);
- **errori nei nostri appunti/oracoli** (dati trascritti male) → si correggono e si annotano **come tali**, non come MC-*.

Istanzia la regola universale _"Keep living documentation, not just commits"_ — ogni scoperta/correzione va scritta nei luoghi giusti PRIMA dello step successivo. Mappatura dei tre tipi di documento:
- **`SAL.md`** — _decisioni e idee_ + diario vivo (stato + §8 log cronologico).
- **`docs/48`** — _come funziona_: "oro del motore", formule/regole validate come requisiti del nuovo.
- **`docs/47`** — _correzioni_ applicate (separando bug del vecchio da errori-dato nostri).

La _validation artifact_ del progetto (regola universale _"Done means proven"_) è `last_dump.txt`.

### Stack / comandi
- Test motore: `pnpm --filter @myhouse/engine test` · Lint/format: `pnpm exec biome check engine/src` (da `app/`).
- Banco legacy headless: `php tools/motore-test/harness.php tools/motore-test/fixtures/<id>.php` → `last_dump.txt`.

---

## Business Central — analisi dati commerciali (GRUPPO CAMARLINGHI)

Lavoro: estrazioni dati, report, dashboard, analisi commerciali — anche via skill `bc-commercial-intelligence`.

### Calcoli contabili/gestionali sui dati BC (4° ciclo, set 3, 2026-08-23)
Se il lavoro richiede CALCOLARE una cifra (margine, valorizzazione, scostamento,
roll-forward, indice) e non solo estrarre/mappare dati, usa la skill
`.claude/skills/controllo-gestione/SKILL.md` (hub AI_Programmer): la formula si cita
come oracolo dal codice esistente o si chiede al proprietario del dominio, non si
indovina. Distinta dal censimento campi qui sotto: quello è "che dati esistono", questo
è "come si trasformano in un numero corretto".

### Censimento campi prima dell'analisi (vincolante)
Prima di qualsiasi report/analisi, costruisci un quadro **completo e definitivo** dei dati:
- **Testa ogni endpoint** di `CATALOGO_ENDPOINT_BC.md` (il file NON vive in questo hub: sta nel repo del cliente — vedi sotto) e **testa ogni campo** che restituisce.
- Mappa **tutti** i campi, non solo quelli che sembrano utili ora: prima o poi servono tutti, non scartarne nessuno.
- È completezza di _conoscenza/mappatura_, non codice speculativo — quindi non viola la regola _"Only what is asked"_.

### Come si verifica un risultato (validation artifact)
Processo a due fasi, in quest'ordine:
1. **Mappatura** — estrai i campi dagli endpoint e mappali (cosa sono, da dove vengono).
2. **Riscontro** — confronta con una fonte di verità: interfaccia BC, gestionale, o totali noti.

Un risultato è corretto (regola _"Done means proven and confirmed"_) **solo dopo il riscontro**, mai dopo la sola estrazione.

### Persistenza della conoscenza (struttura `docs/bc/`)
Istanzia _"Keep living documentation"_. 108 endpoint → un file per endpoint, più un indice:
- **`docs/bc/README.md`** — indice + avanzamento: tabella endpoint → stato (da mappare / mappato / verificato), X su 108.
- **`docs/bc/endpoints/<NomeServizio>.md`** — 1 file = 1 endpoint: URL, tabella BC, **elenco completo dei campi** (nome, tipo, significato, stato verifica, note di riscontro).
- **`docs/bc/SAL.md`** — diario vivo + decisioni: **sempre aggiornato**.
- **`docs/bc/CORREZIONI.md`** — errori di mappatura trovati e correzioni applicate.

### Stack / accesso
- Endpoint: **108** catalogati in `CATALOGO_ENDPOINT_BC.md` (OData V4) — il catalogo vive nel REPO DEL CLIENTE, non in questo hub (pattern citazione-non-presidio: il riferimento dichiara dove sta).
- Auth: OAuth2 `client_credentials` (Azure AD), scope `.default`. Tenant/client/secret in **`credenziali BC.rtf`** (confermato 2026-06-23; il `Config.gs` del catalogo è la copia del backend GAS).
- Strumento: **`tools/bc_map.py`** (Python stdlib, nessuna dipendenza) — legge le credenziali a runtime, prende il token, interroga l'endpoint e genera `docs/bc/endpoints/<Nome>.md`. Per un test al volo: `curl`.
- Regola segreti: credenziali usabili per autenticarsi, mai riprodurne i _valori_ in output, commit o documenti (regola _"Never expose secrets"_).
