import urllib.request
import json

url_login = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/token?grant_type=password'
url_update = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/user'
apikey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq'

email = '11977969000133@appvistoria.com.br'
password = 'Mudar123!'

req = urllib.request.Request(url_login, method='POST')
req.add_header('apikey', apikey)
req.add_header('Content-Type', 'application/json')
data = json.dumps({'email': email, 'password': password}).encode('utf-8')

try:
    with urllib.request.urlopen(req, data=data) as response:
        res_data = json.loads(response.read().decode('utf-8'))
        token = res_data['access_token']
        print('Login success')

        req2 = urllib.request.Request(url_update, method='PUT')
        req2.add_header('apikey', apikey)
        req2.add_header('Authorization', f'Bearer {token}')
        req2.add_header('Content-Type', 'application/json')
        data2 = json.dumps({'data': {'name': 'Sumare'}}).encode('utf-8')

        with urllib.request.urlopen(req2, data=data2) as resp2:
            print('Update success')
except Exception as e:
    print('Error:', e)
    if hasattr(e, 'read'):
        print(e.read().decode('utf-8'))
