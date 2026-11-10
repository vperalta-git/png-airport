import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';
import '../config/demo_mode.dart';
import '../config/local_firebase.dart';
import '../screens/mobile_demo_app.dart';
import '../services/png_api_client.dart';
import '../theme/aviation_theme.dart';
import 'connected_session.dart';
import 'connected_website_landing.dart';

const connectedReviewBuild = bool.fromEnvironment('AEROTRANS_CONNECTED_REVIEW');

Future<void> runConnectedReviewApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!connectedReviewBuild || offlineDemoBuild) {
    runApp(MaterialApp(
        theme: AviationTheme.lightTheme,
        home: const Scaffold(
            body: Center(
                child: Text('Use the connected review build command.')))));
    return;
  }
  runApp(const ConnectedReviewBootstrap());
}

class ConnectedReviewBootstrap extends StatefulWidget {
  final Future<void> Function()? initialize;
  final WidgetBuilder? readyBuilder;
  final Uri? webOrigin;
  const ConnectedReviewBootstrap(
      {super.key, this.initialize, this.readyBuilder, this.webOrigin});
  @override
  State<ConnectedReviewBootstrap> createState() =>
      _ConnectedReviewBootstrapState();
}

class _ConnectedReviewBootstrapState extends State<ConnectedReviewBootstrap> {
  bool busy = false, ready = false;
  String? error;
  bool get website => kIsWeb || widget.webOrigin != null;
  @override
  void initState() {
    super.initState();
    connect();
  }

  Future<void> connect() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (website &&
          !AppConfig.hostedTest &&
          !AppConfig.allowsLocalWebServices(widget.webOrigin ?? Uri.base)) {
        setState(() => error =
            'Online services are not configured for this website. Sign-in and bookings are currently unavailable.');
        return;
      }
      await (widget.initialize ?? LocalFirebase.initialize)()
          .timeout(const Duration(seconds: 25));
      if (mounted) setState(() => ready = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = website || AppConfig.hostedTest
            ? 'The review services are unavailable. Sign-in and bookings will be available when the server connection is restored.'
            : 'The review server is unavailable. Keep this phone connected to the '
                'review computer by USB and ask the operator to start the services. '
                'Retry when the connection is restored.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ready
      ? widget.readyBuilder?.call(context) ?? const ConnectedReviewApp()
      : MaterialApp(
          title: website ? 'AeroTrans Papua New Guinea' : 'AeroTrans Connected',
          debugShowCheckedModeBanner: false,
          theme: AviationTheme.lightTheme,
          home: website
              ? ConnectedWebsiteLanding(
                  busy: busy,
                  message: error,
                  onRetry: connect,
                  configured: AppConfig.hostedTest)
              : Scaffold(
                  appBar: AppBar(title: const Text('AeroTrans Connected')),
                  body: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.connecting_airports,
                                        size: 60,
                                        color: AviationColors.primaryNavy),
                                    const SizedBox(height: 20),
                                    Text(
                                        busy
                                            ? 'Connecting to review services'
                                            : 'Connection needs attention',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    if (busy)
                                      const LinearProgressIndicator()
                                    else ...[
                                      DemoMessage(error!),
                                      const SizedBox(height: 16),
                                      FilledButton.icon(
                                          onPressed: connect,
                                          icon: const Icon(Icons.refresh),
                                          label:
                                              const Text('Retry connection')),
                                    ],
                                    const SizedBox(height: 20),
                                    Text(
                                        AppConfig.hostedTest
                                            ? 'Isolated hosted test • Papua New Guinea'
                                            : 'Local backend review • Papua New Guinea\nAn APK alone does not provide remote server access.',
                                        textAlign: TextAlign.center),
                                  ]))))));
}

class ConnectedReviewApp extends StatefulWidget {
  final ConnectedSession? session;
  const ConnectedReviewApp({super.key, this.session});
  @override
  State<ConnectedReviewApp> createState() => _ConnectedReviewAppState();
}

class _ConnectedReviewAppState extends State<ConnectedReviewApp> {
  late final ConnectedSession session;
  String? selectedRole;
  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      session = widget.session!;
    } else {
      final identity = FirebaseConnectedIdentity(FirebaseAuth.instance);
      session = ConnectedSession(
          identity: identity,
          api: PngApiClient(tokenProvider: () => identity.token()));
    }
    session.addListener(refresh);
    session.start();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> switchAccount() async {
    await session.signOut();
    if (mounted && !session.hasIdentity) setState(() => selectedRole = null);
  }

  @override
  void dispose() {
    session.removeListener(refresh);
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  Widget roleCard(String role, IconData icon, String description) {
    final label =
        role == 'SUPERVISOR' ? 'Manager / Supervisor' : roleName(role);
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
            key: ValueKey('connected-role-$role'),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: CircleAvatar(
                backgroundColor:
                    AviationColors.primaryNavy.withValues(alpha: .08),
                child: Icon(icon, color: AviationColors.primaryNavy)),
            title: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(description),
            trailing: const Icon(Icons.chevron_right),
            onTap: session.working
                ? null
                : () => setState(() => selectedRole = role)));
  }

  Widget landing() => Scaffold(
      appBar: AppBar(title: const Text('AeroTrans Connected')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(padding: const EdgeInsets.all(20), children: [
                const DemoBanner(),
                const SizedBox(height: 20),
                Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        color: AviationColors.primaryNavy,
                        borderRadius: BorderRadius.circular(22)),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.flight_takeoff,
                              color: AviationColors.gold500, size: 32),
                          SizedBox(height: 14),
                          Text('One platform. Four workspaces.',
                              style: TextStyle(
                                  fontSize: 25,
                                  height: 1.2,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 10),
                          Text(
                              'Lae / Nadzab • Papua New Guinea\nBookings and operations share the same backend.',
                              style: TextStyle(
                                  color: Colors.white70, height: 1.5)),
                        ])),
                const SizedBox(height: 22),
                Text('Choose your workspace',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                    'Sign in with your own account. Your backend permissions determine which workspace opens.'),
                const SizedBox(height: 16),
                if (session.notice != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(session.notice!,
                          key: const ValueKey('connected-notice'))),
                roleCard('PASSENGER', Icons.person_outline,
                    'Book transfers and follow your reservations'),
                roleCard('DISPATCHER', Icons.support_agent,
                    'Assign drivers and manage dispatch'),
                roleCard('DRIVER', Icons.directions_car_outlined,
                    'View assigned trips and verify pickups'),
                roleCard('SUPERVISOR', Icons.manage_accounts_outlined,
                    'Review activity, staff and vehicles'),
                const SizedBox(height: 8),
                const Text(
                    AppConfig.hostedTest
                        ? 'Hosted test environment • Test accounts and test fares only. No live payments.'
                        : 'Connected local review • Keep USB connected to the review computer. '
                            'Remote reviews require a hosted test environment.',
                    style: TextStyle(fontSize: 12)),
              ]))));

  Widget accountUnavailable() => Scaffold(
      appBar: AppBar(title: const Text('Verify your account')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DemoMessage(session.error ??
                        'Your account has not been verified by the backend.'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                        onPressed: session.working ? null : session.restore,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry account verification')),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: session.working ? null : switchAccount,
                        child: const Text('Sign out and change account')),
                  ])))));

  @override
  Widget build(BuildContext context) {
    final profile = session.profile;
    return MaterialApp(
        // Changing authorized identity destroys all previous account routes.
        key: ValueKey('connected-${profile?['uid'] ?? 'signed-out'}'),
        debugShowCheckedModeBanner: false,
        title: 'AeroTrans Connected',
        theme: AviationTheme.lightTheme,
        home: session.loading || (session.actionBusy && session.hasIdentity)
            ? const Scaffold(
                body: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: 18),
                Text('Verifying your account...')
              ])))
            : profile != null
                ? DemoWorkspace(
                    api: session.api,
                    profile: profile,
                    onLogout: switchAccount,
                    onSwitchAccount: switchAccount)
                : session.hasIdentity
                    ? accountUnavailable()
                    : selectedRole == null
                        ? landing()
                        : PopScope(
                            canPop: false,
                            onPopInvokedWithResult: (didPop, _) {
                              if (!didPop && !session.working) {
                                setState(() => selectedRole = null);
                              }
                            },
                            child: DemoLoginPanel(
                                role: selectedRole!,
                                error: session.error,
                                onBack: () =>
                                    setState(() => selectedRole = null),
                                onLogin: session.signIn,
                                onRegister: session.register)));
  }
}
