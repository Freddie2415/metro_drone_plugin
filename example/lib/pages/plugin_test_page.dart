import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:metro_drone_plugin/models/metronome.dart';
import 'package:metro_drone_plugin/models/drone_tone.dart';
import 'package:metro_drone_plugin/models/tuner.dart';

class PluginTestPage extends StatefulWidget {
  const PluginTestPage({super.key});

  @override
  State<PluginTestPage> createState() => _PluginTestPageState();
}

class _PluginTestPageState extends State<PluginTestPage> {
  final Metronome _metronome = Metronome();
  final DroneTone _droneTone = DroneTone();
  final Tuner _tuner = Tuner();

  String _testResults = '';

  void _logResult(String test, dynamic result) {
    setState(() {
      _testResults += '$test: $result\n';
    });
    if (kDebugMode) {
      print('$test: $result');
    }
  }

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Results display
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _testResults.isEmpty ? 'Test results will appear here...' : _testResults,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _clearResults,
              child: const Text('Clear Results'),
            ),
            const SizedBox(height: 24),

            // Metronome Tests
            const Text(
              'Metronome Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _metronome.start();
                      _logResult('Metronome Start', result);
                    } catch (e) {
                      _logResult('Metronome Start Error', e);
                    }
                  },
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _metronome.stop();
                      _logResult('Metronome Stop', result);
                    } catch (e) {
                      _logResult('Metronome Stop Error', e);
                    }
                  },
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _metronome.tap();
                      _logResult('Metronome Tap', result);
                    } catch (e) {
                      _logResult('Metronome Tap Error', e);
                    }
                  },
                  child: const Text('Tap'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _metronome.setBpm(120);
                      _logResult('Set BPM', result);
                    } catch (e) {
                      _logResult('Set BPM Error', e);
                    }
                  },
                  child: const Text('Set BPM 120'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _metronome.setTimeSignatureNumerator(4);
                      _logResult('Set Time Sig Num', result);
                    } catch (e) {
                      _logResult('Set Time Sig Num Error', e);
                    }
                  },
                  child: const Text('Set 4/4'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _metronome.setDroneDurationRatio(0.5);
                      _logResult('Set Drone Ratio', result);
                    } catch (e) {
                      _logResult('Set Drone Ratio Error', e);
                    }
                  },
                  child: const Text('Drone Ratio'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _metronome.setTickTypes([TickType.accent, TickType.regular, TickType.regular, TickType.regular]);
                      _logResult('Set Tick Types', result);
                    } catch (e) {
                      _logResult('Set Tick Types Error', e);
                    }
                  },
                  child: const Text('Set Tick Types'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Drone Tone Tests
            const Text(
              'Drone Tone Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.start();
                      _logResult('Drone Start', result);
                    } catch (e) {
                      _logResult('Drone Start Error', e);
                    }
                  },
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.stop();
                      _logResult('Drone Stop', result);
                    } catch (e) {
                      _logResult('Drone Stop Error', e);
                    }
                  },
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.setPulsing(true);
                      _logResult('Set Pulsing', result);
                    } catch (e) {
                      _logResult('Set Pulsing Error', e);
                    }
                  },
                  child: const Text('Pulsing On'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.setPulsing(false);
                      _logResult('Set Pulsing', result);
                    } catch (e) {
                      _logResult('Set Pulsing Error', e);
                    }
                  },
                  child: const Text('Pulsing Off'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.setNote(note: 'A', octave: 4);
                      _logResult('Set Note', result);
                    } catch (e) {
                      _logResult('Set Note Error', e);
                    }
                  },
                  child: const Text('Set A4'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.setTuningStandard(440.0);
                      _logResult('Set Tuning', result);
                    } catch (e) {
                      _logResult('Set Tuning Error', e);
                    }
                  },
                  child: const Text('Set 440Hz'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.setSoundType(SoundType.sine);
                      _logResult('Set Sound Type', result);
                    } catch (e) {
                      _logResult('Set Sound Type Error', e);
                    }
                  },
                  child: const Text('Sine Wave'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _droneTone.setSoundType(SoundType.organ);
                      _logResult('Set Sound Type', result);
                    } catch (e) {
                      _logResult('Set Sound Type Error', e);
                    }
                  },
                  child: const Text('Organ Sound'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tuner Tests
            const Text(
              'Tuner Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _tuner.start();
                      _logResult('Tuner Start', result);
                    } catch (e) {
                      _logResult('Tuner Start Error', e);
                    }
                  },
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _tuner.stop();
                      _logResult('Tuner Stop', result);
                    } catch (e) {
                      _logResult('Tuner Stop Error', e);
                    }
                  },
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await _tuner.setTuningStandard(442.0);
                      _logResult('Set Tuner Standard', '$result Hz');
                    } catch (e) {
                      _logResult('Set Tuner Standard Error', e);
                    }
                  },
                  child: const Text('Set 442Hz'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stream Tests
            const Text(
              'Stream Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _metronome.isPlayingStream.listen((isPlaying) {
                      _logResult('Metronome Stream', 'isPlaying: $isPlaying');
                    });
                    _logResult('Stream Listener', 'Metronome isPlaying stream');
                  },
                  child: const Text('Listen Metronome'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _metronome.tickStream.listen((tick) {
                      _logResult('Tick Stream', 'tick: $tick');
                    });
                    _logResult('Stream Listener', 'Metronome tick stream');
                  },
                  child: const Text('Listen Ticks'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _droneTone.droneToneStream.listen((droneTone) {
                      _logResult('Drone Stream', 'Updated: ${droneTone.isPlaying}');
                    });
                    _logResult('Stream Listener', 'Drone tone stream');
                  },
                  child: const Text('Listen Drone'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _tuner.pitchStream.listen((pitch) {
                      _logResult('Pitch Stream', '${pitch.note}${pitch.octave}: ${pitch.frequency.toStringAsFixed(1)}Hz');
                    });
                    _logResult('Stream Listener', 'Tuner pitch stream');
                  },
                  child: const Text('Listen Pitch'),
                ),
              ],
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}