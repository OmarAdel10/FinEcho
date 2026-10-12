import 'package:flutter/material.dart';

/// A temporary screen used while feature views are implemented.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a placeholder screen with a title.
  const new({required this.title, super.key});

  /// The route title displayed in the app bar and body.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
