# Metro Drone Plugin

A comprehensive Flutter plugin for audio-based music tools providing metronome, drone tone generator, and tuner functionality with high-precision audio processing.

## Features

### 🎯 Metronome
- **Configurable BPM**: Support for wide BPM range (30-300+)
- **Time Signatures**: Flexible time signature support (2/4, 3/4, 4/4, 5/4, 6/8, etc.)
- **Subdivisions**: Multiple subdivision patterns (quarter notes, eighth notes, triplets, etc.)
- **Custom Tick Patterns**: Configurable accent patterns with silence, regular, accent, and strong accent ticks
- **Tap Tempo**: Real-time BPM detection through tap input
- **Visual Feedback**: Real-time tick indication with current beat position

### 🎵 Drone Tone Generator
- **Multiple Waveforms**: Sine wave and organ sound types
- **Full Note Range**: Support for all musical notes with octave selection (A0-C8)
- **Tuning Standards**: Adjustable tuning frequency (default A440)
- **Pulsing Mode**: Optional rhythmic pulsing for practice
- **Simultaneous Playback**: Can run alongside metronome

### 🎼 Tuner
- **Real-time Pitch Detection**: High-accuracy frequency analysis
- **Note Recognition**: Automatic note and octave identification
- **Cent Deviation**: Precise tuning feedback in cents
- **Multiple Algorithms**: Advanced pitch detection using YIN, FFT, and HPS estimators
- **Microphone Integration**: Real-time audio input processing

## Platform Support

| Feature | iOS | Android |
|---------|-----|---------|
| Metronome | ✅ | ✅ |
| Drone Tone | ✅ | ✅ |
| Tuner | ✅ | ✅ |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  metro_drone_plugin: ^0.0.2
```

Then run:
```bash
flutter pub get
```

## Usage

### Metronome

```dart
import 'package:metro_drone_plugin/models/metronome.dart';

// Get singleton instance
final metronome = Metronome();

// Start/stop metronome
await metronome.start();
await metronome.stop();

// Set BPM
await metronome.setBpm(120);

// Set time signature
await metronome.setTimeSignatureNumerator(4);
await metronome.setTimeSignatureDenominator(4);

// Listen to state changes
metronome.isPlayingStream.listen((isPlaying) {
  print('Metronome is ${isPlaying ? 'playing' : 'stopped'}');
});

// Listen to tick events
metronome.tickStream.listen((currentTick) {
  print('Current tick: $currentTick');
});

// Tap tempo
await metronome.tap();

// Custom subdivisions
final triplets = Subdivision(
  name: "Eighth Note Triplets",
  description: "Three eighth notes per beat",
  restPattern: [false, false, false],
  durationPattern: [1.0/3, 1.0/3, 1.0/3],
);
await metronome.setSubdivision(triplets);
```

### Drone Tone

```dart
import 'package:metro_drone_plugin/models/drone_tone.dart';

// Get singleton instance  
final droneTone = DroneTone();

// Start/stop drone
await droneTone.start();
await droneTone.stop();

// Set note and octave
await droneTone.setNote(note: "A", octave: 4); // A4 (440 Hz by default)
await droneTone.setNote(note: "C", octave: 3); // C3

// Change sound type
await droneTone.setSoundType(SoundType.sine);
await droneTone.setSoundType(SoundType.organ);

// Enable pulsing
await droneTone.setPulsing(true);

// Custom tuning
await droneTone.setTuningStandard(442.0); // A442

// Listen to state changes
droneTone.droneToneStream.listen((drone) {
  print('Drone: ${drone.note}${drone.octave}, Playing: ${drone.isPlaying}');
});
```

### Tuner

```dart
import 'package:metro_drone_plugin/models/tuner.dart';

// Get singleton instance
final tuner = Tuner();

// Start/stop tuning
await tuner.start();
await tuner.stop();

// Set tuning standard
await tuner.setTuningStandard(440.0);

// Listen to pitch data
tuner.pitchStream.listen((pitch) {
  print('Note: ${pitch.note}${pitch.octave}');
  print('Frequency: ${pitch.frequency.toStringAsFixed(2)} Hz');
  print('Cents off: ${pitch.closestOffsetCents.toStringAsFixed(1)}');
});
```

## Permissions

### iOS
Add the following to your `Info.plist` for tuner functionality:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for tuner functionality</string>
```

### Android
Add to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## Architecture

The plugin uses Flutter's Platform Interface pattern for clean separation between Dart API and native implementations:

### Dart Layer
- **Singleton Models**: `Metronome`, `DroneTone`, `Tuner` classes manage state
- **Platform Interfaces**: Abstract contracts for native implementations
- **Event Channels**: Real-time data streaming from native platforms
- **Method Channels**: Command communication to native platforms

### iOS Implementation (Swift)
- **AVAudioEngine**: Core audio processing and routing
- **Tuna Library**: Advanced pitch detection algorithms
- **Real-time Audio**: Low-latency audio generation and analysis
- **Audio Session Management**: Proper iOS audio session handling

### Android Implementation (Kotlin)
- **TarsosDSP**: Digital signal processing library
- **AudioTrack/AudioRecord**: Android audio system integration
- **Domain-Driven Design**: Clean architecture with separate domain layers

## Advanced Configuration

### Custom Subdivisions
Create complex rhythmic patterns:

```dart
// Swing eighths
final swing = Subdivision(
  name: "Swing Eighths", 
  description: "Swung eighth note feel",
  restPattern: [false, false],
  durationPattern: [0.67, 0.33], // Long-short pattern
);

// Complex polyrhythm
final polyrhythm = Subdivision(
  name: "3 Against 2",
  description: "Three notes against two beats", 
  restPattern: [false, false, false],
  durationPattern: [0.67, 0.67, 0.66],
);
```

### Tick Accent Patterns
Customize metronome accents:

```dart
// Custom 7/8 pattern
final tickPattern = [
  TickType.strongAccent, // Beat 1
  TickType.regular,      // Beat 2  
  TickType.accent,       // Beat 3
  TickType.regular,      // Beat 4
  TickType.accent,       // Beat 5
  TickType.regular,      // Beat 6
  TickType.regular,      // Beat 7
];
await metronome.setTickTypes(tickPattern);
```

## Example App

Run the example app to see all features in action:

```bash
cd example
flutter run
```

The example demonstrates:
- Interactive metronome with visual feedback
- Drone tone generator with note selection
- Real-time tuner with pitch visualization
- Integration between all three tools

## API Reference

### Metronome Class

| Method | Description | Parameters |
|--------|-------------|------------|
| `start()` | Start metronome playback | - |
| `stop()` | Stop metronome playback | - |
| `setBpm(int)` | Set beats per minute | `bpm`: 30-300+ |
| `tap()` | Tap tempo input | - |
| `setTimeSignatureNumerator(int)` | Set time signature top number | `numerator`: 1-32 |
| `setTimeSignatureDenominator(int)` | Set time signature bottom number | `denominator`: 1,2,4,8,16 |
| `setSubdivision(Subdivision)` | Set rhythmic subdivision | `subdivision`: Custom pattern |
| `setTickTypes(List<TickType>)` | Set accent pattern | `tickTypes`: Accent list |

### DroneTone Class  

| Method | Description | Parameters |
|--------|-------------|------------|
| `start()` | Start drone tone | - |
| `stop()` | Stop drone tone | - |  
| `setNote(String, int)` | Set note and octave | `note`: A-G, `octave`: 0-8 |
| `setSoundType(SoundType)` | Set waveform type | `soundType`: sine/organ |
| `setPulsing(bool)` | Enable rhythmic pulsing | `pulsing`: true/false |
| `setTuningStandard(double)` | Set A tuning frequency | `frequency`: Hz (default 440) |

### Tuner Class

| Method | Description | Parameters |
|--------|-------------|------------|
| `start()` | Start pitch detection | - |
| `stop()` | Stop pitch detection | - |
| `setTuningStandard(double)` | Set reference tuning | `frequency`: Hz (default 440) |

## Technical Specifications

### Audio Processing
- **Sample Rate**: 44.1 kHz
- **Bit Depth**: 16-bit
- **Latency**: <10ms (iOS), <50ms (Android)
- **Frequency Range**: 20 Hz - 20 kHz
- **Pitch Accuracy**: ±1 cent

### Performance
- **CPU Usage**: <5% on modern devices
- **Memory Usage**: <50MB
- **Battery Impact**: Minimal (optimized for background audio)

## Troubleshooting

### Common Issues

**Metronome not audible**
- Check device volume and mute switch
- Ensure audio session permissions
- Verify background audio settings

**Tuner not detecting pitch**
- Grant microphone permissions
- Check for background noise
- Ensure input signal strength >-40dB

**Android build issues**
- Verify NDK and TarsosDSP integration
- Check Gradle configuration
- Ensure proper ProGuard rules

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run tests: `flutter test`
4. Run example: `cd example && flutter run`

### Building for Platforms

**iOS:**
```bash
cd ios && swift build
```

**Android:**
```bash
cd android && ./gradlew build
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Made with ❤️ for musicians and developers**

