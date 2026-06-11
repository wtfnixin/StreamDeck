import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/dependency_injection/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/connection/presentation/bloc/connection_bloc.dart';
import 'features/launcher/presentation/bloc/launcher_bloc.dart';
import 'features/clipboard/presentation/bloc/clipboard_bloc.dart';
import 'features/workspace/presentation/bloc/workspace_bloc.dart';
import 'features/gestures/presentation/bloc/gesture_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive Local Database
  await Hive.initFlutter();

  // 2. Initialize Service Locator DI
  await initInjection();

  runApp(const DevDeckApp());
}

class DevDeckApp extends StatelessWidget {
  const DevDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>(),
        ),
        BlocProvider<ConnectionBloc>(
          create: (context) => sl<ConnectionBloc>(),
        ),
        BlocProvider<LauncherBloc>(
          create: (context) => sl<LauncherBloc>(),
        ),
        BlocProvider<ClipboardBloc>(
          create: (context) => sl<ClipboardBloc>(),
        ),
        BlocProvider<WorkspaceBloc>(
          create: (context) => sl<WorkspaceBloc>(),
        ),
        BlocProvider<GestureBloc>(
          create: (context) => sl<GestureBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'DevDeck Remote Control',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
