import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/local_firebase.dart';
import '../models/contracts_v1.dart';
import '../services/png_api_client.dart';
import '../theme/aviation_theme.dart';
import '../config/demo_mode.dart';
part 'mobile_demo_booking.dart';
part 'mobile_demo_management.dart';

String roleName(String role) =>
    {
      'PASSENGER': 'Customer',
      'DISPATCHER': 'Control Room',
      'DRIVER': 'Driver',
      'SUPERVISOR': 'Supervisor',
      'SUPER_ADMIN': 'Supervisor'
    }[role] ??
    role;
String statusName(String value) => value
    .toLowerCase()
    .split('_')
    .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
    .join(' ');
String pgk(int minor) => 'PGK ${(minor / 100).toStringAsFixed(2)}';
String pngTime(String value) =>
    '${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(value).toUtc().add(const Duration(hours: 10)))} PNG';
String readableError(Object error) {
  if (error is ApiException) return error.message;
  if (error is FirebaseAuthException) {
    return {
          'invalid-credential': 'Email or password is incorrect.',
          'wrong-password': 'Email or password is incorrect.',
          'user-not-found': 'Email or password is incorrect.',
          'network-request-failed':
              'Cannot reach the demo authentication service. Check the USB connection.',
          'user-disabled': 'This account is suspended.'
        }[error.code] ??
        error.message ??
        'Sign-in failed.';
  }
  return 'The request could not be completed. Check the demo connection and refresh.';
}

Future<void> runMobileDemo(String expectedRole) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalFirebase.initialize().timeout(const Duration(seconds: 20));
    runApp(MobileDemoApp(expectedRole: expectedRole));
  } catch (error) {
    runApp(LocalFoundationApp(
        role: roleName(expectedRole),
        error:
            'Connect the demo phone by USB and start the local demo services. ${readableError(error)}'));
  }
}

class MobileDemoApp extends StatefulWidget {
  final String expectedRole;
  const MobileDemoApp({super.key, required this.expectedRole});
  @override
  State<MobileDemoApp> createState() => _MobileDemoAppState();
}

class _MobileDemoAppState extends State<MobileDemoApp> {
  late final PngApiClient api;
  StreamSubscription<User?>? subscription;
  Map<String, dynamic>? profile;
  bool restoring = true;
  String? error;
  int generation = 0;
  final navigation = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    api = PngApiClient(
        tokenProvider: () async =>
            FirebaseAuth.instance.currentUser?.getIdToken());
    subscription =
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      final version = ++generation;
      if (user == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            navigation.currentState?.popUntil((route) => route.isFirst);
          }
        });
        if (mounted) {
          setState(() {
            profile = null;
            restoring = false;
          });
        }
        return;
      }
      if (mounted) setState(() => restoring = true);
      try {
        await user.getIdToken(true);
        final me = await api.get('/api/v1/auth/me') as Map<String, dynamic>;
        if (me['role'] != widget.expectedRole &&
            !(widget.expectedRole == 'SUPERVISOR' &&
                me['role'] == 'SUPER_ADMIN')) {
          throw ApiException('WRONG_APP',
              'Use the ${roleName(me['role'] as String)} app for this account.');
        }
        if (mounted && version == generation) {
          setState(() {
            profile = me;
            restoring = false;
            error = null;
          });
        }
      } catch (e) {
        if (mounted && version == generation) {
          setState(() {
            profile = null;
            restoring = false;
            error = readableError(e);
          });
        }
        await FirebaseAuth.instance.signOut();
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> register(
      String name, String email, String password, String phone) async {
    await api.post('/api/v1/auth/register', {
      'schemaVersion': '1',
      'fullName': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone.trim().isNotEmpty) 'phone': phone.trim()
    });
    await login(email, password);
  }

  Future<void> logout() async {
    try {
      await api.post('/api/v1/auth/logout', {});
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      navigatorKey: navigation,
      title: 'AeroTrans ${roleName(widget.expectedRole)} Demo',
      debugShowCheckedModeBanner: false,
      theme: AviationTheme.lightTheme,
      home: restoring
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : profile == null
              ? DemoLoginPanel(
                  role: widget.expectedRole,
                  error: error,
                  onLogin: login,
                  onRegister: register)
              : DemoWorkspace(
                  key: ValueKey(profile!['uid']),
                  api: api,
                  profile: profile!,
                  onLogout: logout));
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: const Text(
          offlineDemoBuild
              ? 'OFFLINE DEMO • Practice data on this phone • No real payments'
              : 'ISOLATED DEMO • Test fares • No live payment collection',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              color: Color(0xFF5F4600),
              fontWeight: FontWeight.w600)));
}

class DemoMessage extends StatelessWidget {
  final String message;
  final VoidCallback? retry;
  const DemoMessage(this.message, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF0EF),
          border: Border.all(color: const Color(0xFFFFDAD6)),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.info_outline, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
            child: Semantics(
                liveRegion: true,
                child: Text(message,
                    style: const TextStyle(
                        color: Color(0xFF7A2420), height: 1.4)))),
        if (retry != null)
          IconButton(
              tooltip: 'Retry',
              onPressed: retry,
              icon: const Icon(Icons.refresh))
      ]));
}

class DemoLoginPanel extends StatefulWidget {
  final String role;
  final String? error;
  final Future<void> Function(String, String) onLogin;
  final Future<void> Function(String, String, String, String) onRegister;
  final VoidCallback? onBack;
  const DemoLoginPanel(
      {super.key,
      required this.role,
      this.error,
      required this.onLogin,
      required this.onRegister,
      this.onBack});
  @override
  State<DemoLoginPanel> createState() => _DemoLoginPanelState();
}

class _DemoLoginPanelState extends State<DemoLoginPanel> {
  final form = GlobalKey<FormState>(),
      name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      phone = TextEditingController();
  bool register = false, busy = false, obscurePassword = true;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (register) {
        await widget.onRegister(
            name.text, email.text, password.text, phone.text);
      } else {
        await widget.onLogin(email.text, password.text);
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  tooltip: 'Back to accounts',
                  onPressed: busy ? null : widget.onBack,
                  icon: const Icon(Icons.arrow_back)),
          title: Text('AeroTrans ${roleName(widget.role)}')),
      body: Column(children: [
        const DemoBanner(),
        Expanded(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView(
                        padding: const EdgeInsets.all(24),
                        shrinkWrap: true,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AviationColors.primaryNavy,
                                    borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.flight_takeoff,
                                    size: 28, color: AviationColors.goldTrim)),
                            const SizedBox(width: 14),
                            const Expanded(
                                child: Text('AEROTRANS',
                                    style: TextStyle(
                                        fontSize: 19,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w700))),
                          ]),
                          const SizedBox(height: 18),
                          Text(
                              register
                                  ? 'Create your customer account'
                                  : 'Sign in to ${roleName(widget.role)}',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          const Text('Papua New Guinea • Lae / Nadzab',
                              style: TextStyle(
                                  color: AviationColors.textSecondary)),
                          const SizedBox(height: 18),
                          if (error != null || widget.error != null)
                            DemoMessage(error ?? widget.error!),
                          Form(
                              key: form,
                              child: Column(children: [
                                if (register)
                                  _field(name, 'Full name',
                                      busy: busy, mandatory: true),
                                _field(email, 'Email',
                                    busy: busy,
                                    mandatory: true,
                                    keyboard: TextInputType.emailAddress,
                                    validate: (v) => v != null &&
                                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                .hasMatch(v.trim())
                                        ? null
                                        : 'Enter a valid email address'),
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: TextFormField(
                                        controller: password,
                                        enabled: !busy,
                                        obscureText: obscurePassword,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        textInputAction: register
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        autofillHints: [
                                          register
                                              ? AutofillHints.newPassword
                                              : AutofillHints.password
                                        ],
                                        onFieldSubmitted:
                                            register ? null : (_) => submit(),
                                        decoration: InputDecoration(
                                            labelText: 'Password',
                                            suffixIcon: IconButton(
                                                tooltip: obscurePassword
                                                    ? 'Show password'
                                                    : 'Hide password',
                                                onPressed: busy
                                                    ? null
                                                    : () => setState(() =>
                                                        obscurePassword =
                                                            !obscurePassword),
                                                icon: Icon(obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined))),
                                        validator: (v) => v != null &&
                                                v.length >= (register ? 10 : 1)
                                            ? null
                                            : register
                                                ? 'Use at least 10 characters'
                                                : 'Enter your password')),
                                if (register)
                                  _field(phone, 'Phone (+675 or country code)',
                                      busy: busy,
                                      keyboard: TextInputType.phone),
                                const SizedBox(height: 8),
                                SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: FilledButton(
                                        onPressed: busy ? null : submit,
                                        child: busy
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : Text(register
                                                ? 'Create account'
                                                : 'Sign in'))),
                                if (widget.role == 'PASSENGER')
                                  TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => setState(() {
                                                register = !register;
                                                error = null;
                                              }),
                                      child: Text(register
                                          ? 'Already registered? Sign in'
                                          : 'Create a customer account')),
                              ])),
                        ]))))
      ]));
}

Widget _field(TextEditingController controller, String label,
        {bool busy = false,
        bool mandatory = false,
        bool secret = false,
        TextInputType? keyboard,
        String? Function(String?)? validate}) =>
    Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
            controller: controller,
            enabled: !busy,
            obscureText: secret,
            keyboardType: keyboard,
            textInputAction: TextInputAction.next,
            autocorrect: !secret,
            enableSuggestions: !secret,
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder()),
            validator: validate ??
                (v) => mandatory && (v == null || v.trim().isEmpty)
                    ? 'Enter ${label.toLowerCase()}'
                    : null));

class DemoWorkspace extends StatefulWidget {
  final PngApiClient api;
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final Future<void> Function()? onSwitchAccount;
  const DemoWorkspace(
      {super.key,
      required this.api,
      required this.profile,
      required this.onLogout,
      this.onSwitchAccount});
  @override
  State<DemoWorkspace> createState() => _DemoWorkspaceState();
}

class _DemoWorkspaceState extends State<DemoWorkspace> {
  int tab = 0;
  bool signingOut = false;
  bool get manager =>
      ['SUPERVISOR', 'SUPER_ADMIN'].contains(widget.profile['role']);
  Future<void> logout() async {
    if (signingOut) return;
    setState(() => signingOut = true);
    try {
      await widget.onLogout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(readableError(error))));
      }
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }

  Future<void> switchAccount() async {
    if (signingOut || widget.onSwitchAccount == null) return;
    setState(() => signingOut = true);
    try {
      await widget.onSwitchAccount!();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(readableError(error))));
      }
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text('AeroTrans ${roleName(widget.profile['role'])}'),
          actions: [
            if (widget.onSwitchAccount != null)
              IconButton(
                  tooltip: 'Switch account',
                  onPressed: signingOut ? null : switchAccount,
                  icon: const Icon(Icons.switch_account_outlined)),
            IconButton(
                tooltip: 'Sign out',
                onPressed: signingOut ? null : logout,
                icon: const Icon(Icons.logout))
          ]),
      body: Column(children: [
        const DemoBanner(),
        Expanded(
            child: tab == 0
                ? DemoBookings(api: widget.api, profile: widget.profile)
                : DemoManagement(api: widget.api, profile: widget.profile))
      ]),
      bottomNavigationBar: manager
          ? NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (v) => setState(() => tab = v),
              destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: 'Operations'),
                  NavigationDestination(
                      icon: Icon(Icons.manage_accounts_outlined),
                      label: 'Management')
                ])
          : null);
}

class StatusChipV1 extends StatelessWidget {
  final String value;
  final bool payment;
  const StatusChipV1(this.value, {super.key, this.payment = false});
  Color get color => payment
      ? {
            'PAID': AviationColors.statusVerified,
            'AUTHORIZED': AviationColors.statusConfirmed,
            'FAILED': AviationColors.statusIncident,
            'REFUNDED': AviationColors.statusAtAirport,
            'CANCELLED': AviationColors.statusCancelled
          }[value] ??
          const Color(0xFF8A4B00)
      : AviationColors.getStatusColor(value);
  @override
  Widget build(BuildContext context) => Chip(
      visualDensity: VisualDensity.compact,
      label: Text('${payment ? 'Payment: ' : ''}${statusName(value)}',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      backgroundColor: color.withValues(alpha: .10),
      side: BorderSide.none);
}

/// Keeps existing screens readable on phones, tablets and wide review windows.
class DemoContentList extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  const DemoContentList(
      {super.key, required this.children, this.maxWidth = 960});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => ListView(
          padding: EdgeInsets.symmetric(
              horizontal: max(18, (constraints.maxWidth - maxWidth) / 2),
              vertical: 20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          children: children));
}

class DemoEmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const DemoEmptyState(
      {super.key,
      required this.title,
      required this.message,
      this.icon = Icons.event_note_outlined});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(children: [
            Icon(icon, size: 36, color: AviationColors.textMuted),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AviationColors.textSecondary, height: 1.4))
          ])));
}
