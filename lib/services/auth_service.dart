import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "https://task-manager-api-fx61.onrender.com/auths";

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

      if (data["user"] != null) {
        final user = data["user"];
        final name = "${user['prenom'] ?? ''} ${user['nom'] ?? ''}".trim();
        await prefs.setString("user_name", name.isNotEmpty ? name : email);
        await prefs.setString("user_email", email);
      } else {
        await prefs.setString("user_name", email);
        await prefs.setString("user_email", email);
      }
    } else {
      throw Exception("Échec de la connexion : ${response.statusCode}");
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
      throw Exception("Échec de l'inscription : ${response.statusCode}");
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
      Uri.parse("$baseUrl/profils"),
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
      Uri.parse("$baseUrl/profils"),
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

  // Envoyer le code de réinitialisation par email
  Future<void> sendResetCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send-reset-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Email introuvable : ${response.statusCode} - ${response.body}",
      );
    }
  }

  // Réinitialiser le mot de passe avec le code
  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
        "newPassword": newPassword,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Erreur : ${response.statusCode} - ${response.body}",
      );
    }
  }
}