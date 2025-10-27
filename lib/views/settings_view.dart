import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/models/quota_schedule.dart';
import 'package:inventory_manager/views/notification_settings_view.dart';

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

  String _getIntervalName(SchedulePeriod period) {
    switch (period) {
      case SchedulePeriod.weekly:
        return 'Weekly';
      case SchedulePeriod.monthly:
        return 'Monthly';
      case SchedulePeriod.quarterly:
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

  void _showQuotaIntervalDialog(BuildContext context, SchedulePeriod currentPeriod) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Preferred Quota Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<SchedulePeriod>(
              title: const Text('Weekly'),
              subtitle: const Text('Reset every 7 days'),
              value: SchedulePeriod.weekly,
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
            RadioListTile<SchedulePeriod>(
              title: const Text('Monthly'),
              subtitle: const Text('Reset every month'),
              value: SchedulePeriod.monthly,
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
            RadioListTile<SchedulePeriod>(
              title: const Text('Quarterly'),
              subtitle: const Text('Reset every 3 months'),
              value: SchedulePeriod.quarterly,
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
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
