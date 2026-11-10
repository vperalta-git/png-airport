import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../blocs/corporate_state.dart';
import '../../models/corporate_passenger.dart';

class NewTransferWizardTab extends StatefulWidget {
  final CorporateState state;
  final Function({
    required String leadPassenger,
    required int passengerCount,
    required String flightNumber,
    required String airportName,
    required String pickupLocation,
    required String destination,
    required DateTime scheduledPickup,
    required String vehicleType,
    required String escortLevel,
    required String poNumber,
    required String costCenter,
    required double farePgk,
    required String notes,
  }) onSubmitTransfer;
  final VoidCallback onCancel;

  const NewTransferWizardTab({
    super.key,
    required this.state,
    required this.onSubmitTransfer,
    required this.onCancel,
  });

  @override
  State<NewTransferWizardTab> createState() => _NewTransferWizardTabState();
}

class _NewTransferWizardTabState extends State<NewTransferWizardTab> {
  final _formKey = GlobalKey<FormState>();

  CorporatePassenger? _selectedPassenger;
  final _customPassengerCtrl = TextEditingController();
  int _passengerCount = 1;

  final _flightCtrl = TextEditingController(text: 'PX102 (Air Niugini)');
  String _selectedAirport = 'Nadzab / Tomodachi (LAE)';
  final _pickupLocCtrl = TextEditingController(text: 'Nadzab Arrival Terminal 1');
  final _destinationCtrl = TextEditingController(text: 'Lae International Hotel, Morobe');

  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 3));
  TimeOfDay _scheduledTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 3)));

  String _selectedVehicle = 'Toyota LandCruiser 79 Security Spec (B6 Armored)';
  String _selectedEscort = 'LEVEL 2 ARMED ESCORT PROTOCOL';

  final _poNumberCtrl = TextEditingController(text: 'PO-2026-MMR-8899');
  final _costCenterCtrl = TextEditingController(text: 'CC-MOROBE-OPS');
  final _notesCtrl = TextEditingController(
    text: 'Executive mining personnel. Armed escort mandatory across Markham Highway corridor. Satellite tracker enabled.',
  );

  final List<String> _airports = [
    'Nadzab / Tomodachi (LAE)',
    "Jackson's International (POM)",
    'Kagamuga Airport (HGU)',
    'Tokua Airport (RAB)',
  ];

  final Map<String, double> _vehicleBaseRates = {
    'Toyota LandCruiser 79 Security Spec (B6 Armored)': 1350.0,
    'Prado B6 Tactical Escort': 890.0,
    'Toyota LandCruiser 200 Executive B6': 1650.0,
    'Dual-Vehicle Tactical Convoy (Lead LC79 + Prado Chase)': 2450.0,
  };

  final Map<String, double> _escortSurcharges = {
    'LEVEL 1 STANDARD CHAUFFEUR': 0.0,
    'LEVEL 2 ARMED ESCORT PROTOCOL': 200.0,
    'LEVEL 3 HIGH-THREAT ARMED CONVOY': 650.0,
  };

  @override
  void initState() {
    super.initState();
    if (widget.state.passengers.isNotEmpty) {
      _selectedPassenger = widget.state.passengers.first;
    }
  }

  @override
  void dispose() {
    _customPassengerCtrl.dispose();
    _flightCtrl.dispose();
    _pickupLocCtrl.dispose();
    _destinationCtrl.dispose();
    _poNumberCtrl.dispose();
    _costCenterCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _calculateTotalFare() {
    final base = _vehicleBaseRates[_selectedVehicle] ?? 1350.0;
    final escort = _escortSurcharges[_selectedEscort] ?? 0.0;
    return base + escort;
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent,
            surface: Color(0xFF151E32),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _scheduledTime,
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              surface: Color(0xFF151E32),
            ),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDate = pickedDate;
          _scheduledTime = pickedTime;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final leadPax = _selectedPassenger != null
          ? _selectedPassenger!.fullName
          : _customPassengerCtrl.text.trim();

      final scheduledDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      widget.onSubmitTransfer(
        leadPassenger: leadPax,
        passengerCount: _passengerCount,
        flightNumber: _flightCtrl.text.trim(),
        airportName: _selectedAirport,
        pickupLocation: _pickupLocCtrl.text.trim(),
        destination: _destinationCtrl.text.trim(),
        scheduledPickup: scheduledDateTime,
        vehicleType: _selectedVehicle,
        escortLevel: _selectedEscort,
        poNumber: _poNumberCtrl.text.trim(),
        costCenter: _costCenterCtrl.text.trim(),
        farePgk: _calculateTotalFare(),
        notes: _notesCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalFare = _calculateTotalFare();
    final subtotal = totalFare / 1.10;
    final gst = totalFare - subtotal;
    final scheduledFormatted = DateFormat('dd MMM yyyy').format(_scheduledDate);
    final timeFormatted = _scheduledTime.format(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOOK CORPORATE TRANSFER & CONVOY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Direct flight meet-and-greet, B6 armored vehicle dispatch, and RPNGC armed escort.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Cancel'),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Form Inputs Column
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Executive Traveler
                      _buildSectionCard(
                        title: '1. EXECUTIVE TRAVELER & FLIGHT PROFILE',
                        icon: Icons.person_outline,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Authorized Corporate Traveler *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<CorporatePassenger?>(
                                      value: _selectedPassenger,
                                      dropdownColor: const Color(0xFF151E32),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _inputDecoration(),
                                      items: [
                                        ...widget.state.passengers.map(
                                          (pax) => DropdownMenuItem(
                                            value: pax,
                                            child: Text('${pax.fullName} — ${pax.department} (${pax.title})'),
                                          ),
                                        ),
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text('➕ Enter Custom / Unregistered Traveler'),
                                        ),
                                      ],
                                      onChanged: (pax) => setState(() => _selectedPassenger = pax),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Passenger Count *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<int>(
                                      value: _passengerCount,
                                      dropdownColor: const Color(0xFF151E32),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _inputDecoration(),
                                      items: List.generate(8, (i) => i + 1)
                                          .map((c) => DropdownMenuItem(value: c, child: Text('$c Passenger(s)')))
                                          .toList(),
                                      onChanged: (c) => setState(() => _passengerCount = c ?? 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_selectedPassenger == null) ...[
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _customPassengerCtrl,
                              label: 'Custom Traveler Full Name *',
                              hint: 'e.g., Jonathan Kaupa (VP Operations)',
                              validator: (v) => _selectedPassenger == null && (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _flightCtrl,
                                  label: 'Flight Number & Airline *',
                                  hint: 'e.g., PX102 (Air Niugini)',
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Airport Facility *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _selectedAirport,
                                      dropdownColor: const Color(0xFF151E32),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _inputDecoration(),
                                      items: _airports
                                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                                          .toList(),
                                      onChanged: (a) => setState(() => _selectedAirport = a ?? _selectedAirport),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _pickupLocCtrl,
                                  label: 'Pickup Gate / Terminal *',
                                  hint: 'e.g., Nadzab Arrival Terminal 1',
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _destinationCtrl,
                                  label: 'Destination Address / Hotel *',
                                  hint: 'e.g., Lae International Hotel, Morobe',
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _pickDateTime,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1524),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 20),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Scheduled Pickup Date & Time', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$scheduledFormatted at $timeFormatted',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Text('CHANGE', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Vehicle & Tactical Escort
                      _buildSectionCard(
                        title: '2. ARMORED VEHICLE & TACTICAL PROTOCOL',
                        icon: Icons.shield_outlined,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Vehicle Platform *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedVehicle,
                                dropdownColor: const Color(0xFF151E32),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: _inputDecoration(),
                                items: _vehicleBaseRates.keys
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text('$v (${_vehicleBaseRates[v]!.toStringAsFixed(0)} PGK Base)'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedVehicle = v ?? _selectedVehicle),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Security Escort Protocol *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedEscort,
                                dropdownColor: const Color(0xFF151E32),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: _inputDecoration(),
                                items: _escortSurcharges.keys
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text('$e (+${_escortSurcharges[e]!.toStringAsFixed(0)} PGK)'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (e) => setState(() => _selectedEscort = e ?? _selectedEscort),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 3: PO & Cost Center
                      _buildSectionCard(
                        title: '3. PROCUREMENT & PO ALLOCATION',
                        icon: Icons.receipt_long_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _poNumberCtrl,
                                  label: 'Purchase Order (PO) Number *',
                                  hint: 'e.g., PO-2026-MMR-8899',
                                  validator: (v) => v == null || v.isEmpty ? 'PO Number is mandatory' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _costCenterCtrl,
                                  label: 'Cost Center / Budget Code *',
                                  hint: 'e.g., CC-MOROBE-OPS',
                                  validator: (v) => v == null || v.isEmpty ? 'Cost Center is mandatory' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _notesCtrl,
                            label: 'Special Mission & Duty of Care Instructions',
                            hint: 'Additional flight tracking, tarmac meet, or armed officer specifications...',
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Live Fare & Tariff Summary Sidebar
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151E32),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined, color: Colors.tealAccent, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'CONTRACT TARIFF QUOTATION',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 16),

                        _buildQuoteRow('Selected Airport', _selectedAirport),
                        const SizedBox(height: 10),
                        _buildQuoteRow('Vehicle Platform', _selectedVehicle.split('(').first),
                        const SizedBox(height: 10),
                        _buildQuoteRow('Tactical Escort', _selectedEscort),
                        const SizedBox(height: 10),
                        _buildQuoteRow('Lead Traveler', _selectedPassenger?.fullName ?? _customPassengerCtrl.text.ifEmpty('Unspecified')),
                        const SizedBox(height: 10),
                        _buildQuoteRow('PO Allocation', _poNumberCtrl.text),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 16),

                        _buildQuoteRow('Subtotal (excl. GST)', '${subtotal.toStringAsFixed(2)} PGK'),
                        const SizedBox(height: 8),
                        _buildQuoteRow('PNG GST (10%)', '${gst.toStringAsFixed(2)} PGK'),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL PGK',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${totalFare.toStringAsFixed(2)} PGK',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          '• Tariff locked under Tier 1 Corporate Framework Agreement.\n• Includes 60 min flight delay standby at Nadzab/Jackson\'s.\n• Monitored live by Port Moresby / Lae Dispatch HQ.',
                          style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              'CONFIRM & DISPATCH TRANSFER',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuoteRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
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
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration().copyWith(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

