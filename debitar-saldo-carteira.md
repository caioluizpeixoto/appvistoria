# Plano de Execução: Débito de Saldo da Carteira

> **Status:** Aguardando aprovação do usuário  
> **Data:** 20/09/2026  
> **Objetivo:** Ativar cobrança financeira e debitar saldo em pesquisas avulsas, troca de tipos de consulta e emissão de laudo em PDF pela primeira vez por placa.

---

## 1. Visão Geral das Regras de Negócio

1. **Pesquisa Avulsa**:
   - Cada consulta nova (`forcarNova: true` ou primeira vez que o parâmetro é buscado) debita o valor do produto escolhido da carteira.
   - Atualização visual imediata do saldo na Home e na Carteira.
2. **Troca do Tipo de Pesquisa**:
   - Chave de idempotência composta: `${produto}:${valor}` (ex: `auto_bin:ABC1234` vs `auto_pericia:ABC1234`).
   - Se o vistoriador consultar uma nova modalidade para o mesmo veículo, o sistema debita a nova modalidade. Se repetir a mesma que já foi paga, não debita.
3. **Primeira Emissão do Laudo em PDF**:
   - Ao concluir a vistoria e gerar o laudo pela 1ª vez para a placa, debita `VEHICLE_REPORT` (R$ 15,00).
   - Reemissões, 2ª via ou correções da mesma placa não são cobradas novamente (`already_processed: true`).
4. **Tolerância e Saldo Negativo**:
   - Se o cliente estiver com saldo menor que o serviço, o sistema permite até 2 operações no negativo (tolerância).
   - Ao esgotar a tolerância, o sistema bloqueia e exibe modal direto para recarga via PIX.

---

## 2. Tarefas de Implementação

- [x] **Fase 1: Backend Supabase**
  - [x] Migration criada em `supabase/migrations/20260921_enable_wallet_enforcement.sql` para habilitar `financial_enforcement_enabled = true` em `financial_settings`.
  - [x] Tabela `service_prices` populada com valores do laudo (R$ 15,00) e dos 16 produtos Radar.
  - [x] Procedure `authorize_paid_operation` refinada com retorno de `price`, `service_name`, `already_processed` e `debited`.

- [x] **Fase 2: Carteira no Flutter (`WalletRepository`)**
  - [x] Mapeado `alreadyProcessed`, `debited`, `price` e `serviceName` no `OperationAuthorizationResult`.
  - [x] Assegurada atualização reativa no `walletNotifier` sem latência e com sync em background.

- [x] **Fase 3: Pesquisas e Troca de Tipos (`identificacao_screen.dart`, `vistoria_wizard_screen.dart` & `background_tasks_cubit.dart`)**
  - [x] Integrado `authorizePaidOperation` com chave `${produto}:${valor}` antes de chamar a Radar (foreground e background).
  - [x] Tratado caso `allowed == false` com o widget `InsufficientBalanceDialog` com atalho para recarga PIX.

- [x] **Fase 4: Emissão do Laudo em PDF (`revisao_screen.dart`)**
  - [x] Integrada autorização de débito de `VEHICLE_REPORT` com referência da placa (`laudo_pdf` / `placaLimpa`) antes de compilar o PDF.
  - [x] Bloqueio implementado se saldo e tolerância estiverem esgotados; débito realizado na 1ª vez; liberado sem custo para 2ª via/reedição.

- [x] **Fase 5: Testes e Validação**
  - [x] Análise estática com `flutter analyze` validada com 0 erros nos componentes de carteira, identificação, wizard e revisão.
