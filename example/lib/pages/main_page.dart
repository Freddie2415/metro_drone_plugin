import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metro_drone_plugin_example/pages/drone_page.dart';
import 'package:metro_drone_plugin_example/pages/metronome_page.dart';
import 'package:metro_drone_plugin_example/pages/tuner_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int pageIndex = 0;

  String get pageTitle {
    return switch (pageIndex) {
      0 => "Metronome",
      1 => "Drone",
      2 => "Tuner",
      int() => "???",
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: [
        MetronomePage(),
        DronePage(),
        TunerPage(),
      ][pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.metronome),
            label: "Metronome",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.waveform_path),
            label: "Drone",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tuningfork),
            label: "Tuner",
          ),
        ],
        onTap: (int? index) {
          pageIndex = index ?? 0;
          setState(() {});
        },
        currentIndex: pageIndex,
      ),
    );
  }
}
