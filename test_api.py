import requests
import json

url = "https://cmcpmppgpbrufrxznost.supabase.co/functions/v1/gerar-ficha-veiculo"
payload = {
    "brand": "FIAT",
    "model": "PUNTO",
    "year": 2014,
    "version": "1.4 ATTRACTIVE 8V FLEX 4P MANUAL",
    "fuel": "FLEX",
    "engine": "1.4",
    "apontamentos": []
}

try:
    response = requests.post(url, json=payload, timeout=45)
    print("Status:", response.status_code)
    data = response.json()
    
    with open("test_resp.json", "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print("Success! Saved to test_resp.json")
except Exception as e:
    print("Error:", e)
