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
    const { brand, model, year, parts } = body

    if (!brand || !model) {
      return new Response(JSON.stringify({ error: 'Marca e modelo são obrigatórios.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      return new Response(JSON.stringify({ error: 'Chave da API Gemini não configurada.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Build the prompt
    let partsDescription = '';
    if (parts && parts.length > 0) {
      const partsList = parts.map((p: any) => `${p.part} painted in ${p.color}`).join(', ');
      partsDescription = `EXCEPT for the following parts which MUST be colored as specified: ${partsList}.`;
    } else {
      partsDescription = 'No parts are damaged, the entire car is light gray.';
    }

    const yearStr = year ? ` ${year}` : '';
    const prompt = `A highly realistic 3D isometric render on a pure white background of a ${brand} ${model}${yearStr}. The car is entirely light gray, ${partsDescription} The image should look like a professional studio automotive diagram.`;

    // A API do Imagen 3 via Gemini (generativelanguage.googleapis.com)
    // Documentação mais recente usa models/imagen-3.0-generate-001:predict
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-fast-generate-001:predict?key=${geminiApiKey}`

    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        instances: [
          {
            prompt: prompt
          }
        ],
        parameters: {
          sampleCount: 1,
          outputOptions: {
            mimeType: "image/jpeg"
          }
        }
      })
    })

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('Erro na API Imagen:', errorText)
      return new Response(JSON.stringify({ error: 'Erro ao gerar imagem com a IA do Google.', details: errorText }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const geminiData = await geminiResponse.json()
    // O retorno da API v1beta do Imagen geralmente está em predictions[0].bytesBase64Encoded
    const base64Image = geminiData.predictions?.[0]?.bytesBase64Encoded

    if (!base64Image) {
      console.error('Resposta da IA não contém a imagem:', JSON.stringify(geminiData));
      return new Response(JSON.stringify({ error: 'Resposta vazia da IA.' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ source: 'gemini-imagen', base64: base64Image }), {
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
