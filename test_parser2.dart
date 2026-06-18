import 'package:xml/xml.dart';

void main() {
  String xmlString = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetConsultaResponse xmlns="http://tempuri.org/">
      <GetConsultaResult><![CDATA[<?xml version="1.0" encoding="utf-8"?>
<retorno>
  <placa>ABC1D23</placa>
  <chassi>CHASSI123</chassi>
  <marca>FIAT</marca>
  <modelo>UNO</modelo>
</retorno>]]></GetConsultaResult>
    </GetConsultaResponse>
  </soap:Body>
</soap:Envelope>''';

  XmlDocument document = XmlDocument.parse(xmlString);
      
  final resultNodes = document.descendantElements.where((e) => 
      e.name.local.toLowerCase() == 'getconsultaresult' || 
      e.name.local.toLowerCase() == 'consultaresult');
      
  if (resultNodes.isNotEmpty) {
    final innerText = resultNodes.first.innerText.trim();
    print("Inner text starts with < ? \${innerText.startsWith('<')}");
    print("Inner text preview: \${innerText.substring(0, 30)}");
    if (innerText.startsWith('<')) {
      document = XmlDocument.parse(innerText);
      print("Parsed inner doc!");
    }
  }

  String? findTag(String tagName) {
    final matches = document.descendantElements.where((element) => 
        element.name.local.toLowerCase() == tagName.toLowerCase());
    if (matches.isNotEmpty) {
      final text = matches.first.innerText.trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  print("Placa: \${findTag('placa')}");
  print("Chassi: \${findTag('chassi')}");
}
