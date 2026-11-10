import 'package:flutter/material.dart';
import '../../models/cloud_service_status.dart';

class CloudServiceTile extends StatelessWidget {
  final CloudServiceModel model;
  final VoidCallback onSync;

  const CloudServiceTile({
    super.key,
    required this.model,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _buildHealthIndicator(model.health),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${model.serviceName} • ${model.recordCount} live records',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            tooltip: 'Verify Service Health',
            onPressed: onSync,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(CloudServiceHealth health) {
    Color color;
    switch (health) {
      case CloudServiceHealth.optimal:
        color = Colors.greenAccent;
        break;
      case CloudServiceHealth.syncing:
        color = Colors.cyanAccent;
        break;
      case CloudServiceHealth.warning:
        color = Colors.amberAccent;
        break;
      case CloudServiceHealth.error:
        color = Colors.redAccent;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 2,
          )
        ],
      ),
    );
  }
}

