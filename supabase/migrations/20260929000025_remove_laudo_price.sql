-- Remove a cobrança do laudo (VEHICLE_REPORT) definindo o preço como 0.00 e desativando o serviço.
-- Mantém apenas a cobrança das pesquisas veiculares (Radar).

UPDATE public.service_prices
SET price = 0.00,
    active = false,
    updated_at = timezone('utc'::text, now())
WHERE service_code = 'VEHICLE_REPORT';
