import 'package:uuid/uuid.dart';

enum FamilyRole { parent, child }

class FamilyMember {
  final String id;
  final String name;
  final String? avatarUrl;
  final FamilyRole role;
  final int points;

  FamilyMember({
    String? id,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.points = 0,
  }) : id = id ?? const Uuid().v4();

  bool get isParent => role == FamilyRole.parent;

  // Convert FamilyMember to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.toString().split('.').last,
      'avatar_url': avatarUrl,
      'points': points,
    };
  }

  // Create FamilyMember from Map
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      role: map['role'] == 'parent' ? FamilyRole.parent : FamilyRole.child,
      avatarUrl: map['avatar_url'],
      points: map['points'] ?? 0,
    );
  }

  // Convert to JSON (alias for toMap)
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON (alias for fromMap)
  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember.fromMap(json);

  // Create a copy with updated fields
  FamilyMember copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    FamilyRole? role,
    int? points,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      points: points ?? this.points,
    );
  }
}

class Family {
  final String id;
  final String name;
  final String createdBy;
  final List<FamilyMember> members;
  final DateTime createdAt;

  Family({
    String? id,
    required this.name,
    required this.createdBy,
    this.members = const [],
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Convert Family to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'members': members.map((member) => member.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Family from Map
  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      id: map['id'],
      name: map['name'],
      createdBy: map['created_by'],
      members: (map['members'] as List)
          .map((memberMap) => FamilyMember.fromMap(memberMap))
          .toList(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Convert to JSON (alias for toMap)
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON (alias for fromMap)
  factory Family.fromJson(Map<String, dynamic> json) => Family.fromMap(json);

  // Get parent members
  List<FamilyMember> get parents {
    return members.where((member) => member.isParent).toList();
  }

  // Get child members
  List<FamilyMember> get children {
    return members.where((member) => !member.isParent).toList();
  }

  // Get a family member by ID
  FamilyMember? getMember(String id) {
    try {
      return members.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }

  // Create a copy with updated fields
  Family copyWith({
    String? id,
    String? name,
    String? createdBy,
    List<FamilyMember>? members,
    DateTime? createdAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}