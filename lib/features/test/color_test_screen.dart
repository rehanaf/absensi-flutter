import 'package:flutter/material.dart';

class ColorTestScreen extends StatelessWidget {
  const ColorTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final colors = [
      _ColorItem('primary', colorScheme.primary, colorScheme.onPrimary),
      _ColorItem('onPrimary', colorScheme.onPrimary, colorScheme.primary),
      _ColorItem('primaryContainer', colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      _ColorItem('onPrimaryContainer', colorScheme.onPrimaryContainer, colorScheme.primaryContainer),
      _ColorItem('secondary', colorScheme.secondary, colorScheme.onSecondary),
      _ColorItem('secondaryContainer', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
      _ColorItem('tertiary', colorScheme.tertiary, colorScheme.onTertiary),
      _ColorItem('tertiaryContainer', colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      _ColorItem('error', colorScheme.error, colorScheme.onError),
      _ColorItem('errorContainer', colorScheme.errorContainer, colorScheme.onErrorContainer),
      _ColorItem('surface', colorScheme.surface, colorScheme.onSurface),
      _ColorItem('surfaceContainer', colorScheme.surfaceContainer, colorScheme.onSurface),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Palette Test'),
        backgroundColor: colorScheme.surfaceContainer,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final item = colors[index];
          return Container(
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Text(
              item.name,
              style: TextStyle(color: item.onColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}

class _ColorItem {
  final String name;
  final Color color;
  final Color onColor;
  _ColorItem(this.name, this.color, this.onColor);
}
