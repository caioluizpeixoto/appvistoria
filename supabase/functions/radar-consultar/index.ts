import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { produto, param, value, forcarNova, tokenConsulta, aguardarRetorno } = await req.json();

    if (!produto || !param || !value) {
      throw new Error("Parâmetros 'produto', 'param' e 'value' são obrigatórios.");
    }

    const produtosMap: Record<string, string> = {
      // 1. Número CRV (PLACA)
      "numero_crv": "21696E59C08FB7F176883961615M79UH32B1WOVGJHFY255O0I",
      // 2. Código CRV (PLACA)
      "codigo_crv": "21697118FF9B1101769019647Q5BFBB9FWVUYXKE9DRDLFYWFZ",
      // 3. Auto Completa (PLACA)
      "auto_completa": "21588A87D591BBD1485473749QJKNKEIFTWHHBWDJJVDNEOB76",
      // 4. Auto BIN (PLACA OU CHASSI)
      "auto_bin": "21589A1C74E953B1486494836NQ70TJ0EUZFTS9K7GGLAMHKOJ",
      // 5. Auto Base Estadual (PLACA)
      "auto_base_estadual": "21589C4F6FE5D851486638959Z74PAKY8WJ4M8EF5LQB945K5N",
      // 6. Auto Perícia (PLACA)
      "auto_pericia": "2158B04671523351487947377ALQNCW8LN4VGIJHLHSFJDD5G9",
      // 7. Auto Leilão (PLACA OU CHASSI)
      "auto_leilao": "2158DD027974724149087909770OG7270OE8LK17N7RET0LSJ3",
      // 8. Auto Estadual + Proprietário (PLACA)
      "auto_estadual_proprietario": "2158DE583B7654714909665876FV8VSPNER2DHLZR81SPVLMZ0",
      // 9. Auto Decodificador de Chassi (CHASSI)
      "auto_decodificador_chassi": "2158F0F1EF0ADB11492185583PRLK042XHWPU83FX7V5DJ8MRT",
      // 10. Auto Gravame (CHASSI)
      "auto_gravame": "2158FA1C23B8B8C1492786211KU65H6GRCDCNNLXZARBEQRLGY",
      // 11. Auto Débitos + Recall (PLACA OU CHASSI)
      "auto_debitos_recall": "2159EA6BFB60104150853529156RSGFTC62RP1XWPKV9CT99P1",
      // 12. Auto Análise (PLACA)
      "auto_analise": "215C7D7C9C6A8151551727772AXVADBADNQZAWS5M9SLVVF0R1",
      // 13. Auto Análise + (PLACA)
      "auto_analise_plus": "215C7D7D8400EAB1551728004RDCEG7NQ58EGUG34O9O4ATTRI",
      // 14. Auto Perícia HRF (PLACA)
      "auto_pericia_hrf": "2162AB9E27B63CD1655414311NO8UOXTCZ2SC4CW1L75PRFEVN",
      // 15. Bin por Motor (MOTOR)
      "bin_por_motor": "2162E98433071ED165947089995HQEQV32WR95PCLFIHJS2AOD",
      // 16. E-CRLV NOVA
      "e_crlv_nova": "216952A87095C431767024752XO8PQAC1LARXMPKCF9J3DQ428",
    };

    const tokenProduto = produtosMap[produto];
    if (!tokenProduto) {
      throw new Error(`Produto não encontrado: ${produto}`);
    }

    const radarUser = Deno.env.get("RADAR_USER") ?? "20401";
    const radarPassword = Deno.env.get("RADAR_PASSWORD") ?? "*Ultra541";
    const radarApiToken = Deno.env.get("RADAR_API_TOKEN") ?? "216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO";

    if (!radarUser || !radarPassword || !radarApiToken) {
      throw new Error("Credenciais da API Radar não configuradas.");
    }

    const basicAuth = btoa(`${radarUser}:${radarPassword}`);

    // Normalizar parâmetros
    const normalizedParam = param.toLowerCase();
    const normalizedValue = value.replace(/[^A-Za-z0-9]/g, "");

    let data: any = null;

    if (tokenConsulta) {
      const detalhesParams = new URLSearchParams();
      detalhesParams.append("consulta", tokenConsulta);

      const detalhesResponse = await fetch("https://www.radarconsultas.com.br/rdrv2/api/consultas/detalhes", {
        method: "POST",
        headers: {
          "Authorization": `Basic ${basicAuth}`,
          "api-token": radarApiToken,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: detalhesParams.toString(),
      });

      data = await detalhesResponse.json();
    } else {
      const bodyParams = new URLSearchParams();
      bodyParams.append("produto", tokenProduto);
      bodyParams.append("param", normalizedParam);
      bodyParams.append("value", normalizedValue);
      
      const aguardar = aguardarRetorno ?? true;
      bodyParams.append("aguardar-retorno", aguardar ? "true" : "false");
      
      if (forcarNova) {
        bodyParams.append("forcar-nova", "true");
      }

      const response = await fetch("https://www.radarconsultas.com.br/rdrv2/api/consultar", {
        method: "POST",
        headers: {
          "Authorization": `Basic ${basicAuth}`,
          "api-token": radarApiToken,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: bodyParams.toString(),
      });

      data = await response.json();
    }

    if (data?.erro) {
      throw new Error(data.erro);
    }

    if (data?.result === 0 && data?.message) {
      throw new Error(data.message);
    }

    const isPolling = !!tokenConsulta;
    let emProcessamento = false;
    let returnedToken = tokenConsulta;

    if (isPolling) {
      if (!data?.consulta || data.consulta.status !== 1) {
        emProcessamento = true;
      }
    } else {
      if (data?.["token-consulta"]) {
        emProcessamento = true;
        returnedToken = data["token-consulta"];
      }
    }

    if (emProcessamento) {
      return new Response(JSON.stringify({
        sucesso: true,
        emProcessamento: true,
        tokenConsulta: returnedToken,
        raw: data
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // extrair dados
    let resultData: any = {};
    let ipvaData: any[] = [];
    let multasData: any[] = [];
    let renajudData: any[] = [];

    const resultados = data?.consulta?.resultados;
    if (Array.isArray(resultados)) {
      for (const item of resultados) {
        const rData = item?.retorno?.data || item?.retorno;
        if (rData) {
          if (rData.placa && !resultData.placa) {
            resultData = { ...resultData, ...rData };
          } else {
            resultData = { ...rData, ...resultData };
          }
          if (Array.isArray(rData.ipva)) {
            ipvaData = rData.ipva;
          }
          if (Array.isArray(rData.multas)) {
            multasData = rData.multas;
          }
          if (Array.isArray(rData.renajud)) {
            renajudData = rData.renajud;
          }
        }
      }
    } else {
      resultData = data;
    }

    if (ipvaData.length > 0) resultData.ipva = ipvaData;
    if (multasData.length > 0) resultData.multas = multasData;
    if (renajudData.length > 0) resultData.renajud = renajudData;
    resultData.resultados_completos = resultados;

    return new Response(JSON.stringify({
      sucesso: true,
      raw: data,
      parsed: {
        placa: resultData.placa || "",
        renavam: resultData.renavam || "",
        chassi: resultData.chassi || "",
        anoFabricacao: resultData.anofabricacaoveiculo || resultData.anofabricacao || "",
        anoModelo: resultData.anomodeloveiculo || resultData.anomodelo || "",
        marcaModelo: resultData.marcamodelo || "",
        cor: resultData.cor || "",
        combustivel: resultData.combustivel || resultData.tipocombustivel || "",
        tipoVeiculo: resultData.tipoveiculo || "",
        especie: resultData.especie || "",
        categoria: resultData.categoria || "",
        motor: resultData.numerodomotor || resultData.motor || "",
        situacao: resultData.situacao || "",
        municipio: resultData.municipio || "",
        estado: resultData.estado || resultData.uf || "",
        proprietario: resultData.nomeproprietario || resultData.proprietario || "",
        documentoProprietario: resultData.documentoproprietario || "",
        restricoes1: resultData.restricoes1 || "",
        restricoes2: resultData.restricoes2 || "",
        restricoes3: resultData.restricoes3 || "",
        restricoes4: resultData.restricoes4 || "",
        informacoesRelevantes: resultData.informacoesRelevantes || resultData.informacoesrelevantes || "",
        ipva: ipvaData,
        multas: multasData,
        renajud: renajudData,
        radar_pdf_url: data.consulta?.view?.full || data.consulta?.resultados?.[0]?.view?.full || "",
        resultadoCompleto: resultData,
      }
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error: any) {
    return new Response(JSON.stringify({ sucesso: false, error: error.message }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
