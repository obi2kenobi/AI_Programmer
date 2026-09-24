#!/bin/bash
# _timeout.sh — timeout portabile per i wrapper llm/ e i loro test (6° ciclo, giro 0
# "baseline", 2026-08-24). macOS non porta GNU coreutils: `timeout` non esiste su una
# shell stock (verificato dal vivo: `command -v timeout` vuoto su /bin/bash 3.2 di
# sistema), e i wrapper morivano con "command not found" (rc=127) PRIMA ancora di
# raggiungere il cervello — il test che li simula (test-ask-usage-log) vedeva rc=1
# dal `set -e` e la suite intera, fail-fast, si fermava al secondo file.
# Contratto: ai_timeout <secondi> <comando...> — exit 124 a timeout, come GNU timeout;
# con segnale: 128+sig; altrimenti l'exit code del comando. Prova in ordine GNU
# `timeout`, homebrew `gtimeout`, e in ultimo un fallback perl (presente su ogni
# macOS) che fork+wait e restituisce 124 allo scadere dell'allarme.
ai_timeout() {
  local secs="$1"; shift
  # AI_TIMEOUT_FORCE_PERL=1 salta i primi due rami: serve al test di regressione
  # per esercitare IL ramo perl spedito (su un Mac con coreutils installato
  # resterebbe altrimenti mai provato — un bug nel fallback passerebbe verde).
  if [ -z "${AI_TIMEOUT_FORCE_PERL:-}" ]; then
    # bug reale (revisione 14 lenti, 2026-08-28): senza "-k", GNU timeout manda SIGTERM
    # allo scadere e poi ASPETTA che il comando termini da solo — se il comando lo
    # ignora/blocca (trap '' TERM), timeout non forza mai la terminazione, esattamente sul
    # ramo più comune (coreutils presenti). Verificato dal vivo: un comando con
    # trap '' TERM sotto `timeout 2` tornava dopo l'intera durata del comando, non a 2s.
    # "-k 5": se il comando è ancora vivo 5s dopo il TERM, SIGKILL — la stessa garanzia che dal
    # 2026-09-23 (T3#1) da anche il fallback perl sotto (prima mandava KILL subito, senza TERM).
    if command -v timeout >/dev/null 2>&1; then command timeout -k 5 "$secs" "$@"; return; fi
    if command -v gtimeout >/dev/null 2>&1; then command gtimeout -k 5 "$secs" "$@"; return; fi
  fi
  command perl -e '
    my $s = shift; my $pid = 0;
    # kill di GRUPPO, non solo del figlio: un nipote orfano (es. `sleep` dentro
    # bash -c) eredita la write-end della pipe della command substitution e la
    # tiene aperta oltre la morte del figlio — lo stesso "sleep orfano" già pagato
    # da run_guarded (tests/test-lib.sh, set 2 giro 9). Il figlio diventa leader
    # del suo gruppo (setpgrp) e il segnale di allarme uccide il gruppo (-$pid).
    # NOTA: qui dentro niente apostrofi nei commenti — questa stringa è delimitata
    # da apici singoli e un apostrofo italiano la chiuderebbe (pagato dal vivo).
    # (2026-09-23, notte dei giri, T3#1): come GNU timeout -k 5 — prima TERM al gruppo, poi fino a
    # 5 secondi di attesa, poi KILL. Prima era KILL subito: sul Mac senza coreutils i trap EXIT dei
    # comandi interrotti non giravano mai (un lock lasciato sporco). Il KILL finale va comunque al
    # gruppo: il nipote orfano muore anche quando il figlio e gia uscito col TERM.
    $SIG{ALRM} = sub {
      if ($pid) {
        kill "TERM", -$pid;
        for (1 .. 50) { last if waitpid($pid, 1) > 0; select(undef, undef, undef, 0.1) }
        kill "KILL", -$pid;
      }
      exit 124 };
    alarm $s;
    $pid = fork();
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127 }
    waitpid($pid, 0);
    exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
  ' "$secs" "$@"
}

# ai_timeout_ramo: quale dei tre rami userebbe ai_timeout qui (2026-09-23, T3#6: il turno lo scrive nel
# log — i rami si comportavano diversamente, e dal log del Mac non si vedeva quale girava)
ai_timeout_ramo() {
  if [ -z "${AI_TIMEOUT_FORCE_PERL:-}" ]; then
    command -v timeout >/dev/null 2>&1 && { echo "GNU timeout"; return; }
    command -v gtimeout >/dev/null 2>&1 && { echo "gtimeout"; return; }
  fi
  echo "perl (TERM, 5 s, KILL)"
}
