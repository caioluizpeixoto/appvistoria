const https = require('https');

https.get('https://bin.autocredcar.com.br/wsautocredcar/consultapdf.asmx?WSDL', (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    const regex = /<s:element name="GetConsulta">([\s\S]*?)<\/s:element>/;
    const match = data.match(regex);
    if (match) {
      console.log(match[0]);
    } else {
      console.log("GetConsulta element not found");
    }
  });
}).on("error", (err) => {
  console.log("Error: " + err.message);
});
