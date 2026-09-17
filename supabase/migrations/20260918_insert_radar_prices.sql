-- ==============================================================================
-- MIGRATION: 20260918_insert_radar_prices.sql
-- DESCRIÇÃO: Insere/Atualiza a tabela service_prices com os novos valores para
-- as pesquisas da Radar Consultas.
-- ==============================================================================

INSERT INTO public.service_prices (service_code, name, price, active)
VALUES 
    ('auto_bin', 'Auto bin', 7.66, true),
    ('bin_por_motor', 'Pesquisa de motor', 7.90, true),
    ('auto_pericia', 'Auto perícia', 35.80, true),
    ('auto_pericia_hrf', 'Auto perícia HRF', 28.90, true),
    ('auto_completa', 'Auto completa', 60.91, true),
    ('auto_leilao', 'Auto leilão', 21.24, true)
ON CONFLICT (service_code) DO UPDATE SET 
    price = EXCLUDED.price,
    name = EXCLUDED.name;
