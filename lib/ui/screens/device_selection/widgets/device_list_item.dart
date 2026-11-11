import 'package:flutter/material.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/l10n/app_localizations.dart';

class DeviceListItem extends StatelessWidget {
  const DeviceListItem({
    required this.device,
    required this.onTap,
    this.onLongPress,
    this.onPower,
    this.busy = false,
    super.key,
  });

  final TVDevice device;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPower;

  /// Shows a spinner instead of the chevron while this TV is connecting.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mac = device.mac;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.tv,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.ipLabel(device.host ?? '—'),
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            if (mac != null && mac.isNotEmpty)
              Text(
                l.macLabel(mac),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
          ],
        ),
        trailing: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : onPower == null
            ? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
            : IconButton(
                tooltip: 'Ligar TV',
                onPressed: onPower,
                icon: const Icon(Icons.power_settings_new),
              ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
