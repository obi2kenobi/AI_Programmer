#!/usr/bin/env node
// verifica-visiva.js — screenshot reale di un deploy Apps Script + guardia contro il falso
// verde (pagina che "si apre" ma mostra un errore). Zero dipendenze nuove: usa il Chromium
// già installato nell'ambiente via CLI headless (--screenshot, --dump-dom), non il package
// playwright (assente in questo repo bash/python — niente node_modules solo per questo).
//
// Uso: node tools/verifica-visiva.js <url> <output.png>
// Exit 0 = screenshot preso, nessun segnale d'errore noto nel testo della pagina.
// Exit 1 = screenshot preso ma la pagina mostra un errore noto (Apps Script o vuota).
// Exit 2 = non è stato possibile aprire l'URL (rete, auth, timeout).
const { execFileSync } = require("child_process");
const fs = require("fs");

const CHROME = process.env.CHROME_PATH || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
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

function main() {
  const url = process.argv[2];
  const out = process.argv[3];
  if (!url || !out) {
    console.error("uso: node tools/verifica-visiva.js <url> <output.png>");
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

  try {
    execFileSync(CHROME, [...FLAGS_COMUNI, `--screenshot=${out}`, "--window-size=1400,1000", url],
      { timeout: 20000, stdio: ["ignore", "ignore", "ignore"] });
  } catch (e) {
    console.error(`✗ screenshot non salvato: ${e.message.split("\n")[0]}`);
    process.exit(2);
  }
  const dimensioni = fs.existsSync(out) ? fs.statSync(out).size : 0;
  console.log(`✓ screenshot salvato: ${out} (${dimensioni} byte)`);

  const trovato = SEGNALI_ERRORE.find((s) => testo.toLowerCase().includes(s.toLowerCase()));
  if (trovato) {
    console.error(`✗ segnale d'errore nella pagina: "${trovato}" — lo screenshot esiste ma NON è un verde valido.`);
    process.exit(1);
  }
  if (testo.length < SOGLIA_TESTO_VUOTO) {
    console.error(`✗ pagina quasi vuota (${testo.length} caratteri di testo) — probabile schermata bianca/errore silenzioso.`);
    process.exit(1);
  }
  console.log(`✓ nessun segnale d'errore noto, ${testo.length} caratteri di testo visibile.`);
}

if (require.main === module) main();
module.exports = { SEGNALI_ERRORE, SOGLIA_TESTO_VUOTO, estraiTesto };
