import 'dart:async';

import 'package:flutter/material.dart';
import 'package:metro_drone_plugin/models/tuner.dart';
import 'package:permission_handler/permission_handler.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final Tuner _tuner = Tuner();
  StreamSubscription<Pitch>? streamSubscription;
  bool isActive = false;

  @override
  void initState() {
    isActive = _tuner.isActive;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<Pitch>(
              stream: _tuner.pitchStream,
              builder: (context, snapshot) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Note: ${snapshot.data?.note ?? "-"}",
                        style: Theme.of(context).textTheme.displaySmall),
                    Text(
                        "Cents Off: ${snapshot.data?.closestOffsetCents.toStringAsFixed(2) ?? "-"}",
                        style: Theme.of(context).textTheme.displaySmall),
                    Text(
                        "Hz: ${snapshot.data?.frequency.toStringAsFixed(2) ?? "-"}",
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                );
              }),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: Text("Tuning Standard",
                      style: Theme.of(context).textTheme.bodyLarge)),
              Expanded(
                child: TextField(
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final standard = double.tryParse(value);
                    if (standard != null) {
                      _tuner.setTuningStandard(standard).then((value) {
                        print("frequency set: $value");
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter value",
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _onTuner,
            child: Text(isActive ? "Stop" : "Start"),
          ),
          TunerIndicator(
            pitchStream: _tuner.pitchStream.map(
              (p) => p.closestOffsetCents.toInt(),
            ),
          ),
        ],
      ),
    );
  }

  void _onTuner() async {
    if (isActive) {
      isActive = await _tuner.stop();
    } else {
      // Request microphone permission before starting
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        try {
          isActive = await _tuner.start();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error starting tuner: $e')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required for tuner')),
          );
        }
      }
    }
    setState(() {});
  }
}

class TunerIndicator extends StatefulWidget {
  const TunerIndicator({super.key, required this.pitchStream});

  final Stream<int> pitchStream;

  @override
  State<TunerIndicator> createState() => _TunerIndicatorState();
}

class _TunerIndicatorState extends State<TunerIndicator> {
  late StreamSubscription<int> _subscription;
  double _indicatorPosition = 0;
  int _currentCents = 0;
  List<FallingDot> _fallingDots = [];

  GlobalKey _containerKey = GlobalKey();

  double get center {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox != null ? renderBox.size.width / 2 : 0;
  }

  double get unitStep =>
      center / 50; // Двигаем индикатор в зависимости от центров

  @override
  void initState() {
    super.initState();
    _subscription = widget.pitchStream.listen((cents) {
      if (_currentCents != cents) {
        setState(() {
          _fallingDots.add(FallingDot(left: center + _indicatorPosition - 5));
          _currentCents = cents;
          _indicatorPosition = unitStep * cents;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _containerKey,
      color: Colors.deepPurple.shade200,
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Stack(
        children: [
          // Центральная линия
          Center(
            child: Container(
              height: 200,
              width: 1,
              color: Colors.white,
            ),
          ),
          // Падающие точки
          ..._fallingDots,
          // Индикатор
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: center - 15 + _indicatorPosition,
            top: 10,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurpleAccent,
              ),
              child: Center(
                child: Text(
                  '$_currentCents',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FallingDot extends StatefulWidget {
  final double left;

  const FallingDot({super.key, required this.left});

  @override
  State<FallingDot> createState() => _FallingDotState();
}

class _FallingDotState extends State<FallingDot> {
  double _top = 15;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _top = 200;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _opacity = 0.55;
          });
        }
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _top = 300;
            _opacity = 0.0;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(seconds: 5),
      curve: Curves.easeIn,
      left: widget.left,
      top: _top,
      child: AnimatedOpacity(
        duration: const Duration(seconds: 5),
        opacity: _opacity,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
