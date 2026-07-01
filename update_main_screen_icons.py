import re

def update_main_screen(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Update CustomNavItem class
    content = content.replace(
        "class CustomNavItem {\n  final String emoji;\n  final String label;\n  CustomNavItem(this.emoji, this.label);\n}",
        "class CustomNavItem {\n  final IconData icon;\n  final String label;\n  CustomNavItem(this.icon, this.label);\n}"
    )

    # Update absenItems
    old_absen = """    final List<CustomNavItem> absenItems = [
      CustomNavItem('🏠', 'Beranda'),
      CustomNavItem('🕰️', 'History'),
      CustomNavItem('📝', 'Izin'),
      CustomNavItem('⚙️', 'Setting'),
    ];"""
    new_absen = """    final List<CustomNavItem> absenItems = [
      CustomNavItem(Icons.home, 'Beranda'),
      CustomNavItem(Icons.history, 'History'),
      CustomNavItem(Icons.assignment, 'Izin'),
      CustomNavItem(Icons.settings, 'Setting'),
    ];"""
    content = content.replace(old_absen, new_absen)

    # Update adminItems
    old_admin = """    final List<CustomNavItem> adminItems = [
      CustomNavItem('📊', 'Dasbor'),
      CustomNavItem('𗂂️', 'Manajemen'),
      CustomNavItem('🛠️', 'Konfigurasi'),
      CustomNavItem('⚙️', 'Setting'),
    ];"""
    new_admin = """    final List<CustomNavItem> adminItems = [
      CustomNavItem(Icons.dashboard, 'Dasbor'),
      CustomNavItem(Icons.folder, 'Manajemen'),
      CustomNavItem(Icons.build, 'Konfigurasi'),
      CustomNavItem(Icons.settings, 'Setting'),
    ];"""
    
    # Due to emoji encoding issues, regex might be safer
    content = re.sub(
        r"final List<CustomNavItem> adminItems = \[[\s\S]*?\];",
        "final List<CustomNavItem> adminItems = [\n      CustomNavItem(Icons.dashboard, 'Dasbor'),\n      CustomNavItem(Icons.folder, 'Manajemen'),\n      CustomNavItem(Icons.build, 'Konfigurasi'),\n      CustomNavItem(Icons.settings, 'Setting'),\n    ];",
        content
    )

    content = re.sub(
        r"final List<CustomNavItem> parentItems = \[[\s\S]*?\];",
        "final List<CustomNavItem> parentItems = [\n      CustomNavItem(Icons.child_care, 'Anak Saya'),\n      CustomNavItem(Icons.settings, 'Setting'),\n    ];",
        content
    )

    # Update AppBar
    old_appbar = """      appBar: AppBar(
        title: Text(settings.appName, style: ShadTheme.of(context).textTheme.h4),
        backgroundColor: ShadTheme.of(context).colorScheme.background,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: ShadTheme.of(context).colorScheme.border,
            height: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const TwemojiText(text: '🔔', style: TextStyle(fontSize: 20)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
          ),
        ],
      ),"""
    
    new_appbar = """      appBar: AppBar(
        title: Text(
          settings.appName, 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
          ),
        ],
      ),"""
    
    # Use regex for AppBar just in case encoding issues break simple replace for the bell emoji
    content = re.sub(r"appBar: AppBar\([\s\S]*?\],\n      \),", new_appbar, content)

    # Update NavigationBar destinations
    content = re.sub(
        r"icon: TwemojiText\(text: item.emoji, style: const TextStyle\(fontSize: 20\)\),",
        r"icon: Icon(item.icon),",
        content
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    update_main_screen('lib/features/main/main_screen.dart')
except Exception as e:
    print(f"Error: {e}")
