import os
import re

with open('lib/features/home/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r"(// Header Section\s*)Container\([\s\S]*?padding: const EdgeInsets.symmetric\(horizontal: 16, vertical: 32\),[\s\S]*?Expanded\([\s\S]*?Text\([\s\S]*?user\?\['name'\] \?\? 'User',[\s\S]*?fontWeight: FontWeight.bold,[\s\S]*?\),[\s\S]*?\),[\s\S]*?\],[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),"

replacement = r'''\1LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              final avatarWidget = CircleAvatar(
                                radius: 36,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  (user?['name'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                                ),
                              );

                              final nameWidget = Text(
                                user?['name'] ?? 'User',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                              );

                              final usernameWidget = Text(
                                user?['username'] ?? 'username',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                              );

                              if (isMobile) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      avatarWidget,
                                      const SizedBox(height: 16),
                                      nameWidget,
                                      const SizedBox(height: 4),
                                      usernameWidget,
                                    ],
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                child: Row(
                                  children: [
                                    avatarWidget,
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          nameWidget,
                                          const SizedBox(height: 4),
                                          usernameWidget,
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),'''

new_content = re.sub(pattern, replacement, content)

if content == new_content:
    print("Failed to match")
else:
    with open('lib/features/home/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Success")
