import 'dart:math'; // Import for Random
import 'package:flutter/material.dart';
import 'helper.dart'; // Import the helper.dart file

// Fish Class
class Fish extends StatefulWidget {
  final Color color;
  final double speed;

  Fish({required this.color, required this.speed});

  @override
  _FishState createState() => _FishState();
}

class _FishState extends State<Fish> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double left = 0;
  double top = 0;
  double angle = 0; // Store the angle for direction

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _controller.addListener(() {
      setState(() {
        // Update position based on angle
        left += cos(angle) * widget.speed; // X-axis movement
        top += sin(angle) * widget.speed; // Y-axis movement

        // Check for boundary collision
        if (left < 0 || left > 280) {
          angle = pi - angle; // Reverse direction horizontally
          left = left.clamp(0.0, 280.0); // Keep within bounds
        }
        if (top < 0 || top > 280) {
          angle = -angle; // Reverse direction vertically
          top = top.clamp(0.0, 280.0); // Keep within bounds
        }

        // Change direction randomly at intervals
        if (Random().nextDouble() < 0.05) { // 5% chance to change direction
          angle = Random().nextDouble() * 2 * pi; // Random angle
        }
      });
    });
    _controller.repeat();
    _randomizeDirection(); // Randomize the initial direction
  }

  void _randomizeDirection() {
    angle = Random().nextDouble() * 2 * pi; // Set initial angle randomly
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 20,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

// Main App Class
void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

// Aquarium Screen
class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> {
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final settings = await DatabaseHelper().loadSettings();
    if (settings != null) {
      setState(() {
        int fishCount = settings['fish_count'] ?? 0;
        double fishSpeed = settings['fish_speed']?.toDouble() ?? 1.0;
        String fishColor = settings['fish_color'] ?? Colors.blue.value.toString();
        selectedSpeed = fishSpeed;
        selectedColor = Color(int.parse(fishColor.replaceFirst('Color(0xff', '0xff')));
        for (int i = 0; i < fishCount; i++) {
          fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
        }
      });
    }
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  void _updateFishSpeed(double newSpeed) {
    setState(() {
      selectedSpeed = newSpeed;
      // Update speed for all existing fish
      fishList = fishList.map((fish) => Fish(color: fish.color, speed: selectedSpeed)).toList();
    });
  }

  void _saveSettings() {
    DatabaseHelper().saveSettings(fishList.length, selectedSpeed, selectedColor.value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          )
        ],
      ),
      body: Center(
        child: Column(
          children: [
            // Aquarium with watery background
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan.withOpacity(0.7), // Light watery blue
                    Colors.lightBlueAccent.withOpacity(0.7), // Lighter blue
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.5), // Border for a glassy effect
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(15), // Rounded corners for a softer aquarium look
              ),
              child: Stack(
                children: fishList.map((fish) => fish).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _addFish,
              child: Text('Add Fish'),
            ),
            Row(
              children: [
                Text('Speed:'),
                Slider(
                  value: selectedSpeed,
                  min: 0.5,
                  max: 5.0, // Adjust maximum speed as needed
                  divisions: 9, // Increased for better control
                  onChanged: (value) {
                    _updateFishSpeed(value); // Update fish speed when slider changes
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text('Color:'),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: [
                    DropdownMenuItem(
                      child: Container(width: 20, height: 20, color: Colors.red),
                      value: Colors.red,
                    ),
                    DropdownMenuItem(
                      child: Container(width: 20, height: 20, color: Colors.blue),
                      value: Colors.blue,
                    ),
                    DropdownMenuItem(
                      child: Container(width: 20, height: 20, color: Colors.green),
                      value: Colors.green,
                    ),
                  ],
                  onChanged: (color) {
                    setState(() {
                      if (color != null) {
                        selectedColor = color; // Update the selected color
                      }
                    });
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
