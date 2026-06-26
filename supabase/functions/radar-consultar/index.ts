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
    const { produto, param, value, forcarNova } = await req.json();

    if (!produto || !param || !value) {
      throw new Error("Parâmetros 'produto', 'param' e 'value' são obrigatórios.");
    }

    const produtosMap: Record<string, string> = {
      "auto_bin": "21589A1C74E953B1486494836NQ70TJ0EUZFTS9K7GGLAMHKOJ",
      "auto_pericia": "2158B04671523351487947377ALQNCW8LN4VGIJHLHSFJDD5G9",
      "auto_completa": "21588A87D591BBD1485473749QJKNKEIFTWHHBWDJJVDNEOB76",
      "auto_leilao": "2158DD027974724149087909770OG7270OE8LK17N7RET0LSJ3",
      "auto_base_estadual": "21589C4F6FE5D851486638959Z74PAKY8WJ4M8EF5LQB945K5N",
      "auto_debitos_recall": "2159EA6BFB60104150853529156RSGFTC62RP1XWPKV9CT99P1",
    };

    const tokenProduto = produtosMap[produto];
    if (!tokenProduto) {
      throw new Error(`Produto não encontrado: ${produto}`);
    }

    const radarUser = Deno.env.get("RADAR_USER") ?? "20401";
    const radarPassword = Deno.env.get("RADAR_PASSWORD") ?? "ussj2306";
    const radarApiToken = Deno.env.get("RADAR_API_TOKEN") ?? "216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO";

    if (!radarUser || !radarPassword || !radarApiToken) {
      throw new Error("Credenciais da API Radar não configuradas.");
    }

    const basicAuth = btoa(`${radarUser}:${radarPassword}`);

    const bodyParams = new URLSearchParams();
    bodyParams.append("produto", tokenProduto);
    bodyParams.append("param", param);
    bodyParams.append("value", value);
    bodyParams.append("aguardar-retorno", "true");
    
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

    const data = await response.json();

    if (data?.erro) {
      throw new Error(data.erro);
    }

    if (data?.result === 0 && data?.message) {
      throw new Error(data.message);
    }

    // extrair dados
    let resultData: any = {};
    if (data?.consulta?.resultados?.[0]?.retorno?.data) {
       resultData = data.consulta.resultados[0].retorno.data;
    } else {
       // Tentar buscar em fallback caso mude algo
       resultData = data;
    }

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
        combustivel: resultData.combustivel || "",
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
