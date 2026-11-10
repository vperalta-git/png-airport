import 'package:flutter/material.dart';
import '../theme/aviation_theme.dart';

/// Public website content has no dependency on Firebase or operational records.
/// Account actions remain unavailable until bootstrap verifies real services.
class ConnectedWebsiteLanding extends StatelessWidget {
  final bool busy;
  final String? message;
  final VoidCallback onRetry;
  final bool configured;
  const ConnectedWebsiteLanding(
      {super.key,
      required this.busy,
      required this.message,
      required this.onRetry,
      this.configured = false});

  Widget workspace(
          String title, String description, IconData icon, double width) =>
      SizedBox(
          width: width,
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: AviationColors.primaryNavy, size: 30),
                        const SizedBox(height: 16),
                        Text(title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(description, style: const TextStyle(height: 1.5)),
                      ]))));

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('AeroTrans Papua New Guinea')),
      body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          children: [
            Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                  color: AviationColors.primaryNavy,
                                  borderRadius: BorderRadius.circular(24)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.flight_takeoff,
                                        color: AviationColors.gold500,
                                        size: 42),
                                    const SizedBox(height: 22),
                                    Text(
                                        'Airport transfers,\nconnected from booking to arrival.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2)),
                                    const SizedBox(height: 18),
                                    const Text(
                                        'Lae / Nadzab • Papua New Guinea',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 17)),
                                    const SizedBox(height: 12),
                                    const Text(
                                        'One platform for customers, dispatch teams, drivers and supervisors.',
                                        style: TextStyle(
                                            color: Colors.white, height: 1.6)),
                                  ])),
                          const SizedBox(height: 24),
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3CD),
                                  borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        busy
                                            ? 'Checking online services'
                                            : configured
                                                ? 'Online services temporarily unavailable'
                                                : 'Online services awaiting configuration',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17)),
                                    const SizedBox(height: 8),
                                    Text(
                                        message ??
                                            'The website is available. We are checking the account and booking services.',
                                        style: const TextStyle(height: 1.5)),
                                    const SizedBox(height: 16),
                                    if (busy)
                                      const LinearProgressIndicator()
                                    else
                                      Wrap(
                                          spacing: 12,
                                          runSpacing: 10,
                                          children: [
                                            const FilledButton(
                                                key:
                                                    ValueKey('website-sign-in'),
                                                onPressed: null,
                                                child: Text(
                                                    'Sign-in unavailable')),
                                            OutlinedButton.icon(
                                                onPressed: onRetry,
                                                icon: const Icon(Icons.refresh),
                                                label: const Text(
                                                    'Check service availability')),
                                          ]),
                                  ])),
                          const SizedBox(height: 32),
                          Text('Four workspaces. One transfer workflow.',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (context, constraints) {
                            final width = constraints.maxWidth >= 720
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth;
                            return Wrap(spacing: 16, runSpacing: 16, children: [
                              workspace(
                                  'Customer',
                                  'Book airport transfers and follow reservations, assigned drivers and pickup details.',
                                  Icons.person_outline,
                                  width),
                              workspace(
                                  'Control Room',
                                  'Coordinate reservations, eligible vehicles and driver assignments.',
                                  Icons.support_agent,
                                  width),
                              workspace(
                                  'Driver',
                                  'Manage assigned trips, passenger pickup verification and trip progress.',
                                  Icons.directions_car_outlined,
                                  width),
                              workspace(
                                  'Manager / Supervisor',
                                  'Review operational activity, staff, vehicles and audit records.',
                                  Icons.manage_accounts_outlined,
                                  width),
                            ]);
                          }),
                          const SizedBox(height: 24),
                          const Text(
                              'Lae / Nadzab pilot • PGK • PNG time (UTC+10)',
                              style: TextStyle(
                                  color: AviationColors.textSecondary)),
                          const SizedBox(height: 24),
                        ]))),
          ]));
}
