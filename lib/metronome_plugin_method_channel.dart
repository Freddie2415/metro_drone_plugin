import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'metronome_plugin_platform_interface.dart';
import 'models/metronome.dart';

/// An implementation of [MetronomePluginPlatform] that uses method channels.
class MethodChannelMetronomePlugin extends MetronomePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('metro_drone_plugin/metronome');
  final eventChannel =
      const EventChannel("metro_drone_plugin/metronome/events");

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
  Future<void> setBpm(int bpm) async {
    return await methodChannel.invokeMethod<void>(
      'setBpm',
      bpm,
    );
  }

  @override
  Future<void> setSubdivision(Subdivision subdivision) async {
    return await methodChannel.invokeMethod<void>(
      'setSubdivision',
      subdivision.toMap(),
    );
  }

  @override
  Future<void> setNextTickType({required int tickIndex}) async {
    return await methodChannel.invokeMethod<void>(
      'setNextTickType',
      tickIndex,
    );
  }

  @override
  Future<void> setTimeSignatureDenominator(int value) async {
    return await methodChannel.invokeMethod<void>(
      'setTimeSignatureDenominator',
      value,
    );
  }

  @override
  Future<void> setTimeSignatureNumerator(int value) async {
    return await methodChannel.invokeMethod<void>(
      'setTimeSignatureNumerator',
      value,
    );
  }

  @override
  Future<void> setDroneDurationRation(double value) async {
    return await methodChannel.invokeMethod<void>(
      'setDroneDurationRatio',
      value,
    );
  }

  @override
  Stream<Map> get updates {
    return eventChannel.receiveBroadcastStream().map((event) => event as Map);
  }
}
