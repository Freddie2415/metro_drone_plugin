import 'package:metro_drone_plugin/tuner_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class TunerPluginPlatform extends PlatformInterface {
  /// Constructs a MetroDronePluginPlatform.
  TunerPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static TunerPluginPlatform _instance = MethodChannelTunerPlugin();

  /// The default instance of [TunerPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelTunerPlugin].
  static TunerPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TunerPluginPlatform] when
  /// they register themselves.
  static set instance(TunerPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool?> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<bool?> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<double?> setTuningStandard(double frequency) {
    throw UnimplementedError('setTuningStandard() has not been implemented.');
  }

  Stream<Map> get updates => throw UnimplementedError();
}
