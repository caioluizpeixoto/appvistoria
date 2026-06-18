const https = require('https');

https.get('https://bin.autocredcar.com.br/wsautocredcar/consultapdf.asmx?WSDL', (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    const regex = /<s:element name="Consulta">([\s\S]*?)<\/s:element>/;
    const match = data.match(regex);
    if (match) {
      console.log(match[0]);
    } else {
      console.log("Consulta element not found");
      // Fallback: print first 2000 chars of types
      const typesMatch = data.match(/<wsdl:types>([\s\S]*?)<\/wsdl:types>/);
      if (typesMatch) console.log(typesMatch[1].substring(0, 2000));
    }
  });
}).on("error", (err) => {
  console.log("Error: " + err.message);
});
