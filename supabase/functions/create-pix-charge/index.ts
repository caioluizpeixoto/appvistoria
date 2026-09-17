import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { getPixProvider } from "../shared/pix/PixProviderFactory.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  // 1. CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 2. Parse payload
    const { amount } = await req.json();

    if (!amount || amount <= 0) {
      return new Response(
        JSON.stringify({ error: 'Valor da recarga inválido.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Initialize Supabase Client (Auth context)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    // 4. Authenticate user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Usuário não autenticado.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Service Role Client to bypass RLS for inserting recharges
    const supabaseService = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 5. Get Wallet ID for the company
    const { data: wallet, error: walletError } = await supabaseService
      .from('wallets')
      .select('id')
      .eq('company_id', user.id)
      .single();

    if (walletError || !wallet) {
      return new Response(
        JSON.stringify({ error: 'Carteira não encontrada para esta empresa.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 6. Create Pending Recharge in DB
    const { data: recharge, error: rechargeError } = await supabaseService
      .from('recharges')
      .insert({
        company_id: user.id,
        user_id: user.id,
        wallet_id: wallet.id,
        amount: amount,
        status: 'pending',
        payment_method: 'pix',
        provider: Deno.env.get('PIX_PROVIDER_MODE') || 'mock'
      })
      .select()
      .single();

    if (rechargeError || !recharge) {
      throw new Error(`Erro ao criar recarga: ${rechargeError?.message}`);
    }

    // 7. Call Pix Provider
    const pixProvider = getPixProvider();
    const chargeResult = await pixProvider.createCharge(amount, user.id, recharge.id);

    // 8. Update Recharge with Pix Info
    await supabaseService
      .from('recharges')
      .update({
        txid: chargeResult.txid,
        pix_copy_paste: chargeResult.pixCopyPaste,
        qr_code_data: chargeResult.qrCodeData
      })
      .eq('id', recharge.id);

    // 9. Return success payload
    return new Response(
      JSON.stringify({
        recharge_id: recharge.id,
        txid: chargeResult.txid,
        pixCopyPaste: chargeResult.pixCopyPaste,
        qrCodeData: chargeResult.qrCodeData,
        amount: amount
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Erro na função create-pix-charge:', error);
    return new Response(
      JSON.stringify({ error: 'Erro interno ao processar a cobrança Pix.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
