import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:draft_1/sync/sync_service.dart';
import 'package:draft_1/theme/app_theme.dart';

/// Settings screen for the optional cloud backup. Lets the user turn sync on or
/// off, see its current status, push a manual sync, and restore the cloud copy
/// onto this device. Rebuilds itself from [SyncService] (a [ChangeNotifier]).
class SyncSettingsScreen extends StatelessWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = SyncService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud sync')),
      body: ListenableBuilder(
        listenable: sync,
        builder: (context, _) {
          final colors = context.colors;
          final configured = sync.isConfigured;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Back up your study data and restore it on your other devices. '
                'Your data is always saved on this device first, so everything '
                'keeps working offline; changes sync automatically once you are '
                'back online.',
                style:
                    context.text.bodyLarge?.copyWith(color: colors.bodyText),
              ),
              const VGap(AppSpacing.xl),
              AppCard(
                padding: EdgeInsets.zero,
                radius: AppRadius.md,
                child: SwitchListTile(
                  title: Text(
                    'Cloud sync',
                    style: context.text.titleMedium
                        ?.copyWith(color: colors.onSurface),
                  ),
                  subtitle: Text(
                    configured
                        ? (sync.enabled ? 'On' : 'Off')
                        : 'No sync service configured',
                    style: context.text.bodyLarge
                        ?.copyWith(color: colors.onSurface),
                  ),
                  secondary: Icon(Icons.cloud_sync, color: colors.onSurface),
                  value: sync.enabled,
                  activeThumbColor: colors.positive,
                  onChanged: configured
                      ? (value) => sync.setEnabled(value)
                      : null,
                ),
              ),
              const VGap(AppSpacing.lg),
              _StatusCard(sync: sync),
              const VGap(AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: (configured && sync.enabled)
                    ? () => _syncNow(context, sync)
                    : null,
                style: AppButtons.positive(context),
                icon: const Icon(Icons.sync),
                label: const Text('Sync now'),
              ),
              const VGap(AppSpacing.md),
              OutlinedButton.icon(
                onPressed:
                    configured ? () => _confirmRestore(context, sync) : null,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Restore from backup'),
              ),
              const VGap(AppSpacing.lg),
              if (!configured)
                Text(
                  'To enable cloud sync, configure a sync endpoint via the '
                  'SYNC_API_URL (and optional SYNC_USER_ID / SYNC_API_KEY) '
                  'settings when building the app.',
                  style: context.text.bodyLarge
                      ?.copyWith(color: colors.neutral),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _syncNow(BuildContext context, SyncService sync) async {
    await sync.syncNow(manual: true);
    if (!context.mounted) return;
    final ok = sync.status == SyncStatus.idle;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Synced.'
            : 'Could not sync: ${sync.lastError ?? 'unknown error'}'),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, SyncService sync) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'This replaces the study data on this device with your most recent '
          'cloud backup. Unsynced changes on this device will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await sync.restoreFromCloud();
    if (!context.mounted) return;
    final ok = sync.status == SyncStatus.idle;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Restored from backup.'
            : 'Could not restore: ${sync.lastError ?? 'unknown error'}'),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SyncService sync;
  const _StatusCard({required this.sync});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final last = sync.lastSyncedAt;
    return AppCard(
      radius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color(colors)),
              const HGap(AppSpacing.md),
              Text(
                _label,
                style: context.text.titleMedium
                    ?.copyWith(color: colors.onSurface),
              ),
            ],
          ),
          const VGap(AppSpacing.sm),
          Text(
            last == null
                ? 'Last synced: never'
                : 'Last synced: ${DateFormat('MMM d, h:mm a').format(last)}',
            style: context.text.bodyLarge?.copyWith(color: colors.onSurface),
          ),
          if (sync.hasPendingChanges)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'You have changes waiting to be backed up.',
                style:
                    context.text.bodyLarge?.copyWith(color: colors.warning),
              ),
            ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (sync.status) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.error:
        return Icons.error_outline;
      case SyncStatus.idle:
        return Icons.cloud_done;
      case SyncStatus.disabled:
        return Icons.cloud_off;
    }
  }

  Color _color(AppColors colors) {
    switch (sync.status) {
      case SyncStatus.idle:
        return colors.positive;
      case SyncStatus.error:
        return colors.danger;
      case SyncStatus.offline:
        return colors.warning;
      case SyncStatus.syncing:
      case SyncStatus.disabled:
        return colors.onSurface;
    }
  }

  String get _label {
    switch (sync.status) {
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.offline:
        return 'Offline — will retry when reconnected';
      case SyncStatus.error:
        return 'Sync error';
      case SyncStatus.idle:
        return sync.enabled ? 'Up to date' : 'Idle';
      case SyncStatus.disabled:
        return 'Sync off';
    }
  }
}
