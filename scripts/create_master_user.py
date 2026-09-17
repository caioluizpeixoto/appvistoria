import urllib.request
import json
import sys

URL_SIGNUP = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/signup'
APIKEY = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq'

def create_master_user(username, password='Mudar123!', name='Diretoria Master'):
    clean = ''.join(c for c in username if c.isdigit()) or username
    email = f'{clean}@appvistoria.com.br'
    
    req = urllib.request.Request(URL_SIGNUP, method='POST')
    req.add_header('apikey', APIKEY)
    req.add_header('Content-Type', 'application/json')
    
    data = json.dumps({
        'email': email,
        'password': password,
        'data': {
            'role': 'master',
            'name': name
        }
    }).encode('utf-8')
    
    try:
        with urllib.request.urlopen(req, data=data) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            print(f'[+] Sucesso ao criar usuário Master!')
            print(f'ID: {res_data.get("id")}')
            print(f'Email: {res_data.get("email")}')
            print(f'Metadata: {res_data.get("user_metadata")}')
    except urllib.error.HTTPError as e:
        print(f'[ERRO] HTTP {e.code}: {e.read().decode("utf-8")}')
    except Exception as e:
        print(f'[ERRO]: {e}')

if __name__ == '__main__':
    user = sys.argv[1] if len(sys.argv) > 1 else '42136154800'
    pwd = sys.argv[2] if len(sys.argv) > 2 else 'Mudar123!'
    nm = sys.argv[3] if len(sys.argv) > 3 else 'Diretoria Master'
    create_master_user(user, pwd, nm)
