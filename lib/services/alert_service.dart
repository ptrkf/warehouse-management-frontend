import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class Alert {
  final int id;
  final String type;
  final String message;
  final DateTime timestamp;
  final bool read;

  Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      type: json['type'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      read: json['read'],
    );
  }
}

class AlertService {
  static const String baseUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080';
  
  // Pobierz wszystkie alerty
 static Future<List<Alert>> getAlerts() async {
  try {
    final token = await TokenService.getToken();
    print('🔑 Token for alerts: $token'); // Debug - pokaż cały token
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/alerts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    print('📡 Alerts response status: ${response.statusCode}');
    print('📝 Alerts response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Alert.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    print('❌ Alerts error: $e');
    return [];
  }
}
  
  // Wygeneruj nowe alerty
  static Future<bool> generateAlerts() async {
    try {
      final token = await TokenService.getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/alerts/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // POPRAWKA: dodano "Bearer "
        },
      );
      
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (e) {
      return false;
    }
  }
  
  // Oznacz alert jako przeczytany
  static Future<bool> markAsRead(int alertId) async {
    try {
      final token = await TokenService.getToken();
      
      final response = await http.patch(
        Uri.parse('$baseUrl/api/alerts/$alertId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}