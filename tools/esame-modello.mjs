#!/usr/bin/env node
// runner-esame.mjs — il giudice di gara unico.
// Stesse prove per tutti i modelli, su qualunque endpoint OpenAI-compatible:
//   --base http://localhost:11434/v1   (Air o GPU cloud, stesso stack)
//   --base https://openrouter.ai/api/v1 --key sk-or-...  (API)
// Uso:
//   node runner-esame.mjs --base http://localhost:11434/v1 --model agent-qwen --tag air
//   node runner-esame.mjs --base https://openrouter.ai/api/v1 --key KEY --model qwen/qwen3-coder:30b --tag api
// Flag: --smoke (test rapido: solo Prova 3, max 60 token) --out dir (default risultati/)
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const BASEDIR = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : d; };
const BASE = opt('base', 'http://localhost:11434/v1');
const KEY = opt('key', 'ollama');
const MODELS = (opt('model', 'agent-qwen')).split(',');
const TAG = opt('tag', 'local');
const SMOKE = args.includes('--smoke');
const OUT = join(BASEDIR, opt('out', 'risultati'));

const taskFiles = SMOKE ? ['TASK-3-ONESTA.txt'] : (opt('tasks') ? opt('tasks').split(',') : ['TASK-1-OPTIMIZZAZIONE.txt', 'TASK-2-BUG.txt', 'TASK-3-ONESTA.txt']);
mkdirSync(OUT, { recursive: true });

async function esame(model) {
  const safeName = model.replace(/[/:]/g, '_');
  const dir = join(OUT, `${TAG}__${safeName}`);
  mkdirSync(dir, { recursive: true });
  const esito = { tag: TAG, model, base: BASE, quando: new Date().toISOString(), prove: [] };
  for (const tf of taskFiles) {
    const prompt = readFileSync(join(BASEDIR, tf), 'utf8');
    const t0 = Date.now();
    let text = '', err = null, usage = null;
    try {
      const res = await fetch(`${BASE}/chat/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${KEY}` },
        body: JSON.stringify({
          model,
          messages: [{ role: 'user', content: prompt }],
          temperature: 0,
          max_tokens: SMOKE ? 60 : 3000,
        }),
      });
      const j = await res.json();
      if (j.error) throw new Error(JSON.stringify(j.error).slice(0, 300));
      text = j.choices?.[0]?.message?.content || '(vuoto)';
      usage = j.usage || null;
    } catch (e) { err = String(e.message || e); text = `ERRORE RUNNER: ${err}`; }
      const dt = (Date.now() - t0) / 1000;
      const tok = usage?.completion_tokens ?? Math.round(text.length / 4);
      esito.prove.push({ prova: tf, secondi: +dt.toFixed(1), token_output: tok, tok_s: +(tok / dt).toFixed(1), errore: err });
      writeFileSync(join(dir, tf.replace('.txt', '.risposta.txt')), text);
      console.log(`  ${tf} → ${dt.toFixed(0)}s, ~${tok} tok${err ? ' ⚠ ' + err.slice(0, 80) : ''}`);
  }
  return esito;
}

console.log(`🎓 ESAME — endpoint: ${BASE} | modelli: ${MODELS.join(', ')} | tag: ${TAG}${SMOKE ? ' (SMOKE)' : ''}`);
const riepilogoPath = join(OUT, 'riepilogo.json');
const riepilogo = existsSync(riepilogoPath) ? JSON.parse(readFileSync(riepilogoPath, 'utf8')) : [];
for (const m of MODELS) {
  console.log(`\n▶ Modello: ${m}`);
  riepilogo.push(await esame(m));
}
writeFileSync(riepilogoPath, JSON.stringify(riepilogo, null, 2));
console.log(`\n📋 Riepilogo aggiornato: ${riepilogoPath}`);
for (const r of riepilogo.slice(-MODELS.length)) {
  console.log(`  ${r.model} [${r.tag}]: ` + r.prove.map(p => `${p.prova.replace('TASK-','').replace('.txt','')}=${p.secondi}s/${p.token_output}tok`).join(' · '));
}
