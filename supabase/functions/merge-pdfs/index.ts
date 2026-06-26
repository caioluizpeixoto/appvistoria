import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { PDFDocument } from 'https://esm.sh/pdf-lib@1.17.1'

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
    const { vistoriaPdfBase64, externalPdfUrl, filename } = await req.json()

    if (!vistoriaPdfBase64) {
      return new Response(JSON.stringify({ error: 'PDF da vistoria ausente.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 1. Carregar o PDF principal (Vistoria)
    const vistoriaBytes = Uint8Array.from(atob(vistoriaPdfBase64), c => c.charCodeAt(0))
    const finalDoc = await PDFDocument.load(vistoriaBytes)

    // 2. Tentar baixar e mesclar o PDF externo, se houver
    if (externalPdfUrl) {
      try {
        console.log(`Baixando PDF externo de: ${externalPdfUrl}`)
        const response = await fetch(externalPdfUrl)
        
        if (response.ok) {
          const contentType = response.headers.get('content-type')
          let externalBuffer: ArrayBuffer | null = null;

          if (contentType && contentType.includes('application/pdf')) {
            externalBuffer = await response.arrayBuffer()
          } else if (contentType && contentType.includes('text/html')) {
            console.log('Detectado HTML. Tentando converter para PDF via API2PDF...');
            const apiKey = Deno.env.get('API2PDF_KEY');
            if (!apiKey) {
              console.error('Chave API2PDF_KEY não configurada. Não é possível converter HTML.');
            } else {
              const apiResponse = await fetch('https://v2.api2pdf.com/chrome/url', {
                method: 'POST',
                headers: {
                  'Authorization': apiKey,
                  'Content-Type': 'application/json'
                },
                body: JSON.stringify({ url: externalPdfUrl, inlinePdf: true })
              });
              
              if (apiResponse.ok) {
                const apiData = await apiResponse.json();
                if (apiData.FileUrl) {
                  const convertedPdfRes = await fetch(apiData.FileUrl);
                  if (convertedPdfRes.ok) {
                    externalBuffer = await convertedPdfRes.arrayBuffer();
                    console.log('Conversão HTML->PDF concluída com sucesso.');
                  }
                }
              } else {
                console.error('Erro na API2PDF:', await apiResponse.text());
              }
            }
          } else {
            console.error('O arquivo externo não é um PDF válido e não pôde ser convertido:', contentType)
          }

          if (externalBuffer) {
            const externalDoc = await PDFDocument.load(externalBuffer)
            
            // Copiar todas as páginas do PDF externo para o documento final
            const externalPages = await finalDoc.copyPages(externalDoc, externalDoc.getPageIndices())
            for (const page of externalPages) {
              finalDoc.addPage(page)
            }
            console.log('PDF externo mesclado com sucesso.')
          }
        } else {
          console.error(`Erro ao baixar o PDF externo: Status ${response.status}`)
        }
      } catch (err) {
        console.error('Erro ao processar o PDF externo:', err)
        // Opcional: não retornar erro fatal, o usuário pelo menos recebe o laudo base
      }
    }

    // 3. Salvar o PDF mesclado
    const mergedPdfBytes = await finalDoc.save()
    
    // @ts-ignore
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    // @ts-ignore
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 4. Upload para o Supabase Storage (Bucket: laudos)
    const finalFilename = filename || `laudo_${Date.now()}.pdf`
    const { error: uploadError } = await supabase.storage
      .from('laudos')
      .upload(finalFilename, mergedPdfBytes, {
        contentType: 'application/pdf',
        upsert: true
      })

    if (uploadError) {
      console.error('Erro no upload do Storage:', uploadError)
      return new Response(JSON.stringify({ error: 'Erro ao salvar o PDF final.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 5. Gerar URL assinada válida por 24 horas (86400 segundos)
    const { data: signedData, error: signedError } = await supabase.storage
      .from('laudos')
      .createSignedUrl(finalFilename, 86400)

    if (signedError || !signedData?.signedUrl) {
      console.error('Erro ao gerar URL assinada:', signedError)
      return new Response(JSON.stringify({ error: 'Erro ao gerar URL do PDF.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ url: signedData.signedUrl }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Erro interno na função:', error)
    return new Response(JSON.stringify({ error: 'Erro interno no servidor' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
