import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Keys for SharedPreferences
  static const String _familyKey = 'family';
  static const String _tasksKey = 'tasks';
  static const String _shoppingListKey = 'shoppingList';
  static const String _currentUserKey = 'current_user';
  static const String _lastUserIdKey = 'lastUserId';

  // Save family data
  Future<void> saveFamily(Family family) async {
    await _prefs.setString(_familyKey, jsonEncode(family.toJson()));
  }

  // Load family data
  Future<Family?> loadFamily() async {
    final familyJson = _prefs.getString(_familyKey);
    if (familyJson != null) {
      return Family.fromJson(jsonDecode(familyJson));
    }
    return null;
  }

  // Save tasks
  Future<void> saveTasks(List<TaskModel> tasks) async {
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    await _prefs.setString(_tasksKey, jsonEncode(tasksJson));
  }

  // Load tasks
  Future<List<TaskModel>> loadTasks() async {
    final tasksJson = _prefs.getString(_tasksKey);
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      return decoded.map((task) => TaskModel.fromJson(task)).toList();
    }
    return [];
  }

  // Save shopping list
  Future<void> saveShoppingList(List<ShoppingItem> items) async {
    final itemsJson = items.map((item) => item.toJson()).toList();
    await _prefs.setString(_shoppingListKey, jsonEncode(itemsJson));
  }

  // Load shopping list
  Future<List<ShoppingItem>> loadShoppingList() async {
    final itemsJson = _prefs.getString(_shoppingListKey);
    if (itemsJson != null) {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      return decoded.map((item) => ShoppingItem.fromJson(item)).toList();
    }
    return [];
  }

  // Save current user ID
  Future<void> saveCurrentUser(String userId) async {
    await _prefs.setString(_currentUserKey, userId);
  }

  // Load current user ID
  Future<String?> loadCurrentUser() async {
    return _prefs.getString(_currentUserKey);
  }

  // Save last user ID
  Future<void> saveLastUserId(String userId) async {
    await _prefs.setString(_lastUserIdKey, userId);
  }

  // Load last user ID
  Future<String?> getLastUserId() async {
    return _prefs.getString(_lastUserIdKey);
  }

  // Initialize app with sample data if needed
  Future<void> initializeWithSampleDataIfNeeded() async {
    final family = await loadFamily();
    if (family == null) {
      // Create sample family
      final sampleFamily = Family(
        name: 'Smith Family',
        members: [
          FamilyMember(
            name: 'John Smith',
            role: FamilyRole.parent,
          ),
          FamilyMember(
            name: 'Jane Smith',
            role: FamilyRole.parent,
          ),
          FamilyMember(
            name: 'Tommy Smith',
            role: FamilyRole.child,
          ),
          FamilyMember(
            name: 'Sarah Smith',
            role: FamilyRole.child,
          ),
        ],
      );
      await saveFamily(sampleFamily);

      // Set default current user to first parent
      await saveCurrentUser(sampleFamily.members[0].id);

      // Create sample tasks
      final now = DateTime.now();
      final sampleTasks = [
        TaskModel(
          id: const Uuid().v4(),
          title: 'Take out the trash',
          description: 'Don\'t forget to separate recyclables',
          assignedTo: sampleFamily.members[2].id, // Assigned to Tommy
          createdBy: sampleFamily.members[0].id, // Created by John
          dueDate: now.add(const Duration(days: 1)),
        ),
        TaskModel(
          id: const Uuid().v4(),
          title: 'Do homework',
          description: 'Math and Science assignments',
          assignedTo: sampleFamily.members[2].id, // Assigned to Tommy
          createdBy: sampleFamily.members[1].id, // Created by Jane
          dueDate: now.add(const Duration(days: 2)),
        ),
        TaskModel(
          id: const Uuid().v4(),
          title: 'Clean bedroom',
          description: 'Make bed and put toys away',
          assignedTo: sampleFamily.members[3].id, // Assigned to Sarah
          createdBy: sampleFamily.members[1].id, // Created by Jane
          dueDate: now.add(const Duration(days: 1)),
        ),
        TaskModel(
          id: const Uuid().v4(),
          title: 'Pay electricity bill',
          description: 'Due by end of month',
          assignedTo: sampleFamily.members[0].id, // Assigned to John
          createdBy: sampleFamily.members[0].id, // Created by John
          dueDate: now.add(const Duration(days: 5)),
        ),
      ];
      await saveTasks(sampleTasks);

      // Create sample shopping list
      final sampleShoppingList = [
        ShoppingItem(
          id: const Uuid().v4(),
          name: 'Milk',
          quantity: 1,
          addedBy: sampleFamily.members[0].id, // Added by John
        ),
        ShoppingItem(
          id: const Uuid().v4(),
          name: 'Eggs',
          quantity: 1,
          addedBy: sampleFamily.members[1].id, // Added by Jane
        ),
        ShoppingItem(
          id: const Uuid().v4(),
          name: 'Bread',
          quantity: 2,
          addedBy: sampleFamily.members[1].id, // Added by Jane
        ),
        ShoppingItem(
          id: const Uuid().v4(),
          name: 'Cereal',
          quantity: 1,
          addedBy: sampleFamily.members[2].id, // Added by Tommy
        ),
      ];
      await saveShoppingList(sampleShoppingList);
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}