import 'package:flutter/foundation.dart';
import 'package:nanoid/nanoid.dart';

class Member {
  final String id;
  final String name;
  final String mobile;
  final List<String> rsalIds; // Foreign key referencing the group ID

  Member({
    required this.name,
    required this.mobile,
    this.rsalIds = const [],
  }) : id = nanoid();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'rsalIds': rsalIds,
      };

  Map<String, Object?> toMapWithoutRsalIds() => {
        'id': id,
        'name': name,
        'mobile': mobile,
      };

  Member.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        name = map['name'] as String,
        mobile = map['mobile'] as String,
        rsalIds = (map['rsalIds'] ?? List<String>.empty()) as List<String>;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          id == other.id &&
          name == other.name &&
          mobile == other.mobile &&
          listEquals(rsalIds, other.rsalIds);

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ mobile.hashCode ^ rsalIds.hashCode;

  @override
  String toString() {
    return 'Member(id: $id, name: $name, rsalIds: ${rsalIds.toString()})';
  }
}
