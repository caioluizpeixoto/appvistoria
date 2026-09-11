import urllib.request
import urllib.error
import json
import re

url_signup = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/signup'
url_login = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/token?grant_type=password'
url_update = 'https://cmcpmppgpbrufrxznost.supabase.co/auth/v1/user'
apikey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq'

clients = [
    {
        'name': 'Ultra Visão Indaiatuba',
        'raw_cnpj': '08420171000181',
    },
    {
        'name': 'Ultra Visão Salto',
        'raw_cnpj': '08420171000424',
    },
    {
        'name': 'Ultra Visão Monte Mor',
        'raw_cnpj': '22.931.9060001-62',
    }
]

default_password = 'Mudar123!'

print("=== INICIANDO CADASTRO DE CLIENTES CNPJ ===")

for client in clients:
    cnpj_clean = re.sub(r'[^0-9]', '', client['raw_cnpj'])
    name = client['name']
    email = f"{cnpj_clean}@appvistoria.com.br"
    
    print(f"\n--- Processando: {name} (CNPJ: {cnpj_clean}) ---")
    print(f"E-mail: {email}")
    
    # 1. Tentativa de Cadastro (signUp)
    signup_req = urllib.request.Request(url_signup, method='POST')
    signup_req.add_header('apikey', apikey)
    signup_req.add_header('Content-Type', 'application/json')
    
    signup_payload = json.dumps({
        'email': email,
        'password': default_password,
        'data': {
            'role': 'empresa',
            'name': name,
            'cnpj': cnpj_clean
        }
    }).encode('utf-8')
    
    user_created = False
    try:
        with urllib.request.urlopen(signup_req, data=signup_payload) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            user_id = data.get('id') or (data.get('user') and data.get('user').get('id'))
            print(f"[OK] Conta criada com sucesso. ID: {user_id}")
            user_created = True
    except urllib.error.HTTPError as e:
        err_body = e.read().decode('utf-8')
        if "already registered" in err_body or "User already registered" in err_body:
            print(f"[INFO] Usuário já estava cadastrado no Supabase. Atualizando metadados...")
        else:
            print(f"[ERRO] Falha no signUp: {e.code} - {err_body}")
    
    # 2. Testar Login e atualizar metadados para garantir que role e name estejam 100% corretos
    login_req = urllib.request.Request(url_login, method='POST')
    login_req.add_header('apikey', apikey)
    login_req.add_header('Content-Type', 'application/json')
    login_payload = json.dumps({
        'email': email,
        'password': default_password
    }).encode('utf-8')
    
    try:
        with urllib.request.urlopen(login_req, data=login_payload) as resp:
            login_data = json.loads(resp.read().decode('utf-8'))
            token = login_data.get('access_token')
            user_info = login_data.get('user', {})
            current_meta = user_info.get('user_metadata', {})
            print(f"[OK] Login bem-sucedido! Token obtido.")
            print(f"     Metadados atuais: {current_meta}")
            
            # Garantir atualização do nome e role se necessário
            update_req = urllib.request.Request(url_update, method='PUT')
            update_req.add_header('apikey', apikey)
            update_req.add_header('Authorization', f'Bearer {token}')
            update_req.add_header('Content-Type', 'application/json')
            
            update_payload = json.dumps({
                'data': {
                    'role': 'empresa',
                    'name': name,
                    'cnpj': cnpj_clean
                }
            }).encode('utf-8')
            
            with urllib.request.urlopen(update_req, data=update_payload) as resp_up:
                up_data = json.loads(resp_up.read().decode('utf-8'))
                final_meta = up_data.get('user_metadata', {})
                print(f"[OK] Metadados confirmados com sucesso: {final_meta}")
                
    except urllib.error.HTTPError as e:
        print(f"[ERRO] Falha no login/atualização: {e.code} - {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"[ERRO] Exceção inesperada: {e}")

print("\n=== PROCESSO CONCLUÍDO ===")
