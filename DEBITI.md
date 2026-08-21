# DEBITI.md — il registro delle scorciatoie rimandate

Ogni scorciatoia deliberatamente rimandata (regola §2, da ponytail) si scrive qui:
cosa, perché è stata rimandate, quando va saldata. "Poi" non deve diventare "mai".

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| | | | |

## Da review Opus 2026-08-21 (rinvii deliberati)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 | Rotazione log di ~/night-shift.log e ~/morning-gate.log | nessun limite raggiunto | quando un file supera ~10 MB |
| 2026-08-21 | Path /opt/homebrew hardcoded (ollama) — portabilità Intel/Linux | scelta "solo Mac Apple Silicon" dichiarata | se il sistema girerà altrove |
| 2026-08-21 | Test funzionali per bc_map.py / bc_index.py | nessuna regressione ancora | alla prima modifica sostanziale |

## Da dev-critic — verifica dogfooding della review Opus (2026-08-21, notte)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 | `gate_allowlist_ok()` (`night-shift/lib.sh`) verificata bucabile: `bash -c`, `python3 -c`, `awk system()`, `sed .../e` passano l'allowlist perché controlla solo il primo token, non cosa fa l'interprete con gli argomenti — testato dal vivo (bypass confermati). Il sandbox seatbelt non compensa: nega solo rete e scrittura fuori workdir, non la lettura. Non corretto in questo giro: cambia il modello di minaccia, serve il sì esplicito di Luca prima di stringere ulteriormente l'allowlist o negare le letture nel sandbox | decisione di design, non bug meccanico — rimandata al prossimo giro con Luca |
| 2026-08-21 | Stesso file: lo split su `;`/`\|`/`&&`/`\|\|` non rispetta le virgolette — un comando legittimo con quei caratteri dentro una stringa citata (es. `grep -c "a;b" file`) viene scartato per errore di parsing, non per una vera protezione (falso positivo) | minore, non blocca nulla oggi (il banco può sempre riprovare un comando diverso) | se un banco avversariale legittimo comincia a essere scartato spesso |
