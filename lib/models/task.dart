class Task {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final String priority;
  final String? assigneeFirstName;
  final String? assigneeLastName;

  Task({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.priority,
    this.assigneeFirstName,
    this.assigneeLastName,
  });

  // Convertit priorité anglaise → française
  static String _priorityToFrench(String p) {
    switch (p) {
      case 'High': return 'Élevée';
      case 'Medium': return 'Moyenne';
      case 'Low': return 'Basse';
      default: return p;
    }
  }

  // Convertit priorité française → anglaise
  String _priorityToEnglish(String p) {
    switch (p) {
      case 'Élevée': return 'High';
      case 'Moyenne': return 'Medium';
      case 'Basse': return 'Low';
      default: return p;
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: DateTime.tryParse(
            json['dueDate'] ?? json['updatedAt'] ?? ''
          ) ?? DateTime.now(),
      priority: _priorityToFrench(json['priority'] ?? 'Medium'),
      assigneeFirstName: json['assigneeFirstName'],
      assigneeLastName: json['assigneeLastName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'priority': _priorityToEnglish(priority),
      'color': '#0000FF',
      'dueDate': date.toIso8601String(),
    };
  }
}