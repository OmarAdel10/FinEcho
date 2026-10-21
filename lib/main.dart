import 'package:finecho/app/bootstrap/app_startup.dart';
import 'package:flutter/widgets.dart';

/// Mounts the FinEcho application.
///
/// The [runner] parameter keeps the entrypoint executable in tests without
/// mounting a second root widget.
Future<void> main({void Function(Widget app) runner = runApp}) async {
  runner(await buildApp());
}
