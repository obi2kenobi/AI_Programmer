# Terzo ventaglio — consolidamento (2026-09-24)

Brief: `docs/giri/2026-09-24-terzo/00-BRIEF.md`. Cinque lenti, un giro ciascuna, ognuno in un clone:
V1 il turno eseguito, V2 i banchi come giudici, V3 le skill come istruzioni, V4 il tempo, V5 il catalogo
dei pattern. I rapporti grezzi (V1-V5) restano nella cartella ma sono ignorati da git: portano
citazioni `file:riga` del commit `6b94283`, che il lavoro successivo ha spostato. Dettagli di ogni cura
nel SAL, voce 18°.

## Esito

- **30 rilievi** nei tetti (6 per giro) e **12 fuori tetto** (5 di V3, 9 sabotaggi verdi di V2, 1 di V5).
- **Verificati eseguendo**: tutti i rilievi curati hanno avuto un banco rosso prima e un sabotaggio
  rosso dopo. Fa eccezione V5 R4, che è provato con launchctl finto e non contro il launchd vero (⏳ Mac).
- **Smentite**: una. Il rapporto V2 (rilievo 5) diceva «6.3→63: rc 0, 10 OK». Col sorgente vero quel
  sabotaggio fa rosso il caso «sana». Il verde era bytecode stantio (E-047, sotto).
- **Convergenza**: tre giri indipendenti (V1, V2, V4) sono arrivati allo stesso punto, il gate del fixer
  e la suite: senza tetto, sulla copia sbagliata, con una ricorsione. È il tema trasversale più forte.

## Temi trasversali

1. **Il giudice che non giudica** (V2, V4, V5; E-047). Banchi verdi col codice rotto: dati che non
   distinguono, rami senza caso, la suite che contava i giri invece dei banchi, bytecode stantio. La
   cura è stata alla radice: la suite conta i verdetti e usa una cache fresca, e ogni ramo ha un caso.
2. **Il documento che dice ieri** (V3, V5). Skill e pattern descrivevano lo stato di prima (il
   morning-gate, «il grafo non c'è», il lock a 12 h). I banchi ora confrontano il registro con le àncore
   e i documenti con lo stato.
3. **Il tempo come bene** (V4, V1). Budget senza sentinella, attese a vuoto, una chiamata di rete vera
   nella suite. Ora la suite dice la quota usata; tre banchi scendono da 47 a 17 s; la rete non entra
   più senza ASK_VIVO=1.

## Tassonomia

**Implementata**
- V1#1, #5 (e V4#6): il gate del fixer giudica il ramo, banco per banco sotto tetto.
- V1#2: la caccia non riapre lo stesso diff.
- V1#3: la definizione non conta come chiamata.
- V1#4: l'heredoc che bash 5.2 rompe a runtime.
- V1#6a-c: la lente muta, la provenienza del commit, `Closes #N`.
- V2#1: mutation-tests annidato (E-046). V2#2: il conteggio della suite. V2#3: il deploy.
- V2#4: gli hook di sync-repo. V2#5: le soglie della crisi. V2#6: i dati di dominio.
- V2 fuori tetto: S5a, S6a-c, S12b, S23, S24a, S26.
- V3#1-#6, e i cinque fuori tetto (fork-stato, goal, PRESIDI, post-mortem, design-doc).
- V4#1: lo sforo muto. V4#2: la sentinella del margine. V4#3 (in parte): tre banchi.
- V4#4: /tmp sporcata. V4#5: la chiamata vera.
- V5 R1-R6.

**Esclusa** (serve una decisione di Luca; domande in DEBITI.md, ognuna col perché)
- V1#3 seguito: come distinguere un'issue di correzione.
- V1#6d: il ramo opencode morto e il watchdog promesso da CLAUDE.md §7.
- V1#6e: il test generato mai eseguito.
- V4#2 seguito: la sentinella deve far rosso?

**Rinviata**
- V4#3 resto: i casi di `run_guarded` in `tests/test-lib.sh`, dove l'attesa è il caso da provare.
- V2 S4: il gestore `$metadata` non raggiunto.
- V2 S18b: la lente `echo +0` che non vede le virgolette; oggi non c'è nessuna occorrenza.
- V5 R3(b): l'avviso nel pre-commit quando si tocca un file ancorato.
- V5 fuori tetto: il corpo di allowlist-per-segmento, incompleto ma non falso.
- Tutto ciò che solo il Mac prova: DEBITI, sezione ⏳.

**Già coperta**
- V2 S21, già preso da `tests/test-dashboard.sh`.

## Prerequisiti nascosti

- E-047 era un prerequisito di ogni sabotaggio su un modulo Python. Finché la suite leggeva la cache,
  un verde non provava niente. È curato prima degli altri banchi di dominio.

## Errori miei in questo ventaglio (REGISTRO)

- **E-046**: la cura Q32 annidava mutation-tests nel proprio banco. Il SAL lo nominava, il registro no:
  ora c'è.
- **E-047**: sabotaggi giudicati sul bytecode stantio, miei e del giro V2.
- **Svista di consegna**: due messaggi di commit hanno perso l'apostrofo («c e», «d issue»), per le
  virgolette di printf. Non riscritti: la storia del ramo non si riscrive.
