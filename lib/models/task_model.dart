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
  final String familyId;
  final bool isRecurring;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly'
  final DateTime? recurrenceEndDate;
  final String? category; // 'chores', 'homework', 'personal', 'other'

  TaskModel({
    String? id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.createdBy,
    this.dueDate,
    this.isCompleted = false,
    this.points = 0,
    required this.familyId,
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceEndDate,
    this.category,
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
      'family_id': familyId,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'category': category,
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
      familyId: json['family_id'],
      isRecurring: json['is_recurring'] ?? false,
      recurrencePattern: json['recurrence_pattern'],
      recurrenceEndDate: json['recurrence_end_date'] != null ? DateTime.parse(json['recurrence_end_date']) : null,
      category: json['category'],
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
    String? familyId,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? recurrenceEndDate,
    String? category,
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
      familyId: familyId ?? this.familyId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      category: category ?? this.category,
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