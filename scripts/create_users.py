import urllib.request
import json

url = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/signup'
apikey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq'

users = [
    {'username': '43664222806', 'role': 'usuario'},
    {'username': '11977969000133', 'role': 'empresa'},
    {'username': '24868718000162', 'role': 'empresa'},
]

for u in users:
    username = u['username']
    role = u['role']
    email = f'{username}@appvistoria.com.br'
    password = 'Mudar123!'
    
    req = urllib.request.Request(url, method='POST')
    req.add_header('apikey', apikey)
    req.add_header('Content-Type', 'application/json')
    
    data = json.dumps({
        'email': email,
        'password': password,
        'data': {'role': role}
    }).encode('utf-8')
    
    try:
        with urllib.request.urlopen(req, data=data) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            print(f'Success {username}: {res_data.get("id")}')
    except urllib.error.HTTPError as e:
        print(f'Error {username}: {e.read().decode("utf-8")}')
