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
    let { brand, model, year, version, fuel, engine } = body

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

    // Buscar no banco se já existe ficha
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

    // Se não existir, chamar Gemini
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      return new Response(JSON.stringify({ error: 'Chave da API Gemini não configurada.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`

    const prompt = `Você é um especialista técnico automotivo brasileiro. Crie uma ficha técnica detalhada para o veículo informado. Retorne APENAS JSON válido, sem markdown, sem texto fora do JSON. Use dados aproximados quando necessário e marque valores incertos como estimados.

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
],
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
      return new Response(JSON.stringify({ error: 'Erro ao gerar ficha com Gemini.' }), {
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

    // Salvar no Supabase
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
      // Continuar mesmo se falhar ao salvar cache
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
