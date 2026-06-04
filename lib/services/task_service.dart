import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskService {
  final String baseUrl = "https://task-manager-api-fx61.onrender.com/task";

  // Récupérer le token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // 📥 Récupérer toutes les tâches
  Future<List<Task>> getTasks() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception("Échec de la récupération des tâches");
    }
  }

  // ➕ Créer une tâche
  Future<Task> createTask(Task task) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(task.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Échec de la création : ${response.statusCode} - ${response.body}",
      );
    }
  }

  // ✏️ Mettre à jour une tâche
  Future<Task> updateTask(Task task) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse("$baseUrl/${task.id}"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(task.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Échec de la mise à jour : ${response.statusCode} - ${response.body}",
      );
    }
  }

  // 🗑️ Supprimer une tâche
  Future<void> deleteTask(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        "Échec de la suppression : ${response.statusCode}",
      );
    }
  }
}