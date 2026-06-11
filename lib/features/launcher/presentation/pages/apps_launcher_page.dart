import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/launcher_models.dart';
import '../bloc/launcher_bloc.dart';
import '../bloc/launcher_event.dart';
import '../bloc/launcher_state.dart';

class AppsLauncherPage extends StatefulWidget {
  const AppsLauncherPage({super.key});

  @override
  State<AppsLauncherPage> createState() => _AppsLauncherPageState();
}

class _AppsLauncherPageState extends State<AppsLauncherPage> {
  @override
  void initState() {
    super.initState();
    
    // Force horizontal (landscape) orientation on entry
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    context.read<LauncherBloc>().add(LauncherLoadApps());
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
      case 'terminal': return Icons.terminal_rounded;
      case 'description': return Icons.description_rounded;
      case 'code': return Icons.code_rounded;
      case 'language': return Icons.language_rounded;
      case 'calculate': return Icons.calculate_rounded;
      case 'assessment': return Icons.assessment_rounded;
      case 'gamepad': return Icons.gamepad_rounded;
      case 'work': return Icons.work_rounded;
      default: return Icons.rocket_launch_rounded;
    }
  }

  Widget _buildAppIcon(AppModel app) {
    if (app.icon != null && app.icon!.startsWith('data:image/')) {
      try {
        final base64Str = app.icon!.split(',')[1];
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            bytes,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              _getIconData(app.icon),
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      } catch (_) {}
    }

    final name = app.name.toLowerCase();
    String? brandIconUrl;
    if (name.contains('code') || name.contains('vs code') || name.contains('visual studio')) {
      brandIconUrl = 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vscode/vscode-original.svg';
    } else if (name.contains('chrome') || name.contains('browser')) {
      brandIconUrl = 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/chrome/chrome-original.svg';
    } else if (name.contains('github')) {
      brandIconUrl = 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/github/github-original.svg';
    } else if (name.contains('terminal') || name.contains('bash') || name.contains('cmd') || name.contains('powershell')) {
      brandIconUrl = 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/bash/bash-original.svg';
    }

    if (brandIconUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          brandIconUrl,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            _getIconData(app.icon),
            color: Colors.white,
            size: 28,
          ),
        ),
      );
    }

    return Icon(
      _getIconData(app.icon),
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
        title: const Text('Quick App Launcher'),
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
          } else if (state is LauncherAppsLoaded) {
            final apps = state.apps;
            return _buildContent(apps);
          } else if (state is LauncherFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load apps',
                    style: TextStyle(fontSize: 18, color: AppTheme.textPrimary.withOpacity(0.9), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<LauncherBloc>().add(LauncherLoadApps()),
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

  Widget _buildContent(List<AppModel> apps) {
    final displayApps = apps.take(8).toList();
    final showAddButton = displayApps.length < 8;
    final itemCount = displayApps.length + (showAddButton ? 1 : 0);

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
              'Tap to trigger, hold to delete. Max 8 apps.',
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
                  if (showAddButton && index == displayApps.length) {
                    return _buildAddKeyButton();
                  }
                  return _buildAppKey(displayApps[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppKey(AppModel app) {
    const baseColor = Color(0xFF2979FF); // Blue tint
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: GestureDetector(
          onTap: () {
            context.read<LauncherBloc>().add(LauncherLaunchApp(app.id));
          },
          onLongPress: () => _showDeleteConfirmation(app),
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
                _buildAppIcon(app),
                const SizedBox(height: 6),
                Text(
                  app.name,
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
          onTap: () => _showAddAppDialog(context),
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

  void _showDeleteConfirmation(AppModel app) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Shortcut?'),
        content: Text('Are you sure you want to remove the shortcut for ${app.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<LauncherBloc>().add(LauncherDeleteApp(app.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddAppDialog(BuildContext context) {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    String selectedIcon = 'rocket';
    String selectedCategory = 'Utility';

    final icons = [
      {'label': 'Rocket', 'value': 'rocket'},
      {'label': 'Terminal', 'value': 'terminal'},
      {'label': 'Document', 'value': 'description'},
      {'label': 'Code', 'value': 'code'},
      {'label': 'Globe', 'value': 'language'},
      {'label': 'Calculator', 'value': 'calculate'},
      {'label': 'Chart', 'value': 'assessment'},
      {'label': 'Gamepad', 'value': 'gamepad'},
      {'label': 'Work', 'value': 'work'},
    ];

    final categories = ['Utility', 'Developer', 'System', 'Game', 'Social', 'Other'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Register Application'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'App Name',
                    hintText: 'e.g. VS Code',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(
                    labelText: 'Executable Path / Command',
                    hintText: 'e.g. code or notepad.exe',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCategory = val);
                  },
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
                if (nameController.text.isNotEmpty && pathController.text.isNotEmpty) {
                  context.read<LauncherBloc>().add(LauncherAddApp(
                    name: nameController.text,
                    executablePath: pathController.text,
                    icon: selectedIcon,
                    category: selectedCategory,
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
