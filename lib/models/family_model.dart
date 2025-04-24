import 'package:uuid/uuid.dart';

enum FamilyRole { parent, child }

class FamilyMember {
  final String id;
  String name;
  FamilyRole role;
  String? profilePicture;

  FamilyMember({
    String? id,
    required this.name,
    required this.role,
    this.profilePicture,
  }) : id = id ?? const Uuid().v4();

  // Convert FamilyMember to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.toString().split('.').last,
      'profilePicture': profilePicture,
    };
  }

  // Create FamilyMember from Map
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      role: map['role'] == 'parent' ? FamilyRole.parent : FamilyRole.child,
      profilePicture: map['profilePicture'],
    );
  }

  // Check if this family member is a parent
  bool get isParent => role == FamilyRole.parent;

  // Create a copy of this family member with updated fields
  FamilyMember copyWith({
    String? name,
    FamilyRole? role,
    String? profilePicture,
  }) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}

class Family {
  final String id;
  String name;
  List<FamilyMember> members;

  Family({
    String? id,
    required this.name,
    this.members = const [],
  }) : id = id ?? const Uuid().v4();

  // Convert Family to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members.map((member) => member.toMap()).toList(),
    };
  }

  // Create Family from Map
  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      id: map['id'],
      name: map['name'],
      members: (map['members'] as List)
          .map((memberMap) => FamilyMember.fromMap(memberMap))
          .toList(),
    );
  }

  // Convert Family to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create Family from JSON
  factory Family.fromJson(Map<String, dynamic> json) => Family.fromMap(json);

  // Add a new family member
  void addMember(FamilyMember member) {
    members.add(member);
  }

  // Remove a family member by ID
  void removeMember(String memberId) {
    members.removeWhere((member) => member.id == memberId);
  }

  // Get parent members
  List<FamilyMember> get parents {
    return members.where((member) => member.role == FamilyRole.parent).toList();
  }

  // Get child members
  List<FamilyMember> get children {
    return members.where((member) => member.role == FamilyRole.child).toList();
  }

  // Get a family member by ID
  FamilyMember? getMember(String id) {
    try {
      return members.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }
}