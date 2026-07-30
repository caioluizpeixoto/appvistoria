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
    const { brand, model, year, version, type, parts, customInstruction } = body

    if (!brand || !model) {
      return new Response(JSON.stringify({ error: 'Marca e modelo são obrigatórios.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const brandStr = brand.toString().trim()
    const modelStr = model.toString().trim()
    const yearStr = year ? year.toString().trim() : '2022'
    const versionStr = version ? version.toString().trim() : 'Limited T270'
    const typeStr = type ? type.toString().trim() : 'SUV'
    const vehicleFullName = `${brandStr} ${modelStr} ${yearStr}`.trim()
    const customAdjustment = customInstruction ? customInstruction.toString().trim() : ''

    // ── Supabase Client para Cache ──────────────────────────────────────────
    // @ts-ignore
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    // @ts-ignore
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    let supabase: any = null
    if (supabaseUrl && supabaseServiceKey) {
      supabase = createClient(supabaseUrl, supabaseServiceKey)
    }

    // ── Calcular Hash das Peças ──────────────────────────────────────────────
    let partsHash = 'CLEAN'
    if (parts && Array.isArray(parts) && parts.length > 0) {
      const sorted = [...parts].sort((a: any, b: any) => (a.part || '').localeCompare(b.part || ''))
      partsHash = sorted.map((p: any) => `${p.part}:${p.color}`).join('|')
    }

    // ── 1. Verificar no Cache do Banco (Somente se não houver ajuste customizado) ──
    if (supabase && !customAdjustment) {
      try {
        const { data: cached } = await supabase
          .from('vehicle_ai_images')
          .select('image_base64, source')
          .eq('brand', brandStr)
          .eq('model', modelStr)
          .eq('year', yearStr)
          .eq('parts_hash', partsHash)
          .maybeSingle()

        if (cached && cached.image_base64) {
          console.log('⚡ Retornando imagem do CACHE do Supabase para:', vehicleFullName, partsHash)
          return new Response(JSON.stringify({ source: 'cache', base64: cached.image_base64 }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
      } catch (cacheErr) {
        console.error('Erro ao consultar cache de imagens:', cacheErr)
      }
    }

    let partsInstruction = '- No damage, scratches, dents or highlights. ALL body parts are 100% neutral metallic gray (#A9A9A9).'
    if (parts && parts.length > 0) {
      const partsList = parts.map((p: any) => `${p.part} MUST BE PAINTED IN ${p.color.toUpperCase()}`).join(', ')
      partsInstruction = `- STRICT PARTS COLORING INSTRUCTION: ONLY these exact parts are colored: ${partsList}.
- COLOR BOUNDARY & PRECISION RULE:
  1) When coloring a part (like a hood or a door), you MUST color the ENTIRE part edge-to-edge (covering 100% of its surface). Do not leave unpainted gray patches on that part.
  2) Do NOT spill color over panel gaps. If a door is colored, do NOT color the adjacent A/B/C pillars, roof rails, or window frames. Keep the color strictly inside the structural panel seams of the specified part.
- PERSPECTIVE & SIDE ACCURACY RULE:
  1) The UPPER vehicle shows ONLY the FRONT-LEFT (DRIVER SIDE). Left-side parts (like front/rear left doors/fenders) are visible on the UPPER vehicle. Right-side parts MUST NOT be colored on the upper vehicle.
  2) The LOWER vehicle shows ONLY the REAR-RIGHT (PASSENGER SIDE). Right-side parts (like front/rear right doors/fenders) are visible on the LOWER vehicle. Left-side parts MUST NOT be colored on the lower vehicle.
  3) ALL OTHER BODY PARTS not explicitly listed above MUST REMAIN 100% NEUTRAL METALLIC GRAY (#A9A9A9).`
    }

    let customPromptLine = ''
    if (customAdjustment) {
      customPromptLine = `\n- Additional User Correction / Fix: ${customAdjustment}.`
    }

    const prompt = `Create a clean, high-quality 3D technical illustration of a ${vehicleFullName}. Requirements: - Vehicle: {Marca: ${brandStr} Modelo: ${modelStr} Ano: ${yearStr} Versão: ${versionStr} Tipo: ${typeStr}} - Use the official body shape and proportions of this exact vehicle. - Neutral metallic gray paint (#A9A9A9). ${partsInstruction}${customPromptLine} - White seamless studio background. - Soft professional studio lighting. - Photorealistic 3D render. - No reflections that hide body lines. - High level of detail. - Keep all factory design characteristics. - Original wheels for this model. - Original headlights, taillights, mirrors and bumpers. - No license plate text. - No logos, labels, arrows, legends or annotations. - No shadows outside the vehicle. - Do not crop any part of the vehicle. Layout: - Show EXACTLY TWO vehicles in the same image. - The upper vehicle must be a front-left 3/4 view (approximately 45°). - The lower vehicle must be a rear-right 3/4 view (approximately 45°). - Leave a large vertical gap between the two vehicles (at least 25% of the canvas height). - Both vehicles must be centered horizontally. - Each vehicle should occupy approximately 35% of the image height. - Both vehicles must have exactly the same scale. - Keep generous white margins around both vehicles. Style: - Automotive catalog render. - OEM brochure quality. - Technical illustration. - Consistent perspective. - Clean composition. - Ultra realistic. - 4K quality.`

    // Tentar gerar com modelos de imagem da OpenAI (gpt-image-2, gpt-image-1.5, chatgpt-image-latest, dall-e-3, dall-e-2)
    // @ts-ignore
    const openAiApiKey = Deno.env.get('OPENAI_API_KEY')
    const openAiErrors: string[] = []
    if (openAiApiKey) {
      console.log('Tentando gerar imagem via OpenAI para:', vehicleFullName)
      
      const candidateModels = ['gpt-image-2', 'gpt-image-1.5', 'chatgpt-image-latest', 'dall-e-3', 'dall-e-2']

      for (const modelName of candidateModels) {
        try {
          const isDalle2 = modelName === 'dall-e-2'
          const payload: any = {
            model: modelName,
            prompt: prompt.substring(0, isDalle2 ? 950 : 3900),
            n: 1,
            size: '1024x1024',
          }

          const openAiResponse = await fetch('https://api.openai.com/v1/images/generations', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${openAiApiKey}`,
            },
            body: JSON.stringify(payload)
          })

          if (openAiResponse.ok) {
            const openAiData = await openAiResponse.json()
            const imageUrl = openAiData.data?.[0]?.url
            const b64Direct = openAiData.data?.[0]?.b64_json
            let base64Image = b64Direct

            if (!base64Image && imageUrl) {
              console.log(`Sucesso com OpenAI ${modelName}! Baixando imagem da URL...`)
              const imgRes = await fetch(imageUrl)
              const arrayBuffer = await imgRes.arrayBuffer()
              const uint8Array = new Uint8Array(arrayBuffer)
              let binary = ''
              for (let i = 0; i < uint8Array.byteLength; i++) {
                binary += String.fromCharCode(uint8Array[i])
              }
              base64Image = btoa(binary)
            }

            if (base64Image) {
              // Salvar no Cache do Supabase
              if (supabase) {
                try {
                  await supabase.from('vehicle_ai_images').insert({
                    brand: brandStr,
                    model: modelStr,
                    year: yearStr,
                    parts_hash: partsHash,
                    image_base64: base64Image,
                    source: `openai-${modelName}`,
                  })
                  console.log('💾 Imagem salva no CACHE do Supabase!')
                } catch (insertErr) {
                  console.error('Erro ao salvar cache:', insertErr)
                }
              }

              return new Response(JSON.stringify({ source: `openai-${modelName}`, base64: base64Image }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              })
            }
          } else {
            const errorText = await openAiResponse.text()
            console.error(`Erro no modelo ${modelName} da OpenAI:`, errorText)
            openAiErrors.push(`${modelName}: ${errorText}`)
          }
        } catch (e: any) {
          openAiErrors.push(`${modelName} exception: ${e.message}`)
        }
      }
    } else {
      openAiErrors.push('OPENAI_API_KEY não foi encontrada no ambiente Deno')
    }

    // Se falhar em todos da OpenAI, usa Pollinations como fallback final
    console.log('Fallback para Pollinations AI com os erros:', openAiErrors)

    // Fallback: Pollinations AI
    console.log('Gerando imagem via Pollinations AI para:', vehicleFullName)
    const encodedPrompt = encodeURIComponent(prompt)
    const pollinationsUrl = `https://image.pollinations.ai/prompt/${encodedPrompt}?width=1024&height=1024&nologo=true`

    const imageResponse = await fetch(pollinationsUrl)

    if (!imageResponse.ok) {
      const errorText = await imageResponse.text()
      console.error('Erro na Pollinations API:', errorText)
      return new Response(JSON.stringify({ error: 'Erro ao gerar imagem.', details: errorText }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const arrayBuffer = await imageResponse.arrayBuffer()
    const uint8Array = new Uint8Array(arrayBuffer)
    let binary = ''
    for (let i = 0; i < uint8Array.byteLength; i++) {
      binary += String.fromCharCode(uint8Array[i])
    }
    const base64Image = btoa(binary)

    if (!base64Image) {
      return new Response(JSON.stringify({ error: 'Falha ao converter imagem.' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ source: 'pollinations', base64: base64Image }), {
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
