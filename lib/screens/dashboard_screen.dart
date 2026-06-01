import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import '../services/task_sync_manager.dart';
import '../services/task_cache.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskService _taskService = TaskService();
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  bool isLoading = true;
  String _userName = 'Vous';
  String _userInitial = 'M';
  String? _photoPath;
  String _selectedFilter = 'Toutes';
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;
  final List<String> _filters = ['Toutes', 'Élevée', 'Moyenne', 'Basse'];

  @override
void initState() {
  super.initState();
  _loadUserInfo(); // ← MANQUAIT !
  _loadTasks();
  final syncManager = TaskSyncManager(TaskService(), TaskCache());
  syncManager.syncPendingTasks();
}

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString("user_name") ?? 'Vous';
      _userInitial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'M';
      _photoPath = prefs.getString("user_photo");
    });
  }

  Future<void> _loadTasks() async {
    try {
      final data = await _taskService.getTasks();
      setState(() {
        tasks = data;
        filteredTasks = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterByPriority(String filter) {
    setState(() {
      _selectedFilter = filter;
      filteredTasks = filter == 'Toutes'
          ? tasks
          : tasks.where((t) => t.priority == filter).toList();
    });
  }

  void _searchTasks(String query) {
    setState(() {
      filteredTasks = tasks
          .where((t) => t.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleNotifications() {
    setState(() => _notificationsEnabled = !_notificationsEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsEnabled
            ? 'Notifications activées 🔔'
            : 'Notifications désactivées 🔕'),
        backgroundColor:
            _notificationsEnabled ? Colors.green : Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'Élevée':
        return Colors.red;
      case 'Moyenne':
        return Colors.orange;
      case 'Basse':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getPriorityIcon(String priority) {
    switch (priority) {
      case 'Élevée':
        return Icons.warning_rounded;
      case 'Moyenne':
        return Icons.access_time;
      case 'Basse':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            );
          },
        ),
        title: const Text(
          'Tableau de bord',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          // Cloche notifications
          IconButton(
            icon: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: _notificationsEnabled
                  ? Colors.amber
                  : Colors.white54,
            ),
            onPressed: _toggleNotifications,
          ),
          // Photo de profil
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) => _loadUserInfo());
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB),
                backgroundImage: _photoPath != null
                    ? FileImage(File(_photoPath!))
                    : null,
                child: _photoPath == null
                    ? Text(
                        _userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header bleu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            color: const Color(0xFF1E3A5F),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.list_alt,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tasks.length} Tâches en attente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_getGreeting()}, $_userName',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: _searchTasks,
              decoration: InputDecoration(
                hintText: 'Rechercher une tâche',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filtres
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return GestureDetector(
                  onTap: () => _filterByPriority(filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Liste des tâches
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune tâche pour le moment.\nAppuyez sur + pour en ajouter !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredTasks.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filteredTasks.length) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: const Text(
                                    '"L\'organisation est la clé de la réussite."',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        'Confidentialité',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF)),
                                      ),
                                    ),
                                    const Text('·',
                                        style: TextStyle(
                                            color: Color(0xFF9CA3AF))),
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        'Support',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          final task = filteredTasks[index];
                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TaskDetailScreen(task: task),
                                ),
                              );
                              if (result == true) _loadTasks();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(6),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        getPriorityColor(task.priority),
                                    child: Icon(
                                      getPriorityIcon(task.priority),
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 14,
                                                  color:
                                                      Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                color: getPriorityColor(
                                                        task.priority)
                                                    .withAlpha(25),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6),
                                                border: Border.all(
                                                  color: getPriorityColor(
                                                      task.priority),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                task.priority
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: getPriorityColor(
                                                      task.priority),
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          task.content,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 12,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Échéance : ${task.date.day}/${task.date.month}/${task.date.year}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF9CA3AF),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () async {
          final newTask = await Navigator.push<Task>(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          if (newTask != null) _loadTasks();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF9CA3AF),
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendrier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}