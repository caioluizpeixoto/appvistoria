import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final basicAuth = base64Encode(utf8.encode('20401:*Ultra541'));
  
  final res = await http.post(
    Uri.parse('https://www.radarconsultas.com.br/rdrv2/api/consultar'),
    headers: {
      'Authorization': 'Basic $basicAuth',
      'api-token': '216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'produto': '21589A1C74E953B1486494836NQ70TJ0EUZFTS9K7GGLAMHKOJ',
      'param': 'placa',
      'value': 'GFO5385',
      'aguardar-retorno': 'true'
    }
  );
  
  print('Result:');
  print(res.body);
}
