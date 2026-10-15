# Guida ai cancelli automatici (fondi e deploy-gas) — per chi non l'ha mai fatto

Dal 14/10 (Luca: «la maturita' del progetto e dei partecipanti») i cancelli umani
cambiano guardia: non si tolgono — li apre il sistema QUANDO le condizioni sono vere.

## FONDI — l'auto-merge a quattro condizioni
`tools/fondi.sh <dir-repo> <n-pr>` fonde una PR SOLO se:
1. fondibile (GitHub pulito, non bozza)
2. la lente sicurezza ha scritto PULITA nel commento della PR
3. il banco del repo e' verde (.night-verify)
4. il CENSORE approva (parere del revisore)

Ogni NO dice QUALE condizione e' mancata. Esempio VERO del 14/10:
- bloccato: PR vetrina #1 → "lente ASSENTE" + "tocca .night-verify: le prove
  non si giudicano da chi le scrive" (GIUSTO: quella PR resta al giorno)
- quasi: PR hub #291 → 1-2-3 VERDI, fermata solo dalla quarantena del respiro
  (PR di 4 minuti: protezione legittima; esenzione GIORNO_SUBITO=1 in coda)

Come provarlo da soli: apri una PR piccola, fai girare `giorno.sh lente`,
poi `fondi.sh` — e LEGGI le quattro righe: sono la guida vera.

## DEPLOY-GAS — clasp finalmente permesso, col protocollo
`tools/deploy-gas.sh <dir-progetto-clasp>` spinge su Apps Script SOLO con:
1. banco verde 2. lente PULITA 3. BACKUP del vivo VERIFICATO non vuoto
4. MANIFEST con rollback scritto. Senza backup: SI FERMA. Mai senza ritorno.

## Le regole per chi arriva nuovo
- Un NO del cancello non e' un errore: e' il sistema che ti dice cosa manca.
- Non si aggira una guardia: la si emenda, con una riga e un motivo scritto.
- Il log dice sempre chi ha aperto quale porta e perche'.
