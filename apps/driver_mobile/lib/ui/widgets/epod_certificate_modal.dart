import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/driver_mission.dart';

class EpodCertificateModal extends StatelessWidget {
  final DriverMission mission;

  const EpodCertificateModal({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final epod = mission.epod;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AviationColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AviationColors.statusCompleted, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AviationColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ELECTRONIC PROOF OF DELIVERY (e-POD)',
                    style: TextStyle(
                      color: AviationColors.statusCompleted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    epod?.receiptId ?? 'EPOD-CERTIFICATE',
                    style: const TextStyle(
                      color: AviationColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AviationColors.statusCompleted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AviationColors.statusCompleted),
                ),
                child: const Text(
                  'DELIVERED',
                  style: TextStyle(
                    color: AviationColors.statusCompleted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AviationColors.cardBorder, height: 26),

          // Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AviationColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AviationColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildRow('Signer Name', epod?.signerName ?? mission.passengerName),
                _buildRow('Timestamp', epod?.signedAt ?? 'Signed on Glass'),
                _buildRow('Mission ID', mission.id),
                _buildRow('Booking Ref', mission.bookingRef),
                _buildRow('Vehicle / Convoy', mission.vehicle),
                _buildRow('Rating', '⭐⭐⭐⭐⭐ (${epod?.rating ?? 5}/5 Stars)'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Delivery Remarks
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AviationColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FIELD DISPATCH NOTES:', style: TextStyle(color: AviationColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  epod?.notes ?? 'Safe arrival at destination. Mission concluded without security breaches.',
                  style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AviationColors.primaryNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS CERTIFICATE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
