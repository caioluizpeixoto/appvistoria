import 'package:supabase_flutter/supabase_flutter.dart';

class EmpresaRodapeInfo {
  final String razaoSocial;
  final String linhaEndereco;
  final String linhaContato;

  const EmpresaRodapeInfo({
    required this.razaoSocial,
    required this.linhaEndereco,
    required this.linhaContato,
  });

  static EmpresaRodapeInfo? _cachedInfo;

  static const Map<String, EmpresaRodapeInfo> empresasConhecidas = {
    '11977969000133': EmpresaRodapeInfo(
      razaoSocial: 'SUMARÉ VISTORIAS',
      linhaEndereco:
          '11.977.969/0001-33 - AV REBOUÇAS 1989 - SUMARÉ - SP - CEP 13170-275 - TEL 19 3306.8604',
      linhaContato: 'SUMARE@APPVISTORIA.COM.BR',
    ),
    '08420171000181': EmpresaRodapeInfo(
      razaoSocial: 'ULTRA VISÃO INDAIATUBA',
      linhaEndereco:
          '08.420.171/0001-81 - RUA AUGUSTO DE OLIVEIRA CAMARGO, 321 - CENTRO - INDAIATUBA - SP - CEP 13330-160 - TEL (19) 3885-0007',
      linhaContato: 'SUPORTE@ULTRAVISAO.COM.BR',
    ),
    '08420171000424': EmpresaRodapeInfo(
      razaoSocial: 'ULTRA VISÃO SALTO',
      linhaEndereco:
          '08.420.171/0004-24 - R. SETE DE SETEMBRO, 1111 - VILA HENRIQUE - SALTO - SP - CEP 13320-040 - TEL (11) 94705-6608',
      linhaContato: 'SALTO@ULTRAVISAO.COM.BR',
    ),
    '22931906000162': EmpresaRodapeInfo(
      razaoSocial: 'ULTRA VISÃO MONTE MOR',
      linhaEndereco:
          '22.931.906/0001-62 - R. CHEQUER ASSIS, 321 - JD GUANABARA - MONTE MOR - SP - CEP 13190-000 - TEL (19) 3217-7723',
      linhaContato: 'MONTEMOR@ULTRAVISAO.COM.BR',
    ),
    '24868718000162': EmpresaRodapeInfo(
      razaoSocial: 'AUTO PROVE VISTORIAS',
      linhaEndereco:
          '24.868.718/0001-62 - RUA SETE DE ABRIL 541 CENTRO COSMOPOLIS SP - CEP 13.150.610 - TEL 19 3872-1891',
      linhaContato: 'COSMOPOLIS@ULTRAVISAO.COM.BR',
    ),
  };

  /// Retorna a Razão Social pelo CNPJ limpo se cadastrada nas sementes
  static String resolverNomePorCnpj(String cnpj) {
    final limpo = cnpj.replaceAll(RegExp(r'\D'), '');
    return empresasConhecidas[limpo]?.razaoSocial ?? '';
  }

  /// Carrega as informações da empresa do banco de dados (tabela empresas)
  /// baseado no CNPJ do usuário logado ou metadados de autenticação.
  static Future<EmpresaRodapeInfo> carregarAsync() async {
    final user = Supabase.instance.client.auth.currentUser;
    var cnpj = (user?.userMetadata?['cnpj'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    
    // Se o metadado não tiver cnpj, tenta extrair do email (ex: 11977969000133@appvistoria.com.br)
    if (cnpj.isEmpty && user?.email != null) {
      final emailPrefix = user!.email!.split('@').first.replaceAll(RegExp(r'[^0-9]'), '');
      if (emailPrefix.length == 14) {
        cnpj = emailPrefix;
      }
    }

    final nomeMetadado = (user?.userMetadata?['name'] as String? ?? '').trim();

    if (cnpj.isNotEmpty) {
      try {
        final res = await Supabase.instance.client
            .from('empresas')
            .select()
            .eq('cnpj', cnpj)
            .maybeSingle();

        if (res != null) {
          _cachedInfo = EmpresaRodapeInfo(
            razaoSocial: (res['razao_social'] as String?)?.toUpperCase() ??
                (nomeMetadado.isNotEmpty ? nomeMetadado.toUpperCase() : 'EMPRESA SEM NOME'),
            linhaEndereco: res['endereco'] as String? ?? 'ENDEREÇO NÃO CADASTRADO',
            linhaContato: res['contato'] as String? ?? 'CONTATO NÃO CADASTRADO',
          );
          return _cachedInfo!;
        }
      } catch (e) {
        print('Erro ao buscar empresa no banco: $e');
      }

      // Se não encontrou no banco mas é uma empresa conhecida pelo CNPJ
      if (empresasConhecidas.containsKey(cnpj)) {
        _cachedInfo = empresasConhecidas[cnpj]!;
        return _cachedInfo!;
      }
    }

    // Se o usuário possui nome cadastrado em user_metadata, usa esse nome
    if (nomeMetadado.isNotEmpty && !nomeMetadado.toLowerCase().contains('vistoria')) {
      _cachedInfo = EmpresaRodapeInfo(
        razaoSocial: nomeMetadado.toUpperCase(),
        linhaEndereco: cnpj.isNotEmpty ? 'CNPJ: $cnpj' : 'ENDEREÇO NÃO CADASTRADO',
        linhaContato: user?.email ?? 'CONTATO NÃO CADASTRADO',
      );
      return _cachedInfo!;
    } else if (nomeMetadado.isNotEmpty) {
      _cachedInfo = EmpresaRodapeInfo(
        razaoSocial: nomeMetadado.toUpperCase(),
        linhaEndereco: cnpj.isNotEmpty ? 'CNPJ: $cnpj' : 'ENDEREÇO NÃO CADASTRADO',
        linhaContato: user?.email ?? 'CONTATO NÃO CADASTRADO',
      );
      return _cachedInfo!;
    }

    // Fallback padrão se realmente não houver nenhuma identificação
    _cachedInfo = const EmpresaRodapeInfo(
      razaoSocial: 'APP VISTORIA',
      linhaEndereco: 'SISTEMA DE VISTORIAS VEICULARES',
      linhaContato: 'SUPORTE@APPVISTORIA.COM.BR',
    );
    return _cachedInfo!;
  }

  /// Retorna as informações cacheadas para uso síncrono (ex: gerador de PDF)
  static EmpresaRodapeInfo obterAtual() {
    if (_cachedInfo != null) return _cachedInfo!;

    final user = Supabase.instance.client.auth.currentUser;
    var cnpj = (user?.userMetadata?['cnpj'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (cnpj.isEmpty && user?.email != null) {
      final emailPrefix = user!.email!.split('@').first.replaceAll(RegExp(r'[^0-9]'), '');
      if (emailPrefix.length == 14) cnpj = emailPrefix;
    }

    if (cnpj.isNotEmpty && empresasConhecidas.containsKey(cnpj)) {
      _cachedInfo = empresasConhecidas[cnpj]!;
      return _cachedInfo!;
    }

    final nomeMetadado = (user?.userMetadata?['name'] as String? ?? '').trim();
    if (nomeMetadado.isNotEmpty) {
      _cachedInfo = EmpresaRodapeInfo(
        razaoSocial: nomeMetadado.toUpperCase(),
        linhaEndereco: cnpj.isNotEmpty ? 'CNPJ: $cnpj' : 'ENDEREÇO NÃO CADASTRADO',
        linhaContato: user?.email ?? 'CONTATO NÃO CADASTRADO',
      );
      return _cachedInfo!;
    }

    return const EmpresaRodapeInfo(
      razaoSocial: 'APP VISTORIA',
      linhaEndereco: 'CARREGANDO...',
      linhaContato: 'CARREGANDO...',
    );
  }
}
