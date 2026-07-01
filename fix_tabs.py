import re

with open('lib/features/admin/admin_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

get_icon_method = '''  IconData? _getGroupIcon(String groupName) {
    switch (groupName.toLowerCase()) {
      case 'umum':
        return Icons.settings;
      case 'personalisasi':
        return Icons.palette;
      case 'absensi':
        return Icons.how_to_reg;
      case 'profil':
        return Icons.person;
      case 'alamat':
        return Icons.location_on;
      case 'berkas':
        return Icons.folder;
      case 'keamanan':
        return Icons.security;
      default:
        return null;
    }
  }

  @override'''

content = content.replace('  @override\n  Widget build(BuildContext context) {', get_icon_method + '\n  Widget build(BuildContext context) {')

old_body = '''      body: groups.isEmpty
            ? const Center(child: Text('Tidak ada pengaturan tersedia.'))
            : Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ShadTabs<String>(
                          scrollable: true,
                          key: ValueKey(groups.join('-')),
                          value: groups.first,
                          tabs: groups.map((g) {
                            final items = groupedSettings[g]!;
                            return ShadTab(
                              value: g,
                              child: Text(g),
                              content: ListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                children: [
                                  Text('Pengaturan $g', style: ShadTheme.of(context).textTheme.h4),
                                  const SizedBox(height: 24),
                                  ...items.map(_buildField),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }
  }'''

new_body = '''      body: groups.isEmpty
            ? const Center(child: Text('Tidak ada pengaturan tersedia.'))
            : DefaultTabController(
                length: groups.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: groups.map((g) {
                        final iconData = _getGroupIcon(g);
                        return Tab(
                          icon: iconData != null ? Icon(iconData) : null,
                          text: g,
                        );
                      }).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: groups.map((g) {
                          final items = groupedSettings[g]!;
                          return ListView(
                            padding: const EdgeInsets.all(24.0),
                            children: [
                              Text('Pengaturan $g', style: ShadTheme.of(context).textTheme.h4),
                              const SizedBox(height: 24),
                              ...items.map(_buildField),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
      );
    }
  }'''

content = content.replace(old_body, new_body)

with open('lib/features/admin/admin_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
