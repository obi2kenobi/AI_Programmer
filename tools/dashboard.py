#!/usr/bin/env python3
"""dashboard.py — la finestra di osservazione del sistema.
Uso: dashboard  (da qualsiasi directory) → http://localhost:8787
"""
import http.server, json, os, re, subprocess, time

HUB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG = os.path.expanduser("~/night-shift-console.log")

def stats():
    s = {"oggi": time.strftime("%Y-%m-%d"), "cicli": 0, "tot": 0, "pr": 0,
         "fix": 0, "caccia": 0, "errori": 0, "recent": [], "online": False,
         "modello": "", "attivo": 0, "verifiche": []}
    try:
        lines = open(LOG, errors="ignore").readlines()[-1000:]
    except: lines = []
    for l in lines:
        if "TURNO INIZIATO" in l:
            s["tot"] += 1
            if s["oggi"] in l: s["cicli"] += 1
        if s["oggi"] in l:
            if "PR bozza" in l or "PR https" in l or "PR di caccia" in l: s["pr"] += 1
            if "auto-fix" in l and "senza diff" not in l: s["fix"] += 1
            if "attivo la CACCIA" in l: s["caccia"] += 1
            if "ERRORE" in l or "⛔" in l: s["errori"] += 1
            pass  # verficihe verdi = azzera le rosse
        clean = re.sub(r'\\s*—\\s*\\(\\s*\\)', '', l)\n        if any(k in clean for k in ["TURNO","PR ","auto-fix","CACCIA","caccia","VERIFICA","ciclo-vivo","banco","reparto"]):
            s["recent"].append(l.strip()[1:120])
    s["recent"] = s["recent"][-25:]
    try: s["online"] = True
    except: pass
    try:
        r = subprocess.run(["curl","-sf","http://localhost:11434/api/tags"], capture_output=True, timeout=3)
        if r.returncode == 0: s["modello"] = json.loads(r.stdout)["models"][0]["name"]
    except: pass
    try:
        r = subprocess.run(["pgrep","-f","night-shift/night-shift.sh"], capture_output=True, timeout=3)
        s["attivo"] = len([x for x in r.stdout.decode().split("\n") if x.strip()])
    except: pass
    return s

def page(s):
    attivo = '<span style="background:#1a4a3a;color:#4ecca3;padding:6px 14px;border-radius:20px">🟢 TURNO ATTIVO</span>' if s["attivo"] else '<span style="background:#4a1a1a;color:#e74c3c;padding:6px 14px;border-radius:20px">🔴 FERMO</span>'
    online = '<span style="background:#1a4a3a;color:#4ecca3;padding:6px 14px;border-radius:20px">🌐 ONLINE</span>' if s["online"] else '<span style="background:#4a1a1a;color:#e74c3c;padding:6px 14px;border-radius:20px">📴 OFFLINE</span>'
    modello = f'<span style="background:#16213e;color:#0af;padding:6px 14px;border-radius:20px">🧠 {s["modello"] or "spento"}</span>'
    er = f'{"rosso" if s["errori"] else "verde"}'
    log = "".join(f'<div style="padding:3px 0;border-bottom:1px solid #1a1a2e;color:#8899aa">{r}</div>' for r in s["recent"])
    ver = "".join(f'<div style="color:#e74c3c">❌ {v}</div>' for v in s["verifiche"]) or '<div style="color:#4ecca3">✅ tutte verdi</div>'
    cards = "".join(f'<div style="background:#16213e;border-radius:12px;padding:16px;text-align:center"><div style="font-size:2.2rem;font-weight:bold;color:{c}">{v}</div><div style="font-size:.75rem;color:#8899aa">{l}</div></div>' for v,l,c in [
        (s["cicli"],"CICLI OGGI","#0af"), (s["pr"],"PR OGGI", "#4ecca3" if s["pr"] else "#0af"),
        (s["fix"],"FIX", "#4ecca3" if s["fix"] else "#0af"), (s["caccia"],"CACCE","#0af"),
        (s["errori"],"ERRORI", "#e74c3c" if s["errori"] else "#4ecca3"), (s["tot"],"CICLI TOTALI","#0af")])
    return f'''<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="10">
<title>AI_Programmer</title><style>*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:-apple-system,sans-serif;background:#1a1a2e;color:#eee;padding:20px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:16px 0}}
.sec{{background:#16213e;border-radius:12px;padding:16px;margin-bottom:16px}}
h2{{font-size:.9rem;color:#0af;margin-bottom:10px}} .log{{font-family:Menlo,monospace;font-size:.75rem}}</style></head>
<body><h1 style="font-size:1.3rem;color:#0af;margin-bottom:12px">🤖 AI_Programmer</h1>
<div style="display:flex;gap:10px;flex-wrap:wrap">{attivo}{online}{modello}</div>
<div class="grid">{cards}</div>
<div class="sec"><h2>📅 Attività</h2><div class="log">{log}</div></div>
<div class="sec"><h2>🔍 Verifiche rosse oggi</h2>{ver}</div>
<p style="color:#556;font-size:.7rem">refresh 10s · <a href=http://localhost:8787 style=color:#0af>ricarica</a></p></body></html>'''

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header("Content-Type","text/html; charset=utf-8"); self.end_headers()
        self.wfile.write(page(stats()).encode())
    def log_message(self,*a): pass

if __name__ == "__main__":
    import subprocess
    port = 8787
    try: srv = http.server.HTTPServer(("localhost",port),H)
    except OSError:
        subprocess.run(["pkill","-f","dashboard.py"],capture_output=True); time.sleep(1)
        srv = http.server.HTTPServer(("localhost",port),H)
    print(f"Dashboard su http://localhost:{port} (Ctrl+C per fermare)")
    srv.serve_forever()
