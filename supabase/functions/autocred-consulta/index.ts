const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// @ts-ignore
Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { action, tipoConsulta, valorConsulta, codigoConsulta, idPesquisa } = body

    // @ts-ignore
    const usuario = Deno.env.get('AUTOCRED_USUARIO') || '1932202'
    // @ts-ignore
    const senha = Deno.env.get('AUTOCRED_SENHA') || 'CDywvWZLV3!'

    if (!usuario || !senha) {
      return new Response(JSON.stringify({ error: 'Credenciais não configuradas no servidor' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    const apiUrl = 'https://bin.autocredcar.com.br/wsautocredcar/consultapdf.asmx'

    if (action === 'gerar_consulta') {
      if (!valorConsulta || !codigoConsulta) {
        return new Response(JSON.stringify({ error: 'Faltam parâmetros obrigatórios' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      const consultaSoapBody = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Consulta xmlns="http://tempuri.org/">
      <usuario>${usuario}</usuario>
      <senha>${senha}</senha>
      <tipoDePesquisa>${codigoConsulta}</tipoDePesquisa>
      <parametros>${valorConsulta}</parametros>
      <identCliente>CAIO</identCliente>
      <identSistema>teste app vistoria</identSistema>
    </Consulta>
  </soap:Body>
</soap:Envelope>`

      const consultaRes = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': 'http://tempuri.org/Consulta'
        },
        body: consultaSoapBody
      })

      const consultaText = await consultaRes.text()

      if (!consultaRes.ok) {
        let errorMessage = 'Erro na API AutoCredCar (Consulta)'
        const faultMatch = consultaText.match(/<faultstring>(.*?)<\/faultstring>/i)
        if (faultMatch && faultMatch[1]) {
          errorMessage = faultMatch[1].replace(/--&gt;/g, '->').trim()
        }
        return new Response(JSON.stringify({ error: errorMessage, details: consultaText }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      let unescapedXml = consultaText.replace(/&lt;/g, '<').replace(/&gt;/g, '>')
      let idPesquisaMatch = unescapedXml.match(/<idPesquisa>(.*?)<\/idPesquisa>/i)
      let idPesquisaFound = idPesquisaMatch ? idPesquisaMatch[1] : null

      if (!idPesquisaFound) {
        return new Response(JSON.stringify({ error: 'Não foi possível extrair o idPesquisa. Verifique credenciais ou saldo.', rawResponse: consultaText }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      return new Response(JSON.stringify({ status: 'success', idPesquisa: idPesquisaFound, rawXml: consultaText }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    if (action === 'obter_resultado') {
      if (!idPesquisa) {
        return new Response(JSON.stringify({ error: 'idPesquisa obrigatório para obter resultado' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      const getConsultaSoapBody = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetConsulta xmlns="http://tempuri.org/">
      <usuario>${usuario}</usuario>
      <senha>${senha}</senha>
      <idPesquisa>${idPesquisa}</idPesquisa>
    </GetConsulta>
  </soap:Body>
</soap:Envelope>`

      const getConsultaRes = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': 'http://tempuri.org/GetConsulta'
        },
        body: getConsultaSoapBody
      })

      const getConsultaText = await getConsultaRes.text()

      if (!getConsultaRes.ok) {
        let errorMessage = 'Erro ao buscar resultado da consulta'
        const faultMatch = getConsultaText.match(/<faultstring>(.*?)<\/faultstring>/i)
        if (faultMatch && faultMatch[1]) {
          errorMessage = faultMatch[1].replace(/--&gt;/g, '->').trim()
        }
        return new Response(JSON.stringify({ error: errorMessage, details: getConsultaText }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      return new Response(JSON.stringify({ status: 'success', xmlData: getConsultaText }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    if (action === 'gerar_pdf') {
      if (!idPesquisa) {
        return new Response(JSON.stringify({ error: 'idPesquisa obrigatório para gerar pdf' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      const gerarPdfSoapBody = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GerarPDF xmlns="http://tempuri.org/">
      <usuario>${usuario}</usuario>
      <senha>${senha}</senha>
      <idPesquisa>${idPesquisa}</idPesquisa>
    </GerarPDF>
  </soap:Body>
</soap:Envelope>`

      const gerarPdfRes = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': 'http://tempuri.org/GerarPDF'
        },
        body: gerarPdfSoapBody
      })

      const gerarPdfText = await gerarPdfRes.text()

      if (!gerarPdfRes.ok) {
        let errorMessage = 'Erro ao gerar PDF na AutoCredCar'
        const faultMatch = gerarPdfText.match(/<faultstring>(.*?)<\/faultstring>/i)
        if (faultMatch && faultMatch[1]) {
          errorMessage = faultMatch[1].replace(/--&gt;/g, '->').trim()
        }
        return new Response(JSON.stringify({ error: errorMessage, details: gerarPdfText }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      return new Response(JSON.stringify({ status: 'success', xmlData: gerarPdfText }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    return new Response(JSON.stringify({ error: 'Ação inválida (action missing ou incorreta)' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (error) {
    console.error('Erro interno:', error)
    return new Response(JSON.stringify({ error: 'Erro interno no servidor' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
