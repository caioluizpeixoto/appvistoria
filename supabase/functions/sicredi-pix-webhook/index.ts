import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  // 1. CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Apenas aceitamos POST no webhook
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  try {
    const payload = await req.json();
    console.log('Webhook Recebido:', JSON.stringify(payload));

    // Validar payload mínimo do Sicredi / Mock
    // O payload do Sicredi (Pix) geralmente vem com array 'pix' contendo as cobranças pagas
    if (!payload.pix || !Array.isArray(payload.pix) || payload.pix.length === 0) {
      return new Response(JSON.stringify({ error: 'Formato de payload inválido.' }), { status: 400 });
    }

    const supabaseService = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Processamos cada transação no payload
    for (const item of payload.pix) {
      const txid = item.txid;
      const endToEndId = item.endToEndId;
      // const valor = item.valor; // Caso seja necessário conferir exatidão de centavos no futuro

      if (!txid) {
        console.warn('Transação sem txid recebida:', item);
        continue;
      }

      // Localiza a recarga correspondente
      const { data: recharge, error: fetchError } = await supabaseService
        .from('recharges')
        .select('id, status')
        .eq('txid', txid)
        .maybeSingle();

      if (fetchError || !recharge) {
        console.warn(`Cobrança não encontrada para o txid: ${txid}`);
        continue; // Pode ser um webhook atrasado, ou cobrança não existente. Ignora com sucesso para o Sicredi não re-tentar.
      }

      if (recharge.status === 'paid') {
        console.log(`Cobrança ${txid} já foi paga anteriormente.`);
        continue;
      }

      // Chama a procedure segura (lock for update e idempotência na transação do banco)
      const { data: rpcResult, error: rpcError } = await supabaseService.rpc(
        'process_recharge_payment',
        {
          p_recharge_id: recharge.id,
          p_txid: txid,
          p_external_id: endToEndId
        }
      );

      if (rpcError) {
        console.error(`Falha ao chamar RPC process_recharge_payment para ${txid}:`, rpcError);
        // Marcamos o erro e horário em caso de falha grave
        await supabaseService
          .from('recharges')
          .update({
            error_message: rpcError.message,
            processed_at: new Date().toISOString()
          })
          .eq('id', recharge.id);
        continue;
      }

      if (rpcResult && rpcResult.success) {
        // Marca processed_at indicando que o webhook passou.
        await supabaseService
          .from('recharges')
          .update({ processed_at: new Date().toISOString() })
          .eq('id', recharge.id);
        console.log(`Pix txid ${txid} processado e creditado com sucesso!`);
      } else {
        console.warn(`RPC process_recharge_payment negou operação: ${JSON.stringify(rpcResult)}`);
      }
    }

    // Retorna 200 OK para o Sicredi confirmar o recebimento
    return new Response(JSON.stringify({ message: 'Webhook processado com sucesso' }), { 
      status: 200, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    });

  } catch (error) {
    console.error('Erro ao processar Webhook:', error);
    // Retornamos 200 proativamente na catch genérica dependendo do comportamento desejado
    // Se retornar 500, o Sicredi tentará reenviar. 
    return new Response(
      JSON.stringify({ error: 'Internal Server Error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
