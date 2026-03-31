class NotificationSchedule {
  final int? id;
  final String time; // "HH:mm" format (ej: "08:00", "14:30")
  final String label; // "Mañana", "Tarde", etc.
  final List<int> days; // [0,1,2,3,4,5,6] - 0=Domingo, 6=Sábado
  final bool enabled;

  NotificationSchedule({
    this.id,
    required this.time,
    required this.label,
    required this.days,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'label': label,
      'days': days.join(','), // "0,1,2,3,4,5,6"
      'enabled': enabled ? 1 : 0,
    };
  }

  factory NotificationSchedule.fromMap(Map<String, dynamic> map) {
    return NotificationSchedule(
      id: map['id'],
      time: map['time'],
      label: map['label'],
      days:
          (map['days'] as String).split(',').map((e) => int.parse(e)).toList(),
      enabled: map['enabled'] == 1,
    );
  }

  NotificationSchedule copyWith({
    int? id,
    String? time,
    String? label,
    List<int>? days,
    bool? enabled,
  }) {
    return NotificationSchedule(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
    );
  }
}
