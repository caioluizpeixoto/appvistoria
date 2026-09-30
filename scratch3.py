import re

with open(r'c:\Users\Caio\Desktop\app_vistoria\supabase\functions\gerar-ficha-veiculo\prompt.ts', 'r', encoding='utf-8') as f:
    content = f.read()

new_content = content.replace(
    '''  "secao5_ficha_tecnica": {
    "identificacao": { "marca": "${brand}", "modelo": "${model}", "versao": "${version}", "ano": "${year}", "categoria": "...", "carroceria": "..." },
    "motorizacao": { "tipo_motor": "...", "cilindrada": "...", "cilindros": "...", "valvulas": "...", "potencia": "...", "torque": "...", "combustivel": "..." },
    "transmissao_tracao": { "cambio": "...", "marchas": "...", "tracao": "..." },
    "dimensoes_capacidades": { "comprimento": "...", "porta_malas": "...", "tanque": "...", "peso": "..." },
    "suspensao_freios": { "suspensao_dianteira": "...", "suspensao_traseira": "...", "freios": "..." },
    "rodas_pneus": { "medida_pneus": "..." },
    "equipamentos": { "principais_itens": ["..."] }
  },
  "secao6_desempenho_consumo": {
    "indicadores": [
      { "indicador": "0 a 100 km/h", "valor": "...", "explicacao": "..." },
      { "indicador": "Consumo Urbano", "valor": "...", "explicacao": "..." }
    ]
  },''',
    '''  "secao5_ficha_tecnica": {
    "motorizacao": { "motor": "...", "cilindrada": "...", "alimentacao": "...", "potencia": "...", "torque": "...", "combustivel": "...", "aspiracao": "..." },
    "transmissao": { "cambio": "...", "marchas": "...", "tracao": "..." },
    "dimensoes": { "comprimento": "...", "largura": "...", "altura": "...", "entre_eixos": "...", "porta_malas": "...", "tanque": "...", "peso": "..." }
  },
  "secao6_desempenho_consumo": {
    "desempenho": { "potencia": "...", "torque": "...", "zero_cem": "...", "velocidade_maxima": "..." },
    "consumo": { 
      "cidade_gasolina": "...", "cidade_etanol": "...", 
      "estrada_gasolina": "...", "estrada_etanol": "..." 
    }
  },'''
)

with open(r'c:\Users\Caio\Desktop\app_vistoria\supabase\functions\gerar-ficha-veiculo\prompt.ts', 'w', encoding='utf-8') as f:
    f.write(new_content)
