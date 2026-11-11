import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_event.dart';
import 'package:remote/blocs/tv_connection/tv_connection_state.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_app_control.dart';
import 'package:remote/core/interfaces/tv_input_control.dart';
import 'package:remote/core/interfaces/tv_text_control.dart';
import 'package:remote/core/interfaces/tv_volume_control.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/core/services/app_diagnostics.dart';

export 'tv_connection_event.dart';
export 'tv_connection_state.dart';

class TvConnectionBloc extends Bloc<TvConnectionEvent, TvConnectionState> {
  TvConnectionBloc({required TvRepository repository})
    : _repository = repository,
      super(const TvConnectionState.idle()) {
    on<TvConnectRequested>(_onConnectRequested);
    on<TvDisconnectRequested>(_onDisconnectRequested);
    on<TvSendKeyRequested>(_onSendKeyRequested);
    on<TvPowerOffRequested>(_onPowerOffRequested);
    on<TvForgetRequested>(_onForgetRequested);
    on<TvDisconnectionDetected>(_onDisconnectionDetected);
  }

  final TvRepository _repository;

  /// Bumped by forget/disconnect so a connect that finishes afterwards is
  /// discarded instead of resurrecting the TV.
  int _generation = 0;

  TVDevice wakeConfiguration(TVDevice device) {
    final saved = _repository.knownTvs().where((tv) => tv.host == device.host);
    return saved.isEmpty ? device : saved.first;
  }

  Future<TVDevice> configureWake(TVDevice device, String mac) =>
      _repository.configureWake(device, mac);

  Future<void> sendText(
    String text, {
    required String expectedHost,
    bool submit = false,
  }) async {
    final tv = _repository.current;
    final generation = _generation;
    if (!state.isConnected ||
        state.device?.host != expectedHost ||
        tv is! TvTextControl) {
      throw StateError('Text input unavailable for this session');
    }
    await (tv! as TvTextControl).insertText(text);
    if (submit) {
      if (generation != _generation ||
          _repository.current != tv ||
          !state.isConnected) {
        throw StateError('TV session changed');
      }
      await (tv as TvTextControl).submitText();
    }
  }

  Future<void> openYouTube() async {
    final tv = _repository.current;
    if (!state.isConnected || tv is! TvAppControl) {
      throw UnsupportedError('YouTube shortcut unavailable');
    }
    await (tv! as TvAppControl).openYouTube();
  }

  Future<void> openDisneyPlus() async {
    final tv = _repository.current;
    if (!state.isConnected || tv is! TvAppControl) {
      throw UnsupportedError('Disney+ shortcut unavailable');
    }
    await (tv! as TvAppControl).openDisneyPlus();
  }

  Future<void> openNetflix() => _openStreamingApp(prime: false);
  Future<void> openPrimeVideo() => _openStreamingApp(prime: true);
  Future<void> _openStreamingApp({required bool prime}) async {
    final tv = _repository.current;
    if (!state.isConnected || tv is! TvAppControl) {
      throw UnsupportedError('App shortcut unavailable');
    }
    final apps = tv! as TvAppControl;
    if (prime) {
      await apps.openPrimeVideo();
    } else {
      await apps.openNetflix();
    }
  }

  Future<int?> volume() async {
    final tv = _repository.current;
    if (!state.isConnected || tv is! TvVolumeControl) return null;
    return await (tv! as TvVolumeControl).volume();
  }

  Future<void> setVolume(int value) async {
    final tv = _repository.current;
    if (!state.isConnected || tv is! TvVolumeControl) {
      throw StateError('Volume unavailable');
    }
    await (tv! as TvVolumeControl).setVolume(value);
  }

  Future<List<TvInput>> inputs() async {
    final tv = _repository.current;
    if (tv == null || !state.isConnected || tv is! TvInputControl) {
      throw StateError('TV not connected');
    }
    return await (tv as TvInputControl).inputs();
  }

  Future<void> selectInput(String id) async {
    final tv = _repository.current;
    if (tv == null || !state.isConnected || tv is! TvInputControl) {
      throw StateError('TV not connected');
    }
    await (tv as TvInputControl).selectInput(id);
  }

  Future<void> _onConnectRequested(
    TvConnectRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    // A second tap while a connect (and possibly a pairing prompt) is in
    // flight would open a second socket and a second prompt.
    if (state.isConnecting) return;
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: TvConnectionStatus.connecting,
        device: event.device,
        clearError: true,
        clearDisconnection: true,
      ),
    );

    try {
      unawaited(
        AppDiagnostics.record(
          'stage',
          'Conectando à TV; ligar primeiro: ${event.wakeFirst}',
        ),
      );
      void disconnected(DisconnectionType type) {
        if (!isClosed && generation == _generation) {
          add(TvDisconnectionDetected(type.name));
        }
      }

      if (event.wakeFirst) {
        await _repository.connect(
          event.device,
          onDisconnected: disconnected,
          wakeFirst: true,
        );
      } else {
        await _repository.connect(event.device, onDisconnected: disconnected);
      }
      if (generation != _generation) {
        // Forgotten or disconnected while connecting: drop the session.
        await _repository.disconnect();
        return;
      }
      emit(
        state.copyWith(
          status: TvConnectionStatus.connected,
          device: _repository.currentDevice ?? event.device,
        ),
      );
    } catch (e) {
      unawaited(AppDiagnostics.record('error', 'Conexão: $e'));
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: TvConnectionStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDisconnectRequested(
    TvDisconnectRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    _generation++;
    await _repository.disconnect();
    emit(
      state.copyWith(
        status: TvConnectionStatus.disconnected,
        disconnectionType: DisconnectionType.userInitiated,
      ),
    );
  }

  Future<void> _onSendKeyRequested(
    TvSendKeyRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    if (state.status != TvConnectionStatus.connected) return;
    try {
      await _repository.sendKey(event.key);
    } catch (e) {
      // One key failing (e.g. the LG pointer socket being slow) must not
      // take the session down while the main connection is still alive.
      if (_repository.current?.isConnected ?? false) {
        emit(state.copyWith(errorMessage: e.toString()));
        return;
      }
      emit(
        state.copyWith(
          status: TvConnectionStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPowerOffRequested(
    TvPowerOffRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    if (!state.isConnected) return;
    final generation = _generation;
    try {
      await _repository.sendKey(KeyCodes.KEY_POWER);
      if (generation != _generation) return;
      _generation++;
      await _repository.disconnect();
      emit(
        state.copyWith(
          status: TvConnectionStatus.disconnected,
          disconnectionType: DisconnectionType.userInitiated,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onForgetRequested(
    TvForgetRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    _generation++;
    final device = event.device;
    if (device == null) {
      await _repository.forgetCurrent();
      emit(const TvConnectionState.idle());
      return;
    }
    await _repository.forget(device);
    if (state.device?.host == device.host) {
      emit(const TvConnectionState.idle());
    }
  }

  void _onDisconnectionDetected(
    TvDisconnectionDetected event,
    Emitter<TvConnectionState> emit,
  ) {
    final type = DisconnectionType.values.firstWhere(
      (t) => t.name == event.reason,
      orElse: () => DisconnectionType.unknown,
    );
    emit(
      state.copyWith(
        status: TvConnectionStatus.disconnected,
        disconnectionType: type,
      ),
    );
  }
}
