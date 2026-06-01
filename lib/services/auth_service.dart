import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://10.0.2.2:3000/auths";

  // Connexion
  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data["access_token"] ?? data["token"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("auth_token", token);
    } else {
      throw Exception("Échec de la connexion");
    }
  }

  // Inscription
  Future<void> register(
      String name, String email, String password, String phone) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": name,
        "prenom": name,
        "email": email,
        "password": password,
        "username": email,
        "phone": phone,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Échec de l'inscription");
    }
  }

  // Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Récupérer le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // Vérifier si connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Récupérer le profil utilisateur
  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/profiles"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Impossible de récupérer le profil");
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse("$baseUrl/profiles"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Échec de la mise à jour du profil");
    }
  }
}
