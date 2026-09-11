import urllib.request
import json

def get_json(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode())

res = get_json('https://parallelum.com.br/fipe/api/v1/carros/marcas/59/modelos')
for m in res['modelos']:
    if 'gol' in m['nome'].lower() and '1.0' in m['nome'].lower():
        print(f"ID: {m['codigo']} | Nome: {m['nome']}")
        anos = get_json(f"https://parallelum.com.br/fipe/api/v1/carros/marcas/59/modelos/{m['codigo']}/anos")
        for a in anos:
            if '2021' in a['nome']:
                preco = get_json(f"https://parallelum.com.br/fipe/api/v1/carros/marcas/59/modelos/{m['codigo']}/anos/{a['codigo']}")
                print(f"  -> {a['nome']} = {preco.get('Valor')} (Cód: {preco.get('CodigoFipe')})")
