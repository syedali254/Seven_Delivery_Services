class LogModel {
  final String id;
  final String action;
  final DateTime timestamp;

  LogModel({
    required this.id,
    required this.action,
    required this.timestamp,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'].toString(),
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
