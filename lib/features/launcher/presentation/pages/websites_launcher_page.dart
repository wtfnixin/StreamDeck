import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/launcher_models.dart';
import '../bloc/launcher_bloc.dart';
import '../bloc/launcher_event.dart';
import '../bloc/launcher_state.dart';

class WebsitesLauncherPage extends StatefulWidget {
  const WebsitesLauncherPage({super.key});

  @override
  State<WebsitesLauncherPage> createState() => _WebsitesLauncherPageState();
}

class _WebsitesLauncherPageState extends State<WebsitesLauncherPage> {
  final SocketService _socketService = sl<SocketService>();
  @override
  void initState() {
    super.initState();

    // Force horizontal (landscape) orientation on entry
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    context.read<LauncherBloc>().add(LauncherLoadWebsites());
  }

  @override
  void dispose() {
    // Restore default orientation on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'code': return Icons.code_rounded;
      case 'video_library': return Icons.video_library_rounded;
      case 'chat': return Icons.chat_bubble_rounded;
      case 'language': return Icons.language_rounded;
      case 'work': return Icons.work_rounded;
      default: return Icons.link_rounded;
    }
  }

  Widget _buildWebIcon(WebsiteModel web) {
    try {
      String url = web.url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      final domain = uri.host.isNotEmpty ? uri.host : web.url;
      // Use the agent's favicon proxy to avoid CORS issues in Flutter web
      final agentBase = _socketService.agentBaseUrl ?? 'http://localhost:8080';
      final faviconUrl = '$agentBase/favicon?domain=${Uri.encodeComponent(domain)}';
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          faviconUrl,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.language_rounded,
            color: Colors.white,
            size: 28,
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (_) {}

    return Icon(
      _getIconData(web.icon),
      color: Colors.white,
      size: 28,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D11), // Matte black background
      appBar: AppBar(
        backgroundColor: const Color(0xFF13151B),
        elevation: 0,
        title: const Text('Website Shortcuts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: BlocConsumer<LauncherBloc, LauncherState>(
        listener: (context, state) {
          if (state is LauncherFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LauncherLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          } else if (state is LauncherWebsitesLoaded) {
            final websites = state.websites;
            return _buildContent(websites);
          } else if (state is LauncherFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load websites',
                    style: TextStyle(fontSize: 18, color: AppTheme.textPrimary.withOpacity(0.9), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<LauncherBloc>().add(LauncherLoadWebsites()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(List<WebsiteModel> websites) {
    final displayWebsites = websites.take(8).toList();
    final showAddButton = displayWebsites.length < 8;
    final itemCount = displayWebsites.length + (showAddButton ? 1 : 0);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - kToolbarHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 70;
    final availableWidth = screenWidth - 32;

    double aspectRatio = (availableWidth / 2) / (availableHeight > 0 ? availableHeight : 1);
    if (aspectRatio < 0.75) aspectRatio = 0.75;
    if (aspectRatio > 2.2) aspectRatio = 2.2;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tap to trigger, hold to delete. Max 8 websites.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 columns (4x2 layout)
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (showAddButton && index == displayWebsites.length) {
                    return _buildAddKeyButton();
                  }
                  return _buildWebsiteKey(displayWebsites[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteKey(WebsiteModel web) {
    const baseColor = Color(0xFFEC407A); // Magenta tint
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: GestureDetector(
          onTap: () {
            context.read<LauncherBloc>().add(LauncherLaunchWebsite(web.id));
          },
          onLongPress: () => _showDeleteConfirmation(web),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  baseColor.withOpacity(0.25),
                  baseColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.12),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWebIcon(web),
                const SizedBox(height: 6),
                Text(
                  web.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddKeyButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: GestureDetector(
          onTap: () => _showAddWebsiteDialog(context),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white38,
                  size: 28,
                ),
                SizedBox(height: 6),
                Text(
                  'Add Key',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(WebsiteModel web) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Shortcut?'),
        content: Text('Are you sure you want to remove the shortcut for ${web.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<LauncherBloc>().add(LauncherDeleteWebsite(web.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddWebsiteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    String selectedIcon = 'language';

    final icons = [
      {'label': 'Globe', 'value': 'language'},
      {'label': 'Code', 'value': 'code'},
      {'label': 'Video', 'value': 'video_library'},
      {'label': 'Chat', 'value': 'chat'},
      {'label': 'Briefcase', 'value': 'work'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Register Website Shortcut'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Website Name',
                    hintText: 'e.g. GitHub',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'e.g. https://github.com',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedIcon,
                  decoration: const InputDecoration(labelText: 'Icon Template'),
                  items: icons.map((icon) {
                    return DropdownMenuItem(
                      value: icon['value'],
                      child: Text(icon['label']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedIcon = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                  context.read<LauncherBloc>().add(LauncherAddWebsite(
                    name: nameController.text,
                    url: urlController.text,
                    icon: selectedIcon,
                  ));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
