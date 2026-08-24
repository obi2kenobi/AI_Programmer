#!/usr/bin/env python3
"""Censimento qualità di un progetto Google Apps Script — le famiglie misurate del parco, meccanicamente.

7° ciclo, set 1 (2026-08-24). Porta nel tooling la lezione del corpus gas-agent
di REPO-E: le famiglie di difetti con POPOLAZIONI misurate. Questo rilevatore è
un AUSILIO AL CENSIMENTO, non un verdetto — la regola del corpus vale anche per
lui: «la colonna della pagella NON è il numero dei difetti: sbaglia di 4,4
volte» e «una popolazione sopra soglia non basta: serve una domanda
discriminante». Ogni famiglia qui porta la sua domanda, ed è quello che il
reporter deve rispondere aprendo i casi — non la forma.

Uso: python3 tools/gas_qualita.py <cartella-progetto>
Accetta .js e .gs (lezione del banco: 11 su 16 filtravano solo .js).
NON stampa MAI valori di segreti: solo file:riga e il tipo (regola del mandato).
Byte NUL: i file vengono aperti in UTF-8 con errors='replace' (grep salterebbe
l'intero file — famiglia misurata: 2 file su 1098, i più grandi del parco).
"""
import json
import os
import re
import sys

FUN_RE = re.compile(r"^\s*(?:function\s+([A-Za-z_$][\w$]*)|(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:function|\())", re.M)


def leggi_file(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""


def function_bodies(testo):
    """Nome → corpo normalizzato (brace matching approssimato per funzioni top-level)."""
    out = {}
    for m in FUN_RE.finditer(testo):
        nome = m.group(1) or m.group(2)
        aperta = testo.find("{", m.end())
        if aperta < 0:
            continue
        prof = 0
        for i in range(aperta, len(testo)):
            if testo[i] == "{":
                prof += 1
            elif testo[i] == "}":
                prof -= 1
                if prof == 0:
                    corpo = re.sub(r"\s+", " ", testo[aperta:i]).strip()
                    out[nome] = corpo[:400]
                    break
    return out


def riga_di(testo, idx):
    return testo.count("\n", 0, idx) + 1


def main():
    if len(sys.argv) != 2:
        print("uso: gas_qualita.py <cartella-progetto>", file=sys.stderr)
        return 1
    cartella = sys.argv[1]
    if not os.path.isdir(cartella):
        print(f"ERRORE: {cartella} non è una cartella", file=sys.stderr)
        return 1
    print(f"Cartella letta: {os.path.abspath(cartella)}")

    files = sorted(f for f in os.listdir(cartella)
                   if f.endswith((".js", ".gs")) and not f.startswith("."))
    testi = {f: leggi_file(os.path.join(cartella, f)) for f in files}
    print(f"File considerati: {len(files)} (.js e .gs)")

    famiglie = []

    # 1. test finti: funzioni test* senza throw né assert nel corpo
    siti = []
    for f, t in testi.items():
        for nome, corpo in function_bodies(t).items():
            if re.match(r"^_?[Tt][Ee][Ss][Tt]", nome) and "throw" not in corpo and "assert" not in corpo.lower():
                siti.append(f"{f}:{nome}")
    famiglie.append(("test che non possono fallire",
                     "quale di questi deve diventare un banco? (370 su 625 nel parco confrontano già qualcosa: manca la riga che rende visibile una differenza)",
                     siti))

    # 2. nomi globali in ombra: stesso nome definito in più file (IDENT vs DIVERGENT)
    per_nome = {}
    for f, t in testi.items():
        for nome, corpo in function_bodies(t).items():
            per_nome.setdefault(nome, []).append((f, corpo))
    siti = []
    for nome, defs in sorted(per_nome.items()):
        if len(defs) > 1:
            corpi = {c for _, c in defs}
            tipo = "DIVERGENTI" if len(corpi) > 1 else "identici (innocui)"
            siti.append(f"{nome} in {len(defs)} file [{tipo}]: " + ", ".join(sorted(f for f, _ in defs)))
    famiglie.append(("nomi globali in ombra",
                     "DIVERGENTI: quale dei due corpi gira? (vince l'ordine di caricamento — il sintomo è un totale a zero senza eccezione)",
                     siti))

    # 3. segreti hardcoded (mai il valore): pattern di chiave notevoli
    SECRET_PATTERNS = [r"sk_live_[A-Za-z0-9]{10,}", r"AKIA[0-9A-Z]{12,}", r"AIza[0-9A-Za-z_\-]{20,}",
                       r"ghp_[A-Za-z0-9]{20,}", r"-----BEGIN [A-Z ]*PRIVATE KEY-----"]
    siti = []
    for f, t in testi.items():
        for pat in SECRET_PATTERNS:
            for m in re.finditer(pat, t):
                siti.append(f"{f}:{riga_di(t, m.start())} [{pat.split('[')[0][:12]}…] (valore non riportato)")
    famiglie.append(("segreti hardcoded (valore MAI riportato)",
                     "da spostare in Script Properties come parte del fix — e non si propone MAI di ruotare la credenziale",
                     siti))

    # 4. fuso come offset fisso
    siti = []
    for f, t in testi.items():
        for m in re.finditer(r"formatDate\([^)]*['\"]GMT[+-]\d", t):
            siti.append(f"{f}:{riga_di(t, m.start())}")
    famiglie.append(("fuso come offset fisso 'GMT+N'",
                     "è sbagliato più di metà anno (Roma è GMT+2 da fine marzo a fine ottobre): va 'Europe/Rome'",
                     siti))

    # 5. paginazione chiusa sull'indizio
    siti = []
    for f, t in testi.items():
        for m in re.finditer(r"if\s*\(\s*!?\w*\.?value\b[^)]{0,40}\)\s*(break|return)", t):
            siti.append(f"{f}:{riga_di(t, m.start())}")
    famiglie.append(("paginazione chiusa sull'indizio (!response.value → break)",
                     "un 200 con errore OData nel corpo restituisce [] indistinguibile da uno scarico completo: la forma che regge è if(!Array.isArray(value)) throw col denominatore",
                     siti))

    # 6. clear-poi-scrivi nella stessa funzione
    siti = []
    for f, t in testi.items():
        for nome, corpo in function_bodies(t).items():
            if "clearContents()" in corpo and "setValues(" in corpo:
                siti.append(f"{f}:{nome}")
    famiglie.append(("clearContents + setValues nella stessa funzione",
                     "il lock protegge dalla concorrenza, non dall'interruzione a metà: la cura è UNA setValues sola (intestazione+dati+residuo letto prima)",
                     siti))

    # 7. catch muto
    siti = []
    for f, t in testi.items():
        for m in re.finditer(r"catch\s*\([^)]*\)\s*\{\s*\}", t):
            siti.append(f"{f}:{riga_di(t, m.start())}")
    famiglie.append(("catch vuoto (muto)",
                     "non nasconde l'errore: lo trasforma in un dato — cosa produce questa funzione quando il ramo muore?",
                     siti))

    # 8. webapp anonima (manifest) — con il caveat del deployment
    siti = []
    manifest = os.path.join(cartella, "appsscript.json")
    if os.path.isfile(manifest):
        try:
            wf = json.load(open(manifest, encoding="utf-8")).get("webapp", {})
            if wf.get("access") == "ANYONE_ANONYMOUS":
                siti.append("appsscript.json (manifest — ma l'accesso VERO sta nel deployment, non nel manifest)")
        except json.JSONDecodeError:
            siti.append("appsscript.json non interpretabile")
    famiglie.append(("webapp anonima nel manifest",
                     "il manifest è il default dei NUOVI deployment: l'accesso vero si verifica in Distribuisci→Gestisci distribuzioni; e OGNI funzione globale è un endpoint (google.script.run)",
                     siti))

    # 9. atHour duplicati (fascia, non orario)
    ore = {}
    for f, t in testi.items():
        for m in re.finditer(r"atHour\((\d+)\)", t):
            ore.setdefault(m.group(1), []).append(f"{f}:{riga_di(t, m.start())}")
    siti = [f"atHour({h}) in {len(v)} trigger: " + ", ".join(v) for h, v in sorted(ore.items()) if len(v) > 1]
    famiglie.append(("più trigger sulla stessa atHour",
                     "atHour(N) è una FASCIA di un'ora, non un orario: girano insieme senza ordine garantito (i JSDoc che dicono '05:30' sono la riga che fa credere il contrario)",
                     siti))

    totale_siti = 0
    for nome, domanda, siti in famiglie:
        totale_siti += len(siti)
        print(f"\n## {nome} — {len(siti)}")
        print(f"   domanda: {domanda}")
        for s in siti[:8]:
            print(f"   - {s}")
        if len(siti) > 8:
            print(f"   … e altri {len(siti) - 8}")
    print(f"\nfamiglie sopra zero: {sum(1 for _, _, s in famiglie if s)} su {len(famiglie)} · siti totali: {totale_siti}")
    print("QUESTO NON È UN VERDETTO: è il punto di partenza del censimento — ogni sito va aperto con la sua domanda.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
