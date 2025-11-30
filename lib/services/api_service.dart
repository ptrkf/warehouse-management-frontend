import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080';
  
  // Logowanie
  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/authenticate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token']; 
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Rejestracja
  static Future<String?> register(String firstName, String lastName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firstname': firstName,
          'lastname': lastName,
          'email': email,
          'password': password,
        }),
      );
      
      switch (response.statusCode) {
        case 200:
        case 201:
          final data = jsonDecode(response.body);
          return data['token'];
        
        case 400:
          if (response.body.contains('już istnieje') || 
              response.body.contains('already exists')) {
            return 'EMAIL_EXISTS';
          }
          return 'BAD_REQUEST';
        
        case 500:
          return 'SERVER_ERROR';
        
        default:
          return 'UNKNOWN_ERROR';
      }
    } catch (e) {
      return 'NETWORK_ERROR';
    }
  }
}