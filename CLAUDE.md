# CLAUDE.md — Standard Working Rules

These rules are binding for every development session. No exceptions.

> **Tradeoff:** these rules bias toward caution over speed. For trivial tasks, use judgment.

---

## 1. Process Rules

### Read before acting
Understand the current state of the repo before touching anything. Read relevant files, check git status, understand the context.

### One problem at a time
No jumping ahead, no parallel work on multiple things. Step by step. Complete one task before starting the next.

### Repeat the request in your own words
Before executing, confirm understanding by rephrasing the request. Wait for explicit approval before proceeding.

### If something is unclear, ask — never guess
One extra question is always better than one wrong assumption. Never invent requirements, business logic, or expected behavior.

### Surface interpretations and tradeoffs — don't pick silently
If multiple interpretations exist, present them all instead of choosing one in autonomy. State your assumptions explicitly. If a simpler approach exists, say so and push back when warranted.

### Input and output examples before writing code
Require concrete examples of what goes in and what should come out before implementing any logic.

### Goal-driven execution — define success criteria, loop until verified
Transform tasks into verifiable goals before starting:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan with a check per step:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```
Strong, verifiable criteria let you proceed independently. Weak ones ("make it work") require constant clarification.

### Done means proven and confirmed, never claimed
A step is done only when both hold: you **show the evidence** (passing test, command output, the project's validation artifact) **and** the domain owner **confirms the result is correct**. The user owns the domain knowledge — a technical green light is not the same as being right. Until both, it isn't done.

### Keep living documentation, not just commits
The project's knowledge lives in versioned `.md` documents kept current as you work — not only in commit messages or in your head. Maintain, in the files the project designates:
- **How it works** — validated behavior, formulas, rules: the requirements of record.
- **Decisions and ideas** — why a choice was made, alternatives weighed, open questions.
- **Discoveries and corrections** — write them down BEFORE the next step. Distinguish defects in the system you're studying or reproducing (they become requirements) from errors in your own notes or assumptions (annotate as such, never as defects of the system).

---

## 2. Code Rules

### Only what is asked
No additions, no spontaneous "improvements", no unrequested initiatives. If it wasn't asked for, don't do it.

**The test:** every changed line must trace directly to the user's request.

### Zero waste
No superfluous code, no unnecessary files, no over-engineering. The simplest solution that works is the right one.

**The test:** "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Short functions
If a function exceeds 30-40 lines, it must be broken down. Each function does one thing.

### One file, one responsibility
No monolithic files. Every file has a single, clear purpose.

### No dead code
Don't leave commented-out code, unused imports, or placeholder functions. If it's not used, delete it.

### Respect existing patterns
Follow the conventions already present in the codebase: naming, structure, formatting, architecture. Consistency over personal preference.

### Never expose secrets
Never log, print, paste, or commit credentials, tokens, or sensitive data (credential files, `.env`, key exports). Refer to secrets by file path, not by value. If a secret appears in something to be committed or shared, stop and flag it.

---

## 3. Communication Rules

### Respond in the user's language
If the user writes in Italian, respond in Italian. If in English, respond in English. Match the language of the conversation.

### Be direct and concise
No filler, no unnecessary preambles. State what you're doing and why, then do it.

### Report problems immediately
If something doesn't work, is ambiguous, or seems wrong — say it immediately. Don't try to silently work around issues.

### Show, don't tell
When explaining a change, show the relevant code. When reporting a result, show the output.

---

## 4. Git Rules

### Commit after every working step
So we can always roll back to a point that works. Each commit represents a stable, functional state.

### Commit messages format
Use clear, descriptive messages. Format: `<type>: <short description>`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

Example: `feat: add export functionality for usage reports`

### Never force push
Never use `--force` on shared branches unless explicitly asked.

### Review changes before committing
Always check `git diff` before committing to ensure only intended changes are included.

---

## 5. Error Handling

### Read the error completely
Before attempting a fix, read the full error message and stack trace. Understand the root cause.

### Fix the cause, not the symptom
Don't add workarounds. Find and fix the actual problem.

### One fix at a time
When debugging, change one thing at a time and verify the result before making the next change.

---

## 6. Project-Specific Context

These rules are universal and portable across projects. Concrete project context — file roles, commands, per-project conventions — lives in **`PROJECT.md`**. Read it at the start of each session and keep it in sync.

---

## 7. Delegation & Routing

This repo **calls the LLMs**: uniform wrappers in `llm/` let any project, script, or agent delegate
to any brain with the same gesture (`llm/ask-qwen.sh "..."`, stdin for long context).

### When to delegate — and to whom
- **Local brain (ask-qwen)**: high-volume, low-risk, verifiable work — digests, drafts, triage,
  mechanical commesse. Zero marginal cost, data never leaves the Mac. Measured: 3.7-5.9 tok/s idle.
- **Night shift** (see `night-shift/README.md`): GitHub issues labeled `night-shift` become draft
  PRs overnight. No time limit per issue (decided 2026-08-21). Issues must be **pre-loaded work
  orders** (snippets, line numbers, ready greps) — never investigation briefs: three nights proved
  the local model understands but does not converge when judgment is required.
- **Cloud brains (ask-opus / ask-glm)**: programmatic pipelines. Otherwise work in direct sessions.

### Never delegate
- Architectural decisions, investigations, judgment calls — these belong to the day brains.
- Anything whose verification was not declared **before** the work started (_"Done means proven"_).
- Secret **values** in any prompt (references by file path only — _"Never expose secrets"_).

### Full method
`night-shift/README.md` (method, binding rules, measured numbers) and `llm/README.md`
(decision matrix). System map with every constraint and its provenance: `docs/system.md`.

### Navigation before reading (graphify, from 2026-08-21)
Before paging through files to locate code, query the graph: `graphify query "<question>"`
returns a deterministic subgraph with exact `file:L` references (build with
`graphify extract . --code-only` if `graphify-out/graph.json` is missing). The local brain at
~4 tok/s must never pay the read-everything tax — and neither should you. Trust the graph for
orientation and location; never as an oracle for call semantics (`calls` edges are unresolved —
lesson paid by AI_Develop on 2026-08-08).

### Goal loops (/goal)
For iterative optimization during the day use `/goal <verifiable objective> | max N attempts`:
restate the objective as a verification with its level (1-5, see docs/system.md), one change per
attempt, log every attempt in `loops/<date>-<slug>.md`, adversarial check before claiming
success, hard attempt cap. Note the deliberate asymmetry: night shift has NO time limit (single
long commessa); day goal loops always have a cap (iterative optimization).
