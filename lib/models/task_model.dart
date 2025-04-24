import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String assignedTo;
  final String createdBy;
  final DateTime? dueDate;
  final bool isCompleted;
  final int points;

  TaskModel({
    String? id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.createdBy,
    this.dueDate,
    this.isCompleted = false,
    this.points = 0,
  }) : id = id ?? const Uuid().v4();

  String get formattedDueDate {
    return DateFormat('MMM dd, yyyy').format(dueDate ?? DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted,
      'points': points,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assigned_to'],
      createdBy: json['created_by'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      isCompleted: json['is_completed'] ?? false,
      points: json['points'] ?? 0,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? createdBy,
    DateTime? dueDate,
    bool? isCompleted,
    int? points,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      points: points ?? this.points,
    );
  }
}

class ShoppingItem {
  final String id;
  final String title;
  final String? description;
  final int quantity;
  final String addedBy;
  final bool isPurchased;

  ShoppingItem({
    String? id,
    required this.title,
    this.description,
    required this.quantity,
    required this.addedBy,
    this.isPurchased = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'quantity': quantity,
      'added_by': addedBy,
      'is_purchased': isPurchased,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      quantity: json['quantity'],
      addedBy: json['added_by'],
      isPurchased: json['is_purchased'] ?? false,
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? title,
    String? description,
    int? quantity,
    String? addedBy,
    bool? isPurchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      addedBy: addedBy ?? this.addedBy,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}