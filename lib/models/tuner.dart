import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:metro_drone_plugin/tuner_plugin_platform_interface.dart';

class Tuner {
  StreamSubscription? _streamSubscription;
  final _pitchController = StreamController<Pitch>.broadcast();

  Stream<Pitch> get pitchStream => _pitchController.stream;
  static final Tuner _instance = Tuner._();

  factory Tuner() => _instance;

  bool _isActive = false;

  bool get isActive => _isActive;

  Tuner._();

  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    if (!_pitchController.isClosed) {
      _pitchController.close();
    }
  }

  Future<bool> start() async {
    _isActive = await TunerPluginPlatform.instance.start() ?? false;

    if (_isActive) {
      _streamSubscription?.cancel();
      _streamSubscription =
          TunerPluginPlatform.instance.updates.listen(_onTunerDataChanged);
    }

    return _isActive;
  }

  Future<bool> stop() async {
    _isActive = await TunerPluginPlatform.instance.stop() ?? false;
    if (!_isActive) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
    return _isActive;
  }

  void _onTunerDataChanged(Map map) {
    try {
      if (map.containsKey("pitch") && map["pitch"] is Map) {
        final pitchMap = map["pitch"] as Map;
        final pitch = Pitch(
          note: pitchMap["note"]?.toString() ?? "Unknown",
          octave: pitchMap["octave"]?.toString() ?? "Unknown",
          frequency: (pitchMap["frequency"] as num?)?.toDouble() ?? 0.0,
          closestOffsetCents:
              (pitchMap["closestOffsetCents"] as num?)?.toDouble() ?? 0.0,
        );
        _pitchController.add(pitch);
      }
    } catch (e, stackTrace) {
      debugPrint("Ошибка в onDataUpdated: $e\n$stackTrace");
    }
  }
}

class Pitch {
  final String note;
  final String octave;
  final double frequency;
  final double closestOffsetCents;

  Pitch({
    required this.note,
    required this.octave,
    required this.frequency,
    required this.closestOffsetCents,
  });
}
