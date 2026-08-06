import 'package:flutter/material.dart';

class HardwareDetailScreen extends StatelessWidget {
  const HardwareDetailScreen({super.key, required this.hardwareId});

  final String hardwareId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hardware Details')),
      body: Center(
        child: Text('Details for hardware $hardwareId'),
      ),
    );
  }
}
