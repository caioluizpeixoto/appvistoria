import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const reqIdLog = crypto.randomUUID().split('-')[0];
  const log = (msg: string, data?: any) => {
    console.log(`[${reqIdLog}] ${msg}`, data ? JSON.stringify(data) : '');
  };

  try {
    const { 
      vistoriaId, 
      empresaId, 
      produto, 
      param, 
      value, 
      forcarNova, 
      tokenConsulta, 
      aguardarRetorno,
      idPesquisaClient
    } = await req.json();

    if (!produto || !param || !value) {
      throw new Error("Parâmetros 'produto', 'param' e 'value' são obrigatórios.");
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error("Autorização ausente.");
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
      throw new Error("Configuração do servidor ausente.");
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });
    
    // Cliente admin para garantir atualizações de status mesmo se o usuário perder permissão
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      throw new Error("Usuário não autenticado.");
    }
    const userId = user.id;

    const produtosMap: Record<string, string> = {
      "numero_crv": "21696E59C08FB7F176883961615M79UH32B1WOVGJHFY255O0I",
      "codigo_crv": "21697118FF9B1101769019647Q5BFBB9FWVUYXKE9DRDLFYWFZ",
      "auto_completa": "21588A87D591BBD1485473749QJKNKEIFTWHHBWDJJVDNEOB76",
      "auto_bin": "21589A1C74E953B1486494836NQ70TJ0EUZFTS9K7GGLAMHKOJ",
      "auto_base_estadual": "21589C4F6FE5D851486638959Z74PAKY8WJ4M8EF5LQB945K5N",
      "auto_pericia": "2158B04671523351487947377ALQNCW8LN4VGIJHLHSFJDD5G9",
      "auto_leilao": "2158DD027974724149087909770OG7270OE8LK17N7RET0LSJ3",
      "auto_estadual_proprietario": "2158DE583B7654714909665876FV8VSPNER2DHLZR81SPVLMZ0",
      "auto_decodificador_chassi": "2158F0F1EF0ADB11492185583PRLK042XHWPU83FX7V5DJ8MRT",
      "auto_gravame": "2158FA1C23B8B8C1492786211KU65H6GRCDCNNLXZARBEQRLGY",
      "auto_debitos_recall": "2159EA6BFB60104150853529156RSGFTC62RP1XWPKV9CT99P1",
      "auto_analise": "215C7D7C9C6A8151551727772AXVADBADNQZAWS5M9SLVVF0R1",
      "auto_analise_plus": "215C7D7D8400EAB1551728004RDCEG7NQ58EGUG34O9O4ATTRI",
      "auto_pericia_hrf": "2162AB9E27B63CD1655414311NO8UOXTCZ2SC4CW1L75PRFEVN",
      "bin_por_motor": "2162E98433071ED165947089995HQEQV32WR95PCLFIHJS2AOD",
      "e_crlv_nova": "216952A87095C431767024752XO8PQAC1LARXMPKCF9J3DQ428",
    };

    const tokenProduto = produtosMap[produto];
    if (!tokenProduto) {
      throw new Error(`Produto não encontrado: ${produto}`);
    }

    const radarUser = Deno.env.get("RADAR_USER") ?? "20401";
    const radarPassword = Deno.env.get("RADAR_PASSWORD") ?? "*Ultra541";
    const radarApiToken = Deno.env.get("RADAR_API_TOKEN") ?? "216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO";
    const basicAuth = btoa(`${radarUser}:${radarPassword}`);

    const normalizedParam = param.toLowerCase();
    const normalizedValue = value.replace(/[^A-Za-z0-9]/g, "").toUpperCase();
    const dataHoje = new Date().toISOString().split('T')[0];
    
    // Gerar idempotency_key super robusta
    const uniquePrefix = vistoriaId ? `vistoria:${vistoriaId}` : `avulsa:${empresaId || userId}`;
    const baseKey = `radar:${uniquePrefix}:${produto}:${normalizedParam}:${normalizedValue}`;
    // Se for forçada, usa o idPesquisa do cliente, garantindo que retries do flutter não criem novas, mas novos clicks sim.
    const idempotencyKey = forcarNova && idPesquisaClient ? `${baseKey}:force:${idPesquisaClient}` : `${baseKey}:${dataHoje}`;

    let currentToken = tokenConsulta;
    let reused = false;
    let requestId = null;
    let existingData = null;

    if (!currentToken) {
      log("Iniciando lock de Idempotência:", { idempotencyKey });
      const { data: insertedData, error: insertError } = await supabase
        .from('radar_requests')
        .insert({
          idempotency_key: idempotencyKey,
          vistoria_id: vistoriaId || null,
          user_id: userId,
          company_id: empresaId || null,
          produto: produto,
          param: normalizedParam,
          value: normalizedValue,
          status: 'creating'
        })
        .select('id')
        .single();

      if (insertError) {
        if (insertError.code === '23505') { // UNIQUE VIOLATION
          log("Idempotency Key já existe. Buscando estado atual.");
          const { data: exData } = await supabase
            .from('radar_requests')
            .select('*')
            .eq('idempotency_key', idempotencyKey)
            .single();

          if (exData) {
            reused = true;
            existingData = exData;
            requestId = exData.id;
            log(`Estado atual encontrado: ${existingData.status}`);
            
            if (existingData.status === 'creating') {
              return new Response(JSON.stringify({
                sucesso: true,
                emProcessamento: true,
                reused: true,
                tokenConsulta: null,
                message: "A pesquisa está sendo criada por outro processo."
              }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
            }
            if (existingData.status === 'processing') {
              currentToken = existingData.radar_token;
            }
            if (existingData.status === 'completed') {
              let reparsed = existingData.parsed_data;
              try {
                if (existingData.raw_response) {
                  reparsed = parseRadarData(existingData.raw_response);
                }
              } catch (e) {
                // Keep old data if re-parse fails
              }

              return new Response(JSON.stringify({
                sucesso: true,
                reused: true,
                parsed: reparsed,
                raw: existingData.raw_response
              }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
            }
            if (existingData.status === 'failed_before_create' || existingData.status === 'error') {
              log("Pesquisa anterior falhou sem cobrar. Permitindo nova tentativa.");
              const { data: updatedData } = await supabase
                .from('radar_requests')
                .update({ status: 'creating', error_message: null })
                .eq('id', existingData.id)
                .eq('status', existingData.status)
                .select('id')
                .single();
                
              if (updatedData) {
                 reused = false; 
                 requestId = updatedData.id;
              } else {
                 return new Response(JSON.stringify({ sucesso: false, error: "Conflito de concorrência ao retomar pesquisa." }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
              }
            }
            if (existingData.status === 'creation_unknown') {
              log("Pesquisa em estado creation_unknown. Iniciando recuperação rigorosa.");
              try {
                 const listarResponse = await fetch("https://www.radarconsultas.com.br/rdrv2/api/consultas/listar", {
                    method: "POST",
                    headers: {
                      "Authorization": `Basic ${basicAuth}`,
                      "api-token": radarApiToken,
                      "Content-Type": "application/x-www-form-urlencoded",
                    },
                    body: new URLSearchParams({ param: normalizedParam, value: normalizedValue }).toString(),
                 });
                 const listarData = await listarResponse.json();
                 
                 let candidateTokens = [];
                 if (listarData?.consultas && Array.isArray(listarData.consultas)) {
                    const tenMinutesAgo = new Date(Date.now() - 10 * 60000);
                    
                    for (const c of listarData.consultas) {
                       const tProd = c.codigo_produto?.toString() || c.produto?.toString();
                       const cData = c.data_inclusao || c.data; // Formato de data da Radar
                       
                       // Checagem rigorosa: mesmo produto e data recente
                       if (tProd === tokenProduto || tProd === produto) {
                          // Tenta parsear a data (se existir)
                          let isRecent = true;
                          if (cData) {
                             // Algumas APIs retornam DD/MM/YYYY HH:mm:ss, outras ISO. Fazemos o melhor esforço:
                             // Para simplificar: se não puder ler, confia. Se puder ler, exige ser recente.
                             const parsedDate = new Date(cData);
                             if (!isNaN(parsedDate.getTime())) {
                                isRecent = parsedDate >= tenMinutesAgo;
                             }
                          }
                          
                          if (isRecent && c.token) {
                             candidateTokens.push(c.token);
                          }
                       }
                    }
                 }
                 
                 if (candidateTokens.length === 1) {
                    const recoveredToken = candidateTokens[0];
                    log(`Único token candidato encontrado. Recuperação validada: ${recoveredToken}`);
                    await supabaseAdmin.from('radar_requests').update({
                      status: 'processing',
                      radar_token: recoveredToken,
                      error_message: 'Recuperado de creation_unknown com segurança'
                    }).eq('id', requestId);
                    currentToken = recoveredToken;
                 } else if (candidateTokens.length > 1) {
                    log("MÚLTIPLOS candidatos encontrados. Recuperação abortada para evitar erro.", candidateTokens);
                    throw new Error("Recuperação bloqueada: múltiplas consultas candidatas. Contate o suporte.");
                 } else {
                    log("Nenhum token recente encontrado no histórico. Marcando como failed_before_create para permitir estorno/nova tentativa.");
                    // Opcionalmente, poderíamos estornar aqui. Mas preferimos manter creation_unknown até certeza,
                    // ou deixar tentar de novo. O usuário pediu: "manter creation_unknown".
                    throw new Error("Aguardando confirmação de recebimento pela Radar. Tente novamente em 2 minutos pelo Histórico.");
                 }
              } catch (recovErr) {
                 throw new Error(recovErr.message || "Tentando recuperar status da Radar. Aguarde.");
              }
            }
          }
        } else {
          log("Erro de BD inesperado", insertError);
          throw new Error(`Falha de BD: ${insertError?.message || 'Desconhecido'} (Code: ${insertError?.code || 'N/A'})`);
        }
      } else {
        requestId = insertedData.id;
      }
    } else {
       // É polling explícito com token, mas precisamos do requestId para marcar completo
       const { data: exData } = await supabaseAdmin.from('radar_requests').select('id, status').eq('radar_token', currentToken).maybeSingle();
       if (exData) {
          requestId = exData.id;
          reused = true; // pois o Flutter já fez a criação antes
       }
    }

    let data: any = null;

    if (currentToken) {
      log(`Polling consulta existente: ${currentToken}`);
      const detalhesParams = new URLSearchParams();
      detalhesParams.append("consulta", currentToken);

      try {
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
      } catch (e) {
        throw new Error("Erro de conexão ao consultar status na Radar.");
      }
    } else if (!reused) {
      // ===== 1. AUTORIZAR E DEDUZIR SALDO *ANTES* DA RADAR =====
      let authorized = false;
      let friendlyName = produto;
      try {
         // Compatibilidade Retroativa: Apps antigos não enviam idPesquisaClient e fazem o débito no frontend.
         // Para evitar débito duplo (frontend + backend), se não houver idPesquisaClient, nós NÃO debitamos aqui.
         if (idPesquisaClient) {
             log("Verificando saldo e autorizando operação no Backend...", { idPesquisaClient });
             const authRes = await supabase.rpc('authorize_paid_operation', {
               p_service_code: produto,
               p_reference_type: 'radar_pesquisa',
               p_reference_id: idPesquisaClient, // Usa o UUID do app, trava perfeitamente o frontend
               p_description: `Pesquisa ${friendlyName} (${normalizedParam.toUpperCase()}: ${normalizedValue})`
             });
             if (authRes.data && authRes.data.allowed === true) {
                authorized = true;
                log("Operação financeira autorizada/reservada com sucesso no backend.");
             } else {
                log("Saldo insuficiente ou bloqueado.", authRes.data);
                await supabaseAdmin.from('radar_requests').update({ status: 'failed_before_create', error_message: 'Saldo insuficiente ou restrito.' }).eq('id', requestId);
                throw new Error(authRes.data?.reason || "Saldo insuficiente para realizar a pesquisa.");
             }
         } else {
             log("AVISO: App antigo detectado (idPesquisaClient ausente). Deixando a autorização para o Frontend.");
             authorized = true;
         }
      } catch (errDebit) {
         if (errDebit.message?.includes("Saldo insuficiente")) throw errDebit;
         log("Erro de BD na autorização.", errDebit);
         await supabaseAdmin.from('radar_requests').update({ status: 'failed_before_create', error_message: 'Erro interno de faturamento.' }).eq('id', requestId);
         throw new Error("Sistema de faturamento indisponível no momento. Tente novamente.");
      }

      // ===== 2. CHAMAR A RADAR =====
      log("RADAR_PAID_REQUEST_STARTED", { idempotencyKey, param: normalizedParam, value: normalizedValue, produto });
      const bodyParams = new URLSearchParams();
      bodyParams.append("produto", tokenProduto);
      bodyParams.append("param", normalizedParam);
      bodyParams.append("value", normalizedValue);
      const aguardar = aguardarRetorno ?? true;
      bodyParams.append("aguardar-retorno", aguardar ? "true" : "false");
      
      try {
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
      } catch (e) {
        log("Network Timeout após POST para Radar. Mudando para creation_unknown", { error: e.toString() });
        // O dinheiro FOI cobrado! Ficará em creation_unknown.
        // O próximo acesso tentará puxar do /listar. Se não conseguir recuperar nunca,
        // o suporte terá que analisar. Não estornamos porque não temos certeza absoluta se a Radar falhou ou passou.
        if (requestId) {
          await supabaseAdmin.from('radar_requests').update({ 
            status: 'creation_unknown',
            error_message: e.toString()
          }).eq('id', requestId);
        }
        throw new Error("Timeout na comunicação com a Radar. O sistema tentará recuperar automaticamente. Aguarde 2 minutos no Histórico.");
      }
    }

    if (data?.erro || (data?.result === 0 && data?.message)) {
      const errM = data.erro || data.message;
      if (requestId && !reused) {
         log(`API da Radar recusou a consulta: ${errM}.`);
         // Radar retornou erro explícito = Radar NÃO COBROU.
         // Se o app for novo, estornamos o que cobramos. Se for antigo, não fizemos débito prévio.
         if (idPesquisaClient) {
             try {
                 await supabaseAdmin.rpc('refund_paid_operation', { p_reference_id: idPesquisaClient, p_reason: `Estorno: ${errM}` });
                 log("Estorno concluído com sucesso.");
             } catch (refErr) {
                 log("ERRO CRÍTICO AO ESTORNAR!", refErr);
             }
         }
         await supabaseAdmin.from('radar_requests').update({ status: 'failed_before_create', error_message: errM }).eq('id', requestId);
      }
      throw new Error(errM);
    }

    const isPolling = !!currentToken;
    let emProcessamento = false;
    let returnedToken = currentToken;

    if (isPolling) {
      if (!data?.consulta || data.consulta.status !== 1) {
        emProcessamento = true;
      }
    } else {
      if (data?.["token-consulta"]) {
        emProcessamento = true;
        returnedToken = data["token-consulta"];
      } else if (data?.consulta?.token) {
        returnedToken = data.consulta.token;
        if (data.consulta.status !== 1) {
          emProcessamento = true;
        }
      }
    }

    // A REQUISIÇÃO FOI CRIADA COM SUCESSO NA RADAR. SALVAMOS O TOKEN. O DÉBITO JÁ FOI FEITO.
    if (!isPolling && !reused && returnedToken && requestId) {
       log("Consulta criada na Radar. Salvando token.", { returnedToken });
       
       await supabaseAdmin.from('radar_requests').update({
         radar_token: returnedToken,
         status: 'processing'
       }).eq('id', requestId);
    }

    if (emProcessamento) {
      return new Response(JSON.stringify({
        sucesso: true,
        emProcessamento: true,
        tokenConsulta: returnedToken,
        reused: reused, // Flutter usa para não inserir duplicata local
        raw: data
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    function parseRadarData(rawObj: any) {
      let rDataMerged: any = {};
      let ipvaData: any[] = [];
      let multasData: any[] = [];
      let renajudData: any[] = [];

      const resultados = rawObj?.consulta?.resultados;
      if (Array.isArray(resultados)) {
        for (const item of resultados) {
          const rData = item?.retorno?.data || item?.retorno;
          if (rData) {
            const rDataLower: any = {};
            for (const key in rData) {
              if (Object.prototype.hasOwnProperty.call(rData, key)) {
                rDataLower[key.toLowerCase()] = rData[key];
              }
            }
            if (rDataLower.placa && !rDataMerged.placa) {
              rDataMerged = { ...rDataMerged, ...rDataLower };
            } else {
              rDataMerged = { ...rDataLower, ...rDataMerged };
            }
            if (Array.isArray(rDataLower.ipva)) ipvaData = rDataLower.ipva;
            if (Array.isArray(rDataLower.multas)) multasData = rDataLower.multas;
            if (Array.isArray(rDataLower.renajud)) renajudData = rDataLower.renajud;
          }
        }
      } else if (rawObj) {
        for (const key in rawObj) {
          if (Object.prototype.hasOwnProperty.call(rawObj, key)) {
            rDataMerged[key.toLowerCase()] = rawObj[key];
          }
        }
      }

      if (ipvaData.length > 0) rDataMerged.ipva = ipvaData;
      if (multasData.length > 0) rDataMerged.multas = multasData;
      if (renajudData.length > 0) rDataMerged.renajud = renajudData;
      rDataMerged.resultados_completos = resultados;

      return {
        placa: rDataMerged.placa || "",
        renavam: rDataMerged.renavam || "",
        chassi: rDataMerged.chassi || "",
        anoFabricacao: rDataMerged.anofabricacaoveiculo || rDataMerged.anofabricacao || "",
        anoModelo: rDataMerged.anomodeloveiculo || rDataMerged.anomodelo || "",
        marcaModelo: rDataMerged.marcamodelo || rDataMerged.marca_modelo || "",
        cor: rDataMerged.cor || "",
        combustivel: rDataMerged.combustivel || rDataMerged.tipocombustivel || "",
        tipoVeiculo: rDataMerged.tipoveiculo || "",
        especie: rDataMerged.especie || "",
        categoria: rDataMerged.categoria || "",
        motor: rDataMerged.numerodomotor || rDataMerged.motor || "",
        situacao: rDataMerged.situacao || "",
        municipio: rDataMerged.municipio || "",
        estado: rDataMerged.estado || rDataMerged.uf || "",
        proprietario: rDataMerged.nomeproprietario || rDataMerged.proprietario || "",
        documentoProprietario: rDataMerged.documentoproprietario || "",
        restricoes1: rDataMerged.restricoes1 || "",
        restricoes2: rDataMerged.restricoes2 || "",
        restricoes3: rDataMerged.restricoes3 || "",
        restricoes4: rDataMerged.restricoes4 || "",
        informacoesRelevantes: rDataMerged.informacoesrelevantes || rDataMerged.informacoesrelevantes || "",
        ipva: ipvaData,
        multas: multasData,
        renajud: renajudData,
        radar_pdf_url: rawObj?.consulta?.view?.full || rawObj?.consulta?.resultados?.[0]?.view?.full || "",
        resultadoCompleto: rDataMerged,
      };
    }

    const parsedData = parseRadarData(data);

    if (requestId) {
      await supabaseAdmin.from('radar_requests').update({
        status: 'completed',
        raw_response: data,
        parsed_data: parsedData
      }).eq('id', requestId);
    }

    return new Response(JSON.stringify({
      sucesso: true,
      reused: reused,
      raw: data,
      parsed: parsedData
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
