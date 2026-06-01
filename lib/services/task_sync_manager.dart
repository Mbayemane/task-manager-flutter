import 'package:flutter/material.dart';
import 'task_service.dart';
import 'task_cache.dart';
import '../models/task.dart';

class TaskSyncManager {
  final TaskService _service;
  final TaskCache _cache;

  TaskSyncManager(this._service, this._cache);

  Future<void> syncPendingTasks() async {
    try {
      // 1. Envoyer les tâches en attente vers l’API
      final List<Task> pendingTasks = await _cache.getPendingTasks();
      for (Task task in pendingTasks) {
        final Task created = await _service.createTask(task);
        if (created.id != null) {
          await _cache.markAsSynced(created.id!);
        } else {
          debugPrint("Attention : tâche créée sans id côté API");
        }
      }

      // 2. Recharger depuis l’API et mettre à jour le cache
      final List<Task> tasks = await _service.getTasks();
      await _cache.saveTasks(tasks);
    } catch (e) {
      debugPrint("Erreur de synchronisation : $e");
    }
  }
}
