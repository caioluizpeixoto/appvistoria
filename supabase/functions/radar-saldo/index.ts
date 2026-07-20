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
    const radarUser = Deno.env.get("RADAR_USER") ?? "20401";
    const radarPassword = Deno.env.get("RADAR_PASSWORD") ?? "*Ultra541";
    const radarApiToken = Deno.env.get("RADAR_API_TOKEN") ?? "216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO";

    if (!radarUser || !radarPassword || !radarApiToken) {
      throw new Error("Credenciais da API Radar não configuradas.");
    }

    const basicAuth = btoa(`${radarUser}:${radarPassword}`);

    // Tentativa genérica de buscar saldo (substitua pela URL exata caso seja diferente)
    const response = await fetch("https://www.radarconsultas.com.br/rdrv2/api/saldo", {
      method: "GET",
      headers: {
        "Authorization": `Basic ${basicAuth}`,
        "api-token": radarApiToken,
      }
    });

    const data = await response.json();

    if (data?.erro) {
      throw new Error(data.erro);
    }

    return new Response(JSON.stringify({
      sucesso: true,
      saldo: data?.saldo ?? data?.result ?? data ?? "N/A"
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
