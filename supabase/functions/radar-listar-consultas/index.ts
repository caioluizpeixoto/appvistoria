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
    const { param, value } = await req.json();

    const radarUser = Deno.env.get("RADAR_USER") ?? "20401";
    const radarPassword = Deno.env.get("RADAR_PASSWORD") ?? "*Ultra541";
    const radarApiToken = Deno.env.get("RADAR_API_TOKEN") ?? "216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO";

    if (!radarUser || !radarPassword || !radarApiToken) {
      throw new Error("Credenciais da API Radar não configuradas.");
    }

    const basicAuth = btoa(`${radarUser}:${radarPassword}`);

    let todasConsultas: any[] = [];
    const normalizedParam = (param ?? "").toLowerCase();
    const normalizedValue = (value ?? "").replace(/[^A-Za-z0-9]/g, "").toUpperCase();

    // Se estiver buscando um veículo específico, busca páginas para cobrir todo o histórico
    const maxPages = (param && value) ? 10 : 1;

    for (let p = 1; p <= maxPages; p++) {
      const listParams = new URLSearchParams();
      listParams.append("page", p.toString());
      listParams.append("forpage", "100");
      if (param && value) {
        listParams.append("param", normalizedParam);
        listParams.append("value", value);
      }

      const listResponse = await fetch("https://www.radarconsultas.com.br/rdrv2/api/consultas/list", {
        method: "POST",
        headers: {
          "Authorization": `Basic ${basicAuth}`,
          "api-token": radarApiToken,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: listParams.toString(),
      });

      const listData = await listResponse.json();
      if (listData?.erro) break;

      const items = listData?.consultas;
      if (!items || !Array.isArray(items) || items.length === 0) {
        break;
      }

      todasConsultas = todasConsultas.concat(items);

      if (param && value) {
        const achou = items.some((c: any) => {
          const itemVal = (c.parametro_valor ?? "").toString().replace(/[^A-Za-z0-9]/g, "").toUpperCase();
          return itemVal === normalizedValue;
        });
        if (achou || items.length < 100) break;
      }
    }

    let consultasFiltradas = [];

    if (param && value) {
      consultasFiltradas = todasConsultas.filter((c: any) => {
        const itemVal = (c.parametro_valor ?? "").toString().replace(/[^A-Za-z0-9]/g, "").toUpperCase();
        const itemParam = (c.parametro ?? "").toString().toLowerCase();
        return itemVal === normalizedValue && (itemParam === normalizedParam || itemParam.includes(normalizedParam) || normalizedParam.includes(itemParam) || normalizedParam.length === 0);
      });
    } else {
      consultasFiltradas = todasConsultas;
    }

    return new Response(JSON.stringify({
      sucesso: true,
      consultas: consultasFiltradas
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
