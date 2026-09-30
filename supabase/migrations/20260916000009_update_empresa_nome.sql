-- ==============================================================================
-- UPDATE SCRIPT: Organizar Nomes das Empresas pelo CNPJ Exato
-- DESCRIÇÃO: Como muitos laudos foram salvos apenas como "ULTRA VISAO" genérico,
-- este script usa o CNPJ (que é único de cada loja) para separar corretamente.
-- ==============================================================================

-- 1. Preencher CNPJ vazio buscando do JSON (se houver)
UPDATE public.vistorias_cloud
SET empresa_cnpj = dados_completos->'vistoria'->>'unidadeCnpj'
WHERE empresa_cnpj IS NULL 
  AND dados_completos->'vistoria'->>'unidadeCnpj' IS NOT NULL;

-- 2. Padronizar nomes oficiais baseado no CNPJ (100% de precisão)
UPDATE public.vistorias_cloud SET empresa_nome = 'Ultra Visão Indaiatuba' WHERE empresa_cnpj LIKE '%08420171000181%';
UPDATE public.vistorias_cloud SET empresa_nome = 'Ultra Visão Salto'      WHERE empresa_cnpj LIKE '%08420171000424%';
UPDATE public.vistorias_cloud SET empresa_nome = 'Ultra Visão Monte Mor'  WHERE empresa_cnpj LIKE '%22931906000162%';
UPDATE public.vistorias_cloud SET empresa_nome = 'Auto Prove Vistorias'   WHERE empresa_cnpj LIKE '%24868718000162%';
UPDATE public.vistorias_cloud SET empresa_nome = 'Sumaré Vistorias'       WHERE empresa_cnpj LIKE '%11977969000133%';

-- 3. Caso o CNPJ esteja vazio, usamos as regras de texto como segurança
UPDATE public.vistorias_cloud SET empresa_nome = 'Ultra Visão Indaiatuba' WHERE empresa_nome ILIKE '%Indaiatuba%' AND empresa_nome != 'Ultra Visão Indaiatuba';
UPDATE public.vistorias_cloud SET empresa_nome = 'Ultra Visão Salto'      WHERE empresa_nome ILIKE '%Salto%' AND empresa_nome != 'Ultra Visão Salto';
UPDATE public.vistorias_cloud SET empresa_nome = 'Ultra Visão Monte Mor'  WHERE empresa_nome ILIKE '%Monte Mor%' AND empresa_nome != 'Ultra Visão Monte Mor';
UPDATE public.vistorias_cloud SET empresa_nome = 'Auto Prove Vistorias'   WHERE empresa_nome ILIKE '%Auto Prove%' AND empresa_nome != 'Auto Prove Vistorias';
UPDATE public.vistorias_cloud SET empresa_nome = 'Sumaré Vistorias'       WHERE empresa_nome ILIKE '%Sumar%' AND empresa_nome != 'Sumaré Vistorias';
