import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../blocs/incident/incident_bloc.dart';
import '../../blocs/incident/incident_event.dart';

class IncidentModal extends StatefulWidget {
  final String missionId;

  const IncidentModal({super.key, required this.missionId});

  @override
  State<IncidentModal> createState() => _IncidentModalState();
}

class _IncidentModalState extends State<IncidentModal> {
  final String _selectedSeverity = 'CRITICAL';
  String _selectedType = 'Security Threat / Highway Block';
  final _notesController = TextEditingController(text: 'Heavy traffic congestion / potential roadblock spotted ahead on Markham Link.');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AviationColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AviationColors.statusIncident, width: 2)),
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
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AviationColors.statusIncident, size: 24),
              SizedBox(width: 8),
              Text(
                'INCIDENT COMMAND / SOS ALARM',
                style: TextStyle(color: AviationColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mission ID: ${widget.missionId} • Instant Control Room Dispatch Broadcast',
            style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Big Red SOS Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.emergency, color: Colors.white, size: 22),
              label: const Text('🚨 ONE-TOUCH DISTRESS SOS PING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AviationColors.statusIncident,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                context.read<IncidentBloc>().add(
                      TriggerSosAlert(
                        missionId: widget.missionId,
                        locationDescription: 'Markham Valley Highway Corridor (GPS pinged)',
                      ),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AviationColors.statusIncident,
                    content: Text('🚨 SOS SIGNAL BROADCAST TO CONTROL ROOM & ARMED RESPONSE UNITS!'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: AviationColors.cardBorder),
          const SizedBox(height: 10),

          // Incident Report Form
          const Text('REPORT OPERATIONAL EVENT', style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            dropdownColor: AviationColors.cardDark,
            decoration: const InputDecoration(isDense: true),
            items: const [
              DropdownMenuItem(value: 'Security Threat / Highway Block', child: Text('Security Threat / Highway Block')),
              DropdownMenuItem(value: 'Highlands Gravel Slide / Washout', child: Text('Highlands Gravel Slide / Washout')),
              DropdownMenuItem(value: 'Vehicle Mechanical Breakdown', child: Text('Vehicle Mechanical Breakdown')),
              DropdownMenuItem(value: 'Weather / Fog Diversion', child: Text('Weather / Fog Diversion')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Field Description / Detour Route',
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AviationColors.gold500),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                context.read<IncidentBloc>().add(
                      ReportFieldIncident(
                        missionId: widget.missionId,
                        severity: _selectedSeverity,
                        issueType: _selectedType,
                        notes: _notesController.text,
                      ),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AviationColors.statusEnRoute,
                    content: Text('Field report queued: $_selectedType'),
                  ),
                );
              },
              child: const Text('SUBMIT OPERATIONAL INCIDENT', style: TextStyle(color: AviationColors.gold500, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
