import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'metronome_plugin_platform_interface.dart';
import 'models/metronome.dart';

/// An implementation of [MetronomePluginPlatform] that uses method channels.
class MethodChannelMetronomePlugin extends MetronomePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('metro_drone_plugin/metronome');
  final metronomeUpdatesEventChannel =
      const EventChannel("metro_drone_plugin/metronome/events");

  final metronomeTickEventChannel =
      const EventChannel("metro_drone_plugin/metronome/tick");

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> start() async {
    return await methodChannel.invokeMethod<String>("start");
  }

  @override
  Future<String?> stop() async {
    return await methodChannel.invokeMethod<String>("stop");
  }

  @override
  Future<String?> tap() async {
    return await methodChannel.invokeMethod<String>("tap");
  }

  @override
  Future<String?> setBpm(int bpm) async {
    return await methodChannel.invokeMethod<String>(
      'setBpm',
      bpm,
    );
  }

  @override
  Future<String?> setSubdivision(Subdivision subdivision) async {
    return await methodChannel.invokeMethod<String>(
      'setSubdivision',
      subdivision.toMap(),
    );
  }

  @override
  Future<String?> setNextTickType({required int tickIndex}) async {
    return await methodChannel.invokeMethod<String>(
      'setNextTickType',
      tickIndex,
    );
  }

  @override
  Future<String?> setTimeSignatureDenominator(int value) async {
    return await methodChannel.invokeMethod<String>(
      'setTimeSignatureDenominator',
      value,
    );
  }

  @override
  Future<String?> setTimeSignatureNumerator(int value) async {
    return await methodChannel.invokeMethod<String>(
      'setTimeSignatureNumerator',
      value,
    );
  }

  @override
  Future<String?> setDroneDurationRation(double value) async {
    return await methodChannel.invokeMethod<String>(
      'setDroneDurationRatio',
      value,
    );
  }

  @override
  Future<String?> setTickTypes(List<TickType> value) async {
    return await methodChannel.invokeMethod<String>(
      'setTickTypes',
      value.map((t) => t.toString()).toList(),
    );
  }

  @override
  Stream<Map> get updates {
    return metronomeUpdatesEventChannel
        .receiveBroadcastStream()
        .map((event) => event as Map);
  }

  @override
  Stream<int> get tickStream {
    return metronomeTickEventChannel
        .receiveBroadcastStream()
        .map((event) => event as int);
  }
}
