#!/usr/bin/env node
// verifica-visiva.js — screenshot reale di un deploy Apps Script + guardia contro il falso
// verde (pagina che "si apre" ma mostra un errore). Zero dipendenze nuove: usa il Chromium
// già installato nell'ambiente via CLI headless (--screenshot, --dump-dom), non il package
// playwright (assente in questo repo bash/python — niente node_modules solo per questo).
//
// Uso: node tools/verifica-visiva.js <url> <output.png>
// Exit 0 = screenshot preso, nessun segnale d'errore noto nel testo della pagina.
// Exit 1 = screenshot preso ma la pagina mostra un errore noto (Apps Script o vuota).
// Exit 2 = non è stata aperta la webapp: rete, accesso Google, certificato, timeout, browser assente.
const { execFileSync } = require("child_process");
const fs = require("fs");

// (Q21, 2026-09-23, giro A7 della notte): il default era il percorso di UNA cloud — sul Mac mancava
// e l'errore diceva «impossibile aprire l'URL». Ora si cerca fra i candidati del Mac e della cloud;
// nessuno = exit 2 detto come tale.
const CANDIDATI_CHROME = [
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  "/opt/pw-browsers/chromium",
  "/usr/bin/chromium", "/usr/bin/chromium-browser", "/usr/bin/google-chrome",
];
function trovaChrome() {
  if (process.env.CHROME_PATH) return fs.existsSync(process.env.CHROME_PATH) ? process.env.CHROME_PATH : null;
  return CANDIDATI_CHROME.find((c) => fs.existsSync(c)) || null;
}
const FLAGS_COMUNI = ["--headless=new", "--no-sandbox", "--disable-gpu", "--virtual-time-budget=8000"];

// Segnali noti di Apps Script/webapp rotta — non un elenco esaustivo, un primo filtro onesto.
// "undefined"/"NaN"/"[object Object]" aggiunti al Giro 7 dei test 2026-08-21: un report con
// un campo mancante (es. Customer_Name assente) li mostra a schermo e prima passava per sano
// (verificato dal vivo: night-shift-pilot, riga con Customer_Name mancante -> "undefined" in
// tabella, exit 0 prima del fix). "null" bare escluso apposta: in un progetto in italiano
// collide con "nullo"/"nulla" (falso positivo) — richiederebbe un match a parola intera, non
// fatto qui perché SEGNALI_ERRORE oggi è solo substring, non regex.
const SEGNALI_ERRORE = [
  "Autorizzazione richiesta", "Richiesta di autorizzazione", "Authorization required",
  "Errore di script", "Script error", "exception", "Spiacenti, si è verificato un errore",
  "Sorry, unable to open the file at this time",
  "undefined", "NaN", "[object Object]",
];
const SOGLIA_TESTO_VUOTO = 40; // caratteri di testo visibile sotto cui la pagina è "vuota"
// (Q21): pagine che NON sono la webapp — misurate stanotte con Chromium headless, davano exit 0:
// l'accesso di Google (webapp che chiede il login, aperta da un browser anonimo) e le pagine
// d'errore di Chrome (certificato, rete), che portano sempre un codice ERR_… in ogni lingua.
// Sono «non aperta» (exit 2), non un verde e non un errore della webapp.
const SEGNALI_NON_PAGINA = [
  /\bERR_[A-Z_]+\b/,
  /Utilizza il tuo Account Google|Use your Google Account/i,
  /Accedi - Account Google|Sign in - Google Accounts/i,
];

// estrazione-per-testabilità: isolata dalla logica di dominio (Chromium, exit code) per
// poterla provare con dati sintetici (pattern estrazione-per-testabilita.md).
function estraiTesto(dom) {
  // bug reale (revisione 14 lenti, 2026-08-28): la sola rimozione dei tag lasciava intatto
  // il CONTENUTO di <script>/<style> — il codice JS di una pagina normale contiene quasi
  // sempre la stringa "undefined" (es. `typeof x === "undefined"`), facendo scattare un
  // falso "segnale d'errore" su pagine perfettamente sane. Rimuovere i blocchi script/style
  // per intero PRIMA di spogliare i tag rimanenti.
  return dom
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// giudica(testo): {esito, motivo} — 0 verde · 1 la webapp mostra un errore · 2 non e' la webapp
function giudica(testo) {
  const nonPagina = SEGNALI_NON_PAGINA.find((r) => r.test(testo));
  if (nonPagina) return { esito: 2, motivo: `non e' la webapp (accesso Google o pagina d'errore di Chrome: ${testo.match(nonPagina)[0]})` };
  const trovato = SEGNALI_ERRORE.find((s) => testo.toLowerCase().includes(s.toLowerCase()));
  if (trovato) return { esito: 1, motivo: `segnale d'errore nella pagina: "${trovato}" — lo screenshot esiste ma NON è un verde valido` };
  if (testo.length < SOGLIA_TESTO_VUOTO) return { esito: 1, motivo: `pagina quasi vuota (${testo.length} caratteri di testo) — probabile schermata bianca/errore silenzioso` };
  return { esito: 0, motivo: `nessun segnale d'errore noto, ${testo.length} caratteri di testo visibile` };
}

// (2026-09-24, terzo ventaglio, V3#5): la skill promette il confronto con la volta prima, ma lo
// screenshot nuovo scriveva sopra il vecchio allo stesso percorso. Ora il vecchio si sposta accanto,
// <nome>.prima.png, e l'uscita dice «prima N byte → dopo M byte». Nessun precedente = null, detto.
function conservaPrima(out) {
  if (!fs.existsSync(out)) return null;
  const percorso = out.replace(/(\.png)?$/i, ".prima.png");
  fs.renameSync(out, percorso);
  return { percorso, byte: fs.statSync(percorso).size };
}

function main() {
  const url = process.argv[2];
  const out = process.argv[3];
  if (!url || !out) {
    console.error("uso: node tools/verifica-visiva.js <url> <output.png>");
    process.exit(2);
  }
  const CHROME = trovaChrome();
  if (!CHROME) {
    console.error(`✗ nessun Chromium trovato (CHROME_PATH=${process.env.CHROME_PATH || "non impostato"}; cercati: ${CANDIDATI_CHROME.join(", ")}) — non ho aperto l'URL`);
    process.exit(2);
  }

  let dom;
  try {
    dom = execFileSync(CHROME, [...FLAGS_COMUNI, "--dump-dom", url],
      { encoding: "utf8", timeout: 20000, stdio: ["ignore", "pipe", "ignore"] });
  } catch (e) {
    console.error(`✗ impossibile aprire ${url}: ${e.message.split("\n")[0]}`);
    process.exit(2);
  }
  const testo = estraiTesto(dom);

  const prima = conservaPrima(out);
  console.log(prima ? `↻ screenshot precedente spostato in ${prima.percorso}` : "· nessuno screenshot precedente allo stesso percorso");
  try {
    execFileSync(CHROME, [...FLAGS_COMUNI, `--screenshot=${out}`, "--window-size=1400,1000", url],
      { timeout: 20000, stdio: ["ignore", "ignore", "ignore"] });
  } catch (e) {
    console.error(`✗ screenshot non salvato: ${e.message.split("\n")[0]}`);
    process.exit(2);
  }
  const dimensioni = fs.existsSync(out) ? fs.statSync(out).size : 0;
  console.log(`✓ screenshot salvato: ${out} (${dimensioni} byte)`);
  if (prima) console.log(`  confronto grezzo: prima ${prima.byte} byte → dopo ${dimensioni} byte`);

  const g = giudica(testo);
  if (g.esito !== 0) {
    console.error(`✗ ${g.motivo}.`);
    process.exit(g.esito);
  }
  console.log(`✓ ${g.motivo}.`);
}

if (require.main === module) main();
module.exports = { SEGNALI_ERRORE, SEGNALI_NON_PAGINA, SOGLIA_TESTO_VUOTO, estraiTesto, giudica, trovaChrome, conservaPrima };
