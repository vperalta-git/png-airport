import 'package:flutter/material.dart';
import '../../models/corporate_passenger.dart';

class AddTravelerDialog extends StatefulWidget {
  final Function(CorporatePassenger) onTravelerAdded;

  const AddTravelerDialog({
    super.key,
    required this.onTravelerAdded,
  });

  @override
  State<AddTravelerDialog> createState() => _AddTravelerDialogState();
}

class _AddTravelerDialogState extends State<AddTravelerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _deptCtrl = TextEditingController(text: 'Morobe Geological Services');
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+675 ');
  final _idCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController(text: '+675 7333 4444 (Base Ops)');
  bool _isVip = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _deptCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final passenger = CorporatePassenger(
        id: 'pax_${DateTime.now().millisecondsSinceEpoch}',
        fullName: _nameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        idNumber: _idCtrl.text.trim(),
        isVip: _isVip,
        emergencyContact: _emergencyCtrl.text.trim(),
      );

      widget.onTravelerAdded(passenger);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF151E32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add_alt_1_outlined, color: Colors.blueAccent),
                        SizedBox(width: 10),
                        Text(
                          'REGISTER EXECUTIVE TRAVELER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Add authorized personnel for seamless corporate flight transfers.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 20),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _nameCtrl,
                                label: 'Full Legal Name *',
                                hint: 'e.g., Jonathan Kaupa',
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _titleCtrl,
                                label: 'Corporate Title / Role *',
                                hint: 'e.g., Chief Geologist',
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _deptCtrl,
                                label: 'Department / Unit *',
                                hint: 'e.g., Exploration Ops',
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _idCtrl,
                                label: 'Passport / National ID *',
                                hint: 'e.g., PNG-PASS-772180',
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _emailCtrl,
                                label: 'Corporate Email *',
                                hint: 'e.g., j.kaupa@morobe.pg',
                                validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _phoneCtrl,
                                label: 'Mobile / Satellite Phone *',
                                hint: 'e.g., +675 7123 4567',
                                validator: (v) => v == null || v.length < 5 ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emergencyCtrl,
                          label: 'Emergency Security Contact *',
                          hint: 'e.g., +675 7333 4444 (Base Ops)',
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Designate as High-Priority VIP Traveler', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(
                            'Enables expedited tarmac meet-and-greet and priority convoy staging.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                          value: _isVip,
                          activeColor: Colors.tealAccent,
                          onChanged: (val) => setState(() => _isVip = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Save Traveler'),
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
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
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }
}

