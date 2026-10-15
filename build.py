"""Reconstruye index.html a partir de la página del artefacto y los datos.

Uso: python build.py page.html snapshot.json
- page.html: HTML completo del artefacto «Círculo de Competencia» (tal cual).
- snapshot.json: {"asOf", "companies", "analyses"} exportado de su base de datos.
La lista de cotizadas se toma de data/universe.json. Todo se incrusta en un único
index.html que funciona sin servidor ni sesión.
"""
import json, sys, pathlib

root = pathlib.Path(__file__).resolve().parent
page = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
snap = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
uni = json.loads((root / "data" / "universe.json").read_text(encoding="utf-8"))
assert len(snap["companies"]) >= 100 and len(snap["analyses"]) >= 100, "snapshot incompleto"

def embed(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c")

REPS = [
    ('const r = await fetch("universe.json"); const j = await r.json();',
     'const j = JSON.parse(document.getElementById("data-universe").textContent);'),
    ('fetch("snapshot.json").then(r => r.json()).then(j => {',
     'Promise.resolve().then(() => JSON.parse(document.getElementById("data-snapshot").textContent)).then(j => {'),
    ('; se refrescan tres veces cada día laborable (hacia las 9:40, 18:40 y 23:40, hora de Madrid)',
     '; se refrescan tres veces cada día laborable'),
    ('<title>Círculo de Competencia</title>', '<title>Círculo de Competencia · ARSE Socios</title>'),
]
for old, new in REPS:
    if old not in page:
        sys.exit(f"No encontrado en la página: {old[:60]}")
    page = page.replace(old, new)

anchor = "\n<script>\n(() => {"
page = page.replace("\r\n", "\n")
if anchor not in page:
    sys.exit("No se encontró el script principal")
data = (f'\n<script type="application/json" id="data-universe">{embed(uni)}</script>'
        f'\n<script type="application/json" id="data-snapshot">{embed(snap)}</script>')
page = page.replace(anchor, data + anchor, 1)
(root / "index.html").write_text(page, encoding="utf-8", newline="\n")
print(f"index.html: {len(snap['companies'])} empresas, asOf {snap.get('asOf')}")
