import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Email form
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'david.vance@bhp.com');
  final _passwordCtrl = TextEditingController(text: 'Pass1234!');
  bool _obscurePassword = true;

  // WhatsApp form
  final _waFormKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+675';
  final _waPhoneCtrl = TextEditingController(text: '71234567');
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  String? _otpHint;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+675', 'country': 'Papua New Guinea', 'flag': '🇵🇬'},
    {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
    {'code': '+677', 'country': 'Solomon Islands', 'flag': '🇸🇧'},
    {'code': '+62', 'country': 'Indonesia', 'flag': '🇮🇩'},
    {'code': '+63', 'country': 'Philippines', 'flag': '🇵🇭'},
    {'code': '+64', 'country': 'New Zealand', 'flag': '🇳🇿'},
    {'code': '+44', 'country': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '+1', 'country': 'United States', 'flag': '🇺🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _waPhoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _fullWhatsAppNumber => '$_selectedCountryCode ${_waPhoneCtrl.text.trim()}';

  void _submitEmailLogin() {
    if (_emailFormKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            EmailLoginSubmitted(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            ),
          );
    }
  }

  void _requestWhatsAppOtp() {
    if (_waFormKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            SendWhatsAppOtpRequested(whatsappNumber: _fullWhatsAppNumber),
          );
    }
  }

  void _submitWhatsAppLogin() {
    if (_otpCtrl.text.trim().length >= 4) {
      context.read<AuthBloc>().add(
            WhatsAppLoginSubmitted(
              whatsappNumber: _fullWhatsAppNumber,
              otp: _otpCtrl.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07101E),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AviationColors.statusIncident,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is OtpSent) {
            setState(() {
              _otpSent = true;
              _otpHint = state.codeHint;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('WhatsApp verification code sent to ${state.whatsappNumber} (Code: ${state.codeHint})'),
                backgroundColor: AviationColors.statusCompleted,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo & Header
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151E32),
                        shape: BoxShape.circle,
                        border: Border.all(color: AviationColors.gold500, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AviationColors.gold500.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.shield, color: AviationColors.gold500, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PNG SECURE AIRPORT TRANSFER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nadzab Tomodachi (AYNZ) & Jacksons (POM)\nArmed Convoy & VIP Chauffeur Portal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Main Authentication Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151E32),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tab Bar
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F1524),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: AviationColors.gold500,
                              indicatorWeight: 3,
                              labelColor: AviationColors.gold500,
                              unselectedLabelColor: Colors.white54,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.email_outlined, size: 18),
                                  text: 'Email & Password',
                                ),
                                Tab(
                                  icon: Icon(Icons.chat_bubble_outline, size: 18),
                                  text: 'WhatsApp Number',
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: SizedBox(
                              height: 330,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Tab 1: Email Form
                                  _buildEmailLoginForm(isLoading),
                                  // Tab 2: WhatsApp Form
                                  _buildWhatsAppLoginForm(isLoading),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              color: AviationColors.gold500,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Guest Option
                    TextButton.icon(
                      icon: const Icon(Icons.person_outline, size: 16, color: Colors.white60),
                      label: const Text(
                        'Continue as Guest (Instant Emergency Booking)',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      onPressed: () {
                        context.read<AuthBloc>().add(GuestContinueRequested());
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fast Demo Quick Sign-in Expansion
                    ExpansionTile(
                      shape: const Border(),
                      title: const Text(
                        'OPERATIONAL DEMO ACCOUNTS (PNG FIELD TEAMS)',
                        style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        textAlign: TextAlign.center,
                      ),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildDemoChip('Capt. David Vance (BHP)', 'david.vance@bhp.com'),
                            _buildDemoChip('Sarah Jenkins (UN)', 'sarah.jenkins@un.org'),
                            _buildDemoChip('Hiroshi Tanaka (JICA)', 'tanaka.hiroshi@jica.go.jp'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailLoginForm(bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Corporate & Passenger Sign In',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
            decoration: _inputDecoration(
              label: 'Corporate / Personal Email',
              hint: 'e.g., david.vance@bhp.com',
              icon: Icons.alternate_email,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            obscureText: _obscurePassword,
            validator: (v) => v == null || v.length < 4 ? 'Password required' : null,
            decoration: _inputDecoration(
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AviationColors.gold500,
              foregroundColor: AviationColors.navy900,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isLoading ? null : _submitEmailLogin,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AviationColors.navy900),
                  )
                : const Text(
                    'SIGN IN WITH EMAIL',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppLoginForm(bool isLoading) {
    return Form(
      key: _waFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Instant WhatsApp Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Receive an instant OTP via WhatsApp for high-security field login.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Country Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1524),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    dropdownColor: const Color(0xFF151E32),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: _countryCodes.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['code'],
                        child: Text('${c['flag']} ${c['code']}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCountryCode = v ?? '+675'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // WhatsApp Number Input
              Expanded(
                child: TextFormField(
                  controller: _waPhoneCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().length < 6 ? 'Enter valid phone number' : null,
                  decoration: _inputDecoration(
                    label: 'WhatsApp Mobile Number',
                    hint: '7123 4567',
                    icon: Icons.phone_android,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_otpSent) ...[
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'SEND WHATSAPP CODE',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
              onPressed: isLoading ? null : _requestWhatsAppOtp,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Code sent! Demo Code: ${_otpHint ?? "482910"}',
                      style: const TextStyle(color: Color(0xFF25D366), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _otpCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: _inputDecoration(
                label: 'Enter 6-Digit WhatsApp Code',
                hint: '482910',
                icon: Icons.key_outlined,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isLoading ? null : _submitWhatsAppLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'VERIFY & SIGN IN',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoChip(String label, String email) {
    return ActionChip(
      backgroundColor: const Color(0xFF0F1524),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      avatar: const Icon(Icons.login, color: AviationColors.gold500, size: 14),
      onPressed: () {
        _emailCtrl.text = email;
        _passwordCtrl.text = 'DemoPass2026!';
        _submitEmailLogin();
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.white54, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0F1524),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AviationColors.gold500),
      ),
    );
  }
}

