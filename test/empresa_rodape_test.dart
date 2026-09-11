import 'package:flutter_test/flutter_test.dart';
import 'package:app_vistoria/core/services/empresa_rodape_helper.dart';

void main() {
  test('EmpresaRodapeInfo formatação e consistência', () {
    // 1. Indaiatuba
    const indaiatuba = EmpresaRodapeInfo(
      razaoSocial: 'ULTRA VISÃO INDAIATUBA',
      linhaEndereco: '08.420.171/0001-81 - RUA AUGUSTO DE OLIVEIRA CAMARGO, 321 - CENTRO - INDAIATUBA - SP - CEP 13330-160 - TEL (19) 3885-0007',
      linhaContato: 'SUPORTE@ULTRAVISAO.COM.BR',
    );
    expect(indaiatuba.razaoSocial, 'ULTRA VISÃO INDAIATUBA');
    expect(indaiatuba.linhaEndereco, contains('08.420.171/0001-81'));
    expect(indaiatuba.linhaEndereco, contains('(19) 3885-0007'));
    expect(indaiatuba.linhaContato, 'SUPORTE@ULTRAVISAO.COM.BR');

    // 2. Salto
    const salto = EmpresaRodapeInfo(
      razaoSocial: 'ULTRA VISÃO SALTO',
      linhaEndereco: '08.420.171/0004-24 - R. SETE DE SETEMBRO, 1111 - VILA HENRIQUE - SALTO - SP - CEP 13320-040 - TEL (11) 94705-6608',
      linhaContato: 'SALTO@ULTRAVISAO.COM.BR',
    );
    expect(salto.razaoSocial, 'ULTRA VISÃO SALTO');
    expect(salto.linhaEndereco, contains('08.420.171/0004-24'));
    expect(salto.linhaEndereco, contains('(11) 94705-6608'));
    expect(salto.linhaContato, 'SALTO@ULTRAVISAO.COM.BR');

    // 3. Monte Mor
    const monteMor = EmpresaRodapeInfo(
      razaoSocial: 'ULTRA VISÃO MONTE MOR',
      linhaEndereco: '22.931.906/0001-62 - R. CHEQUER ASSIS, 321 - JD GUANABARA - MONTE MOR - SP - CEP 13190-000 - TEL (19) 3217-7723',
      linhaContato: 'MONTEMOR@ULTRAVISAO.COM.BR',
    );
    expect(monteMor.razaoSocial, 'ULTRA VISÃO MONTE MOR');
    expect(monteMor.linhaEndereco, contains('22.931.906/0001-62'));
    expect(monteMor.linhaEndereco, contains('(19) 3217-7723'));
    expect(monteMor.linhaContato, 'MONTEMOR@ULTRAVISAO.COM.BR');
  });
}
