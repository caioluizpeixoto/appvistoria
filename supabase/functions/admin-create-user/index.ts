import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Client with service key to verify caller and create user
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);
    
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing Authorization header');
    const token = authHeader.replace('Bearer ', '');
    
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
    
    if (userError || !user) throw new Error('Unauthorized');
    
    const isMaster = user.user_metadata?.is_master === true || user.user_metadata?.role === 'master';
    if (!isMaster) {
      throw new Error('Acesso negado: Apenas o Master pode criar novos logins de empresas.');
    }

    const { email, password, nome, cnpj, empresa_nome } = await req.json();

    if (!email || !password || !cnpj) {
      throw new Error('Faltam parâmetros obrigatórios (email, password, cnpj).');
    }

    const { data: newUser, error: createError } = await supabaseClient.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
      user_metadata: {
        nome: nome || email.split('@')[0],
        cnpj: cnpj,
        empresa_nome: empresa_nome,
        role: 'vistoriador',
        is_master: false
      }
    });

    if (createError) {
      throw createError;
    }

    return new Response(JSON.stringify({ success: true, user: newUser.user }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
