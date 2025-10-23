import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';

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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
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
                  subtitle: const Text('Expiration reminders'),
                  trailing: Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                            ToggleNotifications(value),
                          );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_getThemeModeName(settings.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context, settings.themeMode),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Nutritional Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: const Text('Daily Targets'),
                  subtitle: Text(
                    'Calories: ${settings.dailyCalorieTarget.toInt()} kcal',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDailyTargetsDialog(context, settings),
                ),
                ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: const Text('Expiration Warning'),
                  subtitle: Text('${settings.expirationWarningDays} days before expiration'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExpirationWarningDialog(
                    context,
                    settings.expirationWarningDays,
                  ),
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
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Export Data'),
                  subtitle: const Text('Backup your inventory'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import feature coming soon!')),
                    );
                  },
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GitHub link coming soon!')),
                    );
                  },
                ),
              ],
            );
          }

          return const Center(child: Text('Loading settings...'));
        },
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(ChangeThemeMode(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(ChangeThemeMode(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(ChangeThemeMode(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExpirationWarningDialog(BuildContext context, int currentDays) {
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Expiration Warning'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Days before expiration',
            suffixText: 'days',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                context.read<SettingsBloc>().add(
                      UpdateExpirationWarningDays(days),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDailyTargetsDialog(BuildContext context, settings) {
    final caloriesController = TextEditingController(
      text: settings.dailyCalorieTarget.toInt().toString(),
    );
    final carbsController = TextEditingController(
      text: settings.dailyCarbohydratesTarget.toInt().toString(),
    );
    final fatsController = TextEditingController(
      text: settings.dailyFatsTarget.toInt().toString(),
    );
    final proteinController = TextEditingController(
      text: settings.dailyProteinTarget.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Daily Nutritional Targets'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  suffixText: 'kcal',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Carbohydrates',
                  suffixText: 'g',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fats',
                  suffixText: 'g',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protein',
                  suffixText: 'g',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final calories = double.tryParse(caloriesController.text);
              final carbs = double.tryParse(carbsController.text);
              final fats = double.tryParse(fatsController.text);
              final protein = double.tryParse(proteinController.text);

              context.read<SettingsBloc>().add(
                    UpdateDailyTargets(
                      calories: calories,
                      carbohydrates: carbs,
                      fats: fats,
                      protein: protein,
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
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
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
