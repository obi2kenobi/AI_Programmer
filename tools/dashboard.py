#!/usr/bin/env python3
"""dashboard.py — la finestra di OSSERVAZIONE e ANALISI del sistema (v5, 2026-09-22).

v5 — CHIARA E LAMPANTE (richiesta di Luca: «più chiara e lampante»):
- IL VERDETTO in cima: la pagina GIUDICA (fermo / muto / sta consegnando / gira a
  vuoto) con il motivo in una riga — non siamo noi a interpretare i numeri.
- LA FILA DELLE PR: la pipeline del giorno (consegnata → quarantena → rinvio →
  delibera) coi numeri veri. Il 22/9 cinque PR in quarantena erano INVISIBILI
  e le ho contate a mano col terminale: il punto cieco piu' costoso.
- IL BATTITO: minuti dall'ultima riga di log + il buco di silenzio piu' grande
  del giorno. Le 11 ore di buio della notte non si vedevano da nessuna parte.
- LETTURE CALCOLATE: il funnel e i debiti si commentano da soli sulla prima
  anomalia vera, non con suggerimenti generici.

Le tre domande restano le stesse (il metodo: le domande prima del codice):
1. CONSEGNA?     — il FUNNEL del giorno + LA FILA DELLE PR.
2. COSA BLOCCA?  — le cadute con le righe vere del log.
3. COME STA?     — debiti col TREND vero e verdetto, drift, censore, watchdog.

Uso: dashboard  (da qualsiasi directory) → http://localhost:8787
Override per test: NIGHT_LOG (il log da leggere), NIGHT_CENSUS (dir .git/caccia-registro).
"""
import http.server, json, os, re, subprocess, time
from datetime import datetime

HUB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG = os.path.expanduser(os.environ.get("NIGHT_LOG", "~/night-shift-console.log"))
WORK = os.path.expanduser("~/night-shift-work")

def leggi_log():
    """Tutto il log, non le ultime 4000 righe (D18): 100.000 righe si leggono e si
    contano in 63 ms, la finestra non serviva e sottostimava in silenzio."""
    try:
        return open(LOG, errors="ignore").readlines()
    except Exception:
        return []

def riga_data(l):
    m = re.match(r"\[(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)\]", l)
    return datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S") if m else None

def stats():
    """Conta dal log del turno i numeri della pagina. Ogni contatore nasce da una
    riga FIRMATA del log (la stessa stringa che il turno scrive): se il turno
    cambia una frase, cambia qui — e il test lo dice."""
    oggi = time.strftime("%Y-%m-%d")
    lines = leggi_log()
    s = {"oggi": oggi, "now": time.strftime("%H:%M:%S"),
         "funnel": {}, "gate_bocia": [], "push_err": [], "delibere": [],
         "recent": [], "verifiche": [], "ollama_wedge": 0, "ollama_revive": 0,
         "drift": {}, "pr": 0, "fix": 0, "cicli": 0, "tot": 0, "errori": 0,
         "battito_min": None, "gap_max": None, "pr_eventi": {}}
    F = s["funnel"]
    F["finestre"] = F["trasformatore"] = F["agente_ok"] = F["agente_morto"] = 0
    F["gate"] = F["consegne"] = F["push_fail"] = F["approvate"] = F["rigettate"] = 0
    ultima_apertura = -1
    rosse = []
    prev_dt = None
    for i, l in enumerate(lines):
        d = riga_data(l)
        if d:
            # il BATTITO: la freschezza del log e' la vera domande «il sistema vive?»
            s["battito_min"] = (datetime.now() - d).total_seconds() / 60.0
            if d.strftime("%Y-%m-%d") == oggi:
                if prev_dt:
                    gap = (d - prev_dt).total_seconds() / 60.0
                    if gap > 5 and (s["gap_max"] is None or gap > s["gap_max"][0]):
                        s["gap_max"] = (gap, prev_dt.strftime("%H:%M"), d.strftime("%H:%M"))
                prev_dt = d
        if "TURNO INIZIATO" in l:
            ultima_apertura = i
        di_oggi = d and d.strftime("%Y-%m-%d") == oggi
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
            if "PR di" in l and "→" in l:
                s["pr"] += 1
                m = re.search(r"PR di \S+ → \S+/pull/(\d+)", l)
                if m: s["pr_eventi"].setdefault(m.group(1), []).append("consegnata")
            if "auto-fix" in l and "senza diff" not in l: s["fix"] += 1
            if "ERRORE" in l or "⛔" in l: s["errori"] += 1
            if "Ollama wedged" in l: s["ollama_wedge"] += 1
            if "rianimato dal watchdog" in l: s["ollama_revive"] += 1
            m = re.search(r"PR #(\d+) in quarantena", l)
            if m: s["pr_eventi"].setdefault(m.group(1), []).append("in quarantena")
            m = re.search(r"censore rinvia la PR #(\d+)", l)
            if m: s["pr_eventi"].setdefault(m.group(1), []).append("rinviata dal censore")
            m = re.search(r"DELIBERA: (APPROVA|RIGETTA) PR #(\d+)", l)
            if m:
                F["approvate" if m.group(1) == "APPROVA" else "rigettate"] += 1
                s["delibere"].append(l.strip()[1:180])
                s["pr_eventi"].setdefault(m.group(2), []).append(
                    "APPROVATA" if m.group(1) == "APPROVA" else "RIGETTATA")
            # il nome della repo e' qualunque (l'hub e' pubblico: nessun nome privato nel codice — D24)
            m = re.search(r"([A-Za-z0-9_.-]+): standard: (ALLINEATO|DIVERGENTE)", l)
            if m: s["drift"][m.group(1)] = m.group(2)
            if i >= len(lines) - 400:
                clean = re.sub(r"\s*—\s*\(\s*\)", "", l)
                if any(k in clean for k in ["TURNO", "PR ", "auto-fix", "CACCIA", "caccia", "MIGLIORIA",
                                            "TRASFORMATORE", "VERIFICA", "DELIBERA", "Ollama", "standard:", "registro:"]):
                    s["recent"].append(clean.strip()[1:130])
        if "VERIFICA ROSSA" in l and di_oggi:
            rosse.append((i, l))
    # le rosse del ciclo CORRENTE si filtrano DOPO la scansione (l'ultima apertura
    # la si conosce solo a fine giro — regressione della v4, lezione tenuta)
    s["verifiche"] = [l.strip()[1:140] for i, l in rosse if i >= ultima_apertura]
    s["recent"] = s["recent"][-30:]
    # LA FILA: l'ultimo evento di ogni PR dice dove e' finita
    s["pr_fila"] = {n: ev[-1] for n, ev in s["pr_eventi"].items()}
    # censimento col trend VERO (dal file storia)
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

def verdetto(s):
    """LA RIGA LAMPANTE: la pagina giudica, con il motivo. Ordine di gravita':
    fermo > muto > gira-a-vuoto > sta consegnando > in osservazione."""
    F = s["funnel"]
    battito = s.get("battito_min")
    if not s.get("attivo"):
        return ("#e74c3c", "🔴 FERMO",
                "il turno non e' nei processi — KeepAlive lo riscatta entro 30s; se resta fermo, guarda il log")
    if battito is not None and battito > 15:
        return ("#f39c12", "🟠 VIVO MA MUTO",
                f"il log tace da {battito:.0f} minuti: fase lunga (banco/mutazioni) o blocco vero? il PID c'e'")
    if F["consegne"] or s["pr"]:
        q = sum(1 for v in s.get("pr_fila", {}).values() if v == "in quarantena")
        r = sum(1 for v in s.get("pr_fila", {}).values() if "rinviata" in str(v))
        motivo = f"{F['consegne']} consegne · {s['pr']} PR"
        if q: motivo += f" · {q} in quarantena"
        if r: motivo += f" · {r} rinviate dal censore"
        return ("#4ecca3", "🟢 STA CONSEGNANDO", motivo)
    if F["finestre"] and not F["consegne"]:
        if F["agente_morto"]:
            return ("#f39c12", "🟡 GIRA MA NON CONSEGNA",
                    f"{F['agente_morto']} agenti morti oggi e nessuna consegna: il collo e' l'agente (tetto turni? contesa?)")
        return ("#f39c12", "🟡 GIRA MA NON CONSEGNA",
                f"{F['finestre']} finestre di caccia, zero consegne: guarda il funnel")
    return ("#0af", "🔵 IN OSSERVAZIONE", "il turno vive: cicli, verifiche e drift — il lavoro arrivera'")

def lettura_funnel(F):
    """La lettura CALCOLATA: la prima anomalia vera del funnel, non un consiglio generico."""
    if F["finestre"] >= 3 and not F["trasformatore"] and not F["consegne"]:
        return "le finestre ci sono ma il trasformatore non applica: le forme non sono riconosciute"
    if not F["consegne"] and F["agente_morto"]:
        return f"l'agente muore prima di consegnare ({F['agente_morto']} oggi): tetto dei turni o contesa sul modello"
    if F["consegne"] and F["push_fail"]:
        return "le consegne ci sono ma i push cadono: guarda ②"
    if F["gate"]:
        return f"il gate boccia ({F['gate']} oggi): la miglioria sfora i limiti — piu' chirurgia, meno rewrite"
    if F["consegne"]:
        return "il collo e' pulito: le consegne diventano PR e vanno in quarantena dal censore"
    return "ancora nessuna caccia conclusa oggi"

def lettura_debiti(cens):
    """Il verdetto calcolato della curva del debito: scende, sale o sta ferma
    nella finestra del trend — col colore che la dashboard usa per dirlo."""

    if not cens or len(cens.get("trend") or []) < 2:
        return ""
    delta = cens["trend"][-1]["tot"] - cens["trend"][0]["tot"]
    if delta < 0: return f"<div style='color:#4ecca3;font-size:.78rem;margin-top:4px'>verdetto: STA PAGANDO — {delta} debiti saldati nella finestra</div>"
    if delta > 0: return f"<div style='color:#e74c3c;font-size:.78rem;margin-top:4px'>verdetto: CRESCE ({delta:+d}) — si creano piu' debiti di quanti se ne pagano</div>"
    return "<div style='color:#f39c12;font-size:.78rem;margin-top:4px'>verdetto: STABILE — nessun debito saldato nella finestra: la caccia consegna? il censore fonde?</div>"

def page(s):
    """Rende i numeri in una pagina HTML sola, senza dipendenze. v5: verdetto in
    cima, fila delle PR, battito del log, letture calcolate."""
    F = s["funnel"]
    stadi = [("Finestre di caccia", F["finestre"], "#0af"),
             (" Trasformatore ha applicato", F["trasformatore"], "#4ecca3"),
             (" Agente: onesto 'niente'", F["agente_ok"], "#8899aa"),
             (" Agente: MORTO (Ollama?)", F["agente_morto"], "#e74c3c"),
             (" Gate: bociate", F["gate"], "#f39c12"),
             (" Consegne pronte", F["consegne"], "#4ecca3"),
             (" Push falliti", F["push_fail"], "#e74c3c"),
             ("Censore: APPROVATE", F["approvate"], "#4ecca3"),
             ("Censore: RIGETTATE", F["rigettate"], "#f39c12")]
    maxf = max([v for _, v, _ in stadi] + [1])
    funnel_html = "".join(
        f"<div style='display:flex;align-items:center;gap:10px;margin:4px 0'>"
        f"<div style='width:190px;text-align:right;color:#8899aa;font-size:.78rem'>{nome}</div>"
        f"<div style='background:{col};width:{max(6, int(v * 340 / maxf))}px;height:18px;"
        f"border-radius:4px;color:#fff;font-size:.72rem;display:flex;align-items:center;padding-left:6px'>{v}</div></div>"
        for nome, v, col in stadi)
    # LA FILA DELLE PR: ogni PR con il suo ultimo stato
    fila = s.get("pr_fila", {})
    if fila:
        COLORI_FILA = {"consegnata": "#0af", "in quarantena": "#f39c12",
                       "rinviata dal censore": "#f39c12", "APPROVATA": "#4ecca3", "RIGETTATA": "#e74c3c"}
        fila_html = "<br>".join(
            f"<b style='color:{COLORI_FILA.get(st, '#8899aa')}'>#{n}</b> — {st}"
            for n, st in sorted(fila.items(), key=lambda x: -int(x[0])))
        conta = {}
        for st in fila.values(): conta[st] = conta.get(st, 0) + 1
        fila_sommario = " · ".join(f"{v} {k}" for k, v in sorted(conta.items()))
    else:
        fila_html = "<i>nessuna PR oggi: la caccia non ha ancora consegnato</i>"
        fila_sommario = ""
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
    # IL VERDETTO + IL BATTITO
    vcol, vtit, vmot = verdetto(s)
    battito = s.get("battito_min")
    if battito is None:
        battito_html = "<span style='color:#e74c3c'>log muto</span>"
    elif battito > 15:
        battito_html = f"<span style='color:#e74c3c;font-weight:bold'>⏱ ultimo battito: {battito:.0f} min fa — GUARDA</span>"
    else:
        battito_html = f"<span style='color:#4ecca3'>⏱ ultimo battito: {battito:.0f} min fa</span>"
    gap_html = ""
    if s["gap_max"]:
        g, da, a = s["gap_max"]
        gap_html = f" · <span style='color:{'#f39c12' if g > 30 else '#556'}'>buco max oggi: {g:.0f} min ({da}→{a})</span>"
    return f'''<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="10">
<title>AI_Programmer — analisi</title><style>*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:-apple-system,sans-serif;background:#1a1a2e;color:#eee;padding:18px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:10px;margin:12px 0}}
.sec{{background:#16213e;border-radius:12px;padding:14px;margin-bottom:14px}}
h2{{font-size:.85rem;color:#0af;margin-bottom:8px}} .log{{font-family:Menlo,monospace;font-size:.72rem}}</style></head>
<body><h1 style="font-size:1.25rem;color:#0af">🤖 AI_Programmer — osservazione e analisi</h1>
<div style="font-size:.7rem;color:#556">aggiornato {s['now']} · refresh 10s · {battito_html}{gap_html}</div>
<div style="background:{vcol}22;border:2px solid {vcol};border-radius:12px;padding:12px 16px;margin:10px 0">
<div style="font-size:1.3rem;font-weight:bold;color:{vcol}">{vtit}</div>
<div style="font-size:.85rem;color:#ccc">{vmot}</div></div>
<div class="grid">
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#4ecca3' if s['attivo'] else '#e74c3c'}">{'🟢' if s['attivo'] else '🔴'}</div><div style="font-size:.7rem;color:#8899aa">TURNO</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:#0af">{s['cicli']}</div><div style="font-size:.7rem;color:#8899aa">CICLI OGGI</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#4ecca3' if s['pr'] else '#0af'}">{s['pr']}</div><div style="font-size:.7rem;color:#8899aa">PR OGGI</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#f39c12' if fila else '#8899aa'}">{len(fila)}</div><div style="font-size:.7rem;color:#8899aa">NELLA FILA</div></div>
<div style="background:#16213e;border-radius:12px;padding:12px;text-align:center"><div style="font-size:1.8rem;font-weight:bold;color:{'#e74c3c' if s['ollama_wedge'] else '#4ecca3'}">{s['ollama_wedge']}</div><div style="font-size:.7rem;color:#8899aa">WEDGE OGGI</div></div>
</div>
<div style="font-size:.8rem;color:#8899aa">{ollama}</div>
<div class="sec"><h2>① CONSEGNA? — il funnel di oggi</h2>
{funnel_html}
<div style="color:#f7e055;font-size:.78rem;margin-top:6px">▸ {lettura_funnel(F)}</div></div>
<div class="sec"><h2>② LA FILA DELLE PR — la pipeline del giorno</h2>
<div style="font-size:.75rem;color:#8899aa;margin-bottom:4px">{fila_sommario}</div>
<div style="font-size:.8rem">{fila_html}</div></div>
<div class="sec"><h2>③ COSA BLOCCA? — le cadute di oggi, con le righe vere</h2>{blocchi}</div>
<div class="sec"><h2>④ I DEBITI — censimento, trend e verdetto</h2>
<div style="font-size:.8rem;margin-bottom:6px">{cen_html}</div>
{barrette(s['censimento']['trend'])}{lettura_debiti(s['censimento'])}</div>
<div class="sec"><h2>⑤ IL CENSORE — deliberazioni e motivi</h2><div style="font-size:.75rem">{delib}</div></div>
<div class="sec"><h2>⑥ DRIFT DELLO STANDARD (per repo, oggi)</h2><div style="font-size:.75rem">{drift_html}</div></div>
<div class="sec"><h2>📅 Attività</h2><div class="log">{log}</div></div>
<div class="sec"><h2>🔍 Verifiche rosse (ciclo corrente)</h2>{ver}</div>
<p style="color:#556;font-size:.7rem">v5 · verdetto, fila PR, battito, letture calcolate · <a href=http://localhost:8787 style=color:#0af>ricarica</a></p></body></html>'''

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8"); self.end_headers()
        self.wfile.write(page(stats()).encode())
    def log_message(self, *a): pass

if __name__ == "__main__":
    # --stats: i numeri in JSON e fine (per i test e per chi legge da terminale).
    # (D19): il test lo invocava, la modalita' non esisteva, partiva il server e
    # il test restava appeso.
    import sys
    if "--stats" in sys.argv[1:]:
        print(json.dumps(stats(), ensure_ascii=False, default=str))
        sys.exit(0)
    port = 8787
    try: srv = http.server.HTTPServer(("localhost", port), H)
    except OSError:
        subprocess.run(["bash", "-c", f"lsof -ti :{port} | xargs kill 2>/dev/null"], capture_output=True)
        time.sleep(1)
        srv = http.server.HTTPServer(("localhost", port), H)
    print(f"Dashboard v5 su http://localhost:{port} (Ctrl+C per fermare)")
    srv.serve_forever()
