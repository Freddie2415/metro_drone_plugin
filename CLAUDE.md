# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Metro Drone Plugin is a Flutter plugin that provides three main audio-related functionalities:
- **Metronome**: Configurable metronome with time signatures, subdivisions, and tick patterns
- **Drone Tone**: Sustained tone generator with different sound types (sine, organ) and pulsing capability
- **Tuner**: Audio pitch detection and frequency analysis

## Architecture

This is a Flutter plugin using the Platform Interface pattern with method channels and event channels for platform communication.

### Core Structure
- `lib/`: Dart API layer with singleton pattern models and platform interfaces
- `android/`: Android implementation (currently minimal - only basic plugin structure)
- `ios/`: iOS implementation with full native Swift code including:
  - Audio engine management
  - Signal processing (Tuna library for pitch detection)
  - Real-time audio generation and analysis
- `example/`: Demo app showcasing plugin functionality

### Key Components

#### Dart Layer
- **Models**: `Metronome`, `DroneTone`, `Tuner` - Singleton classes managing state and platform communication
- **Platform Interfaces**: Define contracts between Dart and native platforms
- **Method Channels**: Handle method calls and event streams from native code

#### iOS Implementation
- **MetroDrone**: Main coordinator class managing audio session and components
- **Metronome**: Handles rhythm generation, time signatures, and tick patterns
- **GeneratedDroneTone**: Manages sustained tone generation with different waveforms
- **Tuner**: Uses Tuna pitch detection library for real-time frequency analysis
- **AudioEngineManager**: Coordinates AVAudioEngine for audio processing

#### Android Implementation
- Currently contains only basic plugin structure
- Audio functionality not yet implemented on Android platform

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
- Android implementation is minimal and needs development
- Uses Kotlin with TarsosDSP library (JAR file included in android/libs/)

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

## Common Issues

- **Android**: Most functionality not implemented yet - iOS only
- **Audio Session**: iOS audio session conflicts may occur with other audio apps
- **Permissions**: Tuner requires microphone permissions on both platforms
- **Threading**: Real-time audio processing happens on background threads with event channel communication to Flutter