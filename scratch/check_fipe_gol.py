import urllib.request
import json

def get_json(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode())

try:
    res = get_json('https://parallelum.com.br/fipe/api/v1/carros/marcas/59/modelos')
    modelos = res['modelos']
    gols = [m for m in modelos if 'gol' in m['nome'].lower()]

    print('--- Modelos Gol com ano 2021 ---')
    for g in gols:
        anos_res = get_json(f"https://parallelum.com.br/fipe/api/v1/carros/marcas/59/modelos/{g['codigo']}/anos")
        ano_2021 = [a for a in anos_res if '2021' in a['nome']]
        if ano_2021:
            preco_res = get_json(f"https://parallelum.com.br/fipe/api/v1/carros/marcas/59/modelos/{g['codigo']}/anos/{ano_2021[0]['codigo']}")
            print(f"{g['nome']} | 2021: {preco_res.get('Valor')} | Cod: {preco_res.get('CodigoFipe')}")
except Exception as e:
    print('Erro:', e)
