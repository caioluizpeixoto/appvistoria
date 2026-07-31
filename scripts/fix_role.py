import urllib.request
import json

url_login = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/token?grant_type=password'
url_update = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/user'
apikey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq'

username = '24868718000162'
email = f'{username}@appvistoria.com.br'
password = 'Mudar123!'

try:
    # 1. Login to get token
    req = urllib.request.Request(url_login, method='POST')
    req.add_header('apikey', apikey)
    req.add_header('Content-Type', 'application/json')
    data = json.dumps({'email': email, 'password': password}).encode('utf-8')
    
    with urllib.request.urlopen(req, data=data) as response:
        res_data = json.loads(response.read().decode('utf-8'))
        access_token = res_data['access_token']
        print(f'Logged in successfully.')

    # 2. Update user metadata
    req2 = urllib.request.Request(url_update, method='PUT')
    req2.add_header('apikey', apikey)
    req2.add_header('Authorization', f'Bearer {access_token}')
    req2.add_header('Content-Type', 'application/json')
    data2 = json.dumps({'data': {'role': 'empresa', 'name': 'Vistoria Cosmopolis'}}).encode('utf-8')
    
    with urllib.request.urlopen(req2, data=data2) as response2:
        print('Metadata updated to "Vistoria Cosmopolis" successfully.')

except urllib.error.HTTPError as e:
    print(f'Error: {e.code} - {e.read().decode("utf-8")}')
except Exception as e:
    print(f'Error: {e}')
