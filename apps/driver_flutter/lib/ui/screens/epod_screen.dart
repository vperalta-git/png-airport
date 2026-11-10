import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/driver_mission.dart';
import '../../blocs/missions/missions_bloc.dart';
import '../../blocs/missions/missions_event.dart';
import '../widgets/signature_canvas.dart';

class EpodScreen extends StatefulWidget {
  final DriverMission mission;

  const EpodScreen({super.key, required this.mission});

  @override
  State<EpodScreen> createState() => _EpodScreenState();
}

class _EpodScreenState extends State<EpodScreen> {
  late TextEditingController _signerController;
  late TextEditingController _notesController;
  int _rating = 5;
  bool _hasSignature = false;
  bool _notifyControlRoom = true;
  bool _notifyClientEmail = true;
  bool _notifyWhatsapp = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _signerController = TextEditingController(text: widget.mission.passengerName);
    _notesController = TextEditingController(
      text: 'Safe arrival at ${widget.mission.dropoff}. Luggage intact and passenger cleared.',
    );
  }

  @override
  void dispose() {
    _signerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitEpod() async {
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AviationColors.statusIncident,
          content: Text('Please sign on the touch canvas or tap QUICK SIGN.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final receiptId = 'EPOD-PNG-2026-${widget.mission.id.replaceAll('TRF-', '')}';
    final epod = EpodData(
      receiptId: receiptId,
      signerName: _signerController.text,
      signedAt: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} Today',
      rating: _rating,
      notes: _notesController.text,
      notifiedControlRoom: _notifyControlRoom,
      notifiedClientEmail: _notifyClientEmail,
      notifiedWhatsapp: _notifyWhatsapp,
    );

    if (mounted) {
      context.read<MissionsBloc>().add(
            CompleteMissionWithEpod(
              missionId: widget.mission.id,
              epod: epod,
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELECTRONIC PROOF OF DELIVERY (e-POD)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AviationColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AviationColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: AviationColors.gold500, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission ${widget.mission.id} • ${widget.mission.bookingRef}',
                        style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Drop-off: ${widget.mission.dropoff}',
                        style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Signer Name
          const Text('SIGNATORY FULL NAME', style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: _signerController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person, color: AviationColors.gold500, size: 20),
            ),
          ),
          const SizedBox(height: 18),

          // Touch Signature Canvas
          const Text('PASSENGER DIGITAL SIGNATURE (TOUCH ON GLASS)', style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SignatureCanvas(
            onSignatureChanged: (hasSig) {
              setState(() => _hasSignature = hasSig);
            },
          ),
          const SizedBox(height: 18),

          // 5-Star Rating
          const Text('PASSENGER SERVICE EXPERIENCE RATING', style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              return IconButton(
                iconSize: 32,
                icon: Icon(
                  starNum <= _rating ? Icons.star : Icons.star_border,
                  color: starNum <= _rating ? AviationColors.gold500 : AviationColors.textMuted,
                ),
                onPressed: () => setState(() => _rating = starNum),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Notes
          const Text('DELIVERY & SAFE DROP-OFF NOTES', style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(isDense: true),
          ),
          const SizedBox(height: 18),

          // Broadcast notifications toggles
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AviationColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AviationColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRANSMISSION CHANNELS', style: TextStyle(color: AviationColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800)),
                CheckboxListTile(
                  dense: true,
                  activeColor: AviationColors.gold500,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Live Broadcast to Control Room & ERP Invoice Queue', style: TextStyle(color: AviationColors.textPrimary, fontSize: 12)),
                  value: _notifyControlRoom,
                  onChanged: (val) => setState(() => _notifyControlRoom = val ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  activeColor: AviationColors.gold500,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Transmit e-Receipt to ${widget.mission.passengerEmail}', style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12)),
                  value: _notifyClientEmail,
                  onChanged: (val) => setState(() => _notifyClientEmail = val ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  activeColor: AviationColors.gold500,
                  contentPadding: EdgeInsets.zero,
                  title: Text('SMS / WhatsApp Delivery Ping (${widget.mission.passengerPhone})', style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12)),
                  value: _notifyWhatsapp,
                  onChanged: (val) => setState(() => _notifyWhatsapp = val ?? true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AviationColors.statusCompleted,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isSubmitting ? null : _submitEpod,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SEAL & TRANSMIT ELECTRONIC PROOF OF DELIVERY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
