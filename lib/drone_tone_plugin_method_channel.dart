import 'dart:math';

import 'package:flutter/services.dart';
import 'package:metro_drone_plugin/drone_tone_plugin_platform_interface.dart';

import 'models/drone_tone.dart';

class MethodChannelDroneTonePlugin extends DroneTonePluginPlatform {
  final methodChannel = const MethodChannel('metro_drone_plugin/drone_tone');
  final eventChannel =
      const EventChannel('metro_drone_plugin/drone_tone/events');

  @override
  Future<void> start() async {
    await methodChannel.invokeMethod("start");
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod("stop");
  }

  @override
  Future<void> setPulsing(bool pulsing) async {
    await methodChannel.invokeMethod("setPulsing", pulsing);
  }

  @override
  Future<void> setNote({
    required String note,
    required int octave,
  }) async {
    final int validOctave = min(7, max(1, octave));
    final String validNote = [
      "C",
      "C#",
      "D",
      "D#",
      "E",
      "F",
      "F#",
      "G",
      "G#",
      "A",
      "A#",
      "B",
    ].firstWhere((e) => e == note, orElse: () => "C");

    await methodChannel.invokeMethod(
      "setNote",
      {
        "note": validNote,
        "octave": validOctave,
      },
    );
  }

  @override
  Future<void> setTuningStandard(double frequency) async {
    await methodChannel.invokeMethod("setTuningStandard", frequency);
  }

  @override
  Future<void> setSoundType(SoundType soundType) async {
    await methodChannel.invokeMethod("setSoundType", soundType.toString());
  }

  @override
  Stream<Map> get updates {
    return eventChannel.receiveBroadcastStream().map((event) => event as Map);
  }
}
