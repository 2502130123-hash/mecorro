/// Un renglón del cronograma: qué cambió y cuándo.
class ProfileChange {
  const ProfileChange({
    required this.date,
    required this.field,
    required this.oldValue,
    required this.newValue,
  });

  final DateTime date;
  final String field;
  final String oldValue;
  final String newValue;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'field': field,
    'oldValue': oldValue,
    'newValue': newValue,
  };

  factory ProfileChange.fromJson(Map<String, dynamic> json) => ProfileChange(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    field: json['field'] as String? ?? '',
    oldValue: json['oldValue'] as String? ?? '',
    newValue: json['newValue'] as String? ?? '',
  );
}