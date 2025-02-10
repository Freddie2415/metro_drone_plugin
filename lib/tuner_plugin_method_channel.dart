import 'package:flutter/services.dart';
import 'package:metro_drone_plugin/tuner_plugin_platform_interface.dart';

class MethodChannelTunerPlugin extends TunerPluginPlatform {
  final methodChannel = const MethodChannel("metro_drone_plugin/tuner");
  final eventChannel = const EventChannel("metro_drone_plugin/tuner/events");

  @override
  Future<bool?> start() async {
    return methodChannel.invokeMethod<bool>("start");
  }

  @override
  Future<bool?> stop() async {
    return methodChannel.invokeMethod<bool>("stop");
  }

  @override
  Stream<Map> get updates {
    return eventChannel.receiveBroadcastStream().map((event) => event as Map);
  }
}
