# router/ — WayfinderRouter, il tessuto: cosa usiamo e cosa no (tutto verificato)

## Le ricette di collegamento (verificate 2026-08-21, build 2026.8.0)

| Client | Come | Stato |
|---|---|---|
| OpenCode | `wayfinder-router connect opencode` (già applicato in `~/.config/opencode/opencode.json`) | ✅ |
| Claude Code → LOCALE | `llm/claude-local.sh` — `ANTHROPIC_BASE_URL=http://127.0.0.1:8088` (endpoint Anthropic inbound testato) | ✅ |
| Claude Code → Opus | **non passa dal router**: outbound Anthropic non implementato — sessione/`ask-opus` diretti | ⛔ limite del prodotto |
| Codex | `wayfinder-router connect codex` | non usato |

## Cosa usiamo

- Routing lessicale deterministico → destinazione locale (`localhost:11434/v1`, Qwen3.8-27B)
- Header di trasparenza: `x-wayfinder-router-served-by/-score/-request-id`
- `/healthz`, `doctor --config`, circuit breaker verso Ollama, failover fail-closed
- **Il turno notturno NON dipende dal router** (OpenCode ha anche la linea diretta): garanzia
  «nessun punto di failure singolo»

## Leve disponibili, non ancora usate

- **Privacy posture** (`on-device-only` / `local-devices` / `hosted-allowed`, header per richiesta;
  `offline = true` forza on-device): LA leva per i dati aziendali (BC) — quando una richiesta
  deve essere garantita on-device, si dichiara
- **Route nominate** (`@route/night`, `@route/digest` in config): routing verificato ma risposta
  vuota nel test → **SPERIMENTALI**: non farci conto finché indagate
- Virtual keys, deployment pools, tier hosted: per quando le metriche del gate lo giustificheranno

## Config

- Template versionato: `wayfinder-router.toml` (nessun segreto, solo riferimenti)
- Live: `~/.config/wayfinder-router/wayfinder-router.toml`
- Servizio: LaunchAgent `com.luca.wayfinder` (KeepAlive, WorkingDirectory scrivibile —
  il router scrive la savings dir relativa alla CWD: da root in sola lettura muore)
