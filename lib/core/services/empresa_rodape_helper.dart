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

  static EmpresaRodapeInfo obterAtual() {
    final user = Supabase.instance.client.auth.currentUser;
    final metaName = (user?.userMetadata?['name'] as String?)?.trim();
    final nameUpper = (metaName ?? '').toUpperCase();
    final cnpj = (user?.userMetadata?['cnpj'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final email = (user?.email ?? '').toLowerCase();

    // 1. Indaiatuba
    if (nameUpper.contains('INDAIATUBA') || cnpj == '08420171000181' || email.startsWith('08420171000181')) {
      return EmpresaRodapeInfo(
        razaoSocial: metaName?.isNotEmpty == true ? metaName!.toUpperCase() : 'ULTRA VISÃO INDAIATUBA',
        linhaEndereco: '08.420.171/0001-81 - RUA AUGUSTO DE OLIVEIRA CAMARGO, 321 - CENTRO - INDAIATUBA - SP - CEP 13330-160 - TEL (19) 3885-0007',
        linhaContato: 'SUPORTE@ULTRAVISAO.COM.BR',
      );
    }

    // 2. Salto
    if (nameUpper.contains('SALTO') || cnpj == '08420171000424' || email.startsWith('08420171000424')) {
      return EmpresaRodapeInfo(
        razaoSocial: metaName?.isNotEmpty == true ? metaName!.toUpperCase() : 'ULTRA VISÃO SALTO',
        linhaEndereco: '08.420.171/0004-24 - R. SETE DE SETEMBRO, 1111 - VILA HENRIQUE - SALTO - SP - CEP 13320-040 - TEL (11) 94705-6608',
        linhaContato: 'SALTO@ULTRAVISAO.COM.BR',
      );
    }

    // 3. Monte Mor
    if (nameUpper.contains('MONTE MOR') || cnpj == '22931906000162' || email.startsWith('22931906000162')) {
      return EmpresaRodapeInfo(
        razaoSocial: metaName?.isNotEmpty == true ? metaName!.toUpperCase() : 'ULTRA VISÃO MONTE MOR',
        linhaEndereco: '22.931.906/0001-62 - R. CHEQUER ASSIS, 321 - JD GUANABARA - MONTE MOR - SP - CEP 13190-000 - TEL (19) 3217-7723',
        linhaContato: 'MONTEMOR@ULTRAVISAO.COM.BR',
      );
    }

    // 4. Cosmópolis (Auto Prove)
    if (nameUpper.contains('COSMOPOLIS') || nameUpper.contains('AUTO PROVE') || cnpj == '24868718000162' || email.startsWith('24868718000162')) {
      return EmpresaRodapeInfo(
        razaoSocial: metaName?.isNotEmpty == true ? metaName!.toUpperCase() : 'AUTO PROVE VISTORIAS',
        linhaEndereco: '24.868.718/0001-62 - RUA SETE DE ABRIL 541 CENTRO COSMOPOLIS SP - CEP 13.150.610 - TEL 19 3872-1891',
        linhaContato: 'COSMOPOLIS@ULTRAVISAO.COM.BR',
      );
    }

    // 5. Padrão: Sumaré
    return EmpresaRodapeInfo(
      razaoSocial: metaName?.isNotEmpty == true ? metaName!.toUpperCase() : 'APP VISTORIA',
      linhaEndereco: '11.977.969/0001-33 - AV REBOUÇAS 1989 - SUMARÉ - SP - CEP 13170-275 - TEL 19 3306.8604',
      linhaContato: 'SUMARE@ULTRAVISAO.COM.BR - CREDENCIAMENTO 06/2025-3651- DETRAN SP',
    );
  }
}
