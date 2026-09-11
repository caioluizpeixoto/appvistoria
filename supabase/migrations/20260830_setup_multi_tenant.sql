-- Migração Multi-Tenant (Auto-Sync)
-- Criação das tabelas de Clientes e Vistoriadores vinculadas ao usuário logado

-- 1. Tabela: clientes_cloud
CREATE TABLE IF NOT EXISTS public.clientes_cloud (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    cpf_cnpj TEXT,
    email TEXT,
    telefone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabela: vistoriadores_cloud
CREATE TABLE IF NOT EXISTS public.vistoriadores_cloud (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    cpf TEXT,
    unidade_nome TEXT,
    unidade_cnpj TEXT,
    cargo TEXT DEFAULT 'vistoriador',
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Habilitar RLS (Row Level Security)
ALTER TABLE public.clientes_cloud ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vistoriadores_cloud ENABLE ROW LEVEL SECURITY;

-- Se a tabela vistorias_cloud não existir, criamos ela agora:
CREATE TABLE IF NOT EXISTS public.vistorias_cloud (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    numero_laudo TEXT,
    placa TEXT,
    chassi TEXT,
    status TEXT,
    tipo_vistoria TEXT,
    dados_completos JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS:
ALTER TABLE public.vistorias_cloud ENABLE ROW LEVEL SECURITY;

-- 4. Criar Políticas de Segurança (Policies)
-- Apenas o usuário que criou o dado pode visualizar, atualizar e deletar.

-- Clientes
DROP POLICY IF EXISTS "Usuários veem apenas seus próprios clientes" ON public.clientes_cloud;
CREATE POLICY "Usuários veem apenas seus próprios clientes" 
    ON public.clientes_cloud FOR ALL 
    USING (auth.uid() = user_id) 
    WITH CHECK (auth.uid() = user_id);

-- Vistoriadores
DROP POLICY IF EXISTS "Usuários veem apenas seus próprios vistoriadores" ON public.vistoriadores_cloud;
CREATE POLICY "Usuários veem apenas seus próprios vistoriadores" 
    ON public.vistoriadores_cloud FOR ALL 
    USING (auth.uid() = user_id) 
    WITH CHECK (auth.uid() = user_id);

-- Vistorias
DROP POLICY IF EXISTS "Usuários veem apenas suas próprias vistorias" ON public.vistorias_cloud;
CREATE POLICY "Usuários veem apenas suas próprias vistorias" 
    ON public.vistorias_cloud FOR ALL 
    USING (auth.uid() = user_id) 
    WITH CHECK (auth.uid() = user_id);
