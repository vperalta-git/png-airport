import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../widgets/tactical_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TacticalAppBar(
        title: 'Passenger & Corporate ID',
        subtitle: 'Authorization Level & Security Credentials',
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AviationColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AviationColors.gold500.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AviationColors.navy800,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AviationColors.gold500, width: 2),
                      ),
                      child: const Center(
                        child: Text('👨‍✈️', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Traveler',
                            style: const TextStyle(
                              color: AviationColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.company ?? 'B2B Corporate Account',
                            style: const TextStyle(
                                color: AviationColors.gold400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble,
                                  size: 12, color: Color(0xFF25D366)),
                              const SizedBox(width: 4),
                              Text(
                                user?.whatsappNumber ??
                                    user?.phone ??
                                    '+675 7123 4567',
                                style: const TextStyle(
                                    color: AviationColors.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.login ?? 'david.vance@bhp.com',
                            style: const TextStyle(
                                color: AviationColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AviationColors.statusVerified
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: AviationColors.statusVerified),
                      ),
                      child: const Text(
                        'VIP PROTOCOL',
                        style: TextStyle(
                          color: AviationColors.statusVerified,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Corporate Travel Authorization Box
              const Text(
                'CORPORATE TRAVEL TERMS',
                style: TextStyle(
                    color: AviationColors.gold400,
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AviationColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AviationColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                        'Billing Mode', 'Consolidated Monthly Statement'),
                    _buildInfoRow(
                        'Payment Terms', 'Net 30 Days (Direct Tax Invoicing)'),
                    _buildInfoRow('Armed Convoy Status',
                        'Authorized for Level 2 & 3 Corridors'),
                    _buildInfoRow('Cloud Run Backend URL',
                        context.read<BookingRepository>().apiClient.baseUrl),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Emergency Hotlines
              const Text(
                '24/7 EMERGENCY & ARMED ESCORT HOTLINES',
                style: TextStyle(
                    color: AviationColors.gold400,
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _buildHotlineCard(
                title: 'Nadzab Airfield Operations Command',
                phone: '+675 475 1100',
                desc:
                    'Lae/Morobe 24-hr Airfield & Highway Ground Security Liaison',
              ),
              const SizedBox(height: 8),
              _buildHotlineCard(
                title: 'Jacksons Int\'l Operations Desk',
                phone: '+675 324 4500',
                desc: 'Port Moresby Diplomatic & Close Protection Unit',
              ),
              const SizedBox(height: 24),

              // Edit Profile Button
              OutlinedButton.icon(
                icon: const Icon(Icons.edit,
                    size: 16, color: AviationColors.gold500),
                label: const Text('EDIT CONTACT INFORMATION',
                    style: TextStyle(color: AviationColors.textPrimary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AviationColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _showEditProfileDialog(context, user);
                },
              ),
              const SizedBox(height: 12),

              // Sign Out / Switch Account Button
              OutlinedButton.icon(
                icon: const Icon(Icons.logout,
                    size: 16, color: AviationColors.statusIncident),
                label: const Text(
                  'SIGN OUT / SWITCH OPERATIONAL ACCOUNT',
                  style: TextStyle(
                      color: AviationColors.statusIncident,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color:
                          AviationColors.statusIncident.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                  color: AviationColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AviationColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard(
      {required String title, required String phone, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AviationColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AviationColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AviationColors.statusIncident.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.emergency,
                color: AviationColors.statusIncident, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(desc,
                    style: const TextStyle(
                        color: AviationColors.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(phone,
                    style: const TextStyle(
                        color: AviationColors.gold400,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserSession? user) {
    final nameCtrl = TextEditingController(text: user?.name);
    final compCtrl = TextEditingController(text: user?.company);
    final phoneCtrl = TextEditingController(text: user?.phone);
    final waCtrl =
        TextEditingController(text: user?.whatsappNumber ?? user?.phone);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AviationColors.cardDark,
        title: const Text('Update Profile',
            style: TextStyle(color: AviationColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 10),
            TextField(
                controller: compCtrl,
                decoration:
                    const InputDecoration(labelText: 'Company / Project')),
            const SizedBox(height: 10),
            TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contact Phone')),
            const SizedBox(height: 10),
            TextField(
                controller: waCtrl,
                decoration:
                    const InputDecoration(labelText: 'WhatsApp Number')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AviationColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                    ProfileUpdated(
                      name: nameCtrl.text,
                      company: compCtrl.text,
                      phone: phoneCtrl.text,
                      whatsappNumber: waCtrl.text,
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
