# Análise de Código: Consultas Duplicadas na API da Radar

Aqui está a extração das partes principais do código que controlam as chamadas à API da Radar (Autocred) e a minha análise sobre o que pode estar causando as **15 pesquisas repetidas** cobrando saldo da sua carteira indevidamente.

---

## 1. O Ponto Central: `RadarService`

O arquivo `lib/features/consulta_bin/data/services/radar_service.dart` contém as seguintes lógicas:

### A Trava Inteligente (Em Memória)
```dart
    final cacheKey = '${produto}_${param}_${value.toUpperCase()}';

    if (_ongoingConsultas.containsKey(cacheKey)) {
      print('>>> [TRAVA INTELIGENTE] Consulta já em andamento para $cacheKey. Prevenindo duplicidade!');
      return await _ongoingConsultas[cacheKey]!;
    }
```
**Problema potencial:** Essa trava funciona **apenas enquanto o Future está rodando**. Assim que a requisição de rede devolve Timeout (após 60s esperando a análise técnica) ou lança um erro, a trava é solta (`_ongoingConsultas.remove(cacheKey)`). Se a UI tentar de novo logo em seguida (por exemplo, um loop no Flutter ou setState do Wizard), ele vai iniciar uma **nova** pesquisa.

### A Trava de 24h (Banco de Dados / API)
Para tentar evitar criar pesquisas repetidas, o código tenta listar o histórico primeiro:
```dart
      if (currentToken == null) {
        try {
          // Busca o histórico recente
          final recentList = await listarConsultasRadar(produto: produto, param: param, value: value);
          
          if (recent.isNotEmpty) {
              // ... valida se tem menos de 24h
              if (diff.inHours < 24) {
                isForcarNova = false;
                final tk = mostRecent['token']?.toString() ?? '';
                if (tk.isNotEmpty) {
                  currentToken = tk; // REAPROVEITA O TOKEN!
                }
              }
          }
        } catch (e) {
          if (e is TimeoutException) rethrow;
          print('Erro na trava 24h: $e'); // <-- AQUI MORA O PERIGO
        }
      }
```
**O Gande Problema:** Se o método `listarConsultasRadar` falhar por **instabilidade de rede**, falha da Edge Function (`radar-listar-consultas`) ou erro de CORS, ele cai no `catch`, imprime o erro e **continua a execução com `currentToken = null`**. O código acha que não existe histórico e manda a Radar criar uma **nova consulta, debitando créditos**.

### O Loop de Polling e Retentativas Interno
```dart
        if (emProcessamento) {
          pollingAttempts++;
          final maxTentativas = isPolling ? 2 : 12; // (12 tentativas de 5s = 60s)
          if (pollingAttempts > maxTentativas) {
            throw TimeoutException('A pesquisa foi aberta na Radar e está em análise técnica pelo Detran.');
          }
          await Future.delayed(Duration(seconds: isPolling ? 2 : 5));
          continue;
        }
```
Quando isso atinge o limite de tentativas (Detran demorando), ele dá throw `TimeoutException`.

---

## 2. A Camada de Interface (Telas que Chamam a Pesquisa)

### Arquivo: `lib/features/vistoria/presentation/screens/vistoria_wizard_screen.dart`
Quando a Vistoria abre, ou quando o usuário clica em algum botão de pesquisar:
```dart
  Future<void> _verificarStatusRadar({bool blockUI = false}) async {
    if (_isPollingRadar) return;
    _isPollingRadar = true;
    
    // ... tenta listarConsultasRadar
    // ... se não achar, ou se for pra iniciar, chama _retryRadarConsulta()
  }

  Future<void> _retryRadarConsulta({bool blockUI = false}) async {
      // ... faz o request pra consultarVeiculo()
      final veiculoApi = await service.consultarVeiculo(...);
  }
```

---

## 🕵️‍♂️ Onde as 15 Consultas Repetidas Estão Nascendo? (Meu Diagnóstico)

A cobrança duplicada da Radar ocorre sempre que a API recebe um POST sem o `consulta=TOKEN` (ou seja, criando uma pesquisa nova em vez de consultar o status de uma existente).

Baseado no código que analisamos, eis o provável cenário da falha das 15 pesquisas:

1. A placa vai para consulta, mas o Detran está **lento** e ela entra em "Análise Técnica".
2. O `RadarService` tenta fazer polling (perguntar 12x de 5 em 5 segundos) e dá Timeout.
3. O `VistoriaWizardScreen` ou o usuário **tenta novamente** (porque não carregou).
4. O `RadarService` roda a rotina da **Trava de 24h**, que tenta listar o histórico via API.
5. A API de listagem da Radar **falha ou dá timeout**, a exceção é engolida pelo bloco `catch` e o `currentToken` fica `null`.
6. Como o token não foi recuperado pelo histórico, o `_consultarDiretoRadar` manda a requisição **nova** com `forcar-nova: false`, mas **sem token**, gerando uma pesquisa totalmente nova que custa +1 crédito.
7. O loop repete e consome saldo.

### Sugestão de Solução Imediata:
Vá no arquivo `radar_service.dart`, por volta da linha 337, no bloco da Trava de 24h:
```dart
        } catch (e) {
          if (e is TimeoutException) rethrow; 
          print('Erro na trava 24h: $e');
          // VOCÊ PRECISA ADICIONAR ISSO AQUI:
          throw Exception('Não foi possível verificar o histórico de pesquisas para evitar cobrança duplicada. Tente novamente mais tarde.');
        }
```
Isso vai abortar imediatamente qualquer tentativa de criar uma pesquisa nova caso a checagem de segurança (histórico) falhe. 

Se quiser, me dê a permissão e eu mesmo aplico essa camada blindada contra dupla cobrança no `RadarService`!
