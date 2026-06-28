import os

filepath = r'c:\laragon\www\absensi\public\.htaccess'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

cors_block = '''
<IfModule mod_headers.c>
    <FilesMatch "\.(jpeg|jpg|png|gif|svg|webp)$">
        Header set Access-Control-Allow-Origin "*"
        Header set Access-Control-Allow-Methods "GET, OPTIONS"
    </FilesMatch>
</IfModule>
'''

if 'Access-Control-Allow-Origin' not in content:
    with open(filepath, 'a', encoding='utf-8') as f:
        f.write(cors_block)
