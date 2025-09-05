# CLAUDE.md

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Metro Drone Plugin** is a sophisticated Flutter plugin providing professional-grade audio tools for musicians and music educators. The plugin delivers three core functionalities through a unified, cross-platform interface:

- **Metronome**: High-precision rhythmic timing with advanced features including configurable BPM (30-300+), flexible time signatures, custom subdivision patterns, accent control, and tap tempo functionality
- **Drone Tone**: Multi-waveform tone generator supporting sine and organ sounds with full musical note range (A0-C8), adjustable tuning standards, and optional pulsing modes for practice
- **Tuner**: Real-time pitch detection system utilizing advanced algorithms (YIN, FFT, HPS estimators) for accurate frequency analysis and cent-precision tuning feedback

The plugin is designed for professional music applications requiring low-latency, high-accuracy audio processing with simultaneous playback capabilities.

## Architecture

The plugin implements Flutter's **Platform Interface pattern** for clean separation between Dart API and native implementations, ensuring maintainable cross-platform audio processing.

### Directory Structure
```
metro_drone_plugin/
├── lib/                          # Dart API layer
│   ├── models/                   # Core business logic models
│   │   ├── metronome.dart       # Metronome singleton with state management
│   │   ├── drone_tone.dart      # Drone tone generator singleton  
│   │   └── tuner.dart           # Tuner singleton with pitch detection
│   ├── *_plugin_platform_interface.dart  # Platform interface contracts
│   ├── *_plugin_method_channel.dart      # Method channel implementations
│   └── metronome_plugin.dart    # Main plugin exports
├── android/                      # Android implementation (Kotlin)
│   ├── src/main/kotlin/
│   │   ├── io/modacity/metro_drone_plugin/
│   │   │   ├── MetroDronePlugin.kt      # Main Android plugin class
│   │   │   └── handlers/                # Channel handlers
│   │   └── app/metrodrone/domain/       # Domain-driven architecture
│   │       ├── clicker/                 # Metronome clicking logic
│   │       ├── drone/                   # Drone tone generation  
│   │       ├── metronome/              # Metronome domain logic
│   │       └── tuner/                  # Tuner implementation
│   └── libs/                     # TarsosDSP JAR library
├── ios/                         # iOS implementation (Swift)
│   └── metro_drone_plugin/
│       └── Sources/metro_drone_plugin/
│           ├── MetroDronePlugin.swift   # Main iOS plugin class
│           ├── Handlers/               # Channel handlers
│           └── Source/                 # Core audio implementations
│               ├── MetroDrone.swift    # Main coordinator
│               ├── Metronome.swift     # Metronome implementation
│               ├── GeneratedDroneTone.swift # Drone generator
│               ├── Tuner.swift         # Tuner with Tuna integration
│               ├── AudioEngineManager.swift # AVAudioEngine wrapper
│               └── Tuna/              # Pitch detection library
└── example/                     # Demo application
    ├── lib/pages/              # UI pages for each feature
    └── integration_test/       # Integration test suites
```

### Core Architecture Patterns

#### 1. Singleton Pattern (Dart Layer)
All main components (`Metronome`, `DroneTone`, `Tuner`) implement singleton pattern for:
- **State Consistency**: Single source of truth across the app
- **Resource Management**: Efficient audio resource utilization
- **Event Broadcasting**: Centralized state change notifications
- **Platform Synchronization**: Unified communication with native layers

#### 2. Platform Interface Pattern
```dart
// Abstract contract
abstract class MetronomePluginPlatform extends PlatformInterface {
  Future<String?> start();
  Future<String?> setBpm(int value);
  Stream<Map<String, dynamic>> get updates;
}

// Method channel implementation  
class MethodChannelMetronomePlugin extends MetronomePluginPlatform {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
}
```

#### 3. Domain-Driven Design (Android)
Android implementation follows DDD principles:
- **Domain Layer**: Pure business logic (`metronome/`, `drone/`, `tuner/`)
- **Application Layer**: Plugin handlers coordinating domain services
- **Infrastructure**: Audio system integrations (TarsosDSP, AudioTrack)

### Communication Architecture

#### Method Channels (Command Pattern)
- **Purpose**: Synchronous commands from Dart to native platforms
- **Usage**: Start/stop operations, configuration changes, parameter updates
- **Channels**:
  - `metro_drone_plugin/metronome` - Metronome commands
  - `metro_drone_plugin/drone_tone` - Drone tone commands  
  - `metro_drone_plugin/tuner` - Tuner commands

#### Event Channels (Observer Pattern) 
- **Purpose**: Asynchronous real-time data streaming from native to Dart
- **Usage**: State updates, audio events, real-time measurements
- **Channels**:
  - `metro_drone_plugin/metronome/events` - Metronome state changes
  - `metro_drone_plugin/metronome/tick` - Real-time tick events
  - `metro_drone_plugin/drone_tone/events` - Drone tone state changes
  - `metro_drone_plugin/tuner/events` - Real-time pitch data

### Platform-Specific Implementations

#### iOS Implementation (Swift)
**Architecture**: Coordinator pattern with AVAudioEngine integration

**Key Classes:**
- `MetroDrone`: Main coordinator managing audio session and component lifecycle
- `AudioEngineManager`: AVAudioEngine wrapper handling audio graph setup
- `Metronome`: Precise timing engine using AVAudioEngine scheduling
- `GeneratedDroneTone`: Real-time waveform synthesis with multiple sound types
- `Tuner`: Tuna library integration for advanced pitch detection algorithms
- `Tuna/*`: Comprehensive pitch detection library with YIN, FFT, HPS estimators

**Audio Processing:**
- **Sample Rate**: 44.1 kHz standard
- **Buffer Size**: 1024 samples (23ms latency)
- **Threading**: Background audio threads with main thread UI updates
- **Session Management**: AVAudioSession configuration for simultaneous playback/recording

#### Android Implementation (Kotlin)
**Architecture**: Domain-driven design with clean architecture principles

**Domain Structure:**
```kotlin
// Domain models with business logic
app.metrodrone.domain.metronome.Metronome
app.metrodrone.domain.drone.Drone  
app.metrodrone.domain.tuner.TunerEngine

// Sound generation engines
app.metrodrone.domain.metronome.soundgen.MetronomeSoundGen
app.metrodrone.domain.drone.soundgen.DroneSoundGen

// Platform integration
io.modacity.metro_drone_plugin.handlers.*
```

**Audio Processing:**
- **TarsosDSP**: Digital signal processing library for pitch detection
- **AudioTrack/AudioRecord**: Android audio system integration
- **Threading**: Background audio processing threads
- **Latency**: Target <50ms (hardware dependent)

## Development Commands

### Flutter Commands
```bash
# Run the example app
cd example && flutter run

# Run tests
flutter test

# Run integration tests
cd example && flutter test integration_test/

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Format code
flutter format .
```

### Platform-Specific Development

#### iOS Development
- iOS implementation uses Swift Package Manager
- Audio processing relies on AVAudioEngine and custom DSP code
- Tuna library provides pitch detection algorithms (YIN, FFT, HPS estimators)

#### Android Development  
- Android implementation is complete with full feature parity
- Uses Kotlin with TarsosDSP library (JAR file included in android/libs/)
- Domain-driven architecture with clean separation of concerns

## Key Implementation Details

### State Management
- All three main components (Metronome, DroneTone, Tuner) use singleton pattern
- State synchronization between Dart and native platforms via event channels
- Real-time updates streamed from native code to Flutter UI

### Audio Session Management
- iOS handles audio session configuration for simultaneous playback/recording
- Metronome and drone tone can play simultaneously
- Tuner requires microphone access for pitch detection

### Plugin Architecture
- Uses Flutter's plugin platform interface pattern
- Method channels for commands (start/stop, configuration)
- Event channels for real-time data streams (tick events, pitch data, state updates)

## Testing

- Unit tests in `test/` directory
- Integration tests in `example/integration_test/`
- iOS implementation includes signal processing tests
- Test framework: flutter_test with integration_test package

## Detailed Component Analysis

### Metronome Implementation (lib/models/metronome.dart:57-280)

**Core Features:**
- **Singleton Pattern**: Ensures single instance across application lifecycle
- **State Management**: Real-time synchronization via `StreamController<bool>` for play state
- **Tick Tracking**: Current tick position and pattern management
- **Subdivision Support**: Complex rhythmic patterns with rest and duration arrays
- **Event Streaming**: Separate streams for state changes and tick events

**Key Methods:**
- `start()` / `stop()`: Metronome playback control
- `setBpm(int)`: Tempo configuration (30-300+ BPM)
- `tap()`: Tap tempo implementation for manual BPM detection
- `setSubdivision(Subdivision)`: Rhythmic pattern configuration
- `setTickTypes(List<TickType>)`: Accent pattern customization

**State Properties:**
- `_bpm`: Current tempo setting
- `_isPlaying`: Playback state
- `_timeSignatureNumerator` / `_timeSignatureDenominator`: Time signature
- `_tickTypes`: Accent pattern array (silence, regular, accent, strongAccent)
- `_subdivision`: Current rhythmic subdivision pattern

### Drone Tone Implementation (lib/models/drone_tone.dart:19-148)

**Core Features:**
- **Tone Generation**: Multi-waveform synthesis (sine, organ)
- **Musical Range**: Full note range (A0-C8) with octave precision
- **Tuning Flexibility**: Adjustable reference frequency (default A440)
- **Pulsing Mode**: Rhythmic modulation for practice applications

**Key Methods:**
- `start()` / `stop()`: Drone playback control
- `setNote(String, int)`: Musical note and octave selection
- `setSoundType(SoundType)`: Waveform selection (sine/organ)
- `setPulsing(bool)`: Rhythmic pulsing toggle
- `setTuningStandard(double)`: Reference frequency adjustment

**State Properties:**
- `_isPlaying`: Playback state
- `_isPulsing`: Pulsing mode state
- `_octave`: Current octave (0-8)
- `_note`: Current musical note (A-G)
- `_tuningStandard`: Reference frequency in Hz
- `_soundType`: Current waveform type

### Tuner Implementation (lib/models/tuner.dart:6-101)

**Core Features:**
- **Real-time Analysis**: Continuous pitch detection and frequency measurement
- **Pitch Class Recognition**: Automatic note and octave identification
- **Cent Precision**: Fine-tuning feedback in cent deviations
- **Configurable Reference**: Adjustable tuning standard (A440, A442, etc.)

**Key Methods:**
- `start()` / `stop()`: Pitch detection control
- `setTuningStandard(double)`: Reference frequency configuration

**Data Structures:**
- `Pitch` class: Contains note, octave, frequency, and cent deviation
- Real-time streaming via `pitchStream` for continuous updates

### iOS Native Architecture

**MetroDrone.swift**: Central coordinator class managing:
- Audio session configuration and lifecycle
- Component coordination between metronome, drone, and tuner
- AVAudioEngine setup and audio graph management

**Metronome.swift**: High-precision timing implementation:
- AVAudioEngine scheduled playback for sample-accurate timing
- Dynamic tick pattern generation
- Real-time BPM adjustments without playback interruption

**GeneratedDroneTone.swift**: Real-time synthesis:
- Mathematical waveform generation (sine, sawtooth for "organ" sound)
- Frequency calculation from note/octave/tuning combinations
- Smooth parameter transitions to avoid audio artifacts

**Tuner.swift + Tuna Library**: Advanced pitch detection:
- Multiple algorithm support (YIN, FFT, HPS estimators)
- Real-time audio buffer processing
- Noise filtering and signal validation

### Android Native Architecture

**Domain-Driven Structure**: Clean separation of concerns
- **Domain Models**: Pure business logic without platform dependencies
- **Sound Generators**: Specialized classes for each audio type
- **Handler Layer**: Platform integration and Flutter communication

**Key Android Classes:**
- `Metrodrone.kt`: Main coordinator similar to iOS implementation
- `MetronomeSoundGen.kt`: Android-specific metronome audio generation
- `DroneSoundGen.kt`: Tone synthesis using Android AudioTrack
- `TunerEngine.kt`: TarsosDSP integration for pitch detection

## Development Workflow

### Code Style and Patterns
- **Dart**: Follow Flutter/Dart style guide with singleton pattern for core models
- **Swift**: Use coordinator pattern with protocol-oriented programming
- **Kotlin**: Domain-driven design with clean architecture principles
- **Async Patterns**: Proper handling of audio thread communication

### Testing Strategy
- **Unit Tests**: Core business logic testing in `test/` directory
- **Integration Tests**: End-to-end functionality testing in `example/integration_test/`
- **Platform Tests**: Native audio processing validation (iOS includes Tuna library tests)

### Performance Considerations
- **Memory Management**: Proper disposal of audio resources and stream controllers
- **Threading**: Audio processing on background threads with UI updates on main thread
- **Latency Optimization**: Buffer size tuning for real-time audio requirements
- **Battery Usage**: Efficient audio session management to minimize power consumption

## Platform-Specific Development Guidelines

### iOS Development (Swift)
**Audio Session Management:**
```swift
// Proper audio session configuration
try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
try AVAudioSession.sharedInstance().setActive(true)
```

**Threading Model:**
- Audio processing: Background audio thread (AVAudioEngine)
- Flutter communication: Main thread for event channel updates
- UI updates: Main thread via Flutter's event channels

### Android Development (Kotlin)
**Audio System Integration:**
- `AudioTrack` for playback (metronome, drone)
- `AudioRecord` for capture (tuner)
- Threading: Background threads for audio with handler communication

**Domain Layer Guidelines:**
- Keep domain models platform-agnostic
- Use dependency injection for platform-specific implementations
- Maintain clear boundaries between domain and infrastructure layers

## Troubleshooting and Common Issues

### Audio Issues
- **No Sound on iOS**: Check audio session category and active state
- **High Latency**: Adjust buffer sizes and audio session configuration
- **Crackling/Artifacts**: Ensure smooth parameter transitions in audio generation

### Platform Communication Issues
- **Event Channel Drops**: Verify proper stream handler lifecycle management
- **Method Channel Timeouts**: Check for blocking operations on main thread
- **State Synchronization**: Ensure event channel updates maintain consistency

### Build Issues
- **iOS**: Verify Swift Package Manager dependencies and Tuna library integration
- **Android**: Check TarsosDSP JAR inclusion and ProGuard configuration
- **Flutter**: Ensure proper plugin registration in platform-specific code

### Performance Issues
- **Memory Leaks**: Proper disposal of StreamControllers and audio resources
- **CPU Usage**: Optimize audio buffer sizes and processing algorithms
- **Battery Drain**: Efficient audio session management and background processing

## Future Development Considerations

### Cross-Platform Optimizations
- Performance tuning for both iOS and Android platforms
- Advanced audio session management improvements
- Battery usage optimization across platforms

### Advanced Features
- **MIDI Support**: Integration with external MIDI devices
- **Audio Effects**: Reverb, EQ for enhanced sound quality
- **Custom Waveforms**: User-defined drone tone shapes
- **Advanced Subdivisions**: Polyrhythm and complex meter support

### Performance Optimizations
- **Low-Latency Audio**: Platform-specific optimizations (AAudio on Android)
- **Background Processing**: Efficient audio processing when app is backgrounded
- **Memory Management**: Advanced resource pooling and management