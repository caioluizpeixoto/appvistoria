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

    const listParams = new URLSearchParams();
    listParams.append("page", "1");
    listParams.append("forpage", "100"); // Obter as últimas 100 consultas

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

    if (listData?.erro) {
      throw new Error(listData.erro);
    }

    let consultasFiltradas = [];

    if (listData?.consultas && Array.isArray(listData.consultas)) {
      if (param && value) {
        const normalizedParam = param.toLowerCase();
        const normalizedValue = value.replace(/[^A-Za-z0-9]/g, "");

        consultasFiltradas = listData.consultas.filter((c: any) => 
          c.parametro_valor?.toUpperCase() === normalizedValue.toUpperCase() &&
          c.parametro?.toLowerCase() === normalizedParam
        );
      } else {
        consultasFiltradas = listData.consultas;
      }
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
