# 2026-09-02 — REPO-K: handoff sottosistema notifiche email (diagnosi completa)

Analisi completa di EmailService.gs (95KB, 28 metodi): architettura, identità mittente,
quota, e 4 punti aperti. PR #85 mergiata (diagnosticEmailSender.gs).

## La scoperta principale: il modello a TRE identità di GAS

GmailApp.sendEmail({from: ...}) funziona SOLO se l'indirizzo è l'account primario
o un alias verificato in Gmail. Ma CHI sta eseguendo lo script dipende dal contesto:

| Contesto | Chi esegue | Alias applicabili |
|---|---|---|
| Editor | chi preme Esegui | i suoi |
| Web app (executeAs: USER_DEPLOYING) | chi ha fatto il deploy | i suoi |
| Trigger temporali | chi ha INSTALLATO il trigger | i suoi |

I trigger sono la variabile più insidiosa: conservano l'identità di chi li ha creati,
che può essere diversa sia dall'editor sia dal deployer.

## La causa root dei fallimenti

L'alias ordini.biocombustibili@ NON era verificato in Gmail. Aggiunto e verificato →
diagnosticEmailSender() conferma: mittente utilizzabile, quota residua 1466/1500.

## Le sei eccezioni al retry

6 chiamate bypassano sendWithRetry (5 auto-alert deliberatamente senza retry per non
loopare; 1 notifica di produzione senza retry: sendErrorSummaryEmail :1349).

## I 4 punti aperti

5.1 Identità del DEPLOYER non verificata (executeAs: USER_DEPLOYING = chi conta in
    produzione; diagnostica dall'editor certifica solo l'editor)
5.2 Identità dei 4 TRIGGER non verificata (se appartengono a un account senza alias,
    i report delle 8:00 e 15:00 falliscono in silenzio)
5.3 Indirizzo HARDCODED a :682 che scavalca le costanti (14 punti su 15 usano la
    costante, questo no: il giorno che si cambia, questo resta indietro)
5.4 Web app ANYONE_ANONYMOUS + USER_DEPLOYING: chiunque conosca l'URL esegue col
    deployer. Nessun controllo di identità in WebApp.gs.

## Proposte al canone

1. Il modello a TRE identità (editor/deployer/trigger-owner) merita una nota nel
   metodo GAS: chi diagnostica un problema di permessi deve sapere QUALE identità
   conta per QUALE contesto.
2. L'indirizzo hardcoded che scavalca le costanti è la famiglia «due fonti di verità»
   al quadrato: 14 punti seguono la costante, 1 no — ed è quello che fallisce per
   primo quando la si cambia.
