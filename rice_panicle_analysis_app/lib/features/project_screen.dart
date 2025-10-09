import 'package:flutter/material.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Project Screen',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}