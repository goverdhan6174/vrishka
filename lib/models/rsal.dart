import 'package:flutter/foundation.dart';
import 'package:nanoid/nanoid.dart';

class Rsal {
  final String id;
  final String name;
  final String status;
  final int principalAmount;
  final int duration;
  final DateTime createDate;
  final List<String> memberIds;

  Rsal({
    required this.name,
    required this.createDate,
    required this.principalAmount,
    this.duration = 16,
    this.status = "RUNNING",
    this.memberIds = const [],
  }) : id = nanoid();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'principal_amount': principalAmount,
        'duration': duration,
        'created_at': createDate.toIso8601String(),
        "member_ids": memberIds,
        "status": status,
      };

  Map<String, Object?> toMapWithoutMemberIds() => {
        'id': id,
        'name': name,
        'principal_amount': principalAmount,
        'duration': duration,
        'created_at': createDate.toIso8601String(),
        'status': status,
      };

  Rsal.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        name = map['name'] as String,
        duration = map['duration'] as int,
        principalAmount = map['principal_amount'] as int,
        createDate = DateTime.parse(map['created_at'] as String),
        status = (map['status'] ?? "") as String,
        memberIds = (map['memberIds'] ?? List<String>.empty()) as List<String>;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rsal &&
          id == other.id &&
          name == other.name &&
          createDate == other.createDate &&
          listEquals(memberIds, other.memberIds);

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ createDate.hashCode ^ memberIds.hashCode;

  @override
  String toString() =>
      'Rsal(name: $name, members: ${memberIds.length}, status : $status)';
}
