#!/usr/bin/env python3
"""dashboard.py — la finestra di osservazione del sistema.
Genera una pagina HTML che si aggiorna da sola e la serve su localhost:8787.
Uso: python3 tools/dashboard.py  (poi apri http://localhost:8787)
"""
import http.server
import json
import os
import re
import subprocess
import threading
import time

HUB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG = os.path.expanduser("~/night-shift-console.log")
SAL = os.path.join(HUB, "SAL.md")

def read_log(max_lines=500):
    try:
        with open(LOG, "r", errors="ignore") as f:
            lines = f.readlines()[-max_lines:]
        return lines
    except:
        return []

def parse_stats():
    lines = read_log(2000)
    today = time.strftime("%Y-%m-%d")
    stats = {
        "today": today,
        "turni_oggi": 0,
        "turni_totali": 0,
        "pr_oggi": 0,
        "fix_oggi": 0,
        "caccia_oggi": 0,
        "errori_oggi": 0,
        "ultimo_giro": "",
        "verifiche": [],
        "recent": [],
        "online": False,
        "modello": "",
    }
    
    for l in lines:
        if "TURNO INIZIATO" in l:
            stats["turni_totali"] += 1
            if today in l:
                stats["turni_oggi"] += 1
                stats["ultimo_giro"] = l.strip()
        if "PR bozza" in l or "PR https" in l:
            if today in l:
                stats["pr_oggi"] += 1
        if "auto-fix" in l:
            if today in l:
                stats["fix_oggi"] += 1
        if "caccia" in l.lower() and "attivo" in l.lower():
            if today in l:
                stats["caccia_oggi"] += 1
        if "ERRORE" in l or "⛔" in l:
            if today in l:
                stats["errori_oggi"] += 1
        if "VERIFICA ROSSA" in l and today in l:
            m = re.search(r'VERIFICA ROSSA: (.+)', l)
            if m and m.group(1) not in [v["nome"] for v in stats["verifiche"]]:
                stats["verifiche"].append({"nome": m.group(1), "stato": "rossa"})
        elif "night-verify" in l and "verdi" in l and today in l:
            stats["verifiche"].append({"nome": "night-verify", "stato": "verde"})
    
    # verifiche da .night-verify
    try:
        r = subprocess.run(["bash", os.path.join(HUB, ".night-verify")], 
                          capture_output=True, timeout=60, cwd=HUB)
        stats["night_verify_rc"] = r.returncode
    except:
        stats["night_verify_rc"] = -1
    
    # GitHub raggiungibile?
    try:
        r = subprocess.run(["curl", "-sf", "--max-time", "3", 
                           "https://api.github.com/zen"],
                          capture_output=True, timeout=5)
        stats["online"] = r.returncode == 0
    except:
        stats["online"] = False
    
    # modello
    try:
        r = subprocess.run(["curl", "-sf", "http://localhost:11434/api/tags"],
                          capture_output=True, timeout=3)
        if r.returncode == 0:
            data = json.loads(r.stdout)
            if data.get("models"):
                stats["modello"] = data["models"][0]["name"]
    except:
        pass
    
    # processi attivi
    try:
        r = subprocess.run(["pgrep", "-f", "night-shift.sh"], capture_output=True, timeout=3)
        stats["turno_attivo"] = len(r.stdout.strip().split(b"\n")) if r.stdout.strip() else 0
    except:
        stats["turno_attivo"] = 0
    
    # ultime 30 righe interessanti
    for l in lines:
        if any(k in l for k in ["TURNO", "PR ", "auto-fix", "CACCIA", "caccia", 
                                  "VERIFICA", "ciclo-vivo", "banco", "reparto"]):
            stats["recent"].append({
                "tempo": l[1:20] if l.startswith("[") else "",
                "testo": re.sub(r'\x1b\[[0-9;]*m', '', l.strip())[22:120]
            })
    stats["recent"] = stats["recent"][-25:]
    
    return stats

TEMPLATE = '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="10">
<title>AI_Programmer — Dashboard</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:-apple-system,BlinkMacSystemFont,sans-serif; background:#1a1a2e; color:#eee; padding:20px; }}
h1 {{ font-size:1.4rem; margin-bottom:16px; color:#0af; }}
.grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:12px; margin-bottom:20px; }}
.card {{ background:#16213e; border-radius:12px; padding:16px; text-align:center; }}
.card .val {{ font-size:2.2rem; font-weight:bold; color:#0af; }}
.card .lbl {{ font-size:0.75rem; color:#8899aa; margin-top:4px; }}
.verde {{ color:#4ecca3 !important; }}
.rosso {{ color:#e74c3c !important; }}
.giallo {{ color:#f39c12 !important; }}
.section {{ background:#16213e; border-radius:12px; padding:16px; margin-bottom:16px; }}
.section h2 {{ font-size:1rem; color:#0af; margin-bottom:12px; }}
.log {{ font-family:Menlo,monospace; font-size:0.78rem; line-height:1.5; }}
.log div {{ padding:2px 0; border-bottom:1px solid #1a1a2e; }}
.status-bar {{ display:flex; gap:16px; margin-bottom:16px; flex-wrap:wrap; }}
.pill {{ padding:6px 14px; border-radius:20px; font-size:0.8rem; font-weight:600; }}
.pill.on {{ background:#1a4a3a; color:#4ecca3; }}
.pill.off {{ background:#4a1a1a; color:#e74c3c; }}
</style>
</head>
<body>
<h1>🤖 AI_Programmer — Dashboard del sistema</h1>

<div class="status-bar">
  <span class="pill {'on' if s['turno_attivo'] else 'off'}">
    {'🟢 TURNO ATTIVO' if s['turno_attivo'] else '🔴 TURNO FERMO'}
  </span>
  <span class="pill {'on' if s['online'] else 'off'}">
    {'🌐 ONLINE' if s['online'] else '📴 OFFLINE'}
  </span>
  <span class="pill on">🧠 {s['modello'] or 'modello non caricato'}</span>
  <span class="pill {'on' if s.get('night_verify_rc',-1)==0 else 'off'}">
    {'✅ .night-verify' if s.get('night_verify_rc',-1)==0 else '❌ .night-verify rosso'}
  </span>
</div>

<div class="grid">
  <div class="card"><div class="val">{s['turni_oggi']}</div><div class="lbl">CICLI OGGI</div></div>
  <div class="card"><div class="val {s['pr_oggi'] and 'verde' or ''}">{s['pr_oggi']}</div><div class="lbl">PR CREATE OGGI</div></div>
  <div class="card"><div class="val {s['fix_oggi'] and 'verde' or ''}">{s['fix_oggi']}</div><div class="lbl">FIX APPLICATI</div></div>
  <div class="card"><div class="val">{s['caccia_oggi']}</div><div class="lbl">CACCE ATTIVATE</div></div>
  <div class="card"><div class="val {s['errori_oggi'] and 'rosso' or 'verde'}">{s['errori_oggi']}</div><div class="lbl">ERRORI OGGI</div></div>
  <div class="card"><div class="val">{s['turni_totali']}</div><div class="lbl">CICLI TOTALI</div></div>
</div>

<div class="section">
<h2>📅 Ultime attività</h2>
<div class="log">
{activity}
</div>
</div>

<div class="section">
<h2>🔍 Verifiche</h2>
<div class="log">
{verifiche}
</div>
</div>

<p style="color:#556;font-size:0.7rem;margin-top:12px">
  Aggiornamento automatico ogni 10 secondi ·
  <a href="http://localhost:8787" style="color:#0af">ricarica</a>
</p>
</body>
</html>'''

def make_html(stats):
    activity = ""
    for r in stats["recent"]:
        color = "#8899aa"
        if "PR" in r["testo"]: color = "#4ecca3"
        elif "ERRORE" in r["testo"] or "⛔" in r["testo"]: color = "#e74c3c"
        elif "auto-fix" in r["testo"]: color = "#f39c12"
        elif "TURNO" in r["testo"]: color = "#0af"
        activity += f'<div><span style="color:#556">{r["tempo"]}</span> <span style="color:{color}">{r["testo"]}</span></div>\n'
    
    verifiche = ""
    for v in stats["verifiche"][-10:]:
        icon = "✅" if v["stato"] == "verde" else "❌"
        color = "#4ecca3" if v["stato"] == "verde" else "#e74c3c"
        verifiche += f'<div><span style="color:{color}">{icon} {v["nome"]}</span></div>\n'
    if not verifiche:
        verifiche = '<div style="color:#556">Nessuna verifica registrata oggi</div>'
    
    return TEMPLATE.format(s=stats, activity=activity, verifiche=verifiche)

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        stats = parse_stats()
        html = make_html(stats)
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode())
    def log_message(self, *a):
        pass

if __name__ == "__main__":
    port = 8787
    # se e' già attiva, la riavviamo pulita
    import signal, sys
    try:
        server = http.server.HTTPServer(("localhost", port), Handler)
    except OSError:
        import subprocess
        subprocess.run(["pkill", "-f", "dashboard.py"], capture_output=True)
        time.sleep(1)
        server = http.server.HTTPServer(("localhost", port), Handler)
    print(f"Dashboard su http://localhost:{port} (Ctrl+C per fermare)")
    server.serve_forever()
