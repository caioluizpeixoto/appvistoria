const https = require('https');

https.get('https://bin.autocredcar.com.br/wsautocredcar/consultapdf.asmx?WSDL', (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log(data);
  });
}).on("error", (err) => {
  console.log("Error: " + err.message);
});
