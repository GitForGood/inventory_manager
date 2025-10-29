import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
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
                    'Manage your notification preferences',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Master Notifications'),
                  subtitle: const Text('Enable or disable all notifications'),
                  trailing: Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                            ToggleNotifications(value),
                          );
                    },
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Notification Types',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Expiration Reminders'),
                  subtitle: const Text('Get notified when items are about to expire'),
                  trailing: Switch(
                    value: settings.expirationNotificationsEnabled,
                    onChanged: settings.notificationsEnabled
                        ? (value) {
                            context.read<SettingsBloc>().add(
                                  UpdateExpirationNotifications(value),
                                );
                          }
                        : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.track_changes_outlined),
                  title: const Text('New Quota Period'),
                  subtitle: const Text('Get notified when a new quota period begins'),
                  trailing: Switch(
                    value: settings.quotaGenerationNotificationsEnabled,
                    onChanged: settings.notificationsEnabled
                        ? (value) {
                            context.read<SettingsBloc>().add(
                                  UpdateQuotaGenerationNotifications(value),
                                );
                          }
                        : null,
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Note: Individual notification types are only active when master notifications are enabled.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Loading settings...'));
        },
      ),
    );
  }
}
