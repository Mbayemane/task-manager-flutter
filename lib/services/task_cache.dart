import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskCache {
  static const String _key = 'cached_tasks';
  static const String _pendingKey = 'pending_tasks';

  // Sauvegarder toutes les tâches (API → Cache)
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  // Charger toutes les tâches depuis le cache
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((json) => Task.fromJson(jsonDecode(json))).toList();
  }

  // Ajouter une tâche en attente de synchronisation (offline → API)
  Future<void> addPendingTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_pendingKey) ?? [];
    jsonList.add(jsonEncode(task.toJson()));
    await prefs.setStringList(_pendingKey, jsonList);
  }

  // Récupérer toutes les tâches en attente
  Future<List<Task>> getPendingTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_pendingKey) ?? [];
    return jsonList.map((json) => Task.fromJson(jsonDecode(json))).toList();
  }

  // Marquer une tâche comme synchronisée (la retirer des pending)
  Future<void> markAsSynced(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_pendingKey) ?? [];
    final tasks = jsonList.map((json) => Task.fromJson(jsonDecode(json))).toList();

    tasks.removeWhere((task) => task.id == id);

    final updatedJsonList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_pendingKey, updatedJsonList);
  }

  // Vider le cache complet
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_pendingKey);
  }
}
