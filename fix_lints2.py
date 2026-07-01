import os

with open('lib/features/home/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
'''      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wajah berhasil didaftarkan!')),
        );
      }''', 
'''      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.checkAuthStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wajah berhasil didaftarkan!')),
          );
        }
      }'''
)

with open('lib/features/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
