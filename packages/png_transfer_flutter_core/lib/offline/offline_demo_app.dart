import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/demo_mode.dart';
import '../screens/mobile_demo_app.dart';
import '../theme/aviation_theme.dart';
import 'offline_demo_persistence.dart';
import 'offline_demo_store.dart';

Future<void> runOfflineDemo(String initialRole, {bool allRoles = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!offlineDemoBuild) {
    runApp(MaterialApp(
        theme: AviationTheme.lightTheme,
        home: const Scaffold(
            body: Center(
                child: Text('Use the separate offline APK build command.')))));
    return;
  }
  runApp(OfflineDemoBootstrap(initialRole: initialRole, allRoles: allRoles));
}

/// Owns native storage startup and recovery without recursively restarting runApp.
class OfflineDemoBootstrap extends StatefulWidget {
  final String initialRole;
  final bool allRoles;
  final OfflineDemoPersistence? persistence;
  const OfflineDemoBootstrap(
      {super.key,
      required this.initialRole,
      this.allRoles = false,
      this.persistence});
  @override
  State<OfflineDemoBootstrap> createState() => _OfflineDemoBootstrapState();
}

class _OfflineDemoBootstrapState extends State<OfflineDemoBootstrap> {
  late final OfflineDemoPersistence persistence;
  OfflineDemoStore? store;
  bool busy = false, confirming = false, missingPlugin = false;
  String? error;

  @override
  void initState() {
    super.initState();
    persistence = widget.persistence ?? PreferencesDemoPersistence();
    open();
  }

  Future<void> open({bool reset = false}) async {
    if (busy) return;
    if (mounted) setState(() => busy = true);
    try {
      if (reset) await persistence.clear().timeout(const Duration(seconds: 15));
      final restored = await OfflineDemoStore.open(persistence)
          .timeout(const Duration(seconds: 15));
      if (!mounted) {
        restored.dispose();
        return;
      }
      setState(() {
        store = restored;
        error = null;
      });
    } catch (failure) {
      final unavailable = failure is MissingPluginException ||
          failure is PlatformException && failure.code == 'channel-error';
      // Log only error types/codes, never saved accounts or practice records.
      debugPrint('AeroTrans offline startup: ${failure.runtimeType}'
          '${failure is PlatformException ? ' (${failure.code})' : ''}');
      if (mounted) {
        setState(() {
          missingPlugin = unavailable;
          error = unavailable
              ? 'Android storage is unavailable in this build. Install the latest '
                  'AeroTrans demo APK. Resetting data cannot repair a missing plugin. '
                  '(STORAGE_PLUGIN_UNAVAILABLE)'
              : '${reset ? 'Reset could not be completed. ' : ''}'
                  'Offline practice data could not be opened. Retry, or reset only '
                  'this installation\'s practice data. (OFFLINE_STORAGE_ERROR)';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reset(BuildContext context) async {
    if (busy || confirming || missingPlugin) return;
    setState(() => confirming = true);
    bool? yes;
    try {
      yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Reset offline practice data?'),
                  content: const Text(
                      'This clears only this offline demo installation. Online data and other apps are untouched.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep data')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset practice data'))
                  ]));
    } finally {
      if (mounted) setState(() => confirming = false);
    }
    if (yes == true && mounted) await open(reset: true);
  }

  @override
  void dispose() {
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => store != null
      ? OfflineDemoApp(
          store: store!,
          initialRole: widget.initialRole,
          allRoles: widget.allRoles)
      : MaterialApp(
          theme: AviationTheme.lightTheme,
          home: Builder(
              builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('AeroTrans Offline Demo')),
                  body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (busy) ...[
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              const Text('Opening offline practice data...'),
                            ] else ...[
                              Text(error ?? 'Offline storage is unavailable.'),
                              const SizedBox(height: 16),
                              FilledButton(
                                  onPressed: confirming ? null : () => open(),
                                  child: const Text('Retry opening demo')),
                              if (!missingPlugin)
                                TextButton(
                                    onPressed: confirming
                                        ? null
                                        : () => reset(context),
                                    child: const Text(
                                        'Reset offline practice data')),
                            ],
                          ])))));
}

class _DemoRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> childOpen;
  bool active = true;
  _DemoRouteObserver(this.childOpen);
  void update(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (active) childOpen.value = route.isFirst == false;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      update(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      update(previousRoute);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      update(previousRoute);
}

class OfflineDemoApp extends StatefulWidget {
  final OfflineDemoStore store;
  final String initialRole;
  final bool allRoles;
  const OfflineDemoApp(
      {super.key,
      required this.store,
      required this.initialRole,
      this.allRoles = false});
  @override
  State<OfflineDemoApp> createState() => _OfflineDemoAppState();
}

class _OfflineDemoAppState extends State<OfflineDemoApp> {
  final navigation = GlobalKey<NavigatorState>(),
      childOpen = ValueNotifier(false);
  late final _DemoRouteObserver observer;
  String? active;
  bool busy = false, loginForm = false, prompting = false;
  String? error;
  int generation = 0;
  OfflineDemoStore get store => widget.store;
  BuildContext get dialogContext => navigation.currentState!.overlay!.context;
  Map<String, dynamic>? get profile => store.profile(active);
  Map<String, dynamic> get defaultPersona =>
      store.personas.firstWhere((p) => p['role'] == widget.initialRole,
          orElse: () => store.personas.first);
  @override
  void initState() {
    super.initState();
    active = store.activeUid;
    observer = _DemoRouteObserver(childOpen);
    store.addListener(refresh);
  }

  Future<T?> guardedDialog<T>(
      BuildContext context, WidgetBuilder builder) async {
    if (prompting || busy) return null;
    setState(() => prompting = true);
    try {
      return await showDialog<T>(context: context, builder: builder);
    } finally {
      if (mounted) setState(() => prompting = false);
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(refresh);
    observer.active = false;
    childOpen.dispose();
    super.dispose();
  }

  Future<void> choose(String uid) async {
    if (busy || childOpen.value) return;
    setState(() => busy = true);
    try {
      await store.choosePersona(uid);
      if (mounted) {
        setState(() {
          active = uid;
          error = null;
          loginForm = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> login(String email, String password) async {
    final result = await store.signIn(email, password);
    if (mounted) {
      setState(() {
        active = result['uid'] as String;
        loginForm = false;
        error = null;
      });
    }
  }

  Future<void> register(
      String name, String email, String password, String phone) async {
    final result = await store.register({
      'fullName': name,
      'email': email,
      'password': password,
      'phone': phone
    });
    if (mounted) {
      setState(() {
        active = result['uid'] as String;
        loginForm = false;
        error = null;
      });
    }
  }

  Future<void> logout() async {
    await store.signOut();
    if (mounted) setState(() => active = null);
  }

  Future<void> reset(BuildContext context) async {
    final yes = await guardedDialog<bool>(
        context,
        (ctx) => AlertDialog(
                title: const Text('Reset offline practice data?'),
                content: const Text(
                    'This removes your practice reservations, accounts and changes in this app, then reloads the sample scenarios. Other APKs and the online backend are unaffected.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep data')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset practice data'))
                ]));
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      await store.reset();
      if (mounted) {
        setState(() {
          active = null;
          generation++;
          error = null;
          loginForm = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> selectRole() async {
    if (busy || childOpen.value) return;
    final selected = await guardedDialog<String>(
        dialogContext,
        (ctx) => SimpleDialog(
            title: const Text('Switch demo role'),
            children: store.personas
                .map((p) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, p['uid'] as String),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            '${roleName(p['role'] as String)} - ${p['fullName']}'))))
                .toList()));
    if (selected != null) await choose(selected);
  }

  Widget startRoleButton(String role, IconData icon) {
    final candidates = store.personas.where((p) => p['role'] == role);
    final persona = candidates.isEmpty ? null : candidates.first;
    final label =
        role == 'SUPERVISOR' ? 'Manager / Supervisor' : roleName(role);
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
            height: 54,
            child: FilledButton.icon(
                key: ValueKey('offline-start-$role'),
                onPressed: busy || persona == null
                    ? null
                    : () => choose(persona['uid'] as String),
                icon: Icon(icon),
                label: Text('Open $label demo'))));
  }

  @override
  Widget build(BuildContext context) {
    final current = profile;
    final baseTheme = AviationTheme.lightTheme;
    return MaterialApp(
      title: widget.allRoles
          ? 'AeroTrans All Roles Offline'
          : 'AeroTrans Offline ${roleName(widget.initialRole)}',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigation,
      navigatorObservers: [observer],
      theme: baseTheme.copyWith(
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
              fontFamily:
                  'packages/png_transfer_flutter_core/OfflineAeroRoboto'),
          textTheme: baseTheme.textTheme.apply(
              fontFamily:
                  'packages/png_transfer_flutter_core/OfflineAeroRoboto')),
      builder: (context, child) => FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Column(verticalDirection: VerticalDirection.up, children: [
            Expanded(
                child: MediaQuery.removePadding(
                    context: context,
                    removeTop: current != null,
                    child: child ?? const SizedBox())),
            if (current != null)
              Material(
                  color: AviationColors.primaryNavy,
                  child: SafeArea(
                      bottom: false,
                      child: ValueListenableBuilder<bool>(
                          valueListenable: childOpen,
                          builder: (context, open, _) => Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                              child: Row(children: [
                                Expanded(
                                    child: TextButton(
                                        key: const ValueKey('offline-role'),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            alignment: Alignment.centerLeft,
                                            textStyle: const TextStyle(
                                                fontFamily:
                                                    'packages/png_transfer_flutter_core/OfflineAeroRoboto',
                                                fontSize: 14)),
                                        onPressed: busy || open || prompting
                                            ? null
                                            : selectRole,
                                        child: Row(children: [
                                          Expanded(
                                              child: Text(
                                                  '${roleName(current['role'] as String)} - ${current['fullName']}',
                                                  overflow:
                                                      TextOverflow.ellipsis)),
                                          const Icon(Icons.expand_more)
                                        ]))),
                                IconButton(
                                    key: const ValueKey('offline-guide'),
                                    onPressed: prompting
                                        ? null
                                        : () => guardedDialog<void>(
                                            dialogContext,
                                            (ctx) => AlertDialog(
                                                    title: const Text(
                                                        'Offline practice only'),
                                                    content: const Text(
                                                        'This installation has its own saved practice data. Return to the dashboard and switch demo roles to follow the same reservation through Customer, Control Room, Driver and Supervisor. Other phones and other APK installations do not share these records. No Firebase, server, live payment or messaging is used.'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  ctx),
                                                          child: const Text(
                                                              'Got it'))
                                                    ])),
                                    icon: const Icon(Icons.help_outline,
                                        semanticLabel: 'Offline guide',
                                        color: Colors.white)),
                                IconButton(
                                    key: const ValueKey('offline-reset'),
                                    onPressed: busy || open || prompting
                                        ? null
                                        : () => reset(dialogContext),
                                    icon: const Icon(Icons.restart_alt,
                                        semanticLabel: 'Reset offline demo',
                                        color: Colors.white)),
                              ]))))),
          ])),
      home: current != null
          ? DemoWorkspace(
              key: ValueKey('$active-$generation'),
              api: OfflineDemoClient(store, current['uid'] as String),
              profile: current,
              onLogout: logout)
          : loginForm
              ? DemoLoginPanel(
                  role: widget.initialRole,
                  error: error,
                  onLogin: login,
                  onRegister: register)
              : Builder(
                  builder: (context) => Scaffold(
                      appBar: AppBar(
                          title: Text(widget.allRoles
                              ? 'AeroTrans All Roles Offline'
                              : 'AeroTrans ${roleName(widget.initialRole)} Offline')),
                      body: SafeArea(
                          child: ListView(
                              padding: const EdgeInsets.all(22),
                              children: [
                            const DemoBanner(),
                            SizedBox(height: widget.allRoles ? 12 : 24),
                            Icon(Icons.flight_takeoff,
                                size: widget.allRoles ? 40 : 56,
                                color: AviationColors.primaryNavy),
                            SizedBox(height: widget.allRoles ? 12 : 20),
                            Text(
                                widget.allRoles
                                    ? 'Choose a demo role'
                                    : 'Test the complete flow without internet',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            Text(widget.allRoles
                                ? 'All four roles share the same practice bookings on this phone. Switch accounts from the dashboard to follow one booking. No internet or server is needed.'
                                : 'Practice bookings, driver assignment, pickup codes, trip completion and management are saved on this phone. No server, USB connection or Firebase setup is needed.'),
                            if (!widget.allRoles) ...[
                              const SizedBox(height: 12),
                              const Text(
                                  'Two clearly labelled practice reservations and a small demo fleet are ready. Each APK installation has independent data. Switch demo roles inside this app to follow one reservation from start to finish.'),
                            ],
                            if (error != null) DemoMessage(error!),
                            const SizedBox(height: 24),
                            if (widget.allRoles) ...[
                              startRoleButton(
                                  'PASSENGER', Icons.person_outline),
                              startRoleButton(
                                  'DISPATCHER', Icons.support_agent),
                              startRoleButton('DRIVER', Icons.directions_car),
                              startRoleButton(
                                  'SUPERVISOR', Icons.manage_accounts),
                            ] else
                              SizedBox(
                                  height: 54,
                                  child: FilledButton.icon(
                                      onPressed: busy
                                          ? null
                                          : () => choose(
                                              defaultPersona['uid'] as String),
                                      icon: const Icon(Icons.play_arrow),
                                      label: Text(
                                          'Start ${roleName(widget.initialRole)} demo'))),
                            const SizedBox(height: 12),
                            OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() => loginForm = true),
                                child: const Text(
                                    'Try practice sign-in or registration')),
                            const SizedBox(height: 16),
                            SelectableText(
                                'Practice email: ${defaultPersona['email'] as String}\nPractice password: $offlinePracticePassword'),
                            const SizedBox(height: 12),
                            const Text(
                                'Use made-up details only. Practice login is a local simulation; it does not validate real Firebase authentication or server security.'),
                            const SizedBox(height: 16),
                            TextButton(
                                onPressed: busy ? null : () => reset(context),
                                child: const Text('Reset this offline demo')),
                          ])))),
    );
  }
}
