import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../clipboard/presentation/bloc/clipboard_bloc.dart';
import '../../../clipboard/presentation/bloc/clipboard_event.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _secureStorage = sl<SecureStorage>();
  late bool _clipboardEnabled;

  @override
  void initState() {
    super.initState();
    _clipboardEnabled = _secureStorage.getClipboardSyncEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final host = _secureStorage.getHost() ?? 'Not Connected';
    final port = _secureStorage.getPort()?.toString() ?? 'N/A';
    final deviceId = _secureStorage.getDeviceId() ?? 'Unknown';
    final deviceName = _secureStorage.getDeviceName() ?? 'Flutter Client';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Connection Section
            _buildSectionHeader('Connection Info', Icons.dns_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Host IP / PC IP', host),
                  const Divider(color: Colors.white12, height: 24),
                  _buildInfoRow('Port Number', port),
                  const Divider(color: Colors.white12, height: 24),
                  _buildInfoRow('Client Device Name', deviceName),
                  const Divider(color: Colors.white12, height: 24),
                  _buildInfoRow('Unique Device ID', deviceId, isValueCompact: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Preferences Section
            _buildSectionHeader('Preferences', Icons.tune_rounded),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: SwitchListTile(
                value: _clipboardEnabled,
                title: const Text('Clipboard Synchronization', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share clipboard text automatically with your desktop', style: TextStyle(fontSize: 12)),
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  setState(() {
                    _clipboardEnabled = val;
                  });
                  context.read<ClipboardBloc>().add(ClipboardToggleSync(val));
                },
              ),
            ),
            const SizedBox(height: 32),

            // 3. Destructive Section
            _buildSectionHeader('Security Management', Icons.security_rounded),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUnpairDialog(context),
                icon: const Icon(Icons.link_off_rounded, color: Colors.white),
                label: const Text('Revoke Desktop Pairing', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isValueCompact = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.textPrimary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _showUnpairDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unpair Device?'),
        content: const Text(
          'This will revoke the connection credential token. You will need to scan the pairing QR code again to connect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.go('/pairing');
            },
            child: const Text('Unpair', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
