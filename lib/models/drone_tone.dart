import 'dart:async';

import 'package:metro_drone_plugin/drone_tone_plugin_platform_interface.dart';

enum SoundType {
  sine,
  organ;

  @override
  String toString() {
    return switch (this) {
      SoundType.sine => "sine",
      SoundType.organ => "organ",
    };
  }
}

class DroneTone {
  static final DroneTone _instance = DroneTone._();

  factory DroneTone() => _instance;

  DroneTone._() {
    listenToUpdates();
  }

  bool _isPlaying = false;
  bool _isPulsing = false;
  int _octave = 4;
  String _note = "A";
  double _tuningStandard = 440.0;
  SoundType _soundType = SoundType.sine;

  final _droneToneController = StreamController<DroneTone>.broadcast();

  Stream<DroneTone> get droneToneStream => _droneToneController.stream;

  bool get isPlaying => _isPlaying;

  bool get isPulsing => _isPulsing;

  int get octave => _octave;

  String get note => _note;

  SoundType get soundType => _soundType;

  double get tuningStandard => _tuningStandard;

  Future<String?> start() async {
    return await DroneTonePluginPlatform.instance.start();
  }

  Future<String?> stop() async {
    return await DroneTonePluginPlatform.instance.stop();
  }

  Future<String?> setPulsing(bool pulsing) async {
    return await DroneTonePluginPlatform.instance.setPulsing(pulsing);
  }

  Future<String?> setNote({
    required String note,
    required int octave,
  }) async {
    return await DroneTonePluginPlatform.instance.setNote(note: note, octave: octave);
  }

  Future<String?> setTuningStandard(double frequency) async {
    return await DroneTonePluginPlatform.instance.setTuningStandard(frequency);
  }

  Future<String?> setSoundType(SoundType soundType) async {
    return await DroneTonePluginPlatform.instance.setSoundType(soundType);
  }

  void listenToUpdates() {
    DroneTonePluginPlatform.instance.updates.listen(onDataChanged);
  }

  void onDataChanged(data) {
    print("onDroneToneDataChanged received: $data | type: ${data.runtimeType}");

    if (data is Map) {
      final map = data;

      // Обновляем поле _isPlaying и транслируем изменение через stream, если значение изменилось
      if (map.containsKey("isPlaying") && map["isPlaying"] is bool) {
        bool newIsPlaying = map["isPlaying"] as bool;
        if (newIsPlaying != _isPlaying) {
          _isPlaying = newIsPlaying;
        }
      }

      if (map.containsKey("isPulsing") && map["isPulsing"] is bool) {
        bool newIsPulsing = map["isPulsing"] as bool;
        if (newIsPulsing != _isPulsing) {
          _isPulsing = newIsPulsing;
        }
      }

      if (map.containsKey("octave") && map["octave"] is int) {
        int newOctave = map["octave"] as int;
        if (newOctave != _octave) {
          _octave = newOctave;
        }
      }

      if (map.containsKey("note") && map["note"] is String) {
        String newNote = map["note"] as String;
        if (newNote != _note) {
          _note = newNote;
        }
      }

      if (map.containsKey("tuningStandard") &&
          map["tuningStandard"] is double) {
        double newTuningStandard = map["tuningStandard"] as double;
        if (newTuningStandard != _tuningStandard) {
          _tuningStandard = newTuningStandard;
        }
      }

      if (map.containsKey("soundType") && map["soundType"] is String) {
        final newSoundType = _convertSoundType(map["soundType"] as String);
        if (newSoundType != _soundType) {
          _soundType = newSoundType;
        }
      }

      _droneToneController.add(this);
    } else {
      print("Received data is not a Map. Ignoring update.");
    }
  }

  SoundType _convertSoundType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case "sine":
        return SoundType.sine;
      case "organ":
        return SoundType.organ;
      default:
        return SoundType.sine;
    }
  }
}
