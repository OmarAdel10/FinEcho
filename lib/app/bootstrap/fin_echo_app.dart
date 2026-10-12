import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The root FinEcho application widget.
class FinEchoApp extends StatelessWidget {
  /// Creates the root application widget.
  const new({required this.router, super.key});

  /// The navigation configuration for the app.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinEcho',
      theme: FinEchoTheme.light(),
      darkTheme: FinEchoTheme.dark(),
      routerConfig: router,
    );
  }
}
