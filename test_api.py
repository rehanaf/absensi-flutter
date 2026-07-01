import urllib.request
import urllib.parse
import json

base_url = "http://absensi.test/api"
login_url = f"{base_url}/login"
dashboard_url = f"{base_url}/dashboard/user"

data = urllib.parse.urlencode({
    'username': '101',
    'password': 'password'
}).encode('utf-8')

req = urllib.request.Request(login_url, data=data)
try:
    with urllib.request.urlopen(req) as response:
        login_res = json.loads(response.read().decode())
        
        token = login_res.get('access_token')
        if token:
            req2 = urllib.request.Request(dashboard_url)
            req2.add_header('Authorization', f'Bearer {token}')
            req2.add_header('Accept', 'application/json')
            
            with urllib.request.urlopen(req2) as res2:
                dash_res = json.loads(res2.read().decode())
                print("\n\nDASHBOARD RESPONSE:")
                print(json.dumps(dash_res, indent=2))
except urllib.error.URLError as e:
    print(f"Error: {e}")
    if hasattr(e, 'read'):
        print(e.read().decode())
