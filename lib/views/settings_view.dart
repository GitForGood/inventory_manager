import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/models/daily_calorie_target.dart';
import 'package:inventory_manager/services/recipe_database.dart';
import 'package:inventory_manager/services/recipe_import_service.dart';
import 'package:inventory_manager/services/backup_service.dart';
import 'package:inventory_manager/widgets/calorie_target_bottom_sheet.dart';
import 'package:inventory_manager/widgets/notification_settings_view.dart';
import 'package:inventory_manager/views/theme_swatch_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (state is SettingsLoaded) {
            final settings = state.settings;

            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage notification preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNotificationSettings(context),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('High Contrast Mode'),
                  subtitle: const Text('Increase contrast for better visibility'),
                  trailing: Switch(
                    value: settings.highContrast,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                            ChangeThemeMode(value),
                          );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Colors'),
                  subtitle: const Text('View all theme colors'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ThemeSwatchView(),
                      ),
                    );
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Quota Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Preferred Interval'),
                  subtitle: Text(_getIntervalName(settings.preferredQuotaInterval)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showQuotaIntervalDialog(
                    context,
                    settings.preferredQuotaInterval,
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Inventory Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.local_fire_department),
                  title: const Text('Calorie Target'),
                  subtitle: Text(
                    settings.dailyCalorieTarget != null
                        ? '${_formatNumber(settings.dailyCalorieTarget?.target ?? 0)} kcal'
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCalorieTargetSheet(context, settings.dailyCalorieTarget),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_outlined),
                  title: const Text('Reset Settings'),
                  subtitle: const Text('Restore default settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showResetDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.build_outlined),
                  title: const Text('Recreate Database Tables'),
                  subtitle: const Text('Reset database structure (keeps data)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRecreateTablesDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_menu_outlined),
                  title: const Text('Import Recipes'),
                  subtitle: const Text('Load recipes from GitHub repository'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRecipeImportDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Clear Database'),
                  subtitle: const Text('Delete recipes, inventory, or all data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearDataDialog(context),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Backup',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Export Data'),
                  subtitle: const Text('Backup your inventory'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExportDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showImportDialog(context),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outlined),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: const Text('Open Source'),
                  subtitle: const Text('View on GitHub'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchGithubInBrowser(context)
                ),
              ],
            );
          }

          return const Center(child: Text('Loading settings...'));
        },
      ),
    );
  }
  Future<void> _launchGithubInBrowser(BuildContext context) async {
  final uri = Uri.parse("https://github.com/GitForGood/inventory_manager");
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("https://github.com/GitForGood/inventory_manager"))
    );
  }
}

  String _getIntervalName(ConsumptionPeriod period) {
    switch (period) {
      case ConsumptionPeriod.weekly:
        return 'Weekly';
      case ConsumptionPeriod.monthly:
        return 'Monthly';
      case ConsumptionPeriod.quarterly:
        return 'Quarterly';
    }
  }

  void _showNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsView(),
      ),
    );
  }

  void _showQuotaIntervalDialog(BuildContext context, ConsumptionPeriod currentPeriod) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Preferred Quota Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ConsumptionPeriod>(
              title: const Text('Weekly'),
              subtitle: const Text('Reset every 7 days'),
              value: ConsumptionPeriod.weekly,
              groupValue: currentPeriod,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdatePreferredQuotaInterval(value.index),
                      );
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ConsumptionPeriod>(
              title: const Text('Monthly'),
              subtitle: const Text('Reset every month'),
              value: ConsumptionPeriod.monthly,
              groupValue: currentPeriod,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdatePreferredQuotaInterval(value.index),
                      );
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ConsumptionPeriod>(
              title: const Text('Quarterly'),
              subtitle: const Text('Reset every 3 months'),
              value: ConsumptionPeriod.quarterly,
              groupValue: currentPeriod,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdatePreferredQuotaInterval(value.index),
                      );
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(const ResetSettings());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: Text('Reset', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showRecipeImportDialog(BuildContext context) {
    // Hardcoded URL to the official recipe repository
    const recipeUrl = 'https://raw.githubusercontent.com/GitForGood/inventory_manager/refs/heads/main/data/recipes.json';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Recipes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will import recipes from the official repository and add them to your local database.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Any existing recipes with the same name will be skipped.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Importing recipes...'),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                final importService = RecipeImportService();
                final result = await importService.importRecipesFromUrl(recipeUrl);

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      duration: const Duration(seconds: 5),
                    ),
                  );

                  if (result.hasErrors) {
                    // Show detailed errors in a dialog
                    _showImportErrorsDialog(context, result);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error importing recipes: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showImportErrorsDialog(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Warnings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Some recipes failed to import:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.errors.map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $error', style: const TextStyle(fontSize: 12)),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select what data to clear:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Clear Recipes'),
              subtitle: const Text('Delete all saved recipes'),
              onTap: () {
                Navigator.pop(dialogContext);
                _confirmClearData(
                  context,
                  'Clear All Recipes',
                  'Are you sure you want to delete all recipes? This cannot be undone.',
                  () async {
                    await RecipeDatabase.instance.clearAllRecipes();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All recipes cleared'),
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Clear Inventory'),
              subtitle: const Text('Delete all batches and quotas'),
              onTap: () {
                Navigator.pop(dialogContext);
                _confirmClearData(
                  context,
                  'Clear All Inventory',
                  'Are you sure you want to delete all inventory batches and quotas? This cannot be undone.',
                  () async {
                    await RecipeDatabase.instance.clearAllInventory();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All inventory cleared'),
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event_busy),
              title: const Text('Clear Quotas Only'),
              subtitle: const Text('Delete all consumption quotas'),
              onTap: () {
                Navigator.pop(dialogContext);
                _confirmClearData(
                  context,
                  'Clear All Quotas',
                  'Are you sure you want to delete all consumption quotas? This cannot be undone.',
                  () async {
                    await RecipeDatabase.instance.clearAllQuotas();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All quotas cleared'),
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
              title: Text('Clear All Data', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: const Text('Delete everything (recipes, inventory, food items)'),
              onTap: () {
                Navigator.pop(dialogContext);
                _confirmClearData(
                  context,
                  'Clear ALL Data',
                  'Are you sure you want to delete ALL data including recipes, inventory, food items, and quotas? This cannot be undone!',
                  () async {
                    await RecipeDatabase.instance.clearAllData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All data cleared'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(
    BuildContext context,
    String title,
    String message,
    Future<void> Function() onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await onConfirm();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showCalorieTargetSheet(BuildContext context, DailyCalorieTarget? currentTarget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CalorieTargetBottomSheet(
        currentTarget: currentTarget,
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showRecreateTablesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recreate Database Tables'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will drop and recreate all database tables with empty structures.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will delete ALL data including recipes, inventory, and quotas!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use this only if:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Text('• Database is corrupted', style: TextStyle(fontSize: 12)),
            const Text('• Tables are missing or broken', style: TextStyle(fontSize: 12)),
            const Text('• App won\'t load properly', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Recreating database tables...'),
                    ],
                  ),
                  duration: Duration(seconds: 10),
                ),
              );

              try {
                await RecipeDatabase.instance.recreateAllTables();

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Database tables recreated successfully!'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error recreating tables: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: Text(
              'Recreate Tables',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create a compressed backup file containing:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Text('• All recipes'),
            const Text('• All food items'),
            const Text('• All inventory batches'),
            const Text('• All consumption quotas'),
            const Text('• All settings'),
            const SizedBox(height: 12),
            Text(
              'The backup will be saved as a .gz file.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Exporting data...'),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                final backupService = BackupService();
                final result = await backupService.exportData();

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error exporting data: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will import data from a backup file.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Existing data with the same IDs will be kept. No data will be deleted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Importing data...'),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                final backupService = BackupService();
                final result = await backupService.importData();

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error importing data: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }
}
