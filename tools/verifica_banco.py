#!/usr/bin/env python3
"""Verifica meccanica dell'uscita di un banco GAS — l'exit code non è un verdetto.

7° ciclo, set 3 (2026-08-24). Il corpus gas-agent di REPO-E insegna: «un codice
di uscita NON è un verdetto: crash e accusa escono entrambi con 1» e la riga
finale canonica è UNA: `attese eseguite: N/M · fallite: K` con M DICHIARATO in
cima al banco (se N < M il banco è rosso comunque, perché ne ha saltate). Fino
ad oggi il hub poteva eseguire i .night-verify ma non sapeva GIUDICARE un banco
GAS: questo tool chiude quel buco — il gate, la notte o un agente possono
verificare l'uscita di un banco senza rileggerne la prosa.

Controlli (ognuno da una lezione misurata del corpus):
1. la riga-verdetto canonica ESISTE e in UNA sola copia (misurato: sei
   vocabolari diversi sui 55 banchi del parco — «dire a qualcuno di cercare la
   riga e dargliene sei forme è mandarlo a cercare una cosa non descritta»);
2. N ≤ M (il banco non può eseguire più attese di quante ne dichiara);
3. N == M, altrimenti VERDE PARZIALE: «un banco che passa da otto a sei verdi
   non sembra rotto: sembra un banco più piccolo» — l'attesa mancante è un
   difetto, non un risparmio;
4. K (fallite) dichiara l'esito: 0 = banco VERDE, >0 = ROSSO con motivo;
5. se la riga manca ma l'output esiste: NON È UN BANCO — è un crash o una
   stampa («ALL TESTS COMPLETED è una frase, non un verdetto»).

Uso: python3 tools/verifica_banco.py <file-uscita-banco>
Stampa il verdetto e di quale cartella/parte ha giudicato (l'output integrale
sta nel file). Exit 0 verde · 1 rosso · 2 forma non riconosciuta.
"""
import re
import sys

RIGA_RE = re.compile(r"attese eseguite:\s*(\d+)\s*/\s*(\d+)\s*·\s*fallite:\s*(\d+)")


def main():
    """I cinque controlli del docstring, in ordine di severità: forma prima del
    contenuto (una riga-verdetto ambigua non è giudicabile), poi i conti."""
    if len(sys.argv) != 2:
        print("uso: verifica_banco.py <file-uscita-banco>", file=sys.stderr)
        return 2
    try:
        testo = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    except OSError as e:
        print(f"ERRORE: {e}", file=sys.stderr)
        return 2
    if not testo.strip():
        print(f"VERDETTO: USCITA VUOTA — il banco non ha stampato niente: non è partito, non è verde ({sys.argv[1]})")
        return 1
    matches = RIGA_RE.findall(testo)
    if len(matches) == 0:
        print(f"VERDETTO: NON È UN BANCO — nessuna riga-verdetto canonica 'attese eseguite: N/M · fallite: K' in {sys.argv[1]}")
        print("Un'uscita senza riga-verdetto è una stampa o un crash, non un esito (l'exit code non è un verdetto).")
        return 2
    if len(matches) > 1:
        print(f"VERDETTO: FORMA AMBIGUA — {len(matches)} righe-verdetto in {sys.argv[1]}: una sola, sempre quella")
        return 2
    n, m, k = (int(x) for x in matches[0])
    print(f"riga-verdetto: attese eseguite: {n}/{m} · fallite: {k}")
    if n > m:
        print(f"VERDETTO: FORMA ROTTA — eseguite {n} > dichiarate {m}: il conteggio non torna")
        return 2
    if n < m:
        print(f"VERDETTO: ROSSO (attese saltate) — eseguite {n} su {m} dichiarate: {m - n} attese sono SPARITE in silenzio")
        print("«un banco che passa da otto verdi a sei non sembra rotto: sembra un banco più piccolo» — le attese si contano, e il conto sta scritto.")
        return 1
    if k > 0:
        print(f"VERDETTO: ROSSO — {k} attese fallite su {m}: il difetto c'è (o la correzione non regge)")
        return 1
    print(f"VERDETTO: VERDE — {m} attese eseguite, 0 fallite. Il banco resta una prova solo se un sabotaggio l'ha visto cadere.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
