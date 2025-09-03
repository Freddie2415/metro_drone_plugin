import 'package:metro_drone_plugin/drone_tone_plugin_method_channel.dart';
import 'package:metro_drone_plugin/metronome_plugin_method_channel.dart';
import 'package:metro_drone_plugin/models/drone_tone.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class DroneTonePluginPlatform extends PlatformInterface {
  /// Constructs a DroneTonePluginPlatform.
  DroneTonePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static DroneTonePluginPlatform _instance = MethodChannelDroneTonePlugin();

  /// The default instance of [DroneTonePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelMetronomePlugin].
  static DroneTonePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DroneTonePluginPlatform] when
  /// they register themselves.
  static set instance(DroneTonePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<String?> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Stream<Map> get updates => throw UnimplementedError();

  Future<String?> setPulsing(bool pulsing) async {
    throw UnimplementedError('setPulsing() has not been implemented.');
  }

  Future<String?> setNote({
    required String note,
    required int octave,
  }) async {
    throw UnimplementedError('setNote() has not been implemented.');
  }

  Future<String?> setTuningStandard(double frequency) {
    throw UnimplementedError('setTuningStandard() has not been implemented.');
  }

  Future<String?> setSoundType(SoundType soundType) {
    throw UnimplementedError('setSoundType() has not been implemented.');
  }
}
