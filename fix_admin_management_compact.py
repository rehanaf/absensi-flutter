with open('lib/features/admin/admin_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Remove the description argument from _buildMenuRow calls
content = re.sub(r'description:\s*\'[^\']*\',\s*\n\s*', '', content)

# Replace the definition of _buildMenuRow
old_method = """  Widget _buildMenuRow(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ShadTheme.of(context).textTheme.large),
                  const SizedBox(height: 4),
                  Text(description, style: ShadTheme.of(context).textTheme.muted),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ShadTheme.of(context).colorScheme.muted),
          ],
        ),
      ),
    );
  }"""

new_method = """  Widget _buildMenuRow(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: ShadTheme.of(context).textTheme.large),
            ),
            Icon(Icons.chevron_right, color: ShadTheme.of(context).colorScheme.muted),
          ],
        ),
      ),
    );
  }"""

content = content.replace(old_method, new_method)

with open('lib/features/admin/admin_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
