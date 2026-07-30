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

    // Se não existir, chamar Gemini
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      return new Response(JSON.stringify({ error: 'Chave da API Gemini não configurada.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${geminiApiKey}`

    let extraPrompt = '';
    let extraJsonSchema = '';
    const estadoLocal = uf ? `Considere o mercado do estado de(a) ${uf}, NO BRASIL, para estimativa de preços.` : 'Considere o mercado médio brasileiro para estimativa de preços.';
    
    if (hasApontamentos) {
      extraPrompt = `\nIMPORTANTE: O vistoriador apontou as seguintes DIVERGÊNCIAS/DEFEITOS reais neste veículo durante a vistoria:\n${apontamentos.map((a: string) => '- ' + a).join('\n')}\n\nSua tarefa é ESTIMAR o valor da peça de reposição (nova ou paralela), o custo de mão de obra para reparar ou substituir as peças citadas acima e também indicar exatamente o local no veículo onde esse apontamento costuma ser encontrado (ex: 'Cofre do motor, lado direito' ou 'Estrutura Dianteira'). ${estadoLocal} REGRA CRÍTICA: Assuma sempre que o reparo é uma troca simples de componente mecânico/estético. Nunca orce reparos estruturais complexos (como alinhamento de chassi, solda ou repuxamento de torre), mesmo que o termo utilizado sugira parte estrutural, limite-se ao custo de substituição da peça mecânica correspondente. Inclua essas estimativas no JSON de retorno sob a chave "apontamentos_veiculo". TODOS OS VALORES DEVERÃO SER EM REAIS (R$).`;
      extraJsonSchema = `,\n"apontamentos_veiculo": [\n{\n"peca_ou_problema": "",\n"local_no_veiculo": "",\n"observacao_indicada": "",\n"valor_peca_estimado": "",\n"valor_mao_de_obra_estimado": ""\n}\n]`;
    }
    
    // Sempre adicionar a análise final
    extraPrompt += `\nAlém disso, faça uma análise final da vistoria: se está tudo certo ou se há avarias, apresente o valor médio de venda desse carro no mercado local (${estadoLocal}), calcule um desconto baseado nas avarias informadas (se houver) e sugira o valor de venda final. ATENÇÃO: TODOS OS VALORES FINANCEIROS NO JSON PRECISAM ESTAR EXCLUSIVAMENTE EM REAIS (R$). É PROIBIDO USAR DÓLARES OU FAZER REFERÊNCIA AOS ESTADOS UNIDOS.`;
    extraJsonSchema += `,\n"analise_final": {\n"resumo_estado_veiculo": "",\n"valor_venda_mercado_local": "",\n"desconto_total_avarias": "",\n"valor_venda_sugerido_final": "",\n"justificativa": ""\n}`;

    const prompt = `Você é um especialista técnico automotivo brasileiro. Crie uma ficha técnica detalhada para o veículo informado. Retorne APENAS JSON válido, sem markdown, sem texto fora do JSON. Use dados aproximados quando necessário e marque valores incertos como estimados. OBRIGATÓRIO: TODOS OS PREÇOS E AVALIAÇÕES DEVEM SER EM MOEDA BRASILEIRA (BRL) FORMATADOS COMO "R$ X.XXX,XX". NUNCA USE USD NEM REALIZE AVALIAÇÕES DO MERCADO AMERICANO.${extraPrompt}

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

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('Erro na API Gemini:', errorText)
      return new Response(JSON.stringify({ error: 'Erro ao gerar ficha com Gemini.', details: errorText }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const geminiData = await geminiResponse.json()
    let textResult = geminiData.candidates?.[0]?.content?.parts?.[0]?.text

    if (!textResult) {
      return new Response(JSON.stringify({ error: 'Resposta vazia da IA.' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Limpar possíveis formatações markdown (ex: ```json ... ```)
    textResult = textResult.trim()
    if (textResult.startsWith('```json')) {
      textResult = textResult.replace(/^```json/, '').replace(/```$/, '').trim()
    } else if (textResult.startsWith('```')) {
      textResult = textResult.replace(/^```/, '').replace(/```$/, '').trim()
    }

    let parsedJson
    try {
      parsedJson = JSON.parse(textResult)
    } catch (e) {
      console.error('Erro ao fazer parse do JSON da Gemini:', textResult)
      return new Response(JSON.stringify({ error: 'A IA retornou um formato inválido.' }), {
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

    return new Response(JSON.stringify({ source: 'gemini', data: parsedJson }), {
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
