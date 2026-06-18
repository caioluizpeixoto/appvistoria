const xml = `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <ConsultaResponse xmlns="http://tempuri.org/">
      <ConsultaResult>&lt;Retorno&gt;&lt;RETORNO&gt;&lt;idPesquisa&gt;5215756&lt;/idPesquisa&gt;&lt;/RETORNO&gt;&lt;/Retorno&gt;</ConsultaResult>
    </ConsultaResponse>
  </soap:Body>
</soap:Envelope>`;

let unescapedXml = xml.replace(/&lt;/g, '<').replace(/&gt;/g, '>');
let idMatch = unescapedXml.match(/<idPesquisa>(.*?)<\/idPesquisa>/i);
console.log("ID:", idMatch ? idMatch[1] : null);
