#!/bin/bash
# lib.sh — funzioni condivise del sistema (sourced, non eseguito).
# default_branch(): il branch di default della repo, MAI hardcoded (review 2026-08-21 §2.2:
# tre script assumevano "main" — una repo con "master" rompeva i flussi in silenzio).
default_branch() {
  local dir="$1"
  local ref
  ref=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && {
    echo "${ref#refs/remotes/origin/}"; return 0
  }
  local ghb
  # bug reale (revisione 14 lenti, 2026-08-28): la query jq leggeva `.name` invece di
  # `.defaultBranchRef.name` — con `--json defaultBranchRef` l'oggetto è
  # {"defaultBranchRef":{"name":...}}, quindi `.name` valeva sempre "null" (comando gh
  # riuscito, solo la query sbagliata) e il chiamante non vedeva MAI l'avviso di fallback,
  # perché "&&" scattava comunque con la stringa letterale "null". Verificato con jq sullo
  # stesso schema prima e dopo il fix.
  ghb=$(gh repo view -R "$(git -C "$dir" remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||; s|\.git$||')" \
    --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null) && [ -n "$ghb" ] && [ "$ghb" != "null" ] && { echo "$ghb"; return 0; }
  echo "main" # fallback finale: CHIAMANTE deve avvisare che è un'assunzione
  return 1
}

# mtime(): l'epoch di ultima modifica di un file, portabile (test del sistema completo
# 2026-09-20, D22): `stat -f %m` e' BSD/macOS, su Linux non esiste e il fallback `|| echo 0`
# faceva risultare ogni lock e ogni cooldown «scaduto» (eta' = adesso - 0). Stampa 0 e
# torna 1 se il file non c'e': il chiamante decide.
mtime() {
  local f="$1" t
  t=$(stat -f %m "$f" 2>/dev/null) || t=$(stat -c %Y "$f" 2>/dev/null) || { echo 0; return 1; }
  echo "$t"
}

# rotate_log_if_big(): ruota un log oltre soglia (default 10MB) — una sola generazione
# (file → file.1, sovrascrivendo un .1 precedente: non serve di più per un log locale
# di debug, non un archivio). Debito aperto dal 2026-08-21 ("nessun limite raggiunto");
# night-shift.log e morning-gate.log crescono senza limite da allora.
rotate_log_if_big() {
  local file="$1" soglia_mb="${2:-10}"
  [ -f "$file" ] || return 0
  local size_bytes
  size_bytes=$(wc -c < "$file" 2>/dev/null) || return 0
  local soglia_bytes=$((soglia_mb * 1024 * 1024))
  if [ "$size_bytes" -ge "$soglia_bytes" ]; then
    mv -f "$file" "$file.1"
    : > "$file"
  fi
}

# run_guarded(): esegue un comando con watchdog (i secondi) — l'asimmetria trovata dalla
# review §3 (.night-verify senza timeout fermava il gate per sempre) non torna.
#
# bug reale, alta severità (dogfooding, set 2 "capacità di progettare", 2026-08-22):
# `kill "$wdg"` uccideva solo il SUBSHELL bash che eseguiva "sleep $secs; kill ...", non
# il processo "sleep" che quel subshell aveva generato come figlio — il "sleep" orfano
# restava vivo, e dentro una command substitution ($(...), esattamente come lo chiama
# morning-gate.sh) il descrittore stdout ereditato dal "sleep" orfano teneva la pipe
# APERTA finché il sonno non finiva DA SOLO. Risultato: ogni comando .night-verify (e il
# banco avversariale) impiegava SEMPRE l'intera durata del watchdog (120s in produzione)
# per restituire il risultato, anche se il comando reale finiva in millisecondi —
# verificato dal vivo con `time`: 10.0s esatti per un `run_guarded 10 bash -c "true"`.
# Primo tentativo di fix (`exec sleep` nel subshell watchdog) si è rivelato SBAGLIATO
# alla verifica dal vivo: un secondo subshell non può fare `wait` su un job che non è
# figlio SUO (è figlio del chiamante) — bash lo rifiuta ("not a child of this shell"),
# quindi il killer non uccideva mai il comando davvero bloccato, silenziosamente. Fix
# vero: nessun subshell "figlio di un figlio" — un poll con `kill -0` nel chiamante
# stesso, che possiede sia il comando che il tempo trascorso. Portabile su bash 3.2
# (nessun `wait -n`, non disponibile prima di bash 4.3/5.1 — questo repo ha altrove
# vincoli espliciti di compatibilità con la bash 3.2 di macOS).
# (revisione 10 giri, 2026-09-23): il poll qui sopra mandava TERM al solo figlio diretto e
# restituiva l'rc del comando — un nipote che tiene aperta la pipe (bash -c 'sleep …' dentro
# $(…)) teneva il chiamante per l'intera durata, e un comando che ignora TERM tornava VERDE
# dopo la sua durata intera (riprodotti in tests/test-lib.sh). La cura esisteva gia' in
# llm/_timeout.sh (kill del GRUPPO, KILL dopo 5s, 124 a timeout): run_guarded la usa.
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -F ai_timeout >/dev/null 2>&1 || source "$_LIB_DIR/../llm/_timeout.sh"
run_guarded() {
  local secs="$1"; shift
  ai_timeout "$secs" "$@"
}

# esegui_verifica <dir> <secondi> <riga> <file-uscita>: esegue una riga di .night-verify dalla radice della
# repo, sotto budget, e stampa UNA riga di esito: «VERDE in N s», «ROSSA (rc X) in N s — <ultima riga>»,
# «SFORO DEL BUDGET (S s) — <ultima riga>». L'uscita resta nel file; rc = quello della riga (124 = sforo).
# (2026-09-24, terzo ventaglio, V4#1): il turno scriveva «VERIFICA ROSSA» per ogni rc diverso da 0 e
# buttava l'uscita in /dev/null — uno sforo del budget e un banco rotto erano lo stesso evento, e dopo un
# taglio nessuno sapeva dove la suite si era fermata. L'ultima riga passa dalla maschera: finisce nel log.
esegui_verifica() {
  local dir="$1" sec="$2" riga="$3" out="$4" t0 rc dur ult sen
  t0=$(date +%s)
  (cd "$dir" && ai_timeout "$sec" bash -c "$riga" >"$out" 2>&1 </dev/null); rc=$?
  dur=$(( $(date +%s) - t0 ))
  ult=$(grep -v '^[[:space:]]*$' "$out" 2>/dev/null | tail -1 | cut -c1-160 | mask_secrets)
  case "$rc" in
    # (2026-09-24, quinto ventaglio, R4 R6): la «⚠ SENTINELLA» della suite (budget oltre il 70%) restava nel file
    # d'uscita, che il ciclo dopo sovrascrive: nel log arrivava solo «VERDE». Ora viaggia nella riga VERDE.
    0) sen=$(grep -m1 'SENTINELLA' "$out" 2>/dev/null | cut -c1-160 | mask_secrets)
       echo "VERDE in $dur s${sen:+ — $sen}" ;;
    124) echo "SFORO DEL BUDGET ($sec s) — ${ult:-nessuna uscita}" ;;
    *) echo "ROSSA (rc $rc) in $dur s — ${ult:-nessuna uscita}" ;;
  esac
  return "$rc"
}

# riga_verifica_vuota <riga>: 0 se la riga di .night-verify non e' un comando — vuota, soli spazi o TAB, un commento
# anche indentato. (2026-09-25, settimo ventaglio, V1 R5): la regola UNICA dei lettori di .night-verify. Il turno saltava
# solo "" e «#» in prima colonna: una riga di spazi era `bash -c "   "`, rc 0, «verifica VERDE».
riga_verifica_vuota() {
  local t="${1#"${1%%[![:space:]]*}"}"
  case "$t" in ""|\#*) return 0 ;; esac
  return 1
}

# verdetto_verifica <rc> <comando>: la parola che il commit porta per la `## Verifica` dell'issue. (2026-09-25, settimo
# ventaglio, V2 R3): ogni rc diverso da 0 era «ROTTA» — anche 127 (il comando non c'e': node fuori dal PATH del plist)
# e 124 (il tetto di 60 s). Un finto rosso insegna a ignorare i rossi (D2 2026-09-07).
verdetto_verifica() {
  case "$1" in
    0) echo "PASSA" ;;
    124) echo "SFORO del tetto (60 s): $2" ;;
    126|127) echo "NON ESEGUITA (comando assente o non eseguibile, rc $1): $2" ;;
    *) echo "ROTTA: $2" ;;
  esac
}

# gate_banchi <dir> [secondi-per-banco=300]: il gate del fixer notturno — esegue i banchi di <dir>/tests
# (la copia del ramo con i fix), ciascuno sotto tetto, con un secondo tentativo dopo 2 s per i transienti.
# Stampa «amber <banco>» (passato al secondo), «rosso <banco> — <motivo>» (una riga FAIL, o SFORO), e
# per ultima «TOTALE <verdi> <rossi>». Gli stessi banchi della suite: nessuno escluso (settimo ventaglio, V1 R6).
# (2026-09-24, terzo ventaglio, V1#1, V1#5, V4#6): il ciclo viveva in night-shift.sh e lanciava
# $HERE/../tests — la copia VIVA, non il ramo — senza tetto: un banco che si annidava (E-046) ha fermato il
# turno per sempre, e il commit diceva «banco CHIUSO su questo branch» senza averlo provato.
gate_banchi() {
  local dir="$1" sec="${2:-300}" tt nome out rc pass=0 fail=0
  for tt in "$dir"/tests/test-*.sh; do
    [ -f "$tt" ] || continue
    nome=$(basename "$tt")
    # (2026-09-25, settimo ventaglio, V1 R6): qui si saltavano test-ask-*, test-ai-timeout* e test-stdin-timeout* «perche'
    # chiamano cervelli esterni». Non e' piu' vero: sono ermetici (misurato con un PATH senza claude ne' ollama, 22 s in
    # tutto), e la suite li esegue. Toccato uno di loro dal fixer, nessun banco del gate lo riprovava.
    # (2026-09-25, settimo ventaglio): rc 0 non basta, come in tools/suite.sh — un banco senza asserzioni (o
    # che muore VERDE dentro un `source`) esce 0 lo stesso. Si pretende «N OK, 0 FAIL» con N >= 1; il muto e'
    # rosso subito, senza secondo tentativo (non e' un transitorio).
    out=$(cd "$dir" && ai_timeout "$sec" bash "$tt" 2>&1 </dev/null); rc=$?
    if [ "$rc" -eq 0 ] && grep -qE '^[1-9][0-9]* OK, 0 FAIL( |$)' <<<"$out"; then
      pass=$((pass+1)); continue
    fi
    if [ "$rc" -eq 0 ]; then
      fail=$((fail+1)); echo "rosso $nome — verde senza verdetto (manca «N OK, 0 FAIL» con N >= 1)"; continue
    fi
    sleep 2
    out=$(cd "$dir" && ai_timeout "$sec" bash "$tt" 2>&1 </dev/null); rc=$?
    if [ "$rc" -eq 0 ] && grep -qE '^[1-9][0-9]* OK, 0 FAIL( |$)' <<<"$out"; then
      pass=$((pass+1)); echo "amber $nome"
    elif [ "$rc" -eq 0 ]; then
      fail=$((fail+1)); echo "rosso $nome — verde senza verdetto (manca «N OK, 0 FAIL» con N >= 1)"
    else
      fail=$((fail+1))
      if [ "$rc" -eq 124 ]; then echo "rosso $nome — SFORO del tetto di ${sec}s"
      else echo "rosso $nome — $(grep FAIL <<<"$out" | head -2 | tr '\n' ' ' | mask_secrets)"; fi
    fi
  done
  # (settimo ventaglio, V1 R6): zero banchi non e' verde — la suite con zero banchi e' rossa (tools/suite.sh)
  [ $((pass + fail)) -eq 0 ] && { echo "rosso (nessun banco) — nessun tests/test-*.sh da giudicare in $dir"; fail=1; }
  echo "TOTALE $pass $fail"
}

# funzione_definita_e_chiamata <file> <nome>: 0 se <file> DEFINISCE `function <nome>(` e la CHIAMA su un'altra
# riga. (2026-09-24, terzo ventaglio, V1#3): il turno contava `nome(` ovunque — vero gia' sulla riga della
# definizione — e `function nome` prendeva anche nomeBar: ogni issue che nominava foo() era «gia'
# implementata» e saltata per sempre.
funzione_definita_e_chiamata() {
  local f="$1" n="$2" def="function[[:space:]]+$2[[:space:]]*\\("
  grep -qE "$def" "$f" || return 1
  grep -E "(^|[^A-Za-z0-9_\$.])${n}[[:space:]]*\\(" "$f" | grep -vcE "$def" >/dev/null   # -c, non -q: E-002
}

# ambiente_turno: una riga per il log — la bash, il ramo di ai_timeout, la sandbox (2026-09-23, notte dei
# giri, T3#6). Il turno gira sul Mac, i banchi su Linux: senza questa riga le differenze fra i due
# (il ramo perl del timeout, la sandbox) non si misurano dal log.
# (2026-09-24, sesto ventaglio, S5 R4): diceva la bash del TURNO, ma i banchi partono con `bash` dal PATH (sul Mac
# /opt/homebrew/bin viene prima di /bin): possono essere due bash diverse. E i tre strumenti che al Mac hanno gia'
# morso (sed, timeout, setsid) non si leggevano dal log. Ora la riga dice anche loro.
ambiente_turno() {
  local sb="ASSENTE (esecuzioni senza sandbox; il censore rinvia)" bf sed_s ss
  command -v sandbox-exec >/dev/null 2>&1 && sb="sandbox-exec"
  bf="$(command -v bash) $(bash -c 'echo $BASH_VERSION' 2>/dev/null)"
  sed_s=$(sed --version 2>/dev/null | head -1 | cut -c1-30); sed_s=${sed_s:-BSD}
  ss=$(command -v setsid >/dev/null 2>&1 && echo si || echo ASSENTE)
  echo "ambiente: bash $BASH_VERSION · bash dei figli: $bf · timeout: $(ai_timeout_ramo) · sed: $sed_s · setsid: $ss · sandbox: $sb"
}

# gate_allowlist_ok(): TRUE solo se OGNI segmento del comando (split consapevole delle
# virgolette su && || ; |) inizia con uno strumento che NON PUÒ eseguire codice via argomenti.
# Decisione di Luca 2026-08-21 (opzione c): niente interpreti general-purpose — bash -c,
# python3 -c, awk system(), sed /e, npm run bypassavano il controllo sul primo token
# (verificato dal vivo da dev-critic, vedi DEBITI.md). Il banco smentisce con grep/cat/git.
gate_allowlist_ok() {
  python3 - "$1" <<'PY'
import sys, re
cmd = sys.argv[1]
# bug reale, ALTA (revisione 14 lenti, 2026-08-28): il controllo guardava solo il PRIMO
# TOKEN di ogni segmento — non riconosceva una sostituzione di comando ANNIDATA dentro un
# segmento già ammesso. `echo $(python3 -c "...")` superava l'allowlist (primo token=echo,
# ammesso) ma la sostituzione faceva comunque girare python3 -c con codice arbitrario dentro
# la sandbox seatbelt (che nega solo rete/scritture, non la lettura). Riprodotto dal vivo.
# Rifiuto conservativo: qualunque sostituzione di comando o processo, ovunque compaia nella
# stringa (anche dentro virgolette singole — non vale la pena distinguere, è un banco
# avversariale, non un interprete shell general-purpose).
if "$(" in cmd or "`" in cmd or "<(" in cmd or ">(" in cmd:
    sys.exit(1)
# (2026-09-24, quarto ventaglio, Q5 R1): un A CAPO separa i comandi per la shell ma non per
# split_operators — `grep x f<a capo>touch …` faceva girare la seconda riga senza esame (in agente.sh,
# con eval). Un comando del banco sta su una riga: qualunque carattere di controllo si rifiuta.
if re.search(r"[\x00-\x1f\x7f]", cmd):
    sys.exit(1)
# (Q5 R1): l'espansione delle graffe (`.{.,}/` diventa `../`) si rifiuta fuori dalle virgolette; una
# regex fra virgolette (`grep -E "a{2}"`) resta un dato
def fuori_dalle_virgolette(c):
    out, q = [], None
    for ch in c:
        if q:
            if ch == q: q = None
        elif ch in "\"'":
            q = ch
        else:
            out.append(ch)
    return "".join(out)
if re.search(r"\{[^}]*(,|\.\.)[^}]*\}", fuori_dalle_virgolette(cmd)):
    sys.exit(1)
# le sole redirezioni ammesse: verso /dev/null e 2>&1 (non scrivono niente) — tolte PRIMA del
# controllo sulle redirezioni in split_operators (revisione 10 giri)
cmd = re.sub(r"(?<![\w&])[12]?>>?\s*/dev/null", " ", cmd).replace("2>&1", " ")
# split consapevole delle virgolette: gli operatori DENTRO stringhe citate non separano
# (chiude anche il falso positivo documentato in DEBITI: grep -c "a;b" file)
# (revisione 10 giri, 2026-09-23): anche `&` singolo separa (il comando dopo girava in
# background senza esame) e una redirezione `>` FUORI dalle virgolette rifiuta tutto (il
# banco e' in sola lettura: `grep x f > out` scriveva). Dentro le virgolette restano dati.
def split_operators(c):
    out, buf, q = [], [], None
    i = 0
    while i < len(c):
        ch = c[i]
        if q:
            buf.append(ch)
            if ch == q: q = None
        elif ch in "\"'":
            q = ch; buf.append(ch)
        elif c[i:i+2] in ("&&", "||"):
            out.append("".join(buf)); buf = []; i += 2; continue
        elif ch == ">":
            sys.exit(1)
        elif ch in ";|&":
            out.append("".join(buf)); buf = []
        else:
            buf.append(ch)
        i += 1
    out.append("".join(buf))
    return out

# (2026-09-23, notte dei giri, T5#2): l'allowlist guardava QUALE strumento gira, non COSA legge —
# `cat ~/.git-credentials`, `echo $ZHIPUAI_API_KEY`, `cat /proc/self/environ` passavano, e agente.sh
# poteva scriverne il contenuto in un file che il `git add -A` del turno spinge. Il confine e' il
# progetto: un `$` fuori dagli apici singoli (espansione), un argomento che inizia con / o ~ (anche
# dopo `--opzione=`), un `..` come cartella — si rifiuta. `HEAD~1..HEAD` resta ammesso.
def fuori_dagli_apici_singoli(c):
    q = None
    for ch in c:
        if q:
            if ch == q: q = None
        elif ch in "\"'":
            q = ch
        if ch == "$" and q != "'":
            return True
    return False
if fuori_dagli_apici_singoli(cmd):
    sys.exit(1)
def fuori_dal_progetto(tok):
    # (Q5 R1): apici e backslash si tolgono TUTTI, non solo ai bordi — `'.''.'/`, `\../` e `"."."/`
    # la shell li ricompone in `../`
    t = re.sub(r"[\"'\\]", "", tok)
    for v in (t, t.split("=", 1)[1] if "=" in t else ""):
        v = v.strip("\"'")
        if v.startswith(("/", "~")) or re.search(r"(^|/)\.\.(/|$)", v):
            return True
    return False

ALLOWED = {"grep","cat","diff","wc","head","tail","ls","test","jq","echo","git"}
GIT_RO = {"diff","log","show","grep","status","rev-parse","ls-files","blame"}
for seg in split_operators(cmd):
    seg = seg.strip()
    if not seg:
        continue
    # token grezzo senza shlex (shlex esploderebbe su sintassi shell complessa):
    tokens = seg.split()
    if not tokens:
        continue
    if tokens[0] not in ALLOWED:
        sys.exit(1)
    if any(fuori_dal_progetto(t) for t in tokens[1:]):
        sys.exit(1)
    # (Q5 R1): jq ha il builtin `env` e `$ENV` — l'ambiente (le chiavi comprese) senza scrivere un `$`
    # fuori dagli apici singoli
    if tokens[0] == "jq" and re.search(r"\benv\b|\$ENV|input_filename|\$__loc__", seg):
        sys.exit(1)
    if tokens[0] == "git":
        sub = tokens[1] if len(tokens) > 1 else ""
        if sub not in GIT_RO:
            sys.exit(1)
        # (revisione 10 giri): le opzioni che fanno ESEGUIRE (git grep -O<prog>,
        # --open-files-in-pager, --ext-diff, --textconv) o SCRIVERE (--output) un sottocomando
        # di sola lettura — riprodotto: `git grep -O'echo X' …` eseguiva echo.
        # (2026-09-23, giro A6 della notte): riprodotte due vie ancora aperte — le opzioni corte
        # RAGGRUPPATE (`-iO'cmd'` esegue cmd) e le lunghe ABBREVIATE (`--open-files=cmd`: git
        # accetta ogni prefisso non ambiguo). Ora: un gruppo corto che contiene O si rifiuta, e
        # una lunga che e' l'inizio di un'opzione pericolosa si rifiuta.
        PERICOLOSE = ("open-files-in-pager", "output", "ext-diff", "textconv")
        for t in tokens[2:]:
            if t.startswith("--"):
                nome = t[2:].split("=", 1)[0]
                if nome and any(p.startswith(nome) for p in PERICOLOSE):
                    sys.exit(1)
            elif t.startswith("-") and "O" in t.split("=", 1)[0]:
                sys.exit(1)
sys.exit(0)
PY
}

# mask_secrets(): maschera segreti nell'output del banco avversariale prima che finisca
# nel report (pattern segreto-come-impronta). Copre due forme, non una lista esaustiva
# di forme di segreto (quello richiederebbe un rilevatore per-forma come segreti-parco.js,
# fuori scope qui — annotato in DEBITI.md):
#   1. "parola-chiave=valore" o "parola-chiave: valore" (secret/token/password/key)
#   2. "Authorization: Bearer/Basic/Token <valore>" — trovato scoperto con dogfooding
#      (nuovo ciclo 10 giri, 2026-08-22): un comando che stampa un header HTTP con un
#      Bearer token passava INTERO, perché "Authorization" non contiene nessuna delle
#      parole chiave della forma 1.
# (revisione 10 giri, 2026-09-23): il formato e' quello della regola vincolante di CLAUDE.md
# («Mask, don't omit») e del pattern — «segreto <impronta> · N caratteri», non piu'
# ***MASCHERATO***: chi legge vede che c'era un segreto, quanto era lungo, e se due righe
# portano lo STESSO (impronta = primi 8 hex di sha256). Forma 3 nuova: i token NUDI con
# prefisso noto (ghp_, github_pat_, sk-ant-, xoxb-, AKIA...) — prima passavano interi se
# nessuna parola chiave li precedeva. Una maschera gia' messa («...) non si rimaschera.
# (2026-09-23, notte dei giri, T5#3): anche le credenziali di QUESTO parco — Google OAuth, cioe'
# clasp e la produzione (ya29., 1//0, GOCSPX-), la chiave Zhipu nuda (<32 hex>.<segreto>), PASSWD,
# e la password dentro un URL (fra «utente:» e la chiocciola dell'host). Prima passavano intere.
mask_secrets() {
  python3 -c '
import sys, re, hashlib
def imp(v):
    return "«segreto %s · %d caratteri»" % (hashlib.sha256(v.encode("utf-8", "surrogateescape")).hexdigest()[:8], len(v))
AUTH = re.compile(r"(Authorization[=: ]+(?:Bearer|Basic|Token)[= ]+)([^\s,\"«][^\s,\"]*)", re.I)
# (revisione 10 giri): anche la chiave e il valore fra virgolette — JSON e X="y" (\x27 = apostrofo:
# questo codice vive fra apici singoli di bash)
KW = re.compile(r"((?:secret|token|passwd|password|key)[a-z_]*[\"\x27]?\s*[=:]\s*[\"\x27]?|(?:secret|token|passwd|password|key)[a-z_]* )([^\s,\"\x27«][^\s,\"\x27]*)", re.I)
NUDI = re.compile(r"(?:ghp_|gho_|github_pat_|sk-ant-|sk-proj-|xox[bp]-|AKIA|ya29\.|1//0|GOCSPX-)[A-Za-z0-9_-]{12,}|[0-9a-f]{32}\.[A-Za-z0-9]{16,}")
URL = re.compile(r"(://[^/\s:@\"\x27]+:)([^/\s@\"\x27«]{6,})(@)")
for raw in sys.stdin.buffer:
    l = raw.decode("utf-8", "surrogateescape")
    l = AUTH.sub(lambda m: m.group(1) + imp(m.group(2)), l)
    l = KW.sub(lambda m: m.group(1) + imp(m.group(2)), l)
    l = NUDI.sub(lambda m: imp(m.group(0)), l)
    l = URL.sub(lambda m: m.group(1) + imp(m.group(2)) + m.group(3), l)
    sys.stdout.buffer.write(l.encode("utf-8", "surrogateescape"))
    sys.stdout.buffer.flush()
' || echo "⛔ mask_secrets: la maschera e' MORTA (python) — output SOPPRESSO, non mostrato per sicurezza: e' un rosso, non un silenzio"
}

# impronta_righe: righe «file:riga: contenuto» → «file:riga: «segreto <impronta> · N caratteri»», la riga intera.
# (2026-09-25, settimo ventaglio, V1 R2): per chi SA gia' che la riga e' un segreto (lo strato 1 della lente, che la
# trova con le SHAPES di privacy-check). mask_secrets ha regole sue e non conosce ogni forma (email, telefoni, xoxb
# corti, password in URL con l'apice): passate da li', tornavano in chiaro nel commento pubblico della PR.
impronta_righe() {
  python3 -c '
import sys, re, hashlib
for raw in sys.stdin.buffer:
    l = raw.decode("utf-8", "surrogateescape").rstrip("\n")
    m = re.match(r"^(.*?:[0-9]+): ?(.*)$", l)
    pre, v = (m.group(1) + ": ", m.group(2)) if m else ("", l)
    imp = hashlib.sha256(v.encode("utf-8", "surrogateescape")).hexdigest()[:8]
    sys.stdout.write("%s«segreto %s · %d caratteri»\n" % (pre, imp, len(v)))
' || echo "⛔ impronta_righe: MORTA (python) — righe SOPPRESSE, non mostrate: e' un rosso, non un silenzio"
}

# candidata_censore(): dal JSON di `gh pr list --json number,headRefName,isDraft,title` (stdin)
# il numero della prima PR che il censore ACCETTA — bozza, branch night/*, titolo `caccia:`:
# gli stessi predicati delle guardie di night-shift/revisore.sh. (Revisione 10 giri,
# 2026-09-23): il turno prendeva la prima bozza night/* qualunque; con una PR di issue in
# testa il censore rispondeva «non mio» a ogni ciclo e le caccia dietro non passavano mai.
# (2026-09-24, terzo ventaglio, V1#2): gh elenca le PR piu' RECENTI prima, e si prendeva la prima — la piu'
# nuova, in quarantena — mentre le cacce vecchie non tornavano piu' davanti al censore. Ora la piu' VECCHIA
# (createdAt crescente; senza createdAt l'ordine resta quello di gh).
candidata_censore() {
  jq -r '[.[] | select(.isDraft == true and (.headRefName | startswith("night/")) and ((.title // "") | startswith("caccia:")))] | sort_by(.createdAt // "") | .[0].number // empty' 2>/dev/null
}

# caccia_gia_aperta <dir> <base> <ramo>...: 0 se uno dei rami remoti (le cacce con una PR aperta) porta gia'
# lo stesso diff del commit appena fatto — stesso `git patch-id`. (V1#2, 2026-09-24): il sito saldato torna
# libero su main finche' la PR non e' fusa, il trasformatore lo risalda, e ogni ciclo apriva una PR con lo
# stesso identico diff (4 cicli, 4 PR, misurati dal giro V1).
caccia_gia_aperta() {
  local dir="$1" base="$2" r mio suo; shift 2
  mio=$(git -C "$dir" diff "$base...HEAD" 2>/dev/null | git patch-id --stable 2>/dev/null | cut -d' ' -f1)
  [ -n "$mio" ] || return 1
  for r in "$@"; do
    git -C "$dir" fetch -q origin "$r" 2>/dev/null || continue
    suo=$(git -C "$dir" diff "$base...origin/$r" 2>/dev/null | git patch-id --stable 2>/dev/null | cut -d' ' -f1)
    [ "$suo" = "$mio" ] && { echo "$r"; return 0; }
  done
  return 1
}

# rami_da_scopare <ora-epoch> <soglia-ore> <file-rami> <file-pr>: i rami remoti che la scopa
# del turno puo' cancellare. <file-rami>: «nome<TAB>epoch dell'ultimo commit» per riga;
# <file-pr>: «head<TAB>stato» (OPEN|MERGED|CLOSED) per riga. Regole (decisione di Luca
# 2026-09-23 «un ramo fuso non serve a niente», con le guardie che il codice non aveva):
#  - mai main, mai un ramo con una PR APERTA (anche se un'altra PR sullo stesso nome e' fusa);
#  - PR fusa/chiusa → si cancella;
#  - nessuna PR → si cancella solo oltre la soglia (48h): prima la soglia era nel commento
#    e un ramo spinto un minuto prima della sua PR spariva al ciclo dopo.
# (Revisione 10 giri, 2026-09-23.)
rami_da_scopare() {
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys
ora, soglia = int(sys.argv[1]), int(sys.argv[2]) * 3600
rami = {}
for l in open(sys.argv[3]):
    p = l.rstrip("\n").split("\t")
    if len(p) == 2 and p[0] and p[1].isdigit():
        rami[p[0]] = int(p[1])
stati = {}
for l in open(sys.argv[4]):
    p = l.rstrip("\n").split("\t")
    if len(p) == 2 and p[0]:
        stati.setdefault(p[0], set()).add(p[1])
for nome, eta in rami.items():
    if nome == "main" or "OPEN" in stati.get(nome, set()):
        continue
    if stati.get(nome, set()) & {"MERGED", "CLOSED"}:
        print(nome)
    elif nome not in stati and ora - eta > soglia:
        print(nome)
PY
}

# repo_code(): i codici anonimi sono stati ritirati (dominio, Luca 2026-09-23:
# il mapping non era mai stato alimentato e i nomi possono comparire — resta
# proibito l'ACCESSO). La funzione resta per i chiamatori: restituisce il nome.
repo_code() {
  echo "$1"
}

# forme_prima_del_push <dir> <base>: il cancello fra commit e push (2026-09-23, notte dei giri, T5#3).
# lente_pr gira DOPO il push: sull'hub pubblico un segreto nel diff era gia' su GitHub quando la
# lente lo vedeva. Qui lo strato 1 della lente (le forme di segreto, deterministico, niente cervello)
# su <base>...HEAD: rc 0 = il push puo' partire; altrimenti stampa il rapporto (valori mascherati) e
# rc != 0 — anche DEGRADATA (diff illeggibile) ferma il push: nel dubbio, niente esce.
forme_prima_del_push() {
  local rap rc
  rap=$(LENTE_SOLO_FORME=1 bash "$(dirname "${BASH_SOURCE[0]}")/../tools/lente-sicurezza.sh" "$1" "$2" HEAD 2>/dev/null); rc=$?
  [ $rc -eq 0 ] && return 0
  echo "⛔ forme di segreto nel diff ($2...HEAD): push NON eseguito — $(tail -1 <<<"$rap")"
  grep '^- ' <<<"$rap" | head -5
  return 1
}

# dichiara_file_nuovo <dir> <percorso-relativo>: il file NUOVO che un agente ha creato e che puo'
# entrare nella consegna (2026-09-24, notte dei giri, T5#2b). La lista vive dentro .git: non si committa.
dichiara_file_nuovo() {
  local gd; gd=$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null) || return 1
  printf '%s\n' "$2" >> "$gd/agente-file-nuovi"
}

# aggiungi_consegna <dir> [file-nuovi-dichiarati...]: prepara l'indice della consegna — le modifiche ai
# file tracciati, piu' i SOLI file nuovi dichiarati (qui come argomenti, o da dichiara_file_nuovo).
# (T5#2b): i punti di consegna dopo agente.sh facevano `git add -A`, e un file «di passaggio» nuovo,
# magari con dati letti, entrava nel commit e nel push. Un file nuovo non dichiarato resta nella copia,
# fuori dal commit, e lo si dice; si SPOSTA (mai cancellato) in .git/consegna-fuori/<ora>/, perche' non
# ricompaia a ogni consegna dopo. La dichiarazione si consuma qui.
aggiungi_consegna() {
  local dir="$1" gd f fuori; shift
  gd=$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null) || return 1
  git -C "$dir" add -u || return 1
  { printf '%s\n' "$@"; cat "$gd/agente-file-nuovi" 2>/dev/null; } | grep -v '^$' | sort -u > "$gd/consegna-dichiarati"
  while IFS= read -r f; do
    if grep -qxF -- "$f" "$gd/consegna-dichiarati"; then
      git -C "$dir" add -- "$f" || return 1
    else
      fuori="$gd/consegna-fuori/$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$fuori/$(dirname "$f")" && mv -- "$dir/$f" "$fuori/$f"
      echo "consegna: file nuovo NON dichiarato, fuori dal commit: $f (spostato in $fuori/)"
    fi
  done < <(git -C "$dir" -c core.quotePath=false ls-files --others --exclude-standard)
  rm -f "$gd/agente-file-nuovi" "$gd/consegna-dichiarati"
}

# lente_pr <dir> <base> <head> <url-pr>: la lente sicurezza (dev-critic §2bis) su una PR appena
# creata dalla notte — decisione di Luca, D2 2026-09-23: automatica su TUTTE le PR notturne. Il
# rapporto (valori gia' mascherati da tools/lente-sicurezza.sh) diventa un commento della PR;
# la riga di sintesi va a stdout per il log del chiamante. Non blocca la creazione: chi delibera
# (il censore, il giorno) legge il verdetto — il censore la rilancia da se' prima di fondere.
lente_pr() {
  local dir="$1" base="$2" head="$3" url="$4" rap
  case "$url" in https://*) ;; *) echo "lente sicurezza: nessuna PR da guardare ('$url') — salto dichiarato"; return 0 ;; esac
  rap=$(bash "$(dirname "${BASH_SOURCE[0]}")/../tools/lente-sicurezza.sh" "$dir" "$base" "$head" 2>/dev/null)
  if (cd "$dir" && gh pr comment "$url" --body "$rap") >/dev/null 2>&1; then
    echo "lente sicurezza su $url: $(tail -1 <<<"$rap") (rapporto nel commento della PR)"
  else
    echo "lente sicurezza su $url: $(tail -1 <<<"$rap") — ⚠ commento NON pubblicato sulla PR"
  fi
}

# candidata_parere <dir-stato>: dal JSON di `gh pr list --json number,headRefName,isDraft,title,headRefOid`
# (stdin) il numero della prima PR di ISSUE (bozza, branch night/issue-*) senza parere gia' dato su
# quel commit — decisione di Luca, D10 2026-09-23: «b», il censore giudica le PR delle issue e lascia
# un parere, mai la fusione. Il parere dato vive in <dir-stato>/parere-<numero>-<commit> (lo scrive
# night-shift/revisore.sh): senza questo filtro la stessa PR tornerebbe al censore a ogni ciclo.
candidata_parere() {
  local stato="$1" n oid
  while IFS=$'\t' read -r n oid; do
    [ -n "$n" ] || continue
    [ -f "$stato/parere-$n-$oid" ] && continue
    echo "$n"; return 0
  done < <(jq -r '.[] | select(.isDraft == true and (.headRefName | startswith("night/issue-"))) | [.number, .headRefOid] | @tsv' 2>/dev/null)
}

# verifica_issue_comando <file-issue>: il comando della «## Verifica» che il turno puo' eseguire, o
# vuoto. (2026-09-23, giro A5 della notte): e' testo ESTERNO — l'autore dell'issue puo' modificarlo
# dopo che Luca ha messo la label — e il turno lo esegue. Prima: grep -o sulla forma
# `(node|npm|python3?) …` + denylist → passavano `npm install <pacchetto>`, `npm exec`, `npm i`,
# `python3 -m pip install`, `node -e`, `python3 -c` (riprodotto: 8 vie). Ora la PRIMA riga che
# comincia con node/npm/python si valida PER INTERO: solo `npm test`, o un FILE del progetto
# eseguito (node|python3 <percorso relativo .js/.mjs/.cjs/.py> [argomenti semplici]).
verifica_issue_comando() {
  local riga
  riga=$(sed -n '/^## Verifica/,/^## /p' "$1" 2>/dev/null | grep -E '^(node|npm|python3?)( |$)' | head -1 | sed 's/[[:space:]]*$//')
  [ "$riga" = "npm test" ] && { printf '%s' "$riga"; return 0; }
  grep -qE '^(node|python3?) [A-Za-z0-9_./-]+\.(js|mjs|cjs|py)( [A-Za-z0-9_./=-]+)*$' <<<"$riga" || return 0
  case "$riga" in *" /"*|*..*|*" -"[ecm]" "*|*" --eval"*) return 0 ;; esac   # niente assoluti ne' risalite
  printf '%s' "$riga"
}

# prendi_lock_turno <dir-lock>: 0 = il lock e' di questo processo (preso ora, o gia' suo: il ciclo
# dopo `exec "$0"` ha lo stesso PID), 1 = lo tiene un altro turno VIVO. (Q10, 2026-09-23, giro A5
# della notte): prima contava l'eta' — oltre 1h il lock si toglieva, ma un ciclo con l'issue lenta
# dura fino a 4h (watchdog) e il lock si rubava a un turno vivo. Ora conta il PID: vivo e del
# turno = occupato, a qualunque eta'; morto, o riusato da un altro programma = orfano (E-026) e si
# prende subito. Un lock senza PID (versione di prima) tiene la vecchia regola dell'ora.
# (2026-09-24, notte dei giri, T2#3): davanti a un orfano, due avvii insieme lo prendevano ENTRAMBI
# (32 su 200 nel giro T2, 10 su 60 nel banco): il secondo `rm -rf` cancellava il lock appena preso
# dal primo. Ora il furto e' serializzato da un secondo mkdir (<lock>.furto), e dentro si RIGIUDICA:
# chi arriva dopo trova il lock gia' preso da un vivo e si ferma. Un .furto lasciato da un processo
# morto a meta' si toglie dopo 60 secondi (il furto dura millisecondi).
# dipendenze_mancanti <cmd…> — stampa, separati da spazio, i comandi che mancano sul PATH (niente = tutti ci
# sono). (2026-09-24, quarto ventaglio, Q2 R2): senza jq il ping di generazione restava vuoto, il turno
# scriveva «Ollama wedged» e uccideva un'istanza sana. Prima si esclude l'attrezzo, poi si accusa il cervello.
dipendenze_mancanti() {
  local c m=""
  for c in "$@"; do command -v "$c" >/dev/null 2>&1 || m="${m:+$m }$c"; done
  printf '%s' "$m"
  [ -z "$m" ]
}

# leggi_coda <owner/repo> — le issue night-shift aperte, in JSON su stdout. rc 1 col motivo su stderr se gh
# fallisce o non risponde JSON. (2026-09-24, quarto ventaglio, Q2 R5): senza guardia, un blip di GitHub
# dopo l'auth diventava «TURNO su X:  issue in coda» e una notte senza commesse; «0 issue» non e' «non so».
leggi_coda() {
  local out err rc
  err=$(mktemp "${TMPDIR:-/tmp}/leggi-coda.XXXXXX") || { echo "leggi_coda: mktemp fallito" >&2; return 1; }
  out=$(gh issue list -R "$1" --label night-shift --state open --json number,title,body --limit 50 2>"$err"); rc=$?
  if [ "$rc" -ne 0 ] || ! jq -e 'type == "array"' >/dev/null 2>&1 <<<"$out"; then
    echo "gh rc=$rc: $(tail -1 "$err" | cut -c1-120)${out:+ · risposta: $(head -c 60 <<<"$out")}" >&2
    rm -f "$err"; return 1
  fi
  rm -f "$err"; printf '%s\n' "$out"
}

# allinea_hub <dir> — porta la copia installata del turno a origin/HEAD SENZA buttare il lavoro del giorno.
# (2026-09-24, quinto ventaglio, R5 R1): a ogni ciclo, 24/7, `checkout main || true` + `reset --hard` cancellava
# le modifiche non committate e i commit non pushati, e col checkout fallito resettava il ramo del giorno; il
# log diceva «allineato». Ora: sporco → stash «salvataggio turno <ora>»; commit fuori da origin → ramo
# salvataggio/<ora>; checkout di main fallito → niente reset, rc 1. Ogni cosa messa da parte si dice.
allinea_hub() {
  local d="$1" ts up br sporchi avanti gd err salvato
  ts=$(date +%Y%m%d-%H%M%S)
  # (2026-09-24, sesto ventaglio, S4 R2): un .git/index.lock rimasto da un git ucciso (SIGKILL, Mac spento di colpo)
  # faceva fallire stash e reset a ogni ciclo con la causa in /dev/null, e ogni ciclo apriva un ramo salvataggio/
  # nuovo. Ora si dice per nome e non si tocca niente: toglierlo e' di chi lavora nella copia (DEBITI, S4 D2).
  gd=$(git -C "$d" rev-parse --absolute-git-dir 2>/dev/null)
  if [ -n "$gd" ] && [ -f "$gd/index.lock" ]; then
    echo "NON allineato: $gd/index.lock esiste (da $(( $(date +%s) - $(mtime "$gd/index.lock" 2>/dev/null || date +%s) )) s) — un git ucciso a meta'? Niente stash ne' reset finche' c'e'; se nessun git lavora li', si toglie a mano"
    return 1
  fi
  git -C "$d" fetch -q origin 2>/dev/null || echo "fetch fallito: si allinea all'ultimo origin noto"
  up=$(git -C "$d" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/||'); up=${up:-origin/main}
  br=$(git -C "$d" branch --show-current 2>/dev/null)
  # (S2 R3): lo stash avveniva PRIMA di sapere se main si poteva prendere — col main aperto in un altro worktree
  # niente allineamento, ma il lavoro spariva dal ramo del giorno a ogni ciclo. Prima si decide, poi si mette da parte.
  if [ "$br" != main ] && [ "$br" != master ] \
     && grep -cxE 'branch refs/heads/(main|master)' <<<"$(git -C "$d" worktree list --porcelain 2>/dev/null)" >/dev/null; then
    echo "NON allineato: la copia e' sul ramo '${br:-?}' e main e' aperto in un altro worktree — niente stash ne' reset, il turno gira col metodo che c'e'"
    return 1
  fi
  sporchi=$(git -C "$d" status --porcelain 2>/dev/null | grep -c .)
  if [ "$sporchi" -gt 0 ]; then
    err=$(git -C "$d" -c user.name=night-shift -c user.email=night-shift@localhost stash push -q -u -m "salvataggio turno $ts" 2>&1) \
      || { echo "NON allineato: $sporchi file non committati e lo stash e' fallito ($(tail -1 <<<"$err" | cut -c1-120)) — il turno gira col metodo che c'e'"; return 1; }
    echo "messi da parte $sporchi file non committati: git -C $d stash list («salvataggio turno ${ts}»)"
  fi
  if [ "$br" != main ] && [ "$br" != master ]; then
    git -C "$d" checkout -q main 2>/dev/null || git -C "$d" checkout -q master 2>/dev/null \
      || { echo "NON allineato: la copia e' sul ramo '${br:-?}' e il checkout di main e' fallito — niente reset, il turno gira col metodo che c'e'"; return 1; }
    echo "la copia era sul ramo '$br' (esterno al turno, intatto): tornata a main"
  fi
  avanti=$(git -C "$d" rev-list --count "$up..HEAD" 2>/dev/null || echo 0)
  if [ "$avanti" -gt 0 ]; then
    # (S4 R2): un commit gia' salvato non apre un ramo nuovo a ogni ciclo
    salvato=$(git -C "$d" branch --list 'salvataggio/*' --contains HEAD 2>/dev/null | head -1 | tr -d ' *')
    if [ -n "$salvato" ]; then
      echo "i $avanti commit non su $up sono gia' in $salvato: nessun ramo nuovo"
    else
      git -C "$d" branch "salvataggio/$ts" HEAD && echo "messi da parte $avanti commit non su $up: ramo salvataggio/$ts"
    fi
  fi
  err=$(git -C "$d" reset -q --hard "$up" 2>&1) || { echo "NON allineato: reset su $up fallito ($(tail -1 <<<"$err" | cut -c1-120)) — il turno gira col metodo che c'e'"; return 1; }
  echo "hub allineato a $up"
}

# commit_altrui <dir> <base> <ref> — quanti commit di <base>..<ref> NON sono dell'autore configurato in <dir>
# (il turno). (2026-09-24, quinto ventaglio, R5 R3): il «lease» del turno prendeva come atteso lo sha appena
# letto dal remoto, cioe' non proteggeva niente, e le correzioni del giorno su night/issue-N sparivano.
commit_altrui() {
  local io; io=$(git -C "$1" config user.email 2>/dev/null)
  git -C "$1" log --format=%ae "$2..$3" 2>/dev/null | grep -vcxF -- "${io:-night-shift@localhost}"
}

# messaggio_fix <tipo> <num> <titolo> <autore> <nota> <verifica> — il messaggio del commit di un fix d'issue.
# (2026-09-24, terzo ventaglio, V1#6): il turno lo scriveva a mano con «(risolvi-issue.sh, modello locale)»
# anche quando aveva risolto l'agente della cascata, e senza `Closes #N`: la PR (`gh pr create --fill`
# prende il corpo dal commit) non chiudeva l'issue al merge. La keyword resta INGLESE (CLAUDE.md §4).
messaggio_fix() {
  printf "%s: issue #%s — %s (%s)%s\n\nVerifica dell'issue: %s\n\nCloses #%s\n" "$1" "$2" "$3" "$4" "$5" "$6" "$2"
}

# rianima_ollama — il SOLO gesto che riavvia il server Ollama (pattern cuore-unico-proprietario).
# (2026-09-24, terzo ventaglio, V5 R4): tre punti lo riavviavano, e solo la sonda chiedeva al custode.
# Il watchdog d'inizio ciclo e agente.sh facevano pkill e aspettavano launchd anche dove launchd non c'era:
# l'istanza uccisa non la rialzava nessuno. Ora: custode launchd presente -> kickstart a lui, si aspetta
# la SUA resurrezione; assente -> kill e istanza propria. Esce 0 se /api/version risponde entro ~60 s.
rianima_ollama() {
  local custode
  custode=$(launchctl list 2>/dev/null | awk '/ollama/{print $3; exit}')
  if [ -n "$custode" ]; then
    echo "rianima_ollama: custode launchd $custode — kickstart a lui, attendo la sua resurrezione" >&2
    launchctl kickstart -k "gui/$(id -u)/$custode" 2>/dev/null
  else
    echo "rianima_ollama: nessun custode launchd — kill del serve e istanza propria" >&2
    pkill -f "ollama serve" 2>/dev/null; sleep 4
    OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 OLLAMA_CONTEXT_LENGTH=16384 OLLAMA_KEEP_ALIVE=-1 \
      /opt/homebrew/bin/ollama serve >> ~/ollama-server.log 2>&1 &
  fi
  # (2026-09-24, quinto ventaglio, R4 R3): la scelta si diceva, l'esito no — e i chiamanti (`… | while log`)
  # si mangiano l'rc. La riga d'esito la scrive lei.
  local t0=$SECONDS
  for _ in $(seq 1 30); do
    curl -sf --max-time 1 http://localhost:11434/api/version >/dev/null 2>&1 && { echo "rianima_ollama: esito OK in $((SECONDS - t0)) s" >&2; return 0; }
    sleep 2
  done
  echo "rianima_ollama: esito FALLITO in $((SECONDS - t0)) s (/api/version muto)" >&2
  return 1
}

# comandi_da_incollare <righe> (2026-09-24, sesto ventaglio, S1 R1; CLAUDE.md §3 «What you hand to a human to run
# is code»): le righe in un blocco di codice (il markdown non si mangia gli asterischi), ognuna dentro `bash -c`
# con la quotatura di printf %q — come le esegue il turno. Una riga che finisce in `exit` non chiude il terminale
# di chi la incolla, e un `#` nella riga non e' un commento per zsh senza interactive_comments.
comandi_da_incollare() {
  echo '```'
  while IFS= read -r r; do [ -n "$r" ] && printf 'bash -c %q\n' "$r"; done <<<"$1"
  echo '```'
}

# ferma_opencode_del_turno <file-pid> (2026-09-24, quinto ventaglio, R5 R6; pattern cuore-unico-proprietario):
# la pulizia era `pkill -f "opencode run"` — uccideva anche l'opencode del GIORNO. Il turno ferma solo il PID che
# ha scritto lui nel file, e solo se quel PID e' ancora un «opencode run» (un PID riusato da altro non si tocca).
# Il file si toglie comunque. rc 0 = fermato qualcosa; 1 = niente da fermare.
ferma_opencode_del_turno() {
  local f="$1" pid
  [ -f "$f" ] || return 1
  pid=$(cat "$f" 2>/dev/null); rm -f "$f"
  { [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; } || return 1
  ps -p "$pid" -o command= 2>/dev/null | grep -c 'opencode run' >/dev/null || return 1
  pkill -P "$pid" 2>/dev/null; kill "$pid" 2>/dev/null
  return 0
}

prendi_lock_turno() {   # [programma]: chi e' «vivo» (default night-shift; ciclo-vivo lo usa col suo nome)
  local L="$1" prog="${2:-night-shift}" rc
  if mkdir "$L" 2>/dev/null; then echo $$ > "$L/pid"; return 0; fi
  [ "$(cat "$L/pid" 2>/dev/null)" = "$$" ] && return 0
  lock_turno_orfano "$L" "$prog" || return 1
  if ! mkdir "$L.furto" 2>/dev/null; then
    [ "$(eta_secondi "$L.furto")" -gt 60 ] && rm -rf "$L.furto"
    return 1
  fi
  rc=1
  if lock_turno_orfano "$L" "$prog"; then
    rm -rf "$L"
    mkdir "$L" 2>/dev/null && echo $$ > "$L/pid" && rc=0
  fi
  rmdir "$L.furto" 2>/dev/null
  return $rc
}

# lock_turno_orfano <dir-lock> [programma]: 0 se il lock non e' di nessun processo vivo di quel
# programma — il PID dentro e' morto o di un altro programma; senza PID (versione di prima), se ha piu'
# di un'ora.
lock_turno_orfano() {
  local pid comando
  pid=$(cat "$1/pid" 2>/dev/null)
  if [ -n "$pid" ]; then
    comando=$(ps -p "$pid" -o command= 2>/dev/null)
    grep -qF -- "${2:-night-shift}" <<<"$comando" && return 1
    return 0
  fi
  [ "$(eta_secondi "$1")" -ge 3600 ]
}

# eta_secondi <percorso>: da quanti secondi esiste (0 se non esiste: un file sparito non e' vecchio)
eta_secondi() {
  local m
  m=$(mtime "$1" 2>/dev/null) || { echo 0; return; }
  echo $(( $(date +%s) - m ))
}

# commenta_una_volta <num> <owner/repo> <motivo> <corpo>: commenta l'issue UNA volta per motivo.
# (Q11, 2026-09-23, giro A5 della notte): il cancello Design/Territorio commentava a OGNI ciclo, e
# il turno riparte subito — centinaia di commenti identici in una notte. Il corpo porta un
# marcatore invisibile (<!-- night-gate:<motivo> -->); se c'e' gia', si tace. Commenti illeggibili
# (gh giu', rete) = non si commenta: rc 2, meglio un avviso in meno che uno spam.
commenta_una_volta() {
  local num="$1" repo="$2" marcatore="<!-- night-gate:$3 -->" corpo="$4" gia
  gia=$(gh issue view "$num" -R "$repo" --json comments -q '.comments[].body' 2>/dev/null) || return 2
  grep -qF -- "$marcatore" <<<"$gia" && return 0
  gh issue comment "$num" -R "$repo" --body "$corpo

$marcatore" >/dev/null 2>&1
}

# cancello_design <corpo-issue>: stampa il MOTIVO per cui l'issue non parte, o niente se passa.
# Motivi: territorio-assente · design-assente · «design-povero <caratteri>» · design-senza-fonte ·
# territorio-vago. (2026-09-23, notte dei giri): la sequenza viveva dentro il turno e il suo banco
# ne teneva una COPIA — con il gate spento il banco restava verde. Ora la sequenza vive qui, una
# volta, e tests/test-night-shift-design-gate.sh prova questa funzione. L'ordine conta: i controlli
# di ASSENZA vengono prima di quelli di QUALITA' (una sezione assente estrae una stringa vuota, che
# il controllo di qualita' intercetterebbe col messaggio sbagliato — set 2, 2026-08-22).
cancello_design() {
  local corpo="$1" design_raw design_body terr_body
  grep -q "^## Territorio" <<<"$corpo" || { echo "territorio-assente"; return 0; }
  grep -q "^## Design" <<<"$corpo" || { echo "design-assente"; return 0; }
  design_raw=$(printf '%s' "$corpo" | awk '/^## Design/{f=1;next} /^## /{f=0} f')
  design_body=$(printf '%s' "$design_raw" | tr -d '[:space:]')
  [ "${#design_body}" -lt 80 ] && { echo "design-povero ${#design_body}"; return 0; }
  # una lunghezza non e' una fonte: almeno UN riferimento verificabile (URL, link markdown,
  # SAL.md, un'issue #N, o un percorso di file) — set 2, prosa di riempimento da 87 caratteri
  grep -qiE 'https?://|\[[^]]+\]\([^)]+\)|SAL(\.md)?\b|(issue|pr|#)[[:space:]]*#?[0-9]+|\.[a-z]{2,4}\b' <<<"$design_raw" \
    || { echo "design-senza-fonte"; return 0; }
  terr_body=$(printf '%s' "$corpo" | awk '/^## Territorio/{f=1;next} /^## /{f=0} f')
  grep -qE '\.[a-z]{2,4}\b|file|riga|documento|md\b' <<<"$terr_body" || { echo "territorio-vago"; return 0; }
  return 0
}

