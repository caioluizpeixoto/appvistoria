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

    // Buscar no banco se já existe ficha (só busca cache se não houver apontamentos dinâmicos do vistoriador)
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
        console.log('Retornando dados do cache para:', brand, model, year)
        return new Response(JSON.stringify({ source: 'cache', data: cachedData.data }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    let extraPrompt = '';
    let extraJsonSchema = '';
    const estadoLocal = uf ? `Considere o mercado do estado de(a) ${uf}, NO BRASIL, para estimativa de preços.` : 'Considere o mercado médio brasileiro para estimativa de preços.';
    
    if (hasApontamentos) {
      extraPrompt = `\nIMPORTANTE: O vistoriador registrou os seguintes apontamentos neste veículo durante a vistoria:\n${apontamentos.map((a: string) => '- ' + a).join('\n')}

REGRAS CRÍTICAS DE TRATAMENTO DOS APONTAMENTOS:
1. ITENS MARCADOS COMO "SEM ACESSO", "SEMA ACESSO", "NÃO LOCALIZADO", "PLAQUETA AUSENTE", "AUSENTE" OU "NÃO FOI POSSÍVEL VERIFICAR":
   - Estes itens NÃO SÃO AVARIAS, DEFEITOS NEM SERVIÇOS A FAZER. Indicam apenas impossibilidade física de visualização/acesso ou ausência da plaqueta de identificação (ex: plaqueta de câmbio ausente, gravação oculta, longarina coberta/sem visibilidade).
   - Estar com "plaqueta ausente" NÃO significa câmbio quebrado, irregular ou com defeito mecânico. NUNCA gere troca, reparo ou manutenção por conta de plaqueta ausente.
   - Para estes itens de "SEM ACESSO" ou "PLAQUETA AUSENTE", você DEVE OBRIGATORIAMENTE preencher:
     * "valor_peca_estimado": "R$ 0,00"
     * "valor_mao_de_obra_estimado": "R$ 0,00"
     * "observacao_indicada": "Item sem avaria mecânica/funcional nem defeito pendente (não gera custo de reparo nem serviço a fazer)".
   - NUNCA atribua valor de mão de obra ou valor de peça a um item que está apenas "SEM ACESSO" ou "PLAQUETA AUSENTE".
   - NUNCA inclua o custo destes itens no cálculo do "desconto_total_avarias" nem trate como problema no resumo do estado do veículo.

2. ITENS DE REPINTURA, RETOQUE OU PINTURA JÁ EXECUTADA (ex: repintura, repintado, retoque, micropintura, pintura não original):
   - A repintura é um SERVIÇO DE MANUTENÇÃO ESTÉTICA JÁ REALIZADO no veículo, e NÃO um defeito ou avaria pendente de conserto.
   - Apenas seria uma avaria/problema se o apontamento descrever expressamente danos físicos abertos (ex: risco profundo, amassado, trinca, peça quebrada, massa plástica descascando/trincada, oxidação/ferrugem).
   - Se for apenas a indicação de peça repintada/retoque sem dano aberto relatado:
     * "valor_peca_estimado": "R$ 0,00"
     * "valor_mao_de_obra_estimado": "R$ 0,00"
     * "observacao_indicada": "Serviço estético de repintura já realizado / estética conservada (não é defeito pendente e não gera custo de reparo)".
   - NUNCA atribua valor de peça/mão de obra e NUNCA deduza do "desconto_total_avarias" para peças que apenas foram repintadas no passado.
   - No "resumo_estado_veiculo", trate a repintura apenas como histórico de manutenção estética/conservação, NUNCA como defeito, avaria ou problema depreciativo.

3. ITENS COM AVARIAS REAIS OU DEFEITOS PENDENTES (ex: amassado, risco profundo, trincado, quebrado, corroído/ferrugem, rasgado, vazamento, peça com avaria):
   - Estime o valor da peça de reposição (nova ou paralela) e o custo de mão de obra para reparar ou substituir.
   - REGRA PARA AVARIAS ESTRUTURAIS: Assuma sempre que o reparo é uma troca simples de componente ou serviço pontual. Nunca orce reconstruções ou reparos estruturais complexos de alto custo se for item simples.

Inclua as estimativas no JSON de retorno sob a chave "apontamentos_veiculo". ${estadoLocal} TODOS OS VALORES DEVERÃO SER EM REAIS (R$).`;
      extraJsonSchema = `,\n"apontamentos_veiculo": [\n{\n"peca_ou_problema": "",\n"local_no_veiculo": "",\n"observacao_indicada": "",\n"valor_peca_estimado": "",\n"valor_mao_de_obra_estimado": ""\n}\n]`;
    }
    
    // Sempre adicionar a análise final
    extraPrompt += `\nAlém disso, faça uma análise final da vistoria com ALTO NÍVEL DE DETALHAMENTO (nível laudo premium):
- "resumo_estado_veiculo": Forneça um parágrafo robusto e extremamente profissional resumindo o impacto geral dos apontamentos no veículo (seja positivo ou negativo).
- "justificativa": Escreva pelo menos dois parágrafos detalhando a composição do preço sugerido, a depreciação calculada e a atratividade do modelo no mercado de usados.
Apresente o valor médio de venda desse carro no mercado local (${estadoLocal}), calcule um desconto baseado APENAS nas avarias reais informadas (desconsiderando itens sem acesso) e sugira o valor de venda final. ATENÇÃO: TODOS OS VALORES FINANCEIROS NO JSON PRECISAM ESTAR EXCLUSIVAMENTE EM REAIS (R$). É PROIBIDO USAR DÓLARES OU FAZER REFERÊNCIA AOS ESTADOS UNIDOS.`;
    
    extraJsonSchema += `,\n"analise_final": {\n"resumo_estado_veiculo": "",\n"valor_venda_mercado_local": "",\n"desconto_total_avarias": "",\n"valor_venda_sugerido_final": "",\n"justificativa": ""\n}`;

    const prompt = `Você é um Perito Automotivo MASTER e Avaliador de Mercado Sênior no Brasil. Seu objetivo é criar um relatório/ficha técnica EXTREMAMENTE RICO EM DETALHES, com dados técnicos avançados, problemas crônicos reais bem descritos e valores de peças/mão de obra realistas. Retorne APENAS JSON válido, sem markdown, sem texto fora do JSON. Evite textos genéricos, aprofunde-se nos defeitos conhecidos do motor/câmbio desta versão. OBRIGATÓRIO: TODOS OS PREÇOS E AVALIAÇÕES DEVEM SER EM MOEDA BRASILEIRA (BRL) FORMATADOS COMO "R$ X.XXX,XX". NUNCA USE USD NEM REALIZE AVALIAÇÕES DO MERCADO AMERICANO.${extraPrompt}

Veículo:
Marca: ${brand}
Modelo: ${model}
Ano: ${year}
Versão: ${version || 'Não informada'}
Combustível: ${fuel || 'Não informado'}
Motor: ${engine || 'Não informado'}

O JSON retornado deve seguir rigorosamente esta estrutura:
{
"identificacao": {
"marca": "",
"modelo": "",
"ano": "",
"versao": "",
"combustivel": "",
"motor": ""
},
"especificacoes_tecnicas": {
"potencia": "",
"torque": "",
"cambio": "",
"tracao": "",
"direcao": "",
"suspensao_dianteira": "",
"suspensao_traseira": "",
"freios": "",
"pneus_originais": "",
"tanque": "",
"porta_malas": ""
},
"manutencao": {
"oleo_recomendado": "",
"capacidade_oleo": "",
"fluido_arrefecimento": "",
"fluido_freio": "",
"velas": "",
"correia_ou_corrente": ""
},
"problemas_comuns": [
{
"item": "",
"descricao": "",
"sintomas": "",
"gravidade": "",
"observacao_vistoria": ""
}
],
"pecas_desgaste": [
{
"peca": "",
"vida_util_media": "",
"valor_peca_estimado": "",
"valor_mao_de_obra_estimado": "",
"tempo_mao_de_obra_estimado": ""
}
],
"dicas_vistoria": [
{
"area": "",
"o_que_verificar": "",
"sinal_de_alerta": ""
}
],
"observacoes": [
""
]${extraJsonSchema},
"aviso": "Informações geradas por IA com valores estimados. Confirmar dados técnicos, valores e recalls em fontes oficiais antes de uso comercial ou jurídico."
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
