export const buildPrompt = (brand: string, model: string, year: string, version: string, fuel: string, engine: string, extraPrompt: string, extraJsonSchema: string) => {
return `Você é um Perito Automotivo e Avaliador Técnico Sênior no Brasil.
Seu objetivo é gerar uma ANÁLISE ULTRA (Análise Inteligente e Técnica) do veículo, estritamente profissional e personalizada para a combinação exata deste modelo, ano e versão.

A ANÁLISE ULTRA deve funcionar como um consultor automotivo especializado.
- Explicar os pontos positivos, características mecânicas, desempenho, manutenção e pontos de atenção.
- Não invente dados; se um dado não existir, omita-o.
- Retorne EXCLUSIVAMENTE JSON válido.
${extraPrompt}

Veículo Consultado:
Marca: ${brand}
Modelo: ${model}
Ano: ${year}
Versão: ${version || 'Padrão'}
Combustível: ${fuel || 'Flex'}
Motor: ${engine || 'Padrão'}

O JSON retornado deve seguir RIGOROSAMENTE esta estrutura completa:
{
  "secao1_visao_geral": {
    "resumo_apresentacao": "Texto descritivo de apresentação profissional do modelo.",
    "perfil_utilizacao": "Para qual perfil de uso o veículo é mais adequado.",
    "principais_diferenciais": "O que destaca esse carro no mercado."
  },
  "secao2_pontos_positivos": [
    { "titulo": "Título curto", "descricao": "Explicação técnica da vantagem." }
  ],
  "secao3_pontos_atencao": [
    {
      "componente": "Nome do componente (ex: Câmbio Automático AL4)",
      "motivo": "Por que merece atenção",
      "sinais": "Quais sinais indicam desgaste/problema",
      "verificacao": "Como verificar antes da compra",
      "consequencia_financeira": "Qual o custo estimado se negligenciado",
      "nivel_impacto": "Baixo, Médio ou Alto"
    }
  ],
  "secao4_destaques": [
    { "categoria": "Ex: Segurança", "descricao": "Descrição curta do destaque" }
  ],
  "secao5_ficha_tecnica": {
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
  },
  "secao7_manutencao_custos": {
    "fluidos": [
      { "item": "Óleo do Motor", "especificacao": "ex: 5W30", "capacidade": "ex: 3.5 L", "intervalo_troca": "10.000 km ou 1 ano" }
    ],
    "intervalos_previstos": ["10.000 km", "20.000 km"],
    "custos_estimados": [
      { "item": "Kit Amortecedores Dianteiros", "faixa_custo": "R$ 800 a R$ 1200" }
    ]
  },
  "secao8_seguranca": {
    "recursos": ["ABS", "Airbags frontais", "..."],
    "testes_seguranca": "Resultados Euro NCAP/Latin NCAP se houver"
  },
  "secao9_mercado": {
    "posicionamento": "...",
    "procura_revenda": "...",
    "desvalorizacao": "..."
  },
  "secao10_analise_comprador": {
    "conclusao_especialista": "...",
    "fatores_decisao": ["..."]
  },
  "secao11_resumo_executivo": {
    "destaque_principal": "...",
    "vantagens": "...",
    "atencao": "...",
    "perfil_ideal": "..."
  }${extraJsonSchema}
}`;
}
