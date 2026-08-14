import 'package:syncfusion_flutter_pdf/pdf.dart';
void main() {
  var b1 = <int>[];
  var b2 = <int>[];
  var doc1 = PdfDocument(inputBytes: b1);
  var doc2 = PdfDocument(inputBytes: b2);
  PdfDocument.merge(doc1, doc2);
}
