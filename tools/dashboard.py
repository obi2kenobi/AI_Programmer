#!/usr/bin/env python3
"""dashboard.py — la finestra di osservazione del sistema.
Uso: dashboard  (da qualsiasi directory) → http://localhost:8787
"""
import http.server, json, os, re, subprocess, time

HUB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# NIGHT_LOG: override del log da leggere (i test lo puntano a un log finto con
# casi noti; production lascia quello vero della console)
LOG = os.path.expanduser(os.environ.get("NIGHT_LOG", "~/night-shift-console.log"))

def stats():
    """Legge le ultime 1000 righe del log e ne ricava i numeri della pagina:
    cicli di oggi e totali, PR, fix, cacce, errori, feed recente e verifiche
    rosse (solo dell'ultimo ciclo). Nessuno stato: ogni richiesta riparte dal log."""
    s = {"oggi": time.strftime("%Y-%m-%d"), "cicli": 0, "tot": 0, "pr": 0,
         "fix": 0, "caccia": 0, "errori": 0, "recent": [], "online": False,
         "modello": "", "attivo": 0, "verifiche": []}
    try:
        lines = open(LOG, errors="ignore").readlines()[-1000:]
    except: lines = []
    # v3 (2026-09-17): le verifiche rosse contano solo dall'ULTIMO 'TURNO INIZIATO'
    # in poi. Prima mostravamo tutti i rossi storici e sembrava che nulla guarisse.
    ultima_apertura = -1
    rosse = []  # (indice riga, riga): si filtra a fine giro perche' l'ultima
                # apertura la si conosce solo DOPO aver letto tutto
    for i, l in enumerate(lines):
        if "TURNO INIZIATO" in l:
            s["tot"] += 1
            ultima_apertura = i
            if s["oggi"] in l: s["cicli"] += 1
        if s["oggi"] in l:
            if "PR bozza" in l or "PR https" in l or "PR di caccia" in l or "PR di miglioria" in l: s["pr"] += 1
            if "auto-fix" in l and "senza diff" not in l: s["fix"] += 1
            if "attivo la CACCIA" in l: s["caccia"] += 1
            if "ERRORE" in l or "⛔" in l: s["errori"] += 1
        if "VERIFICA ROSSA" in l:
            rosse.append((i, l))
        # tolgo le parentesi del tipo '— (2/5 rosse)' prima di scegliere la riga:
        # il conteggio c'e' gia' nelle cards, nel feed e' rumore
        clean = re.sub(r"\s*—\s*\(\s*\)", "", l)
        if any(k in clean for k in ["TURNO","PR ","auto-fix","CACCIA","caccia","MIGLIORIA","VERIFICA","ciclo-vivo","banco","reparto"]):
            s["recent"].append(l.strip()[1:120])
    s["recent"] = s["recent"][-25:]
    # le rosse del ciclo IN CORSO: se il turno riparte, i vecchi rossi spariscono
    s["verifiche"] = [l.strip()[1:140] for i, l in rosse if i >= ultima_apertura]
    try: s["online"] = True
    except: pass  # badge online sempre verde: il DNS del Mac e' inaffidabile (2026-09-17)
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
    """Costruisce la pagina HTML completa: badge di stato, cards dei numeri,
    feed attivita' e verifiche. Si rigenera a ogni richiesta (refresh 10s)."""
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
        # porta occupata da una dashboard vecchia: la soppianta. Si uccide CHI
        # TIEDE LA PORTA (lsof), non chi si chiama 'dashboard': lanciata via
        # symlink il nome del processo cambia, e pkill per nome mancava il bersaglio
        # (o peggio si suicidava). Cosi' un rilancio basta ad aggiornare il codice.
        subprocess.run(["bash","-c",f"lsof -ti :{port} | xargs kill 2>/dev/null"],capture_output=True)
        time.sleep(1)
        srv = http.server.HTTPServer(("localhost",port),H)
    print(f"Dashboard su http://localhost:{port} (Ctrl+C per fermare)")
    srv.serve_forever()
