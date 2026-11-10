import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_flutter_core/offline/offline_demo_app.dart';
import 'package:png_transfer_flutter_core/offline/offline_demo_store.dart';
import 'package:png_transfer_flutter_core/config/demo_mode.dart';

class RecoverablePersistence extends MemoryDemoPersistence {
  bool unreadable = true, failReset = true;
  @override
  Future<String?> read() async {
    if (unreadable) throw const FormatException('Invalid practice snapshot');
    return super.read();
  }

  @override
  Future<void> clear() async {
    if (failReset) throw StateError('Storage temporarily unavailable');
    unreadable = false;
    await super.clear();
  }
}

class MissingNativePluginPersistence extends MemoryDemoPersistence {
  @override
  Future<String?> read() async => throw PlatformException(
      code: 'channel-error',
      message: 'Unable to establish connection on channel');
}

void main() {
  testWidgets('combined demo offers all roles sharing one persisted store',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final disk = MemoryDemoPersistence();
    final store = await OfflineDemoStore.open(disk);
    await tester.pumpWidget(
        OfflineDemoApp(store: store, initialRole: 'PASSENGER', allRoles: true));
    await tester.pumpAndSettle();
    for (final role in ['PASSENGER', 'DISPATCHER', 'DRIVER', 'SUPERVISOR']) {
      expect(find.byKey(ValueKey('offline-start-$role')), findsOneWidget);
    }
    final start = find.byKey(const ValueKey('offline-start-DISPATCHER'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('AeroTrans Control Room'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('offline-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer - Demo Customer').last);
    await tester.pumpAndSettle();
    expect(find.text('AeroTrans Customer'), findsOneWidget);
    final restored = await OfflineDemoStore.open(disk);
    expect(restored.activeUid, 'offline-customer');
    expect(
        (await restored.get('offline-customer', '/api/v1/bookings') as List)
            .length,
        2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    restored.dispose();
  }, skip: !offlineDemoBuild);

  testWidgets('startup reset failure is visible and a later reset recovers',
      (tester) async {
    final disk = RecoverablePersistence();
    await tester.pumpWidget(OfflineDemoBootstrap(
        initialRole: 'PASSENGER', allRoles: true, persistence: disk));
    await tester.pumpAndSettle();
    expect(find.textContaining('OFFLINE_STORAGE_ERROR'), findsOneWidget);
    await tester.tap(find.text('Reset offline practice data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset practice data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reset could not be completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
    disk.failReset = false;
    await tester.tap(find.text('Reset offline practice data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset practice data'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a demo role'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('offline-start-PASSENGER')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !offlineDemoBuild);

  testWidgets('missing native storage plugin does not offer a futile reset',
      (tester) async {
    await tester.pumpWidget(OfflineDemoBootstrap(
        initialRole: 'PASSENGER',
        persistence: MissingNativePluginPersistence()));
    await tester.pumpAndSettle();
    expect(find.textContaining('STORAGE_PLUGIN_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Reset offline practice data'), findsNothing);
    await tester.tap(find.text('Retry opening demo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('STORAGE_PLUGIN_UNAVAILABLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !offlineDemoBuild);

  testWidgets(
      'offline startup and role switching work with no Firebase or backend',
      (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await OfflineDemoStore.open(MemoryDemoPersistence());
    await tester
        .pumpWidget(OfflineDemoApp(store: store, initialRole: 'PASSENGER'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OFFLINE DEMO'), findsOneWidget);
    await tester.tap(find.text('Start Customer demo'));
    await tester.pumpAndSettle();
    expect(find.text('AeroTrans Customer'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Customer - Demo Customer')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('offline-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Control Room - Demo Control Room').last);
    await tester.pumpAndSettle();
    expect(find.text('AeroTrans Control Room'), findsOneWidget);
    expect(store.activeUid, 'offline-control');
    await tester.tap(find.byKey(const ValueKey('offline-guide')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Other phones and other APK installations'),
        findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('offline-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset practice data'));
    await tester.pumpAndSettle();
    expect(find.text('Start Customer demo'), findsOneWidget);
    expect(store.activeUid, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
    store.dispose();
  }, skip: !offlineDemoBuild);
  testWidgets('each role starts its own offline walkthrough', (tester) async {
    for (final role in ['DISPATCHER', 'DRIVER', 'SUPERVISOR']) {
      final store = await OfflineDemoStore.open(MemoryDemoPersistence());
      await tester.pumpWidget(
          OfflineDemoApp(key: ValueKey(role), store: store, initialRole: role));
      await tester.pumpAndSettle();
      final start = find.text(role == 'DISPATCHER'
          ? 'Start Control Room demo'
          : role == 'DRIVER'
              ? 'Start Driver demo'
              : 'Start Supervisor demo');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(store.profile(store.activeUid)?['role'], role);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    }
  }, skip: !offlineDemoBuild);
}
