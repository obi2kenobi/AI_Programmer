#!/usr/bin/env python3
"""dashboard.py — la finestra di OSSERVAZIONE e ANALISI del sistema (v4, 2026-09-20).

Tre domande, tre sezioni (il metodo: le domande prima del codice):
1. CONSEGNA?     — il FUNNEL del giorno: finestre → trasformatore → gate → PR
                   → censore → merge. Ogni caduta numerata = il miglioramento dopo.
2. COSA BLOCCA?  — le cadute stesse: agenti morti, gate, push, wedge di Ollama,
                   con le righe vere del log accanto.
3. COME STA?     — debiti col TREND vero (dal file storia del censimento),
                   drift per repo, censore con motivi e budget, watchdog.

Uso: dashboard  (da qualsiasi directory) → http://localhost:8787
Override per test: NIGHT_LOG (il log da leggere), NIGHT_CENSUS (dir .git/caccia-registro).
"""
import http.server, json, os, re, subprocess, time
from datetime import datetime

HUB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG = os.path.expanduser(os.environ.get("NIGHT_LOG", "~/night-shift-console.log"))
WORK = os.path.expanduser("~/night-shift-work")

def leggi_log():
    try:
        return open(LOG, errors="ignore").readlines()[-4000:]
    except Exception:
        return []

def riga_data(l):
    m = re.match(r"\[(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)\]", l)
    return m.group(1) if m else None

def stats():
    oggi = time.strftime("%Y-%m-%d")
    lines = leggi_log()
    s = {"oggi": oggi, "now": time.strftime("%H:%M:%S"),
         "funnel": {}, "gate_bocia": [], "push_err": [], "delibere": [],
         "recent": [], "verifiche": [], "ollama_wedge": 0, "ollama_revive": 0,
         "drift": {}, "pr": 0, "fix": 0, "cicli": 0, "tot": 0, "errori": 0}
    F = s["funnel"]
    F["finestre"] = F["trasformatore"] = F["agente_ok"] = F["agente_morto"] = 0
    F["gate"] = F["consegne"] = F["push_fail"] = F["approvate"] = F["rigettate"] = 0
    ultima_apertura = -1
    rosse = []
    for i, l in enumerate(lines):
        d = riga_data(l)
        if "TURNO INIZIATO" in l:
            ultima_apertura = i
        di_oggi = d and d.startswith(oggi)
        if d and "TURNO INIZIATO" in l:
            s["tot"] += 1
            if di_oggi: s["cicli"] += 1
        if di_oggi:
            if "attivo la CACCIA" in l: F["finestre"] += 1
            if "TRASFORMATORE deterministico" in l: F["trasformatore"] += 1
            if "AGENTE FALLITO" in l: F["agente_morto"] += 1
            if "caccia: sana e nessuna miglioria" in l: F["agente_ok"] += 1
            if "gate BOCCIA" in l or "gate BOCCIA:" in l:
                F["gate"] += 1; s["gate_bocia"].append(l.strip()[1:150])
            if "MIGLIORIA pronta" in l: F["consegne"] += 1
            if "commit/push" in l and "fallito" in l:
                F["push_fail"] += 1; s["push_err"].append(l.strip()[1:200])
            if "PR di" in l and "→" in l: s["pr"] += 1
            if "auto-fix" in l and "senza diff" not in l: s["fix"] += 1
            if "ERRORE" in l or "⛔" in l: s["errori"] += 1
            if "Ollama wedged" in l: s["ollama_wedge"] += 1
            if "rianimato dal watchdog" in l: s["ollama_revive"] += 1
            m = re.search(r"DELIBERA: (APPROVA|RIGETTA) PR #(\d+)", l)
            if m:
                F["approvate" if m.group(1) == "APPROVA" else "rigettate"] += 1
                s["delibere"].append(l.strip()[1:180])
            m = re.search(r"(AI_Programmer|Sistema-Gestione-Magazzino|[A-Za-z_-]+): standard: (ALLINEATO|DIVERGENTE)", l)
            if m: s["drift"][m.group(1)] = m.group(2)
            if i >= len(lines) - 400:
                clean = re.sub(r"\s*—\s*\(\s*\)", "", l)
                if any(k in clean for k in ["TURNO", "PR ", "auto-fix", "CACCIA", "caccia", "MIGLIORIA",
                                            "TRASFORMATORE", "VERIFICA", "DELIBERA", "Ollama", "standard:", "registro:"]):
                    s["recent"].append(clean.strip()[1:130])
        if "VERIFICA ROSSA" in l and di_oggi:
            rosse.append((i, l))
    # le rosse del ciclo CORRENTE si filtrano DOPO la scansione: l'ultima
    # apertura la si conosce solo a fine giro (regressione della mia v4 —
    # la stessa lezione del parser del turno, rifatta a giorni di distanza)
    s["verifiche"] = [l.strip()[1:140] for i, l in rosse if i >= ultima_apertura]
    s["recent"] = s["recent"][-30:]
    # censimento col trend VERO (dal file storia) — la repo che gira
    cen = os.environ.get("NIGHT_CENSUS",
                         os.path.join(WORK, "AI_Programmer", ".git", "caccia-registro", "storia"))
    s["censimento"] = {"ultimo": None, "trend": []}
    try:
        for l in open(cen, errors="ignore").readlines()[-60:]:
            m = re.match(r"(\S+ \S+) E-002=(\d+) E-032=(\d+) tot=(\d+) delta=(-?\d+)", l.strip())
            if m:
                punto = {"t": m.group(1)[:16], "e002": int(m.group(2)),
                         "e032": int(m.group(3)), "tot": int(m.group(4)), "d": int(m.group(5))}
                s["censimento"]["trend"].append(punto)
                s["censimento"]["ultimo"] = punto
    except Exception:
        pass
    # modello + turno attivo (come prima)
    try:
        r = subprocess.run(["curl", "-sf", "--max-time", "3", "http://localhost:11434/api/tags"],
                           capture_output=True, timeout=4)
        if r.returncode == 0:
            s["modello"] = json.loads(r.stdout)["models"][0]["name"]
    except Exception:
        pass
    try:
        r = subprocess.run(["pgrep", "-f", "night-shift/night-shift.sh"], capture_output=True, timeout=3)
        s["attivo"] = len([x for x in r.stdout.decode().split("\n") if x.strip()])
    except Exception:
        s["attivo"] = 0
    return s

def barrette(trend):
    """sparkline SVG del debito nel tempo — analisi vera, dati veri."""
    if len(trend) < 2:
        return "<div style='color:#556;font-size:.75rem'>trend in costruzione (servono ≥2 censimenti)</div>"
    vals = [p["tot"] for p in trend]
    w, h, pad = 560, 70, 8
    mx, mn = max(vals), min(vals)
    span = (mx - mn) or 1
    punti = []
    for j, v in enumerate(vals):
        x = pad + j * (w - 2 * pad) / (len(vals) - 1)
        y = h - pad - (v - mn) * (h - 2 * pad) / span
        punti.append(f"{x:.0f},{y:.0f}")
    primo, ultimo = vals[0], vals[-1]
    delta = ultimo - primo
    colore = "#e74c3c" if delta > 0 else ("#4ecca3" if delta < 0 else "#0af")
    etichetta = f"{primo} → {ultimo} ({'+' if delta > 0 else ''}{delta} dall'inizio della finestra)"
    return (f"<svg width='{w}' height='{h}'><polyline points='{' '.join(punti)}' "
            f"fill='none' stroke='{colore}' stroke-width='2'/></svg>"
            f"<div style='color:{colore};font-size:.75rem'>{etichetta} · max {mx} · min {mn}</div>")

def page(s):
    F = s["funnel"]
    # il funnel: ogni caduta numerata
    stadi = [("Finestre di caccia", F["finestre"], "#0af"),
             (" Trasformatore ha applicato", F["trasformatore"], "#4ecca3"),
             (" Agente: onesto 'niente'", F["agente_ok"], "#8899aa"),
             (" Agente: MORTO (Ollama?)", F["agente_morto"], "#e74c3c"),
             (" Gate: bociate", F["gate"], "#f39c12"),
             (" Consegne pronte", F["consegne"], "#4ecca3"),
             (" Push falliti", F["push_fail"], "#e74c3c"),
             (" Censore: APPROVATE", F["approvate"], "#4ecca3"),
             (" Censore: RIGETTATE", F["rigettate"], "#f39c12")]
    maxf = max([v for _, v, _ in stadi] + [1])
    funnel_html = "".join(
        f"<div style='display:flex;align-items:center;gap:10px;margin:4px 0'>"
        f"<div style='width:190px;text-align:right;color:#8899aa;font-size:.78rem'>{nome}</div>"
        f"<div style='background:{col};width:{max(6, int(v * 340 / maxf))}px;height:18px;"
        f"border-radius:4px;color:#fff;font-size:.72rem;display:flex;align-items:center;padding-left:6px'>{v}</div></div>"
        for nome, v, col in stadi)
    cen = s["censimento"]["ultimo"]
    cen_html = (f"E-002 (tubi) <b>{cen['e002']}</b> · E-032 (fixture vive) <b>{cen['e032']}</b> · "
                f"tot <b>{cen['tot']}</b> · delta ultimo <b>{cen['d']:+d}</b>" if cen else "censimento non disponibile")
    drift_html = "<br>".join(f"{r}: {'✓ allineato' if v == 'ALLINEATO' else '⚠ DIVERGENTE — PR di riallineo in attesa'}"
                             for r, v in s["drift"].items()) or "nessuna misura oggi"
    blocchi = ""
    if s["push_err"]:
        blocchi += "<div style='color:#e74c3c;font-size:.75rem;margin:2px 0'>" + "<br>".join(s["push_err"][-3:]) + "</div>"
    if s["gate_bocia"]:
        blocchi += "<div style='color:#f39c12;font-size:.75rem;margin:2px 0'>" + "<br>".join(s["gate_bocia"][-3:]) + "</div>"
    if not blocchi:
        blocchi = "<div style='color:#4ecca3;font-size:.75rem'>niente da segnalare: nessun gate o push bocciato oggi</div>"
    delib = "<br>".join(s["delibere"][-4:]) or "<i>nessuna deliberazione: il censore aspetta la prima PR in quarantena</i>"
    ver = "".join(f"<div style='color:#e74c3c'>❌ {v}</div>" for v in s["verifiche"]) or "<div style='color:#4ecca3'>✅ tutte verdi</div>"
    log = "".join(f"<div style='padding:2px 0;border-bottom:1px solid #1a1a2e;color:#8899aa'>{r}</div>" for r in reversed(s["recent"][-15:]))
    ollama = f"🧠 {s.get('modello', 'spento')}"
    if s["ollama_wedge"]:
        ollama += f" · <span style='color:#e74c3c'>{s['ollama_wedge']} wedge oggi</span>"
    if s["ollama_revive"]:
        ollama += f" · <span style='color:#4ecca3'>{s['ollama_revive']} rianimati dal watchdog</span>"
    return f'''<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="10">
<title>AI_Programmer — analisi</title><style>*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:-apple-system,sans-serif;background:#1a1a2e;color:#eee;padding:18px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:10px;margin:12px 0}}
.sec{{background:#16213e;border-radius:12px;padding:14px;margin-bottom:14px}}
h2{{font-size:.85rem;color:#0af;margin-bottom:8px}} .log{{font-family:Menlo,monospace;font-size:.72rem}}</style></head>
<body><h1 style="font-size:1.25rem;color:#0af">🤖 AI_Programmer — osservazione e analisi</h1>
<div style="font-size:.7rem;color:#556">aggiornato {s['now']} · refresh 10s</div>
<div class="grid">
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#4ecca3' if s['attivo'] else '#e74c3c'}">{'🟢' if s['attivo'] else '🔴'}</div><div style="font-size:.7rem;color:#8899aa">TURNO</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:#0af">{s['cicli']}</div><div style="font-size:.7rem;color:#8899aa">CICLI OGGI</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#4ecca3' if s['pr'] else '#0af'}">{s['pr']}</div><div style="font-size:.7rem;color:#8899aa">PR OGGI</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#e74c3c' if s['ollama_wedge'] else '#4ecca3'}">{s['ollama_wedge']}</div><div style="font-size:.7rem;color:#8899aa">WEDGE OLLAMA</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#e74c3c' if s['errori'] else '#4ecca3'}">{s['errori']}</div><div style="font-size:.7rem;color:#8899aa">ERRORI OGGI</div></div>
</div>
<div style="font-size:.8rem;color:#8899aa">{ollama}</div>
<div class="sec"><h2>① CONSEGNA? — il funnel di oggi (ogni caduta = il prossimo miglioramento)</h2>
{funnel_html}
<div style="color:#556;font-size:.7rem;margin-top:6px">lettura: se le finestre ci sono ma il trasformatore non applica, le forme non sono riconosciute; se le consegne ci sono ma i push falliscono, guarda ②; se le PR entrano in quarantena e non escono deliberazioni, il censore gira?</div></div>
<div class="sec"><h2>② COSA BLOCCA? — le cadute di oggi, con le righe vere</h2>{blocchi}</div>
<div class="sec"><h2>③ I DEBITI — censimento e trend</h2>
<div style="font-size:.8rem;margin-bottom:6px">{cen_html}</div>
{barrette(s['censimento']['trend'])}</div>
<div class="sec"><h2>④ IL CENSORE — deliberazioni e motivi</h2><div style="font-size:.75rem">{delib}</div></div>
<div class="sec"><h2>⑤ DRIFT DELLO STANDARD (per repo, oggi)</h2><div style="font-size:.75rem">{drift_html}</div></div>
<div class="sec"><h2>📅 Attività</h2><div class="log">{log}</div></div>
<div class="sec"><h2>🔍 Verifiche rosse (ciclo corrente)</h2>{ver}</div>
<p style="color:#556;font-size:.7rem">v4 · analisi: funnel, trend debiti, censore, drift, watchdog · <a href=http://localhost:8787 style=color:#0af>ricarica</a></p></body></html>'''

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8"); self.end_headers()
        self.wfile.write(page(stats()).encode())
    def log_message(self, *a): pass

if __name__ == "__main__":
    port = 8787
    try: srv = http.server.HTTPServer(("localhost", port), H)
    except OSError:
        subprocess.run(["bash", "-c", f"lsof -ti :{port} | xargs kill 2>/dev/null"], capture_output=True)
        time.sleep(1)
        srv = http.server.HTTPServer(("localhost", port), H)
    print(f"Dashboard v4 su http://localhost:{port} (Ctrl+C per fermare)")
    srv.serve_forever()
