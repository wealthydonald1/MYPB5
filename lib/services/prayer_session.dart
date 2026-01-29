import 'dart:async';
import 'package:flutter/foundation.dart';

class PrayerSessionState {
  final String? activeProjectId;
  final bool isRunning;
  final bool isPaused;

  /// seconds elapsed for the currently selected project in this session
  final int elapsedSeconds;

  const PrayerSessionState({
    required this.activeProjectId,
    required this.isRunning,
    required this.isPaused,
    required this.elapsedSeconds,
  });

  const PrayerSessionState.initial()
      : activeProjectId = null,
        isRunning = false,
        isPaused = false,
        elapsedSeconds = 0;

  PrayerSessionState copyWith({
    String? activeProjectId,
    bool? isRunning,
    bool? isPaused,
    int? elapsedSeconds,
  }) {
    return PrayerSessionState(
      activeProjectId: activeProjectId ?? this.activeProjectId,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

class PrayerSessionController extends ChangeNotifier {
  PrayerSessionState _state = const PrayerSessionState.initial();
  Timer? _timer;

  PrayerSessionState get state => _state;

  /// ✅ async so main.dart can await it
  Future<void> init() async {
    _cancelTimer();
    _state = const PrayerSessionState.initial();
    notifyListeners();
  }

  /// This is what your UI displays (session seconds).
  int get displayedElapsedSeconds => _state.elapsedSeconds;

  bool get hasActive => _state.activeProjectId != null;

  /// Select a project (optionally with leftover seconds like carrySeconds)
  Future<bool> selectProject(
    String projectId, {
    int initialElapsedSeconds = 0,
  }) async {
    // Don’t allow switching while timer running
    if (_state.isRunning) return false;

    // Don’t allow switching while paused with progress
    if (_state.isPaused &&
        _state.elapsedSeconds > 0 &&
        _state.activeProjectId != projectId) {
      return false;
    }

    _cancelTimer();

    _state = _state.copyWith(
      activeProjectId: projectId,
      isRunning: false,
      isPaused: false,
      elapsedSeconds: initialElapsedSeconds,
    );

    notifyListeners();
    return true;
  }

  Future<void> start() async {
    if (!hasActive) return;
    if (_state.isRunning) return;

    _state = _state.copyWith(isRunning: true, isPaused: false);
    notifyListeners();

    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _state = _state.copyWith(elapsedSeconds: _state.elapsedSeconds + 1);
      notifyListeners();
    });
  }

  Future<void> pause() async {
    if (!_state.isRunning) return;

    _cancelTimer();
    _state = _state.copyWith(isRunning: false, isPaused: true);
    notifyListeners();
  }

  Future<void> resume() async {
    if (!hasActive) return;
    if (!_state.isPaused) return;

    await start();
  }

  /// Stops timer and returns elapsed seconds, then resets elapsed to 0
  Future<int> stopAndReset() async {
    final seconds = _state.elapsedSeconds;

    _cancelTimer();
    _state = _state.copyWith(
      isRunning: false,
      isPaused: false,
      elapsedSeconds: 0,
    );
    notifyListeners();

    return seconds;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
