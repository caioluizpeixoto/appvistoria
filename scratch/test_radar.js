const fs = require('fs');

async function testRadar() {
  const basicAuth = btoa('20401:*Ultra541');
  const radarApiToken = '216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO';
  
  // Usando auto_completa: 21588A87D591BBD1485473749QJKNKEIFTWHHBWDJJVDNEOB76
  const tokenProduto = "21588A87D591BBD1485473749QJKNKEIFTWHHBWDJJVDNEOB76";

  const bodyParams = new URLSearchParams();
  bodyParams.append("produto", tokenProduto);
  bodyParams.append("param", "placa");
  bodyParams.append("value", "BXZ2I08");
  bodyParams.append("aguardar-retorno", "true");

  console.log('Consultando API Radar...');
  const response = await fetch("https://www.radarconsultas.com.br/rdrv2/api/consultar", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${basicAuth}`,
      "api-token": radarApiToken,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: bodyParams.toString(),
  });

  const data = await response.json();
  fs.writeFileSync('C:\\Users\\Caio\\Desktop\\app_vistoria\\radar_dump.json', JSON.stringify(data, null, 2));
  console.log('Concluído. Veja radar_dump.json');
}

testRadar().catch(console.error);
