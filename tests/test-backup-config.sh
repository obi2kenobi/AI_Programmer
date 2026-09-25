#!/bin/bash
# test-backup-config.sh — 60 giri: backup-config non aveva test
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# il tool esiste, è eseguibile, e gestisce l'assenza di gh
[ -f "$HERE/tools/backup-config.sh" ] && ok "backup-config.sh esiste" || ko "assente"
[ -x "$HERE/tools/backup-config.sh" ] && ok "eseguibile" || ko "non eseguibile"
# senza gh deve fallire pulitamente (non crashare). Il ramo si FORZA sempre
# via PATH: prima, con gh installato, il test si saltava da solo (3 OK di nulla
# — scoperto dal mutation-testing 2026-08-28: tool neutralizzato, test verde).
# (2026-09-23, notte dei giri): era PATH=/usr/bin:/bin — dove gh sta PROPRIO in /usr/bin (Linux
# con apt) l'assenza non era forzata affatto; e NOGH si calcolava senza usarlo. Ora il PATH e' una
# cartella con TUTTI i comandi di /usr/bin e /bin tranne gh.
NOGH=$(mktemp -d)
for c in /usr/bin/* /bin/*; do n=$(basename "$c"); [ "$n" = gh ] || [ -e "$NOGH/$n" ] || ln -s "$c" "$NOGH/$n" 2>/dev/null; done
[ ! -e "$NOGH/gh" ] && [ -e "$NOGH/bash" ] && ok "il PATH di prova ha i comandi ma non gh" || ko "il PATH di prova non esclude gh"
out=$(PATH="$NOGH" bash "$HERE/tools/backup-config.sh" 2>&1); rc=$?
rm -rf "$NOGH"
[ $rc -ne 0 ] && grep -qi "gh\|gist" <<<"$out" && ok "senza gh: errore pulito" || ko "senza gh: crash o silenzio poco chiaro (rc=$rc)"

# (2026-09-25, ottavo ventaglio, O4 R1): il backup non e' mai stato fatto. `gh gist create --secret` e' rifiutato dal gh
# vero («unknown flag: --secret»: un gist e' segreto per default), la forma di `gist edit` pure («too many arguments»), e
# sotto set -e lo script usciva 1 senza dire niente. E i file finivano nel gist coi nomi casuali di mktemp. Qui un gh finto
# che rifiuta i flag come il vero (verificato con gh 2.45 a rete chiusa) e registra i nomi dei file.
FG=$(mktemp -d); mkdir -p "$FG/bin" "$FG/hub/tools" "$FG/hub/night-shift"
cp "$HERE/tools/backup-config.sh" "$FG/hub/tools/"; printf 'o/r feat\n' > "$FG/hub/night-shift/repos.conf"; printf '# D\n' > "$FG/hub/DEBITI.md"
cat > "$FG/bin/gh" <<'GHF'
#!/bin/bash
echo "$*" >> "$GH_LOG"
case "$1 $2" in
  "gist create") for a in "$@"; do case "$a" in --secret) echo "unknown flag: --secret" >&2; exit 1;; esac; done
                 for a in "${@:3}"; do [ -f "$a" ] && basename "$a" >> "$GH_LOG.file"; done
                 echo "https://gist.github.com/finto/0123456789abcdef0123456789abcdef"; exit 0 ;;
  "gist edit") echo "too many arguments" >&2; exit 1 ;;
esac
exit 0
GHF
chmod +x "$FG/bin/gh"
OUT=$(PATH="$FG/bin:$PATH" GH_LOG="$FG/log" bash "$FG/hub/tools/backup-config.sh" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -cx 'repos.conf' "$FG/log.file" >/dev/null 2>&1 && grep -cx 'DEBITI.md' "$FG/log.file" >/dev/null 2>&1 \
  && ok "O4 R1: il backup si crea col gh vero (niente --secret) e i file hanno il loro nome" \
  || ko "O4 R1: backup: rc=$RC, file nel gist: $(tr '\n' ' ' < "$FG/log.file" 2>/dev/null), uscita: $(tail -1 <<<"$OUT")"
printf '#!/bin/bash\necho "HTTP 401: Bad credentials" >&2; exit 1\n' > "$FG/bin/gh"
OUT=$(PATH="$FG/bin:$PATH" bash "$FG/hub/tools/backup-config.sh" 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -c 'backup fallito' <<<"$OUT" >/dev/null && ok "O4 R1: gh in errore → «backup fallito» detto, rc $RC (non un silenzio)" || ko "O4 R1: gh in errore: rc=$RC, uscita «$(tail -1 <<<"$OUT")»"
rm -rf "$FG"

# IE-003 GitLab (2026-08-31): CINQUE backup, nessuno provato col ripristino — 6 ore
# di dati perse. Il backup che non si sa leggere NON è un backup. Con gh attivo
# si verifica che il gist di backup sia LEGGIBILE e contenga i tre file attesi
# (il ripristino vero è dell'umano, ma la leggibilità si prova qui).
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GIST_ID=$(cat "$HERE/.gist-backup-id" 2>/dev/null || echo "")
  if [ -n "$GIST_ID" ]; then
    OUT=$(gh gist view "$GIST_ID" 2>&1) && grep -q "repos.conf" <<<"$OUT" \
      && ok "backup LEGGIBILE e contiene repos.conf (l'antidoto GitLab)" \
      || ko "backup illeggibile o incompleto: sarebbe il sesto backup-che-non-funziona"
  else
    echo "· backup mai creato su questa macchina: verifica del ripristino SALTATA (dichiarato, non contato)"
  fi
else
  echo "· gh assente o non autenticato: verifica del ripristino NON ESEGUIBILE qui (dichiarato, non contato come verde)"
fi

# (revisione 10 giri, 2026-09-23): l'ID del gist SEGRETO e' la sua URL — chi lo legge, legge
# repos.key e repos.conf. Viveva in .gist-backup-id alla radice dell'hub PUBBLICO senza essere
# ignorato: un `git add -A` lo avrebbe pubblicato (ACCESSO, la cosa che la regola vieta).
git -C "$HERE" check-ignore -q .gist-backup-id && ok ".gist-backup-id e' ignorato da git (l'ID del gist segreto non si pubblica)" \
  || ko ".gist-backup-id NON e' ignorato: l'accesso al backup finirebbe nel repo pubblico"

echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
