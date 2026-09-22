import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// @ts-ignore
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    let { brand, model, year, version, fuel, engine, apontamentos, uf } = body

    if (!brand || !model || !year) {
      return new Response(JSON.stringify({ error: 'Marca, modelo e ano são obrigatórios.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Normalização básica
    brand = brand.toString().trim().toUpperCase()
    model = model.toString().trim().toUpperCase()
    year = parseInt(year, 10)
    version = version ? version.toString().trim().toUpperCase() : null
    fuel = fuel ? fuel.toString().trim().toUpperCase() : null
    engine = engine ? engine.toString().trim().toUpperCase() : null

    // @ts-ignore
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    // @ts-ignore
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(JSON.stringify({ error: 'Erro de configuração do servidor.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Buscar no banco se já existe ficha técnica geral (só busca cache se não houver apontamentos dinâmicos do laudo)
    const hasApontamentos = apontamentos && Array.isArray(apontamentos) && apontamentos.length > 0;
    
    if (!hasApontamentos) {
      let query = supabase
        .from('vehicle_ai_specs')
        .select('*')
        .eq('brand', brand)
        .eq('model', model)
        .eq('year', year)

      if (version) query = query.eq('version', version)
      else query = query.is('version', null)
      if (fuel) query = query.eq('fuel', fuel)
      else query = query.is('fuel', null)
      if (engine) query = query.eq('engine', engine)
      else query = query.is('engine', null)

      const { data: cachedData, error: cacheError } = await query.maybeSingle()

      if (cacheError) {
        console.error('Erro ao buscar cache:', cacheError)
      }

      if (cachedData && cachedData.data) {
        console.log('Retornando dados técnicos do cache para:', brand, model, year)
        return new Response(JSON.stringify({ source: 'cache', data: cachedData.data }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    let extraPrompt = '';
    let extraJsonSchema = ',\n"apontamentos_veiculo": []';
    const estadoLocal = uf ? `Considere o mercado do estado de(a) ${uf}, NO BRASIL, para estimativa de preços de peças e serviços.` : 'Considere o mercado médio brasileiro para estimativa de preços de peças e serviços.';
    
    if (hasApontamentos) {
      const apontamentosFormatados = apontamentos.map((a: any, idx: number) => {
        if (typeof a === 'object' && a !== null) {
          const id = a.apontamentoId || a.id || `apt_${idx}`;
          const peca = a.nomePeca || a.peca || a.item || 'Item apontado';
          const desc = a.descricaoProblema || a.motivoAvaria || a.observacao || '';
          return { apontamentoId: String(id), nomePeca: String(peca), descricaoProblema: String(desc) };
        }
        return { apontamentoId: `apt_${idx}`, nomePeca: String(a), descricaoProblema: String(a) };
      });

      extraPrompt = `\nAPONTAMENTOS DA VISTORIA REGISTRADOS PELO VISTORIADOR:
${apontamentosFormatados.map((it: any) => `- [ID: "${it.apontamentoId}"] Peça: "${it.nomePeca}" | Problema: "${it.descricaoProblema}"`).join('\n')}

REGRAS OBRIGATÓRIAS DE ORÇAMENTO DOS APONTAMENTOS (${estadoLocal}):
1. Para CADA apontamento listado acima, você deve retornar um objeto na lista "apontamentos_veiculo" com:
   - "apontamentoId": O mesmo ID recebido correspondente.
   - "nomePeca": Nome da peça danificada.
   - "descricaoProblema": Descrição do dano/defeito.
   - "valorEstimadoPeca": Número numérico (double) estimado para a peça de reposição (ex: 1200.00). Caso não requeira peça nova (ex: apenas repintura/martelinho), coloque 0.0.
   - "valorEstimadoMaoDeObra": Número numérico (double) estimado para a mão de obra/instalação/serviço (ex: 400.00).
2. ITENS SEM ACESSO / NÃO LOCALIZADO / NÃO VERIFICADO / PLAQUETA AUSENTE / DENTRO DO PADRÃO:
   - "valorEstimadoPeca": 0.0
   - "valorEstimadoMaoDeObra": 0.0
3. ITENS DE RETOQUE OU REPINTURA JÁ REALIZADOS ANTERIORMENTE NO VEÍCULO:
   - "valorEstimadoPeca": 0.0
   - "valorEstimadoMaoDeObra": 0.0
4. PROIBIÇÃO ABSOLUTA:
   - A IA NÃO deve calcular valor do veículo, valor FIPE nem sugerir valor de mercado.
   - A IA NÃO deve calcular depreciação nem percentual de depreciação nem valor final.
   - NÃO inclua campos como "valorVeiculo", "valorMercado", "valorFipe", "depreciacao", "percentualDepreciacao", "valorVeiculoDepreciado" ou "valorFinal".`;

      extraJsonSchema = `,\n"apontamentos_veiculo": [\n  {\n    "apontamentoId": "${apontamentosFormatados[0]?.apontamentoId || '123'}",\n    "nomePeca": "${apontamentosFormatados[0]?.nomePeca || 'Para-choque'}",\n    "descricaoProblema": "Descrição do dano",\n    "valorEstimadoPeca": 1200.00,\n    "valorEstimadoMaoDeObra": 400.00\n  }\n]`;
    }

    // ── MODO RÁPIDO: Orçamento de Avarias com IA ─────────────────────────────
    const apenasAvarias = body.apenasAvarias === true || body.modo === 'orcamento_avarias';
    if (apenasAvarias) {
      if (!hasApontamentos) {
        return new Response(JSON.stringify({ source: 'empty', data: { apontamentos_veiculo: [] } }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const promptAvarias = `Você é um Perito Automotivo e Avaliador Técnico Sênior no Brasil.
Seu objetivo é orçar exclusivamente os custos médios de mercado de peças de reposição e mão de obra de reparo/funilaria para as avarias listadas de um veículo vistoriado.
Retorne EXCLUSIVAMENTE um JSON válido no formato:
{
  "apontamentos_veiculo": [
    {
      "apontamentoId": "string (o mesmo ID recebido)",
      "nomePeca": "string",
      "descricaoProblema": "string",
      "valorEstimadoPeca": 0.00,
      "valorEstimadoMaoDeObra": 0.00
    }
  ]
}

Veículo: ${brand} ${model} ${year} ${version || ''} (${engine || ''})
${extraPrompt}`;

      // @ts-ignore
      const openAiKey = Deno.env.get('OPENAI_API_KEY');
      let parsedAvariasJson: any = null;
      let sourceAvarias = '';

      if (openAiKey) {
        try {
          const resp = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${openAiKey}`,
            },
            body: JSON.stringify({
              model: 'gpt-4o-mini',
              response_format: { type: 'json_object' },
              messages: [
                { role: 'system', content: 'Você é um perito avaliador automotivo brasileiro. Retorne exclusivamente JSON válido de acordo com o esquema solicitado.' },
                { role: 'user', content: promptAvarias }
              ],
              temperature: 0.2,
            }),
          });
          if (resp.ok) {
            const resData = await resp.json();
            const content = resData.choices?.[0]?.message?.content;
            if (content) {
              parsedAvariasJson = JSON.parse(content);
              sourceAvarias = 'openai-gpt-4o-mini';
            }
          }
        } catch (e: any) {
          console.error('Erro OpenAI em apenasAvarias:', e.message);
        }
      }

      if (!parsedAvariasJson) {
        // @ts-ignore
        const geminiKey = Deno.env.get('GEMINI_API_KEY');
        if (geminiKey) {
          try {
            const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiKey}`;
            const gResp = await fetch(geminiUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ contents: [{ parts: [{ text: promptAvarias }] }] }),
            });
            if (gResp.ok) {
              const gData = await gResp.json();
              const text = gData.candidates?.[0]?.content?.parts?.[0]?.text;
              if (text) {
                const clean = text.replace(/```json/gi, '').replace(/```/g, '').trim();
                parsedAvariasJson = JSON.parse(clean);
                sourceAvarias = 'gemini-1.5-flash';
              }
            }
          } catch (e: any) {
            console.error('Erro Gemini em apenasAvarias:', e.message);
          }
        }
      }

      if (parsedAvariasJson) {
        return new Response(JSON.stringify({ source: sourceAvarias, data: parsedAvariasJson }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    const prompt = `Você é um Perito Automotivo e Avaliador Técnico Sênior no Brasil.
Seu objetivo é gerar uma FICHA TÉCNICA INTELIGENTE DO VEÍCULO profissional, elegante, estritamente neutra e puramente informativa (sem juízo de valor "caro/barato", "bom/ruim").
Retorne APENAS JSON válido, sem markdown, sem texto fora do JSON.${extraPrompt}

Veículo:
Marca: ${brand}
Modelo: ${model}
Ano: ${year}
Versão: ${version || 'Padrão'}
Combustível: ${fuel || 'Flex'}
Motor: ${engine || 'Padrão'}

O JSON retornado deve seguir RIGOROSAMENTE esta estrutura:
{
"identificacao": {
  "marca": "${brand}",
  "modelo": "${model}",
  "ano": "${year}",
  "versao": "${version || ''}",
  "combustivel": "${fuel || ''}",
  "motor": "${engine || ''}"
},
"resumo_inteligente": "Texto conciso, neutro e institucional (1 parágrafo de 3 a 5 linhas). Exemplo: O [Marca Modelo Versão] reúne características voltadas ao uso cotidiano, com conjunto mecânico amplamente conhecido no mercado nacional. Nesta ficha estão reunidas suas principais especificações técnicas, insumos recomendados e componentes de manutenção, proporcionando uma visão rápida e organizada das principais informações do modelo.",
"informacoes_uteis": {
  "combustivel": "Flex",
  "categoria": "Hatch compacto (ou Sedan, SUV, etc)",
  "ocupantes": "5 lugares",
  "tracao": "Dianteira",
  "cambio": "Manual de 5 marchas (ou Automático)",
  "capacidade_porta_malas": "285 litros",
  "capacidade_tanque": "50 litros"
},
"especificacoes_tecnicas": [
  {"item": "Potência", "informacao": "75 cv"},
  {"item": "Torque", "informacao": "9,7 kgfm"},
  {"item": "Câmbio", "informacao": "Manual de 5 marchas"},
  {"item": "Tração", "informacao": "Dianteira"},
  {"item": "Direção", "informacao": "Hidráulica"},
  {"item": "Suspensão dianteira", "informacao": "Independente tipo McPherson"},
  {"item": "Suspensão traseira", "informacao": "Eixo de torção"},
  {"item": "Freios", "informacao": "Disco ventilado dianteiro / tambor traseiro"},
  {"item": "Pneus originais", "informacao": "175/70 R14"},
  {"item": "Tanque", "informacao": "50 litros"},
  {"item": "Porta-malas", "informacao": "285 litros"}
],
"manutencao_recomendada": [
  {"item": "Óleo recomendado", "especificacao": "5W30 (conforme manual)"},
  {"item": "Capacidade de óleo", "especificacao": "3,5 litros com filtro"},
  {"item": "Fluido de arrefecimento", "especificacao": "Aditivo orgânico + água desmineralizada"},
  {"item": "Fluido de freio", "especificacao": "DOT 4"},
  {"item": "Velas", "especificacao": "NGK BKR6E ou equivalente"},
  {"item": "Sistema de distribuição", "especificacao": "Correia dentada (ou Corrente)"},
  {"item": "Bateria", "especificacao": "12V — especificação compatível com o modelo"}
],
"principais_pecas_manutencao": [
  {"componente": "Pastilhas de freio", "valor_peca": "R$ 150,00", "valor_mao_de_obra": "R$ 100,00", "estimativa_total": "R$ 250,00"},
  {"componente": "Filtro de ar", "valor_peca": "R$ 50,00", "valor_mao_de_obra": "R$ 50,00", "estimativa_total": "R$ 100,00"},
  {"componente": "Jogo de velas", "valor_peca": "R$ 140,00", "valor_mao_de_obra": "R$ 100,00", "estimativa_total": "R$ 240,00"},
  {"componente": "Kit correia dentada", "valor_peca": "R$ 180,00", "valor_mao_de_obra": "R$ 250,00", "estimativa_total": "R$ 430,00"},
  {"componente": "Disco de freio", "valor_peca": "R$ 280,00", "valor_mao_de_obra": "R$ 150,00", "estimativa_total": "R$ 430,00"},
  {"componente": "Kit embreagem", "valor_peca": "R$ 650,00", "valor_mao_de_obra": "R$ 450,00", "estimativa_total": "R$ 1.100,00"}
]${extraJsonSchema},
"observacao_importante": "Ficha Inteligente: As informações técnicas, especificações e insumos apresentados possuem caráter informativo e complementar ao laudo cautelar. Valores podem variar conforme região, fornecedor e condições de mercado. As informações não indicam, por si só, necessidade de manutenção ou substituição dos componentes do veículo vistoriado."
}`

    let parsedJson: any = null
    let sourceUsed = ''

    // ── 1. Tentar gerar com OpenAI (gpt-4o-mini ou gpt-4o) ────────────────────
    // @ts-ignore
    const openAiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (openAiApiKey) {
      console.log('Gerando ficha técnica com OpenAI gpt-4o-mini para:', brand, model, year)
      try {
        const openAiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${openAiApiKey}`,
          },
          body: JSON.stringify({
            model: 'gpt-4o-mini',
            response_format: { type: 'json_object' },
            messages: [
              {
                role: 'system',
                content: 'Você é um especialista técnico automotivo e perito veicular brasileiro. Retorne exclusivamente JSON válido de acordo com o esquema solicitado.'
              },
              {
                role: 'user',
                content: prompt
              }
            ],
            temperature: 0.2,
          })
        })

        if (openAiResponse.ok) {
          const openAiData = await openAiResponse.json()
          const rawContent = openAiData.choices?.[0]?.message?.content
          if (rawContent) {
            parsedJson = JSON.parse(rawContent)
            sourceUsed = 'openai-gpt-4o-mini'
            console.log('Ficha técnica gerada com sucesso via OpenAI!')
          }
        } else {
          const errText = await openAiResponse.text()
          console.error('Erro na chamada OpenAI:', errText)
        }
      } catch (openAiErr: any) {
        console.error('Exceção ao chamar OpenAI:', openAiErr.message)
      }
    }

    // ── 2. Fallback para Gemini se OpenAI não gerou ────────────────────────────
    if (!parsedJson) {
      // @ts-ignore
      const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
      if (geminiApiKey) {
        console.log('Tentando fallback com Gemini para:', brand, model, year)
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`

        const geminiResponse = await fetch(geminiUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            contents: [{
              parts: [{ text: prompt }]
            }]
          })
        })

        if (geminiResponse.ok) {
          const geminiData = await geminiResponse.json()
          let textResult = geminiData.candidates?.[0]?.content?.parts?.[0]?.text
          if (textResult) {
            textResult = textResult.trim()
            if (textResult.startsWith('```json')) {
              textResult = textResult.replace(/^```json/, '').replace(/```$/, '').trim()
            } else if (textResult.startsWith('```')) {
              textResult = textResult.replace(/^```/, '').replace(/```$/, '').trim()
            }
            parsedJson = JSON.parse(textResult)
            sourceUsed = 'gemini-1.5-flash'
            console.log('Ficha técnica gerada com sucesso via Gemini!')
          }
        } else {
          const errorText = await geminiResponse.text()
          console.error('Erro na API Gemini:', errorText)
        }
      }
    }

    if (!parsedJson) {
      return new Response(JSON.stringify({ error: 'Falha ao gerar relatório inteligente nas APIs de IA.' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Salvar no Supabase apenas se não tiver apontamentos (para não cachear defeitos específicos de 1 carro para todo o modelo)
    if (!hasApontamentos) {
      const { error: insertError } = await supabase
        .from('vehicle_ai_specs')
        .insert({
          brand,
          model,
          year,
          version,
          fuel,
          engine,
          data: parsedJson
        })

      if (insertError) {
        console.error('Erro ao salvar cache:', insertError)
      }
    }

    return new Response(JSON.stringify({ source: sourceUsed, data: parsedJson }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Erro interno:', error)
    return new Response(JSON.stringify({ error: 'Erro interno no servidor' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
