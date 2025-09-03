import 'package:flutter/material.dart';
import 'package:metro_drone_plugin/models/drone_tone.dart';
import 'package:metro_drone_plugin/models/metronome.dart';
import 'package:metro_drone_plugin_example/widgets/select_widget.dart';

class DronePage extends StatefulWidget {
  const DronePage({super.key});

  @override
  State<DronePage> createState() => _DronePageState();
}

class _DronePageState extends State<DronePage> {
  final DroneTone _droneTone = DroneTone();
  TextEditingController standardController = TextEditingController(text: "440");
  double droneDurationRatio = 0.5;
  List<String> notes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  @override
  void initState() {
    droneDurationRatio = Metronome().droneDurationRatio;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DroneTone>(
        stream: _droneTone.droneToneStream,
        builder: (context, snapshot) {
          final droneTone = snapshot.data ?? _droneTone;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Sound Type"),
                    Spacer(),
                    SelectWidget<SoundType>(
                      list: SoundType.values,
                      value: droneTone.soundType,
                      onChange: (value) {
                        droneTone.setSoundType(value);
                      },
                      label: "",
                    )
                  ],
                ),
                Row(
                  children: [
                    Text("Pulsed Drone"),
                    Spacer(),
                    Switch(
                      value: droneTone.isPulsing,
                      onChanged: (value) {
                        _droneTone.setPulsing(value);
                      },
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Duration ${Metronome().droneDurationRatio.toStringAsFixed(2)}",
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: droneDurationRatio,
                        onChanged: (value) {
                          Metronome().setDroneDurationRatio(value);
                          setState(() {
                            droneDurationRatio = value;
                          });
                        },
                        min: 0.0,
                        max: 1,
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("Tuning Standard A")),
                    Expanded(
                      child: TextField(
                        controller: standardController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final standard = double.tryParse(value);
                          if (standard != null) {
                            droneTone.setTuningStandard(standard);
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter value",
                        ),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("Octave:")),
                    Expanded(
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _droneTone.setNote(
                                note: _droneTone.note,
                                octave: _droneTone.octave - 1,
                              );
                            },
                            child: Icon(Icons.remove),
                          ),
                          Expanded(
                              child:
                                  Center(child: Text("${droneTone.octave}"))),
                          ElevatedButton(
                            onPressed: () {
                              _droneTone.setNote(
                                note: _droneTone.note,
                                octave: _droneTone.octave + 1,
                              );
                            },
                            child: Icon(Icons.add),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: notes
                      .map(
                        (note) => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: note == droneTone.note
                                ? Colors.deepPurple
                                : null,
                          ),
                          onPressed: () {
                            _droneTone.setNote(
                                note: note, octave: _droneTone.octave);
                            setState(() {});
                          },
                          child: Text(note),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (droneTone.isPlaying) {
                      droneTone.stop();
                    } else {
                      droneTone.start();
                    }
                  },
                  child: Text(droneTone.isPlaying ? "Stop" : "Start"),
                )
              ],
            ),
          );
        });
  }
}
