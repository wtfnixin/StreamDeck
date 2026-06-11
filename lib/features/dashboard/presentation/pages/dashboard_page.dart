import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../connection/presentation/bloc/connection_bloc.dart';
import '../../../connection/presentation/bloc/connection_event.dart';
import '../../../connection/presentation/bloc/connection_state.dart';
import 'package:devdeck/features/clipboard/presentation/bloc/clipboard_bloc.dart';
import 'package:devdeck/features/clipboard/presentation/bloc/clipboard_event.dart';
import 'package:devdeck/features/clipboard/presentation/bloc/clipboard_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    final connectionState = context.read<ConnectionBloc>().state;
    if (connectionState.status == ConnectionStatus.connected) {
      context.read<ClipboardBloc>().add(ClipboardStartSync());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D11), // Matte OLED black background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'DEVDECK',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
        actions: [
          // Settings glass button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white70),
              onPressed: () => context.push('/settings'),
            ),
          ),
          // Disconnect glass button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
            ),
            child: IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
              tooltip: 'Disconnect',
              onPressed: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
      body: BlocListener<ConnectionBloc, ConnectionBlocState>(
        listener: (context, state) {
          if (state.status == ConnectionStatus.connected) {
            context.read<ClipboardBloc>().add(ClipboardStartSync());
          } else {
            context.read<ClipboardBloc>().add(ClipboardStopSync());
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Connection Status Card (breathing pulsing style)
              const ConnectionStatusCard(),
              const SizedBox(height: 18),

              // 2. Live Clipboard Monitor Terminal
              const ClipboardStatusCard(),
              const SizedBox(height: 24),

              // 3. Section Title: Console Hub
              const Text(
                'CONSOLE INTERFACES',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Virtual Stream Deck Hero Panel
              _buildStreamDeckHero(context),
              const SizedBox(height: 18),

              // 5. Category Launcher Modules List
              _buildCategoryList(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamDeckHero(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/stream-deck');
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.22),
                  const Color(0xFFAB47BC).withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Advanced micro grid simulating keycaps
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: index == 4
                              ? const Color(0xFF6366F1).withOpacity(0.8)
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: index == 4 ? [
                            const BoxShadow(
                              color: Color(0xFF6366F1),
                              blurRadius: 4,
                            )
                          ] : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRIMARY CONSOLE',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Virtual Stream Deck',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Unified control center for all actions',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Quick App Launcher', Icons.rocket_launch_rounded, const Color(0xFF2979FF)),
        const SizedBox(height: 8),
        _buildCategoryCard(
          context,
          title: 'App Shortcuts',
          subtitle: 'VS Code, Chrome, Terminal, etc.',
          icon: Icons.rocket_launch_rounded,
          accentColor: const Color(0xFF2979FF),
          route: '/apps',
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Website Shortcuts', Icons.language_rounded, const Color(0xFFEC407A)),
        const SizedBox(height: 8),
        _buildCategoryCard(
          context,
          title: 'URL Shortcuts',
          subtitle: 'GitHub, ChatGPT, Gmail, etc.',
          icon: Icons.language_rounded,
          accentColor: const Color(0xFFEC407A),
          route: '/websites',
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Workspace Profiles', Icons.workspaces_rounded, const Color(0xFFAB47BC)),
        const SizedBox(height: 8),
        _buildCategoryCard(
          context,
          title: 'Workspace Flows',
          subtitle: 'Full development environments',
          icon: Icons.workspaces_rounded,
          accentColor: const Color(0xFFAB47BC),
          route: '/workspaces',
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Gesture Controller Pad', Icons.gesture_rounded, const Color(0xFF00E5FF)),
        const SizedBox(height: 8),
        _buildCategoryCard(
          context,
          title: 'Interactive Gesture Pad',
          subtitle: 'Swipe or tap here to trigger desktop macros',
          icon: Icons.touch_app_rounded,
          accentColor: const Color(0xFF00E5FF),
          route: '/gesture-pad',
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String route,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.18),
                  accentColor.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.04),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke Device Pairing?'),
        content: const Text(
          'This will remove all stored keys and disconnect the remote connection from your PC.',
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
            child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// PULSING INDICATOR FOR HIGH-END CONNECTION SYSTEM
// ----------------------------------------------------
class PulsingStatusDot extends StatefulWidget {
  final Color color;
  const PulsingStatusDot({super.key, required this.color});

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 + (_controller.value * 0.6)),
                blurRadius: 4 + (_controller.value * 8),
                spreadRadius: _controller.value * 1.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, ConnectionBlocState>(
      builder: (context, state) {
        final status = state.status;
        
        Color statusColor;
        String statusText;
        IconData statusIcon;
        List<Color> gradientColors;

        switch (status) {
          case ConnectionStatus.connected:
            statusColor = AppTheme.secondaryColor;
            statusText = 'CONNECTED';
            statusIcon = Icons.wifi_rounded;
            gradientColors = [const Color(0xFF0F172A), const Color(0xFF0F172A)];
            break;
          case ConnectionStatus.connecting:
            statusColor = Colors.orangeAccent;
            statusText = 'CONNECTING...';
            statusIcon = Icons.sync;
            gradientColors = [const Color(0xFF0F172A), const Color(0xFF0F172A)];
            break;
          case ConnectionStatus.disconnected:
            statusColor = Colors.redAccent;
            statusText = 'DISCONNECTED';
            statusIcon = Icons.wifi_off_rounded;
            gradientColors = [const Color(0xFF0F172A), const Color(0xFF0F172A)];
            break;
          case ConnectionStatus.pairingRequired:
            statusColor = AppTheme.primaryColor;
            statusText = 'PAIRING REQUIRED';
            statusIcon = Icons.phonelink_lock_rounded;
            gradientColors = [const Color(0xFF0F172A), const Color(0xFF0F172A)];
            break;
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: statusColor.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.04),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // High tech connector badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
                    ),
                    child: status == ConnectionStatus.connecting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          )
                        : Icon(statusIcon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PulsingStatusDot(color: statusColor),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status == ConnectionStatus.connected
                              ? 'Telemetry connection active'
                              : status == ConnectionStatus.pairingRequired
                                  ? 'Device requires PC validation code'
                                  : 'Waiting for network PC socket',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == ConnectionStatus.disconnected)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                      onPressed: () {
                        context.read<ConnectionBloc>().add(ConnectionReconnectRequested());
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ClipboardStatusCard extends StatelessWidget {
  const ClipboardStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClipboardBloc, ClipboardState>(
      builder: (context, state) {
        String text = 'No content synced yet';
        String subtitle = 'Copy text on your PC to see it here';
        IconData icon = Icons.content_copy_rounded;
        Color accentColor = AppTheme.textSecondary.withOpacity(0.5);
        bool showCopyButton = false;

        if (state is ClipboardSyncing) {
          if (state.lastSyncedContent != null && state.lastSyncedContent!.isNotEmpty) {
            text = state.lastSyncedContent!;
            showCopyButton = true;
            if (state.lastSyncSource == 'remote') {
              subtitle = 'Teleported from PC';
              icon = Icons.terminal_rounded;
              accentColor = AppTheme.secondaryColor;
            } else {
              subtitle = 'Teleported to PC';
              icon = Icons.send_rounded;
              accentColor = AppTheme.primaryColor;
            }
          } else {
            subtitle = 'Telemetry sync active';
            accentColor = AppTheme.primaryColor;
          }
        } else if (state is ClipboardSyncStopped) {
          subtitle = 'Clipboard Sync Disabled';
          accentColor = Colors.redAccent.withOpacity(0.5);
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF13151B), // Terminal black box
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terminal Title bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CLIPBOARD TELEMETRY FEED',
                        style: TextStyle(
                          color: Colors.white30,
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle.toUpperCase(),
                    style: TextStyle(
                      color: accentColor.withOpacity(0.8),
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Code terminal content area
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                  if (showCopyButton) ...[
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.copy_all_rounded, color: Color(0xFF38BDF8), size: 20),
                        tooltip: 'Copy to Clipboard',
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF13151B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: const Color(0xFF38BDF8).withOpacity(0.2)),
                              ),
                              content: const Text(
                                'Copied to local clipboard',
                                style: TextStyle(color: Colors.white70),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
