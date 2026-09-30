import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildPrompt } from './prompt.ts'

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
        // Verificar se o cache possui o formato NOVO (com analise_modelo)
        if (cachedData.data.secao5_ficha_tecnica) {
          console.log('Retornando dados técnicos do cache para:', brand, model, year)
          return new Response(JSON.stringify({ source: 'cache', data: cachedData.data }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        } else {
          console.log('Cache antigo encontrado (sem analise_modelo), ignorando cache e regerando ficha técnica para:', brand, model, year)
        }
      }
    }

    let extraPrompt = '';
    let extraJsonSchema = ',\n"apontamentos_veiculo": []';
    const estadoLocal = uf ? `Considere o mercado do estado de(a) ${uf}, NO BRASIL, para estimativa de preços de peças e serviços.` : 'Considere o mercado médio brasileiro para estimativa de preços de peças e serviços.';
    
    if (hasApontamentos) {
      const apontamentosFormatados = apontamentos.map((a: any, idx: number) => {
        if (typeof a === 'object' && a !== null) {
          const id = a.apontamentoId || a.id || a.item || `apt_${idx}`;
          const peca = a.nomePeca || a.peca || a.item || 'Item apontado';
          const desc = a.descricaoProblema || a.motivoAvaria || a.problema || a.observacao || '';
          return { apontamentoId: String(id), nomePeca: String(peca), descricaoProblema: String(desc) };
        }
        return { apontamentoId: `apt_${idx}`, nomePeca: String(a), descricaoProblema: String(a) };
      });

      extraPrompt = `\nAPONTAMENTOS DA VISTORIA REGISTRADOS PELO VISTORIADOR:
${apontamentosFormatados.map((it: any) => `- [ID: "${it.apontamentoId}"] Peça: "${it.nomePeca}" | Problema: "${it.descricaoProblema}"`).join('\n')}

REGRAS OBRIGATÓRIAS DE ORÇAMENTO DOS APONTAMENTOS (${estadoLocal}):
1. Para CADA apontamento listado acima, você deve retornar um objeto na lista "apontamentos" com:
   - "item": O mesmo ID recebido correspondente.
   - "problema": Descrição do problema / peça danificada.
   - "reparo_recomendado": Serviço recomendado (reparo ou substituição).
   - "valor_peca": Número numérico (double) estimado para a peça de reposição (ex: 1200.00). Caso não requeira peça nova, coloque 0.0.
   - "valor_mao_obra": Número numérico (double) estimado para a mão de obra/serviço (ex: 400.00).
   - "outros_custos": Número numérico (ex: 0.0).
   - "valor_total": A soma dos 3 anteriores (ex: 1600.00).
   - "observacao": Uma breve justificativa da estimativa ou "estimativa de preço varia de R$ X a R$ Y".
2. ITENS SEM ACESSO / DENTRO DO PADRÃO: "valor_peca": 0.0, "valor_mao_obra": 0.0
3. PROIBIÇÃO ABSOLUTA: A IA NÃO deve calcular valor do veículo nem FIPE.`;

      extraJsonSchema = `,\n  "apontamentos": [\n    {\n      "item": "${apontamentosFormatados[0]?.apontamentoId || '123'}",\n      "problema": "${apontamentosFormatados[0]?.nomePeca || 'Para-choque'}",\n      "reparo_recomendado": "Descrição",\n      "valor_peca": 1200.00,\n      "valor_mao_obra": 400.00,\n      "outros_custos": 0.00,\n      "valor_total": 1600.00,\n      "observacao": "Estimativa entre 1000 e 1400"\n    }\n  ]`;
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
  "apontamentos": [
    {
      "item": "string (o mesmo ID recebido)",
      "problema": "string",
      "reparo_recomendado": "string",
      "valor_peca": 0.00,
      "valor_mao_obra": 0.00,
      "outros_custos": 0.00,
      "valor_total": 0.00,
      "observacao": "string"
    }
  ]
}

Veículo: ${brand} ${model} ${year} ${version || ''} (${engine || ''})
${extraPrompt}`;

      // @ts-ignore
      const openAiKey = Deno.env.get('OPENAI_API_KEY');
      let parsedAvariasJson: any = null;
      let sourceAvarias = '';

      let openAiErrorDetailAvarias = '';
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
              try {
                parsedAvariasJson = JSON.parse(content);
                sourceAvarias = 'openai-gpt-4o-mini';
              } catch (e: any) {
                openAiErrorDetailAvarias = `Erro no parse JSON de avarias: ${e.message}`;
              }
            }
          } else {
             const txt = await resp.text();
             openAiErrorDetailAvarias = `Erro HTTP OpenAI avarias: ${resp.status} - ${txt}`;
          }
        } catch (e: any) {
          openAiErrorDetailAvarias = `Exceção de rede OpenAI avarias: ${e.message}`;
          console.error('Erro OpenAI em apenasAvarias:', e.message);
        }
      } else {
         openAiErrorDetailAvarias = 'Chave OPENAI_API_KEY não configurada.';
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
      } else {
         return new Response(JSON.stringify({ error: 'Falha ao orçar avarias com as IAs.', details: openAiErrorDetailAvarias }), {
           status: 502,
           headers: { ...corsHeaders, 'Content-Type': 'application/json' },
         });
      }
    }

    const prompt = buildPrompt(brand, model, year, version, fuel, engine, extraPrompt, extraJsonSchema);

    let parsedJson: any = null
    let sourceUsed = ''

    // ── 1. Tentar gerar com OpenAI (gpt-4o-mini ou gpt-4o) ────────────────────
    // @ts-ignore
    const openAiApiKey = Deno.env.get('OPENAI_API_KEY')
    let openAiErrorDetail = ''

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
            try {
              parsedJson = JSON.parse(rawContent)
              sourceUsed = 'openai-gpt-4o-mini'
              console.log('Ficha técnica gerada com sucesso via OpenAI!')
            } catch (parseError: any) {
              openAiErrorDetail = `Erro ao parsear JSON da OpenAI: ${parseError.message}. Conteúdo: ${rawContent.substring(0, 100)}...`
              console.error(openAiErrorDetail)
            }
          } else {
             openAiErrorDetail = 'OpenAI retornou OK, mas não enviou nenhum conteúdo na resposta.'
          }
        } else {
          const errText = await openAiResponse.text()
          openAiErrorDetail = `Erro HTTP da OpenAI: Status ${openAiResponse.status} - ${errText}`
          console.error(openAiErrorDetail)
        }
      } catch (openAiErr: any) {
        openAiErrorDetail = `Exceção de rede ao chamar OpenAI: ${openAiErr.message}`
        console.error(openAiErrorDetail)
      }
    } else {
      openAiErrorDetail = 'OPENAI_API_KEY não está configurada nos Secrets do Supabase.'
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
      return new Response(JSON.stringify({ error: 'Falha ao gerar relatório inteligente.', details: sourceUsed || 'Nenhuma IA conseguiu gerar um JSON válido.' }), {
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
