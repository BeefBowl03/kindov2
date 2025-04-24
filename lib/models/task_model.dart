import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String createdBy;
  final DateTime dueDate;
  final bool isCompleted;
  final int points;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.createdBy,
    required this.dueDate,
    this.isCompleted = false,
    this.points = 0,
  });

  String get formattedDueDate {
    return DateFormat('MMM dd, yyyy').format(dueDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'points': points,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      assignedTo: json['assignedTo'] as String,
      createdBy: json['createdBy'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
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
  final String name;
  final int quantity;
  final String addedBy;
  final bool isPurchased;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.addedBy,
    this.isPurchased = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'addedBy': addedBy,
      'isPurchased': isPurchased,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      addedBy: json['addedBy'] as String,
      isPurchased: json['isPurchased'] as bool? ?? false,
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? addedBy,
    bool? isPurchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      addedBy: addedBy ?? this.addedBy,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}