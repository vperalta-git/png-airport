import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _selectedCountryCode = '+675';
  UserRole _selectedRole = UserRole.passenger;
  bool _obscurePassword = true;
  bool _agreedToTerms = true;

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
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the PNG Transfer Terms of Service & Security Protocol.'),
          backgroundColor: AviationColors.statusIncident,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final fullWa = '$_selectedCountryCode ${_phoneCtrl.text.trim()}';

      context.read<AuthBloc>().add(
            RegistrationSubmitted(
              name: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              whatsappNumber: fullWa,
              company: _companyCtrl.text.trim(),
              role: _selectedRole,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07101E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CREATE PASSENGER ACCOUNT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
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
          } else if (state is Authenticated) {
            Navigator.pop(context); // Return to home/root
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151E32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AviationColors.gold500.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_add_alt_1, color: AviationColors.gold500, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REGISTRATION PROFILE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Instant WhatsApp & Email Account Creation',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 20),

                        // Full Legal Name
                        TextFormField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                          decoration: _inputDecoration(
                            label: 'Full Legal Name *',
                            hint: 'e.g., Jonathan Kaupa',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email Address
                        TextFormField(
                          controller: _emailCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@') ? 'Valid corporate or personal email required' : null,
                          decoration: _inputDecoration(
                            label: 'Email Address *',
                            hint: 'e.g., j.kaupa@morobe.pg',
                            icon: Icons.alternate_email,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // WhatsApp Number with Country Code
                        const Text(
                          'WhatsApp Verified Mobile Number *',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
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
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.trim().length < 6 ? 'Valid WhatsApp phone required' : null,
                                decoration: _inputDecoration(
                                  label: 'Mobile / WhatsApp Number',
                                  hint: '7123 4567',
                                  icon: Icons.phone_android,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Company / Organization
                        TextFormField(
                          controller: _companyCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration(
                            label: 'Company / Project / Agency (Optional)',
                            hint: 'e.g., Morobe Resources Ltd / UN Logistics',
                            icon: Icons.business_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Role Selector
                        DropdownButtonFormField<UserRole>(
                          initialValue: _selectedRole,
                          dropdownColor: const Color(0xFF151E32),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration(
                            label: 'Account Type',
                            hint: '',
                            icon: Icons.badge_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: UserRole.passenger,
                              child: Text('Individual / Executive Passenger'),
                            ),
                            DropdownMenuItem(
                              value: UserRole.corporate,
                              child: Text('Corporate Travel Procurement Booker'),
                            ),
                          ],
                          onChanged: (r) => setState(() => _selectedRole = r ?? UserRole.passenger),
                        ),
                        const SizedBox(height: 14),

                        // Password Fields
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _passwordCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                obscureText: _obscurePassword,
                                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                                decoration: _inputDecoration(
                                  label: 'Password *',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _confirmPasswordCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                obscureText: _obscurePassword,
                                validator: (v) => v != _passwordCtrl.text ? 'Passwords must match' : null,
                                decoration: _inputDecoration(
                                  label: 'Confirm Password *',
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Terms Checkbox
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _agreedToTerms,
                          activeColor: AviationColors.gold500,
                          checkColor: AviationColors.navy900,
                          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                          title: Text(
                            'I agree to the PNG Transfer Terms of Service & RPNGC Escort Protocol',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                          subtitle: Text(
                            'Mandates satellite GPS tracking and security escorts across high-risk corridors.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AviationColors.gold500,
                            foregroundColor: AviationColors.navy900,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AviationColors.navy900),
                                )
                              : const Text(
                                  'COMPLETE REGISTRATION & SIGN IN',
                                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                ),
                          onPressed: isLoading ? null : _submitRegistration,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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

