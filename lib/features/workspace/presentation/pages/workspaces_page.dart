import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/workspace_models.dart';
import '../bloc/workspace_bloc.dart';
import '../bloc/workspace_event.dart';
import '../bloc/workspace_state.dart';

class WorkspacesPage extends StatefulWidget {
  const WorkspacesPage({super.key});

  @override
  State<WorkspacesPage> createState() => _WorkspacesPageState();
}

class _WorkspacesPageState extends State<WorkspacesPage> {
  @override
  void initState() {
    super.initState();

    // Force horizontal (landscape) orientation on entry
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    context.read<WorkspaceBloc>().add(WorkspaceLoadList());
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
      case 'work': return Icons.work_rounded;
      case 'language': return Icons.language_rounded;
      case 'terminal': return Icons.terminal_rounded;
      case 'videogame_asset': return Icons.videogame_asset_rounded;
      default: return Icons.workspaces_filled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D11), // Matte black background
      appBar: AppBar(
        backgroundColor: const Color(0xFF13151B),
        elevation: 0,
        title: const Text('Workspace Flows'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: BlocConsumer<WorkspaceBloc, WorkspaceState>(
        listener: (context, state) {
          if (state is WorkspaceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          } else if (state is WorkspaceExecutionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workspace flow executed successfully!'),
                backgroundColor: AppTheme.secondaryColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkspaceLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          } else if (state is WorkspaceListLoaded) {
            final list = state.workspaces;
            return _buildContent(list);
          } else if (state is WorkspaceExecutionInProgress) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                  SizedBox(height: 24),
                  Text('Executing Workspace Flow...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Please wait while steps run on your PC', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(List<WorkspaceModel> workspaces) {
    final displayWorkspaces = workspaces.take(8).toList();
    final showAddButton = displayWorkspaces.length < 8;
    final itemCount = displayWorkspaces.length + (showAddButton ? 1 : 0);

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
              'Tap to trigger, hold to delete. Max 8 workflows.',
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
                  if (showAddButton && index == displayWorkspaces.length) {
                    return _buildAddKeyButton();
                  }
                  return _buildWorkspaceKey(displayWorkspaces[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceKey(WorkspaceModel ws) {
    const baseColor = Color(0xFFAB47BC); // Violet/purple tint
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: GestureDetector(
          onTap: () {
            context.read<WorkspaceBloc>().add(WorkspaceExecute(ws.id));
          },
          onLongPress: () => _showDeleteConfirmation(ws),
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
                Icon(
                  _getIconData(ws.icon),
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  ws.name,
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
          onTap: () => _showAddWorkspaceDialog(context),
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

  void _showDeleteConfirmation(WorkspaceModel ws) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Flow?'),
        content: Text('Are you sure you want to delete "${ws.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkspaceBloc>().add(WorkspaceDelete(ws.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddWorkspaceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = 'code';

    List<Map<String, dynamic>> tempActions = [];

    final icons = ['code', 'work', 'language', 'terminal', 'videogame_asset'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Workspace Flow'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Flow Name', hintText: 'e.g. Coding Mode'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Open editor and browser links'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(labelText: 'Icon Template'),
                      items: icons.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedIcon = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Text('Actions Sequence Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (tempActions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No steps added yet. Add steps below.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tempActions.length,
                        itemBuilder: (context, index) {
                          final step = tempActions[index];
                          return ListTile(
                            leading: CircleAvatar(radius: 10, child: Text('${index + 1}', style: const TextStyle(fontSize: 10))),
                            title: Text('${step['actionType']}: ${step['displayDetail']}', style: const TextStyle(fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                              onPressed: () => setDialogState(() => tempActions.removeAt(index)),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddStepBottomSheet(context, (newStep) {
                        setDialogState(() {
                          tempActions.add(newStep);
                        });
                      }),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: const Text('Add Action Step'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceColor,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final wsId = const Uuid().v4();
                    final List<WorkspaceActionModel> actions = [];
                    for (int i = 0; i < tempActions.length; i++) {
                      actions.add(WorkspaceActionModel(
                        id: const Uuid().v4(),
                        workspaceId: wsId,
                        actionType: tempActions[i]['actionType'] as String,
                        payload: Map<String, dynamic>.from(tempActions[i]['payload'] as Map),
                        sequenceOrder: i,
                      ));
                    }
                    final ws = WorkspaceModel(
                      id: wsId,
                      name: nameController.text,
                      description: descController.text,
                      icon: selectedIcon,
                      actions: actions,
                    );
                    context.read<WorkspaceBloc>().add(WorkspaceRegister(ws));
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddStepBottomSheet(BuildContext context, Function(Map<String, dynamic>) onStepAdded) {
    String stepType = 'launch_app';
    final payloadController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Sequence Step', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: stepType,
                decoration: const InputDecoration(labelText: 'Action Type'),
                items: const [
                  DropdownMenuItem(value: 'launch_app', child: Text('Launch Desktop App')),
                  DropdownMenuItem(value: 'launch_website', child: Text('Open Web Link')),
                  DropdownMenuItem(value: 'run_command', child: Text('Run Shell Command')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => stepType = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: payloadController,
                decoration: InputDecoration(
                  labelText: stepType == 'launch_app'
                      ? 'Executable Path / Command (e.g. code)'
                      : stepType == 'launch_website'
                          ? 'URL Path (e.g. https://github.com)'
                          : 'Terminal Command (e.g. shutdown /s /t 60)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (payloadController.text.isNotEmpty) {
                    Map<String, dynamic> payload = {};
                    if (stepType == 'launch_app') {
                      payload = {'executablePath': payloadController.text};
                    } else if (stepType == 'launch_website') {
                      payload = {'url': payloadController.text};
                    } else if (stepType == 'run_command') {
                      payload = {'command': payloadController.text};
                    }

                    onStepAdded({
                      'actionType': stepType,
                      'payload': payload,
                      'displayDetail': payloadController.text,
                    });
                    Navigator.pop(bottomSheetContext);
                  }
                },
                child: const Text('Add Step'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
