import 'dart:math';

import 'package:flutter/services.dart';
import 'package:metro_drone_plugin/drone_tone_plugin_platform_interface.dart';

import 'models/drone_tone.dart';

class MethodChannelDroneTonePlugin extends DroneTonePluginPlatform {
  final methodChannel = const MethodChannel('metro_drone_plugin/drone_tone');
  final eventChannel =
      const EventChannel('metro_drone_plugin/drone_tone/events');

  @override
  Future<String?> start() async {
    return await methodChannel.invokeMethod<String>("start");
  }

  @override
  Future<String?> stop() async {
    return await methodChannel.invokeMethod<String>("stop");
  }

  @override
  Future<String?> setPulsing(bool pulsing) async {
    return await methodChannel.invokeMethod<String>("setPulsing", pulsing);
  }

  @override
  Future<String?> setNote({
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

    return await methodChannel.invokeMethod<String>(
      "setNote",
      {
        "note": validNote,
        "octave": validOctave,
      },
    );
  }

  @override
  Future<String?> setTuningStandard(double frequency) async {
    return await methodChannel.invokeMethod<String>("setTuningStandard", frequency);
  }

  @override
  Future<String?> setSoundType(SoundType soundType) async {
    return await methodChannel.invokeMethod<String>("setSoundType", soundType.toString());
  }

  @override
  Future<String?> configure({
    String? note,
    int? octave,
    double? tuningStandard,
    SoundType? soundType,
    bool? isPulsing,
  }) async {
    final Map<String, dynamic> args = {};

    if (note != null) {
      final String validNote = [
        "C", "C#", "D", "D#", "E", "F",
        "F#", "G", "G#", "A", "A#", "B",
      ].firstWhere((e) => e == note, orElse: () => "C");
      args['note'] = validNote;
    }

    if (octave != null) {
      args['octave'] = min(7, max(1, octave));
    }

    if (tuningStandard != null) {
      args['tuningStandard'] = tuningStandard;
    }

    if (soundType != null) {
      args['soundType'] = soundType.toString();
    }

    if (isPulsing != null) {
      args['isPulsing'] = isPulsing;
    }

    return await methodChannel.invokeMethod<String>("configure", args);
  }

  @override
  Stream<Map> get updates {
    return eventChannel.receiveBroadcastStream().map((event) => event as Map);
  }
}
