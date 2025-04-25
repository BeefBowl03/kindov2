import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> init() async {
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  // Keys for SharedPreferences
  static const String _familyKey = 'family';
  static const String _tasksKey = 'tasks';
  static const String _shoppingListKey = 'shoppingList';
  static const String _currentUserKey = 'current_user';
  static const String _lastUserIdKey = 'lastUserId';

  // String operations
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

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
    final jsonList = items.map((item) => item.toJson()).toList();
    await _prefs.setString(_shoppingListKey, jsonEncode(jsonList));
  }

  // Load shopping list
  List<ShoppingItem> getShoppingList() {
    final jsonString = _prefs.getString(_shoppingListKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ShoppingItem.fromJson(json)).toList();
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
        createdBy: const Uuid().v4(), // Generate a temporary ID for the creator
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
          title: 'Take out the trash',
          description: 'Don\'t forget to separate recyclables',
          assignedTo: sampleFamily.members[2].id, // Assigned to Tommy
          createdBy: sampleFamily.members[0].id, // Created by John
          dueDate: now.add(const Duration(days: 1)),
          familyId: sampleFamily.id,
        ),
        TaskModel(
          title: 'Do homework',
          description: 'Math and Science assignments',
          assignedTo: sampleFamily.members[2].id, // Assigned to Tommy
          createdBy: sampleFamily.members[1].id, // Created by Jane
          dueDate: now.add(const Duration(days: 2)),
          familyId: sampleFamily.id,
        ),
        TaskModel(
          title: 'Clean bedroom',
          description: 'Make bed and put toys away',
          assignedTo: sampleFamily.members[3].id, // Assigned to Sarah
          createdBy: sampleFamily.members[1].id, // Created by Jane
          dueDate: now.add(const Duration(days: 1)),
          familyId: sampleFamily.id,
        ),
        TaskModel(
          title: 'Pay electricity bill',
          description: 'Due by end of month',
          assignedTo: sampleFamily.members[0].id, // Assigned to John
          createdBy: sampleFamily.members[0].id, // Created by John
          dueDate: now.add(const Duration(days: 5)),
          familyId: sampleFamily.id,
        ),
      ];
      await saveTasks(sampleTasks);

      // Create sample shopping list
      final sampleShoppingList = [
        ShoppingItem(
          title: 'Milk',
          quantity: 1,
          addedBy: sampleFamily.members[0].id, // Added by John
        ),
        ShoppingItem(
          title: 'Eggs',
          quantity: 1,
          addedBy: sampleFamily.members[1].id, // Added by Jane
        ),
        ShoppingItem(
          title: 'Bread',
          quantity: 2,
          addedBy: sampleFamily.members[1].id, // Added by Jane
        ),
        ShoppingItem(
          title: 'Cereal',
          quantity: 1,
          addedBy: sampleFamily.members[2].id, // Added by Tommy
        ),
      ];
      await saveShoppingList(sampleShoppingList);
    }
  }

  // Clear all data
  Future<void> clear() async {
    await _prefs.clear();
  }
}