import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/storage/secure_storage.dart';
import 'clipboard_event.dart';
import 'clipboard_state.dart';

class ClipboardBloc extends Bloc<ClipboardEvent, ClipboardState> {
  final SocketService _socketService;
  final SecureStorage _secureStorage;
  Timer? _pollingTimer;
  String _lastContent = '';
  bool _isListeningSocket = false;

  ClipboardBloc(this._socketService, this._secureStorage) : super(ClipboardInitial()) {
    on<ClipboardStartSync>(_onStartSync);
    on<ClipboardStopSync>(_onStopSync);
    on<ClipboardLocalChanged>(_onLocalChanged);
    on<ClipboardRemoteReceived>(_onRemoteReceived);
    on<ClipboardToggleSync>(_onToggleSync);
  }

  Future<void> _onStartSync(ClipboardStartSync event, Emitter<ClipboardState> emit) async {
    if (!_secureStorage.getClipboardSyncEnabled()) {
      emit(ClipboardSyncStopped());
      return;
    }
    emit(const ClipboardSyncing(lastSyncedContent: null, lastSyncSource: null));

    // Listen to remote changes
    if (!_isListeningSocket) {
      _socketService.on('clipboard:sync', (data) {
        if (data is Map && data['content'] is String) {
          final content = data['content'] as String;
          add(ClipboardRemoteReceived(content));
        }
      });
      _isListeningSocket = true;
    }

    // Start polling local clipboard changes
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text != null && text.isNotEmpty && text != _lastContent) {
          _lastContent = text;
          add(ClipboardLocalChanged(text));
        }
      } catch (e) {
        // Suppress errors on web where reading clipboard without user action throws
      }
    });
  }

  void _onStopSync(ClipboardStopSync event, Emitter<ClipboardState> emit) {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    if (_isListeningSocket) {
      _socketService.off('clipboard:sync');
      _isListeningSocket = false;
    }

    emit(ClipboardSyncStopped());
  }

  void _onLocalChanged(ClipboardLocalChanged event, Emitter<ClipboardState> emit) {
    AppLogger.info('📋 Local clipboard change detected, syncing to PC: "${event.content.substring(0, event.content.length > 20 ? 20 : event.content.length)}..."');
    
    _socketService.emit('clipboard:sync', {'content': event.content});
    
    emit(ClipboardSyncing(
      lastSyncedContent: event.content,
      lastSyncSource: 'local',
    ));
  }

  Future<void> _onRemoteReceived(ClipboardRemoteReceived event, Emitter<ClipboardState> emit) async {
    if (event.content == _lastContent) return;

    AppLogger.info('📋 Received remote clipboard from PC: "${event.content.substring(0, event.content.length > 20 ? 20 : event.content.length)}..."');
    _lastContent = event.content;

    try {
      await Clipboard.setData(ClipboardData(text: event.content));
    } catch (e) {
      AppLogger.warning('Failed to write to local clipboard (often blocked by browser security): $e');
    }

    emit(ClipboardSyncing(
      lastSyncedContent: event.content,
      lastSyncSource: 'remote',
    ));
  }

  Future<void> _onToggleSync(ClipboardToggleSync event, Emitter<ClipboardState> emit) async {
    await _secureStorage.setClipboardSyncEnabled(event.enabled);
    if (event.enabled) {
      add(ClipboardStartSync());
    } else {
      add(ClipboardStopSync());
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    if (_isListeningSocket) {
      _socketService.off('clipboard:sync');
    }
    return super.close();
  }
}
