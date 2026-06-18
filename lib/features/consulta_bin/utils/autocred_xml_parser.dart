import 'package:xml/xml.dart';
import '../domain/entities/autocred_veiculo.dart';

class AutoCredXmlParser {
  static AutoCredVeiculo parse(String xmlString) {
    try {
      XmlDocument document = XmlDocument.parse(xmlString);
      
      // Em muitas APIs SOAP, o XML real vem como uma string codificada dentro de <GetConsultaResult>
      final resultNodes = document.descendantElements.where((e) => 
          e.name.local.toLowerCase() == 'getconsultaresult' || 
          e.name.local.toLowerCase() == 'consultaresult');
          
      if (resultNodes.isNotEmpty) {
        final innerText = resultNodes.first.innerText.trim();
        // Se o texto dentro de GetConsultaResult for um XML embutido, parseamos ele
        if (innerText.startsWith('<')) {
          try {
            document = XmlDocument.parse(innerText);
          } catch (_) {
            // Se falhar, mantém o documento original
          }
        }
      }

      // Helper para buscar texto da tag ignorando case e namespace
      String? findTag(String tagName) {
        final matches = document.descendantElements.where((element) => 
            element.name.local.toLowerCase() == tagName.toLowerCase());
        if (matches.isNotEmpty) {
          final text = matches.first.innerText.trim();
          return text.isEmpty ? null : text;
        }
        return null;
      }

      final placa = findTag('placa') ?? findTag('placaveiculo') ?? '';
      
      // Se não houver placa, pode ser que o XML venha em outro formato ou indique erro
      return AutoCredVeiculo(
        placa: placa,
        chassi: findTag('chassi'),
        motor: findTag('motor') ?? findTag('numeromotor'),
        marca: findTag('marca'),
        modelo: findTag('modelo') ?? findTag('marcamodelo'),
        anoFabricacao: findTag('anofabricacao') ?? findTag('anofab') ?? findTag('ano_fabricacao'),
        anoModelo: findTag('anomodelo') ?? findTag('anomod') ?? findTag('ano_modelo'),
        cor: findTag('cor'),
        renavam: findTag('renavam'),
        municipio: findTag('municipio') ?? findTag('cidade'),
        uf: findTag('uf') ?? findTag('estado'),
        restricoes: findTag('restricoes') ?? findTag('restricao') ?? findTag('ocorrencia'),
        arquivoPesquisaUrl: findTag('arquivopesquisa'),
        dadosExtras: {
          'situacao': findTag('situacao'),
          'leilao': findTag('leilao'),
          'sinistro': findTag('sinistro'),
          'msgErro': findTag('mensagemerro') ?? findTag('erro'),
        },
      );
    } catch (e) {
      throw Exception('Erro ao fazer parse do XML da AutoCredCar: $e');
    }
  }
}
