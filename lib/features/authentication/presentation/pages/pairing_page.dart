import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pairing_info.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PairingPage extends StatefulWidget {
  const PairingPage({super.key});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MobileScannerController _scannerController;
  final _formKey = GlobalKey<FormState>();
  
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _submitManualPairing() {
    if (_formKey.currentState?.validate() ?? false) {
      final host = _hostController.text.trim();
      final port = int.parse(_portController.text.trim());
      final token = _tokenController.text.trim();

      context.read<AuthBloc>().add(
        AuthPairDeviceRequested(
          PairingInfo(host: host, port: port, token: token),
        ),
      );
    }
  }

  void _onQRScanned(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.startsWith('devdeck://pair')) {
        try {
          final uri = Uri.parse(code);
          final host = uri.queryParameters['host'];
          final portStr = uri.queryParameters['port'];
          final token = uri.queryParameters['token'];

          if (host != null && portStr != null && token != null) {
            final port = int.parse(portStr);
            context.read<AuthBloc>().add(
              AuthPairDeviceRequested(
                PairingInfo(host: host, port: port, token: token),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid QR Code format')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully Paired with Agent!')),
          );
          context.go('/dashboard');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('DevDeck Pairing'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
                Tab(icon: Icon(Icons.edit_note), text: 'Manual Setup'),
              ],
            ),
          ),
          body: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text('Connecting and pairing with DevDeck Agent...'),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), // Prevent camera dispose issues
                  children: [
                    // Tab 1: QR Scanner View
                    _buildQRScannerTab(),
                    
                    // Tab 2: Manual Settings View
                    _buildManualSetupTab(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildQRScannerTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Align the QR code printed in the PC Agent terminal inside the scanner box below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onQRScanned,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildManualSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Enter PC Agent Host Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ensure your Android device and PC are on the same local network.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host IP Address',
                hintText: 'e.g., 192.168.1.5',
                prefixIcon: Icon(Icons.computer),
              ),
              keyboardType: TextInputType.values.first, // Text input
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter Host IP Address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Agent Port',
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter Agent Port';
                }
                if (int.tryParse(val.trim()) == null) {
                  return 'Port must be a number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Pairing Token',
                hintText: 'Generated by your PC Agent',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter pairing token';
                }
                return null;
              },
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _submitManualPairing,
              child: const Text('Pair Device'),
            ),
          ],
        ),
      ),
    );
  }
}
