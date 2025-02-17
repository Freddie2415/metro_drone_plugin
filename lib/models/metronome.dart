import 'dart:async';

import 'package:collection/collection.dart';

import '../metronome_plugin_platform_interface.dart';

enum TickType { silence, regular, accent, strongAccent }

class Subdivision {
  final String name;
  final String description;
  final List<bool> restPattern;
  final List<double> durationPattern;

  Subdivision({
    required this.name,
    required this.description,
    required this.restPattern,
    required this.durationPattern,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Subdivision &&
        other.name == name &&
        other.description == description &&
        ListEquality().equals(other.restPattern, restPattern) &&
        ListEquality().equals(other.durationPattern, durationPattern);
  }

  @override
  int get hashCode => Object.hash(
        name,
        description,
        const ListEquality().hash(restPattern),
        const ListEquality().hash(durationPattern),
      );

  @override
  String toString() {
    return name;
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "restPattern": restPattern,
      "durationPattern": durationPattern,
    };
  }
}

class Metronome {
  int _bpm = 120;
  bool _isPlaying = false;
  int _timeSignatureNumerator = 4;
  int _timeSignatureDenominator = 4;
  int _currentTick = 0;
  double _droneDurationRatio = 0.5;
  List<TickType> _tickTypes =
      List.generate(4, (index) => TickType.regular); // по умолчанию 4 элемента
  Subdivision _subdivision = Subdivision(
    name: "Quarter Notes",
    description: "One quarter note per beat",
    restPattern: [true],
    durationPattern: [1.0],
  );

  // Контроллер для трансляции изменений поля _isPlaying
  final _isPlayingController = StreamController<bool>.broadcast();
  final _tickController = StreamController<int>.broadcast();
  final _metronomeController = StreamController<Metronome>.broadcast();

  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  Stream<int> get tickStream => _tickController.stream;

  Stream<Metronome> get metronomeStream => _metronomeController.stream;

  StreamSubscription? _updatesStreamSubscription;
  StreamSubscription? _tickStreamSubscription;

  static final Metronome _instance = Metronome._();

  Metronome._() {
    listenToUpdates();
  }

  factory Metronome() => _instance;

  // Геттеры для чтения состояния
  int get bpm => _bpm;

  bool get isPlaying => _isPlaying;

  int get timeSignatureNumerator => _timeSignatureNumerator;

  int get timeSignatureDenominator => _timeSignatureDenominator;

  int get currentTick => _currentTick;

  double get droneDurationRatio => _droneDurationRatio;

  List<TickType> get tickTypes => _tickTypes;

  Subdivision get subdivision => _subdivision;

  /// Методы управления метрономом.
  Future<String?> start() {
    return MetronomePluginPlatform.instance.start();
  }

  Future<String?> stop() {
    return MetronomePluginPlatform.instance.stop();
  }

  Future<void> tap() async {
    await MetronomePluginPlatform.instance.tap();
  }

  Future<void> setBpm(int value) async {
    await MetronomePluginPlatform.instance.setBpm(value);
  }

  Future<void> setSubdivision(Subdivision value) async {
    await MetronomePluginPlatform.instance.setSubdivision(value);
  }

  Future<void> setTimeSignatureNumerator(int value) async {
    await MetronomePluginPlatform.instance.setTimeSignatureNumerator(value);
  }

  Future<void> setTimeSignatureDenominator(int value) async {
    await MetronomePluginPlatform.instance.setTimeSignatureDenominator(value);
  }

  Future<void> setNextTickType({required int tickIndex}) async {
    await MetronomePluginPlatform.instance
        .setNextTickType(tickIndex: tickIndex);
  }

  Future<void> setDroneDurationRatio(double value) async {
    await MetronomePluginPlatform.instance.setDroneDurationRation(value);
  }

  Future<void> setTickTypes(List<TickType> value) async {
    await MetronomePluginPlatform.instance.setTickTypes(value);
  }

  /// Подписка на обновления с платформенной части через EventChannel.
  void listenToUpdates() {
    _updatesStreamSubscription?.cancel();
    _updatesStreamSubscription = null;
    _updatesStreamSubscription =
        MetronomePluginPlatform.instance.updates.listen(_onDataChanged);

    _tickStreamSubscription?.cancel();
    _tickStreamSubscription = null;
    _tickStreamSubscription =
        MetronomePluginPlatform.instance.tickStream.listen(_onTickChanged);
  }

  void _onTickChanged(int value) {
    _tickController.add(value);
  }

  /// Обработка входящих данных (обновлений) с платформы.
  void _onDataChanged(data) {
    print("onMetronomeDataChanged received: $data | type: ${data.runtimeType}");

    if (data is Map) {
      final map = data;

      // Обновляем поле _isPlaying и транслируем изменение через stream, если значение изменилось
      if (map.containsKey("isPlaying") && map["isPlaying"] is bool) {
        bool newIsPlaying = map["isPlaying"] as bool;
        if (newIsPlaying != _isPlaying) {
          _isPlaying = newIsPlaying;
          _isPlayingController.add(_isPlaying);
        }
      }

      // Обновляем поле _bpm
      if (map.containsKey("bpm") && map["bpm"] is int) {
        _bpm = map["bpm"] as int;
      }

      // Обновляем поле _timeSignatureNumerator
      if (map.containsKey("timeSignatureNumerator") &&
          map["timeSignatureNumerator"] is int) {
        _timeSignatureNumerator = map["timeSignatureNumerator"] as int;
      }

      // Обновляем поле _timeSignatureDenominator
      if (map.containsKey("timeSignatureDenominator") &&
          map["timeSignatureDenominator"] is int) {
        _timeSignatureDenominator = map["timeSignatureDenominator"] as int;
      }

      // Обновляем subdivision
      if (map.containsKey("subdivision") && map["subdivision"] is Map) {
        final subdivisionMap = map["subdivision"] as Map;
        _subdivision = Subdivision(
          name: subdivisionMap["name"] is String
              ? subdivisionMap["name"] as String
              : _subdivision.name,
          description: subdivisionMap["description"] is String
              ? subdivisionMap["description"] as String
              : _subdivision.description,
          restPattern: subdivisionMap["restPattern"] is List
              ? (subdivisionMap["restPattern"] as List).cast<bool>()
              : _subdivision.restPattern,
          durationPattern: subdivisionMap["durationPattern"] is List
              ? (subdivisionMap["durationPattern"] as List).cast<double>()
              : _subdivision.durationPattern,
        );
      }

      // Обновляем tickTypes
      if (map.containsKey("tickTypes") && map["tickTypes"] is List) {
        final tickTypesData = map["tickTypes"] as List;
        _tickTypes = tickTypesData.map<TickType>((type) {
          if (type is String) {
            return _convertTickType(type);
          } else {
            return TickType.regular;
          }
        }).toList();
      }

      // Обновляем поле _currentTick
      if (map.containsKey("currentTick") && map["currentTick"] is int) {
        _currentTick = map["currentTick"] as int;
      }

      if (map.containsKey("droneDurationRatio") &&
          map["droneDurationRatio"] is double) {
        _droneDurationRatio = map["droneDurationRatio"] as double;
      }

      _metronomeController.add(this);
    } else {
      print("Received data is not a Map. Ignoring update.");
    }
  }

  /// Вспомогательная функция для преобразования строкового значения в TickType.
  TickType _convertTickType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case "silence":
        return TickType.silence;
      case "accent":
        return TickType.accent;
      case "strongaccent":
        return TickType.strongAccent;
      case "regular":
      default:
        return TickType.regular;
    }
  }

  /// Метод для корректного завершения работы (например, при уничтожении объекта)
  void dispose() {
    stop();
    _updatesStreamSubscription?.cancel();
    _isPlayingController.close();
    _updatesStreamSubscription = null;

    _tickStreamSubscription?.cancel();
    _tickController.close();
    _tickStreamSubscription = null;
  }
}
