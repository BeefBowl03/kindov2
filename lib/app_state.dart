import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import '../services/storage_service.dart';

class AppState with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  // App data
  Family? _family;
  List<TaskModel> _tasks = [];
  List<ShoppingItem> _shoppingList = [];
  String? _currentUserId;
  bool _isLoading = true;

  // Getters
  Family? get family => _family;
  List<TaskModel> get tasks => _tasks;
  List<ShoppingItem> get shoppingList => _shoppingList;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;

  // Get current user
  FamilyMember? get currentUser {
    if (_currentUserId == null || _family == null) return null;
    return _family!.getMember(_currentUserId!);
  }

  // Check if current user is a parent
  bool get isParent => currentUser?.isParent ?? false;

  // Get tasks assigned to current user
  List<TaskModel> get myTasks {
    if (_currentUserId == null) return [];
    return _tasks.where((task) => task.assignedTo == _currentUserId).toList();
  }

  // Get tasks created by current user
  List<TaskModel> get createdTasks {
    if (_currentUserId == null) return [];
    return _tasks.where((task) => task.createdBy == _currentUserId).toList();
  }

  // Get completed tasks for current user
  List<TaskModel> get completedTasks {
    return myTasks.where((task) => task.isComplete).toList();
  }

  // Get pending tasks for current user
  List<TaskModel> get pendingTasks {
    return myTasks.where((task) => !task.isComplete).toList();
  }

  // Initialize the app state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Initialize with sample data if needed
    await _storageService.initializeWithSampleDataIfNeeded();

    // Load all data
    _family = await _storageService.loadFamily();
    _tasks = await _storageService.loadTasks();
    _shoppingList = await _storageService.loadShoppingList();
    _currentUserId = await _storageService.loadCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  // Set current user
  Future<void> setCurrentUser(String userId) async {
    _currentUserId = userId;
    await _storageService.saveCurrentUser(userId);
    notifyListeners();
  }

  // Add a task
  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  // Update a task
  Future<void> updateTask(TaskModel updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _storageService.saveTasks(_tasks);
      notifyListeners();
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  // Toggle task completion status
  Future<void> toggleTaskComplete(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(isComplete: !task.isComplete);
      await _storageService.saveTasks(_tasks);
      notifyListeners();
    }
  }

  // Add a shopping item
  Future<void> addShoppingItem(ShoppingItem item) async {
    _shoppingList.add(item);
    await _storageService.saveShoppingList(_shoppingList);
    notifyListeners();
  }

  // Update a shopping item
  Future<void> updateShoppingItem(ShoppingItem updatedItem) async {
    final index = _shoppingList.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _shoppingList[index] = updatedItem;
      await _storageService.saveShoppingList(_shoppingList);
      notifyListeners();
    }
  }

  // Delete a shopping item
  Future<void> deleteShoppingItem(String itemId) async {
    _shoppingList.removeWhere((item) => item.id == itemId);
    await _storageService.saveShoppingList(_shoppingList);
    notifyListeners();
  }

  // Toggle shopping item completion status
  Future<void> toggleShoppingItemComplete(String itemId) async {
    final index = _shoppingList.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _shoppingList[index];
      _shoppingList[index] = item.copyWith(isCompleted: !item.isCompleted);
      await _storageService.saveShoppingList(_shoppingList);
      notifyListeners();
    }
  }

  // Add a family member (only for parents)
  Future<void> addFamilyMember(FamilyMember member) async {
    if (_family != null && isParent) {
      _family!.addMember(member);
      await _storageService.saveFamily(_family!);
      notifyListeners();
    }
  }

  // Remove a family member (only for parents)
  Future<void> removeFamilyMember(String memberId) async {
    if (_family != null && isParent) {
      _family!.removeMember(memberId);
      await _storageService.saveFamily(_family!);
      notifyListeners();
    }
  }

  // Update a family member
  Future<void> updateFamilyMember(FamilyMember updatedMember) async {
    if (_family != null && isParent) {
      final index = _family!.members.indexWhere((member) => member.id == updatedMember.id);
      if (index != -1) {
        _family!.members[index] = updatedMember;
        await _storageService.saveFamily(_family!);
        notifyListeners();
      }
    }
  }
}