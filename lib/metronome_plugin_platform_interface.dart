import 'package:metro_drone_plugin/metronome_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/metronome.dart';

abstract class MetronomePluginPlatform extends PlatformInterface {
  /// Constructs a MetroDronePluginPlatform.
  MetronomePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static MetronomePluginPlatform _instance = MethodChannelMetronomePlugin();

  /// The default instance of [MetronomePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelMetronomePlugin].
  static MetronomePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MetronomePluginPlatform] when
  /// they register themselves.
  static set instance(MetronomePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<String?> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<String?> tap() {
    throw UnimplementedError('tap() has not been implemented.');
  }

  Future<void> setBpm(int bpm) {
    throw UnimplementedError('setBpm() has not been implemented.');
  }

  Future<void> setSubdivision(Subdivision subdivision) {
    throw UnimplementedError('setSubdivision() has not been implemented.');
  }

  Future<void> setTimeSignatureNumerator(int value) {
    throw UnimplementedError(
        'setTimeSignatureNumerator() has not been implemented.');
  }

  Future<void> setTimeSignatureDenominator(int value) {
    throw UnimplementedError(
        'setTimeSignatureDenominator() has not been implemented.');
  }

  Future<void> setNextTickType({required int tickIndex}) {
    throw UnimplementedError('setNextTickType() has not been implemented.');
  }

  Future<void> setDroneDurationRation(double value) {
    throw UnimplementedError(
        'setDroneDurationRation() has not been implemented.');
  }

  Stream<Map> get updates => throw UnimplementedError();
}
