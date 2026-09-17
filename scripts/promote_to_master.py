import sys
import urllib.request
import json

# ==============================================================================
# SCRIPT DE PROMOÇÃO DE USUÁRIO PARA PERFIL MASTER (ADMIN MASTER)
# ==============================================================================
# Uso:
#   python scripts/promote_to_master.py [username/CPF/CNPJ] [senha]
# Exemplo:
#   python scripts/promote_to_master.py 42136154800 Mudar123!
# ==============================================================================

URL_LOGIN = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/token?grant_type=password'
URL_UPDATE = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/user'
APIKEY = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq'

def promote_to_master(username: str, password: str, custom_name: str = 'Admin Master'):
    clean_user = ''.join(c for c in username if c.isdigit())
    if not clean_user:
        clean_user = username
    email = f'{clean_user}@appvistoria.com.br'

    print(f'[*] Autenticando com {email}...')

    # 1. Login para obter access_token
    req_login = urllib.request.Request(URL_LOGIN, method='POST')
    req_login.add_header('apikey', APIKEY)
    req_login.add_header('Content-Type', 'application/json')
    payload_login = json.dumps({'email': email, 'password': password}).encode('utf-8')

    try:
        with urllib.request.urlopen(req_login, data=payload_login) as resp:
            data_login = json.loads(resp.read().decode('utf-8'))
            access_token = data_login['access_token']
            user_data = data_login.get('user', {})
            current_metadata = user_data.get('user_metadata', {})
            print(f'[+] Login efetuado com sucesso! User ID: {user_data.get("id")}')
            print(f'[*] Metadados atuais: {current_metadata}')

        # 2. Atualizar user_metadata para role = 'master'
        new_metadata = dict(current_metadata)
        new_metadata['role'] = 'master'
        if 'name' not in new_metadata or not new_metadata['name']:
            new_metadata['name'] = custom_name

        req_update = urllib.request.Request(URL_UPDATE, method='PUT')
        req_update.add_header('apikey', APIKEY)
        req_update.add_header('Authorization', f'Bearer {access_token}')
        req_update.add_header('Content-Type', 'application/json')
        payload_update = json.dumps({'data': new_metadata}).encode('utf-8')

        with urllib.request.urlopen(req_update, data=payload_update) as resp_update:
            res_update = json.loads(resp_update.read().decode('utf-8'))
            print('[OK] Perfil atualizado com SUCESSO!')
            print(f'[OK] Nova role: {res_update.get("user_metadata", {}).get("role")}')
            print(f'[OK] Nome: {res_update.get("user_metadata", {}).get("name")}')
            print('O usuário agora é MASTER e tem acesso global a todos os laudos e recursos!')

    except urllib.error.HTTPError as e:
        print(f'[ERRO] HTTP {e.code}: {e.read().decode("utf-8")}')
    except Exception as e:
        print(f'[ERRO]: {e}')

if __name__ == '__main__':
    user = sys.argv[1] if len(sys.argv) > 1 else '42136154800'
    pwd = sys.argv[2] if len(sys.argv) > 2 else 'Mudar123!'
    name = sys.argv[3] if len(sys.argv) > 3 else 'Diretoria Master'
    promote_to_master(user, pwd, name)
