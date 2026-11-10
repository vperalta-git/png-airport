import 'dart:convert';
import 'package:http/http.dart' as http;

class FlightRadarService {
  final String liveServerUrl;

  FlightRadarService({this.liveServerUrl = 'http://127.0.0.1:5050'});

  Future<Map<String, dynamic>> fetchLiveRadarData() async {
    try {
      final res = await http
          .get(Uri.parse('$liveServerUrl/api/nadzab/flights/live'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback to embedded snapshot
    }
    return _getFallbackSnapshot();
  }

  Map<String, dynamic> _getFallbackSnapshot() {
    return {
      'airport': {
        'name': "Nadzab Tomodachi International Airport",
        'iata': 'LAE',
        'icao': 'AYNZ',
        'city': 'Lae, Morobe Province',
        'metar': {
          'temperature': '28°C',
          'condition': 'Overcast / Light Mist',
          'wind': '090° @ 12 kt',
          'qnh': '1014 hPa',
          'category': 'VFR',
          'metar': 'AYNZ 081200Z 09012KT 9999 BKN020 28/23 Q1014',
        }
      },
      'arrivals': [
        {
          'id': 'arr-px102',
          'code': 'PX102',
          'carrier': 'Air Niugini',
          'type': 'arrival',
          'originCode': 'POM',
          'originCity': 'Port Moresby',
          'destCode': 'LAE',
          'destCity': 'Lae (Nadzab)',
          'scheduledTime': '14:30',
          'estimatedTime': '14:45',
          'flightDate': 'Today',
          'status': 'Delayed (+15m)',
          'aircraft': 'Boeing 737-800 (P2-PXC)',
          'gate': 'Gate 02',
          'carousel': 'Belt 1',
          'delayMinutes': 15,
        },
        {
          'id': 'arr-cg852',
          'code': 'CG852',
          'carrier': 'PNG Air',
          'type': 'arrival',
          'originCode': 'HGU',
          'originCity': 'Mount Hagen',
          'destCode': 'LAE',
          'destCity': 'Lae (Nadzab)',
          'scheduledTime': '16:15',
          'estimatedTime': '16:15',
          'flightDate': 'Today',
          'status': 'On Time',
          'aircraft': 'ATR 72-600 (P2-ATR)',
          'gate': 'Gate 01',
          'carousel': 'Belt 2',
          'delayMinutes': 0,
        },
        {
          'id': 'arr-px104',
          'code': 'PX104',
          'carrier': 'Air Niugini',
          'type': 'arrival',
          'originCode': 'POM',
          'originCity': 'Port Moresby',
          'destCode': 'LAE',
          'destCity': 'Lae (Nadzab)',
          'scheduledTime': '18:40',
          'estimatedTime': '18:40',
          'flightDate': 'Today',
          'status': 'Scheduled',
          'aircraft': 'Fokker 100',
          'gate': 'Gate 03',
          'carousel': 'Belt 1',
          'delayMinutes': 0,
        },
      ],
      'departures': [
        {
          'id': 'dep-px103',
          'code': 'PX103',
          'carrier': 'Air Niugini',
          'type': 'departure',
          'originCode': 'LAE',
          'originCity': 'Lae (Nadzab)',
          'destCode': 'POM',
          'destCity': 'Port Moresby',
          'scheduledTime': '15:15',
          'estimatedTime': '15:30',
          'flightDate': 'Today',
          'status': 'Boarding',
          'aircraft': 'Boeing 737-800',
          'gate': 'Gate 02',
          'carousel': '-',
          'delayMinutes': 15,
        },
        {
          'id': 'dep-cg853',
          'code': 'CG853',
          'carrier': 'PNG Air',
          'type': 'departure',
          'originCode': 'LAE',
          'originCity': 'Lae (Nadzab)',
          'destCode': 'RAB',
          'destCity': 'Rabaul (Tokua)',
          'scheduledTime': '17:00',
          'estimatedTime': '17:00',
          'flightDate': 'Today',
          'status': 'On Time',
          'aircraft': 'ATR 72-600',
          'gate': 'Gate 01',
          'carousel': '-',
          'delayMinutes': 0,
        },
      ],
    };
  }
}
