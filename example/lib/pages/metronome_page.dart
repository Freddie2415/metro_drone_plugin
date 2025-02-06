import 'package:flutter/material.dart';
import 'package:metro_drone_plugin/metronome_plugin.dart';
import 'package:metro_drone_plugin_example/widgets/select_widget.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  final Metronome _metronome = Metronome.instance;
  List<int> beats = List.generate(16, (index) => index + 1);
  List<Subdivision> subdivisions = [
    // 1
    Subdivision(
        name: "Quarter Notes",
        description: "One quarter note per beat",
        restPattern: [true],
        durationPattern: [1.0]),
    // 2
    Subdivision(
        name: "Eighth Notes",
        description: "Two eighth notes",
        restPattern: [true, true],
        durationPattern: [0.5, 0.5]),
    // 3
    Subdivision(
        name: "Sixteenth Notes",
        description: "Four equal sixteenth notes",
        restPattern: [true, true, true, true],
        durationPattern: [0.25, 0.25, 0.25, 0.25]),
    // 4
    Subdivision(
        name: "Triplet",
        description: "Three equal triplets",
        restPattern: [true, true, true],
        durationPattern: [0.34, 0.33, 0.33]),
    // 5
    Subdivision(
        name: "Swing",
        description: "Swing eighth notes (2/3 + 1/3)",
        restPattern: [true, true],
        durationPattern: [0.66, 0.34]),
    // 6
    Subdivision(
        name: "Rest and Eighth Note",
        description: "Rest followed by an eighth note",
        restPattern: [false, true],
        durationPattern: [0.5, 0.5]),
    // 7
    Subdivision(
        name: "Dotted Eighth and Sixteenth",
        description: "Dotted eighth and one sixteenth note",
        restPattern: [true, true],
        durationPattern: [0.75, 0.25]),
    // 8
    Subdivision(
        name: "16th Note & Dotted Eighth",
        description: "One sixteenth note and one dotted eighth",
        restPattern: [true, true],
        durationPattern: [0.25, 0.75]),
    // 9
    Subdivision(
        name: "2 Sixteenth Notes & Eighth Note",
        description: "Two sixteenth notes and one eighth note",
        restPattern: [true, true, true],
        durationPattern: [0.25, 0.25, 0.5]),
    // 10
    Subdivision(
        name: "Eighth Note & 2 Sixteenth Notes",
        description: "One eighth note and two sixteenth notes",
        restPattern: [true, true, true],
        durationPattern: [0.5, 0.25, 0.25]),
    // 11
    Subdivision(
        name: "16th Rest, 16th Note, 16th Rest, 16th Note",
        description: "Alternating silence and sixteenth notes",
        restPattern: [false, true, false, true],
        durationPattern: [0.25, 0.25, 0.25, 0.25]),
    // 12
    Subdivision(
        name: "16th Note, Eighth Note, 16th Note",
        description: "Sixteenth, eighth, and sixteenth notes",
        restPattern: [true, true, true],
        durationPattern: [0.25, 0.5, 0.25]),
    // 13
    Subdivision(
        name: "2 Triplets & Triplet Rest",
        description: "Two triplets followed by a rest",
        restPattern: [true, true, false],
        durationPattern: [0.34, 0.33, 0.33]),
    // 14
    Subdivision(
        name: "Triplet Rest & 2 Triplets",
        description: "Rest for triplet and two triplet notes",
        restPattern: [false, true, true],
        durationPattern: [0.34, 0.33, 0.33]),
    // 15
    Subdivision(
        name: "Triplet Rest, Triplet, Triplet Rest",
        description: "Rest, triplet, and rest",
        restPattern: [false, true, false],
        durationPattern: [0.34, 0.33, 0.33]),
    // 16
    Subdivision(
        name: "Quintuplets",
        description: "Five equal notes in one beat",
        restPattern: [true, true, true, true, true],
        durationPattern: [0.2, 0.2, 0.2, 0.2, 0.2]),
    // 17
    Subdivision(
        name: "Septuplets",
        description: "Seven equal notes in one beat",
        restPattern: [true, true, true, true, true, true, true],
        durationPattern: [0.143, 0.143, 0.143, 0.143, 0.143, 0.143, 0.142])
  ];

  Color getTickColor(index) {
    return switch (_metronome.tickTypes[index]) {
      TickType.silence => Colors.grey,
      TickType.regular => Colors.blue,
      TickType.accent => Colors.orange,
      TickType.strongAccent => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: StreamBuilder<Metronome>(
          stream: _metronome.metronomeStream,
          builder: (context, snapshot) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 80,
                  child: Row(
                    spacing: 10,
                    children: List.generate(
                      _metronome.tickTypes.length,
                      (index) => Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _metronome.setNextTickType(tickIndex: index);
                          },
                          child: Container(color: getTickColor(index)),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "BPM: ${_metronome.bpm.toInt()}",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Slider(
                  value: _metronome.bpm.toDouble(),
                  max: 400,
                  min: 20,
                  onChanged: (value) {
                    _metronome.setBpm(value.toInt());
                  },
                ),
                SelectWidget<int>(
                  label: "Beats count",
                  list: beats,
                  value: _metronome.timeSignatureNumerator,
                  onChange: (beatsCount) {
                    _metronome.setTimeSignatureNumerator(beatsCount);
                  },
                ),
                SizedBox(height: 10),
                SelectWidget<Subdivision>(
                  label: "Subdivision",
                  list: subdivisions,
                  value: _metronome.subdivision,
                  onChange: (subdivision) {
                    _metronome.setSubdivision(subdivision);
                  },
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_metronome.isPlaying) {
                          _metronome.stop();
                        } else {
                          _metronome.start();
                        }
                      },
                      child: Text(_metronome.isPlaying ? "Stop" : "Start"),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        _metronome.tap();
                      },
                      child: Text("Tap"),
                    ),
                  ],
                ),
              ],
            );
          }),
    );
  }
}
