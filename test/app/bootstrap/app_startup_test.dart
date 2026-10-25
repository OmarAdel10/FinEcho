import 'package:finecho/app/bootstrap/app_startup.dart';
import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/main.dart' as app;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() async {
    await GetIt.instance.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
    await GetIt.instance.reset();
  });

  test('builds the application after loading the persisted state', () async {
    final widget = await buildApp(useInMemoryStorage: true);

    expect(widget, isA<FinEchoApp>());
    expect(sl<SecurityCubit>().state.status, SecurityAccessStatus.unlocked);
    expect(sl<SecurityCubit>().state.isLocked, isFalse);
    expect(sl<OnboardingCubit>().state.status, OnboardingStatus.ready);
  });

  test('wires the app lock into the application scope', () async {
    final widget = await buildApp(useInMemoryStorage: true);

    expect(widget.securityCubit, isNotNull);
    expect(widget.securityCubit, same(sl<SecurityCubit>()));
    expect(widget.analyticsCubit, isNotNull);
    expect(widget.analyticsCubit, same(sl<AnalyticsCubit>()));
  });

  test('mounts the application through the entrypoint', () async {
    Widget? mounted;

    await app.main(
      runner: (widget) => mounted = widget,
      useInMemoryStorage: true,
    );

    expect(mounted, isA<FinEchoApp>());
  });
}
