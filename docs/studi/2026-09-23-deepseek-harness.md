# Studio a fondo: deepseek-harness — cosa rubiamo davvero

(hub: obi2kenobi/AI_Programmer — integrazione delle idee, NON del software: e' developer
preview senza audit di sicurezza, nodo/pnpm, e il turno non affida la produzione a un preview)

## I sei furti (in ordine di valore per noi)

### 1. CATALOGO EVENTI (da event-producer-consumer.md)
Il loro documento elenca ogni evento: chi lo produce, chi lo consuma. Il nostro equivalente
sono le firme di log: "DELIBERA:", "TRASFORMATORE deterministico", "gate BOCCIA",
"MIGLIORIA pronta", "AGENTE FALLITO", "Ollama wedged", ecc. L'audit-2 ha dimostrato che
una firma senza consumatori = contatore cieco per mesi. Il catalogo:
  docs/eventi.md: firma -> chi la scrive (file:riga) -> chi la legge (dashboard.py:riga,
  cervello-impara.sh:NN, turno NN) -> se ha guardia (test che verifica il flusso)
Guardiano: test-eventi.sh — per ogni firma nel catalogo, verifica che il produttore esista
ancora e abbia almeno un consumatore vero.

### 2. REPEAT-TOOL-REMINDER (da guard/repeat-tool-reminder)
Il loro guard osserva quando il modello ripete l'identica chiamata a tool e glielo ricorda
("cambia approccio o finisci"). Il nostro agente.sh: l'agente puo' fare 8 turni di edit
sullo stesso file senza che nessuno gli dica niente — la "non-convergenza sui bersagli
debito" che abbiamo visto. La cura: nel loop dell'agente, se l'azione N e' IDENTICA
all'azione N-1 (stesso JSON), il RESULT porta un avviso: "hai ripetuto la stessa identica
azione: cambia approccio o dichiara finish". Zero costo, azzerabile via env.

### 3. GOAL DURABLE (da packages/goal)
Loro: un objective per sessione che sopravvive a restart, resume e fork, con tools
create/get/update e il comando umano /goal. Il nostro equivalente mancante: una issue
lunga puo' attraversare 5 cicli del turno e nessuno ricorda QUAL'E' l'obiettivo. Il
nostro adattamento bash: .git/goal-issue-N (file di stato nel repo di lavoro, come
caccia-registro): l'agente ce l'ha nel prompt (obiettivo + cosa gia' fatta), il censore
lo vede ("questa PR serve al goal #N?"), la dashboard lo mostra. Per le issue lunghe.

### 4. LEZIONI POSTMORTEM (da postmortem/0003)
Il loro postmortem 0003 e' esattamente la nostra classe E-038: l'agente ha "verificato"
un server diverso da quello dell'utente perche' non sapeva QUALE fosse il suo ambiente.
La lezione da portare nel nostro REGISTRO come E-039:
  "L'agente deve conoscere i prerequisiti nascosti del runtime: la modalita' di avvio
  e' contesto dell'applicazione, non sapere tribale. Verifica CONTRO lo stato esterno,
  non contro il self-report."

### 5. VERIFY THE WORLD, NOT THE SELF-REPORT (da testing.md)
La loro regola di test piu' preziosa: "un'e2e assertion RIesEGUE il comando o RIlegge il
file esternamente; una keyword probe sull'output dell'agente lascia passare un agente
che bara. Assert che i file non toccati siano byte-identici."
Il nostro banco deploy-assistito lo fa gia' (verifica STORICO + pacchetto consumato);
generalizziamo la regola nel metodo: ogni banco che verifica un lavoro dell'agente deve
guardare il MONDO dopo, non l'output dell'agente.

### 6. PROFILO UNICO DEL TURNO (da profiles/bundles)
Tutta la configurazione dichiarata in un punto e ricomposta a avvio. Il nostro equiv:
profiles/notturno.conf letto a inizio ciclo (il nostro exec-per-ciclo = HMR gratis):
modello, timeout, budget agenti, rotazione lenti. Sostituisce i default sparsi in 7 file.

## Cosa NON prendiamo (e perche', dichiarato)

- Il software stesso: developer preview, no audit, breaking changes annunciati; il
  turno e' 24/7 incustodito. SAFETY.md loro: "must not be treated as secure or
  production-ready".
- Compaction automatica: il nostro agente ha num_ctx fisso e turni brevi per design;
  la conversazione non cresce abbastanza da giustificarla.
- Agent teams / spawn_teammate: il turno e' seriale per design (lock per repo);
  il parallelismo e' il modo piu' veloce di creare contese GPU su 24GB.
- Browser-use / computer-use: nessun caso d'uso notturno; il browser lo usa il giorno.

---

# Secondo giro di studio: l'ecosistema dei 1.000 plugin

(awesome-dsh-plugin: la community ha prodotto 1.000 plugin in giorni. Ecco
quelli che insegnano qualcosa al NOSTRO sistema, con cosa rubiamo.)

## I 4 plugin che valgono oro per noi

### 1. dsh-repeat-stop (173787247) — "Hard-stop consecutive identical tool calls"
Il nostro repeat-reminder AVVERTISCE; questo plugin HARD-STOPPA dopo N
ripetizioni identiche configurabili. Per l'agente notturno: se dopo il
warning il modello ripete UN ALTRA volta l'azione identica, il terzo colpo
deve essere un exit con dichiarazione, non un altro giro di GPU bruciata.
RUBIAMO: lo stop-dopo-N, non solo il reminder.

### 2. dsh-evidence-gate (AaronandWork) — "cross-checks first-hand claims
against a durable per-session tool-activity index, blocks unverified guesses
and tracks blocked-versus-converted metrics"
Un cancello che verifica OGNI affermazione dell'agente contro l'indice
durable di cio' che i tool hanno DAVVERO fatto in sessione. Blocca le
supposizioni non verificate. E **conta bloccati vs convertiti**.
RUBIAMO: il revisore potrebbe contare quante affermazioni della PR sono
verificate contro l'output reale dei tool vs quante sono supposizione pura.
E la metrica blocked-vs-converted: quante PR il censore ha bloccato che
poi sono state convertite in verifiche vere.

### 3. qiushi-dsh-evidence-audit (030611) — "hash-chained JSONL receipts
for tool results... without storing prompts"
Ricevute con hash-chain per OGNI risultato di tool: immutabili,
verificabili, senza salvare il contenuto. Per il nostro censore: ogni
verifica dichiarata nella PR porta il suo hash — se l'hash non torna,
la prova e' rifiutata.
RUBIAMO: il principio delle ricevute hashate per le prove del censore.

### 4. dsh-auto-memory (Aik358) — "proactive associative memory, three-layer
auto-consolidation, skill crystallization, handoff ledgers that survive
context switches"
Il piu' ambizioso: memoria proattiva a 3 strati con consolidazione
automatica e handoff-ledger che sopravvive ai cambio di contesto.
Il nostro cervello e' a 1 strato (le note statiche) + il /learn serale.
RUBIAMO: l'idea del handoff-ledger — quando l'agente cambia finestra di
contesto (il nostro num_ctx e' fisso ma il modello cambia sessione), il
ledger dice al nuovo what the old one was doing.

## I 3 principi che l'ecosistema conferma

1. **Verification is a plugin, not a feature** — 5+ plugin diversi per
   verificare/attestare/bloccare: la community ha capito che la verifica
   e' un punto di estensione, non un'opzione di configurazione. Il nostro
   sistema la tratta uguale (banco, censore, gate) — conferma che siamo
   sulla strada giusta.

2. **Memory is the battleground** — 15+ plugin di memoria diversi:
   triage, auto-consolidation, handoff, crystallization. Nessuno ha
   ancora vinto. Il nostro cervello è semplice e dichiarato — meglio
   semplice e onesto che complesso e opaco.

3. **Billing/telemetry come categoria a se'** — 6+ plugin solo per
   contare token e costi: la community paga per sapere quanto spende.
   Il nostro bencina fa lo stesso per la GPU locale. Conferma.
