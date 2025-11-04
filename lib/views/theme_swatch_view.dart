import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme color swatch viewer for debugging and checking theme colors
class ThemeSwatchView extends StatelessWidget {
  const ThemeSwatchView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Color Swatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary Colors Section
            _buildSectionHeader(context, 'Primary Colors'),
            _buildColorCard(context, 'primary', colorScheme.primary, colorScheme.onPrimary),
            _buildColorCard(context, 'onPrimary', colorScheme.onPrimary, colorScheme.primary),
            _buildColorCard(context, 'primaryContainer', colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
            _buildColorCard(context, 'onPrimaryContainer', colorScheme.onPrimaryContainer, colorScheme.primaryContainer),
            _buildColorCard(context, 'primaryFixed', colorScheme.primaryFixed, colorScheme.onPrimaryFixed),
            _buildColorCard(context, 'onPrimaryFixed', colorScheme.onPrimaryFixed, colorScheme.primaryFixed),
            _buildColorCard(context, 'primaryFixedDim', colorScheme.primaryFixedDim, colorScheme.onPrimaryFixedVariant),
            _buildColorCard(context, 'onPrimaryFixedVariant', colorScheme.onPrimaryFixedVariant, colorScheme.primaryFixedDim),

            const SizedBox(height: 24),

            // Secondary Colors Section
            _buildSectionHeader(context, 'Secondary Colors'),
            _buildColorCard(context, 'secondary', colorScheme.secondary, colorScheme.onSecondary),
            _buildColorCard(context, 'onSecondary', colorScheme.onSecondary, colorScheme.secondary),
            _buildColorCard(context, 'secondaryContainer', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
            _buildColorCard(context, 'onSecondaryContainer', colorScheme.onSecondaryContainer, colorScheme.secondaryContainer),
            _buildColorCard(context, 'secondaryFixed', colorScheme.secondaryFixed, colorScheme.onSecondaryFixed),
            _buildColorCard(context, 'onSecondaryFixed', colorScheme.onSecondaryFixed, colorScheme.secondaryFixed),
            _buildColorCard(context, 'secondaryFixedDim', colorScheme.secondaryFixedDim, colorScheme.onSecondaryFixedVariant),
            _buildColorCard(context, 'onSecondaryFixedVariant', colorScheme.onSecondaryFixedVariant, colorScheme.secondaryFixedDim),

            const SizedBox(height: 24),

            // Tertiary Colors Section
            _buildSectionHeader(context, 'Tertiary Colors (Success/Green)'),
            _buildColorCard(context, 'tertiary', colorScheme.tertiary, colorScheme.onTertiary),
            _buildColorCard(context, 'onTertiary', colorScheme.onTertiary, colorScheme.tertiary),
            _buildColorCard(context, 'tertiaryContainer', colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
            _buildColorCard(context, 'onTertiaryContainer', colorScheme.onTertiaryContainer, colorScheme.tertiaryContainer),
            _buildColorCard(context, 'tertiaryFixed', colorScheme.tertiaryFixed, colorScheme.onTertiaryFixed),
            _buildColorCard(context, 'onTertiaryFixed', colorScheme.onTertiaryFixed, colorScheme.tertiaryFixed),
            _buildColorCard(context, 'tertiaryFixedDim', colorScheme.tertiaryFixedDim, colorScheme.onTertiaryFixedVariant),
            _buildColorCard(context, 'onTertiaryFixedVariant', colorScheme.onTertiaryFixedVariant, colorScheme.tertiaryFixedDim),

            const SizedBox(height: 24),

            // Error Colors Section
            _buildSectionHeader(context, 'Error Colors (Red/Warning)'),
            _buildColorCard(context, 'error', colorScheme.error, colorScheme.onError),
            _buildColorCard(context, 'onError', colorScheme.onError, colorScheme.error),
            _buildColorCard(context, 'errorContainer', colorScheme.errorContainer, colorScheme.onErrorContainer),
            _buildColorCard(context, 'onErrorContainer', colorScheme.onErrorContainer, colorScheme.errorContainer),

            const SizedBox(height: 24),

            // Surface Colors Section
            _buildSectionHeader(context, 'Surface Colors'),
            _buildColorCard(context, 'surface', colorScheme.surface, colorScheme.onSurface),
            _buildColorCard(context, 'onSurface', colorScheme.onSurface, colorScheme.surface),
            _buildColorCard(context, 'surfaceDim', colorScheme.surfaceDim, colorScheme.onSurface),
            _buildColorCard(context, 'surfaceBright', colorScheme.surfaceBright, colorScheme.onSurface),
            _buildColorCard(context, 'surfaceContainerLowest', colorScheme.surfaceContainerLowest, colorScheme.onSurface),
            _buildColorCard(context, 'surfaceContainerLow', colorScheme.surfaceContainerLow, colorScheme.onSurface),
            _buildColorCard(context, 'surfaceContainer', colorScheme.surfaceContainer, colorScheme.onSurface),
            _buildColorCard(context, 'surfaceContainerHigh', colorScheme.surfaceContainerHigh, colorScheme.onSurface),
            _buildColorCard(context, 'surfaceContainerHighest', colorScheme.surfaceContainerHighest, colorScheme.onSurface),
            _buildColorCard(context, 'onSurfaceVariant', colorScheme.onSurfaceVariant, colorScheme.surface),
            _buildColorCard(context, 'surfaceTint', colorScheme.surfaceTint, colorScheme.onSurface),

            const SizedBox(height: 24),

            // Outline Colors Section
            _buildSectionHeader(context, 'Outline & Shadow Colors'),
            _buildColorCard(context, 'outline', colorScheme.outline, colorScheme.surface),
            _buildColorCard(context, 'outlineVariant', colorScheme.outlineVariant, colorScheme.surface),
            _buildColorCard(context, 'shadow', colorScheme.shadow, colorScheme.surface),
            _buildColorCard(context, 'scrim', colorScheme.scrim, colorScheme.surface),

            const SizedBox(height: 24),

            // Inverse Colors Section
            _buildSectionHeader(context, 'Inverse Colors'),
            _buildColorCard(context, 'inverseSurface', colorScheme.inverseSurface, colorScheme.onInverseSurface),
            _buildColorCard(context, 'onInverseSurface', colorScheme.onInverseSurface, colorScheme.inverseSurface),
            _buildColorCard(context, 'inversePrimary', colorScheme.inversePrimary, colorScheme.primary),

            const SizedBox(height: 32),

            // Text Theme Section
            _buildSectionHeader(context, 'Text Styles'),
            _buildTextStyleCard(context, 'displayLarge', textTheme.displayLarge),
            _buildTextStyleCard(context, 'displayMedium', textTheme.displayMedium),
            _buildTextStyleCard(context, 'displaySmall', textTheme.displaySmall),
            _buildTextStyleCard(context, 'headlineLarge', textTheme.headlineLarge),
            _buildTextStyleCard(context, 'headlineMedium', textTheme.headlineMedium),
            _buildTextStyleCard(context, 'headlineSmall', textTheme.headlineSmall),
            _buildTextStyleCard(context, 'titleLarge', textTheme.titleLarge),
            _buildTextStyleCard(context, 'titleMedium', textTheme.titleMedium),
            _buildTextStyleCard(context, 'titleSmall', textTheme.titleSmall),
            _buildTextStyleCard(context, 'bodyLarge', textTheme.bodyLarge),
            _buildTextStyleCard(context, 'bodyMedium', textTheme.bodyMedium),
            _buildTextStyleCard(context, 'bodySmall', textTheme.bodySmall),
            _buildTextStyleCard(context, 'labelLarge', textTheme.labelLarge),
            _buildTextStyleCard(context, 'labelMedium', textTheme.labelMedium),
            _buildTextStyleCard(context, 'labelSmall', textTheme.labelSmall),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildColorCard(BuildContext context, String name, Color color, Color textColor) {
    final hexColor = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: hexColor));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $hexColor to clipboard'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hexColor,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.copy,
                color: textColor.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextStyleCard(BuildContext context, String name, TextStyle? style) {
    if (style == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The quick brown fox jumps',
              style: style,
            ),
            const SizedBox(height: 4),
            Text(
              'Size: ${style.fontSize?.toStringAsFixed(0)}pt, Weight: ${style.fontWeight?.toString().split('.').last}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
