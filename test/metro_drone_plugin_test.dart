import 'package:flutter_test/flutter_test.dart';
import 'package:metro_drone_plugin/metronome_plugin_method_channel.dart';
import 'package:metro_drone_plugin/metronome_plugin_platform_interface.dart';
import 'package:metro_drone_plugin/models/metronome.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMetroDronePluginPlatform
    with MockPlatformInterfaceMixin
    implements MetronomePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> setBpm(int bpm) {
    // TODO: implement setBpm
    throw UnimplementedError();
  }

  @override
  Future<String?> start() {
    // TODO: implement start
    throw UnimplementedError();
  }

  @override
  Future<String?> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

  @override
  // TODO: implement updates
  Stream<Map> get updates => throw UnimplementedError();

  @override
  Future<String?> setNextTickType({required int tickIndex}) {
    // TODO: implement setNextTickType
    throw UnimplementedError();
  }

  @override
  Future<String?> setSubdivision(Subdivision subdivision) {
    // TODO: implement setSubdivision
    throw UnimplementedError();
  }

  @override
  Future<String?> setTimeSignatureDenominator(int value) {
    // TODO: implement setTimeSignatureDenominator
    throw UnimplementedError();
  }

  @override
  Future<String?> setTimeSignatureNumerator(int value) {
    // TODO: implement setTimeSignatureNumerator
    throw UnimplementedError();
  }

  @override
  Future<String?> tap() {
    // TODO: implement tap
    throw UnimplementedError();
  }

  @override
  Future<String?> setDroneDurationRation(double value) {
    // TODO: implement setDroneDurationRation
    throw UnimplementedError();
  }

  @override
  Future<String?> setTickTypes(List<TickType> value) {
    // TODO: implement setTickTypes
    throw UnimplementedError();
  }

  @override
  // TODO: implement tickStream
  Stream<int> get tickStream => throw UnimplementedError();
}

void main() {
  final MetronomePluginPlatform initialPlatform = MetronomePluginPlatform.instance;

  test('$MethodChannelMetronomePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMetronomePlugin>());
  });

  // test('getPlatformVersion', () async {
  //   MetronomePlugin metroDronePlugin = MetronomePlugin();
  //   MockMetroDronePluginPlatform fakePlatform = MockMetroDronePluginPlatform();
  //   MetronomePluginPlatform.instance = fakePlatform;
  //
  //   expect(await metroDronePlugin.getPlatformVersion(), '42');
  // });
}
