import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;
  Family? _family;
  FamilyMember? _currentUser;
  List<TaskModel> _tasks = [];
  List<ShoppingItem> _shoppingList = [];
  bool _isLoading = true;

  AppState(this._storage) {
    _loadData();
  }

  // Getters
  bool get isLoading => _isLoading;
  Family? get family => _family;
  FamilyMember? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;
  bool get isParent => _currentUser?.isParent ?? false;
  List<TaskModel> get tasks => _tasks;
  List<ShoppingItem> get shoppingList => _shoppingList;

  List<TaskModel> get myTasks {
    return _tasks.where((task) => task.assignedTo == currentUserId).toList();
  }

  List<TaskModel> get familyTasks {
    return _tasks.where((task) => task.assignedTo != currentUserId).toList();
  }

  List<TaskModel> get pendingTasks {
    return _tasks.where((task) => !task.isCompleted).toList();
  }

  List<TaskModel> get completedTasks {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  // Data Loading
  Future<void> _loadData() async {
    try {
      _family = await _storage.loadFamily();
      if (_family == null) {
        // Create the Smith family with default members
        final johnSmith = FamilyMember(
          name: 'John Smith',
          role: FamilyRole.parent,
        );
        final janeSmith = FamilyMember(
          name: 'Jane Smith',
          role: FamilyRole.parent,
        );
        final tommySmith = FamilyMember(
          name: 'Tommy Smith',
          role: FamilyRole.child,
        );
        final sarahSmith = FamilyMember(
          name: 'Sarah Smith',
          role: FamilyRole.child,
        );
        
        _family = Family(
          name: 'Smith Family',
          members: [johnSmith, janeSmith, tommySmith, sarahSmith],
        );
        await _storage.saveFamily(_family!);
        _currentUser = johnSmith;
        await _storage.saveLastUserId(johnSmith.id);
      } else {
        final lastUserId = await _storage.getLastUserId();
        if (lastUserId != null) {
          _currentUser = _family!.members.firstWhere(
            (member) => member.id == lastUserId,
            orElse: () => _family!.members.first,
          );
        }
      }
      _tasks = await _storage.loadTasks();
      _shoppingList = await _storage.loadShoppingList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Family Management
  Future<void> addFamilyMember(FamilyMember member) async {
    if (_family == null) {
      _family = Family(name: 'My Family', members: [member]);
    } else {
      _family!.members.add(member);
    }
    await _storage.saveFamily(_family!);
    notifyListeners();
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    final index = _family!.members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _family!.members[index] = member;
      await _storage.saveFamily(_family!);
      if (_currentUser?.id == member.id) {
        _currentUser = member;
      }
      notifyListeners();
    }
  }

  Future<void> deleteFamilyMember(String memberId) async {
    _family!.members.removeWhere((member) => member.id == memberId);
    await _storage.saveFamily(_family!);
    notifyListeners();
  }

  Future<void> switchUser(String userId) async {
    final member = _family!.members.firstWhere((m) => m.id == userId);
    _currentUser = member;
    await _storage.saveLastUserId(userId);
    notifyListeners();
  }

  // Task Management
  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _storage.saveTasks(_tasks);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      await _storage.saveTasks(_tasks);
      notifyListeners();
    }
  }

  // Shopping List Management
  Future<void> addShoppingItem(ShoppingItem item) async {
    _shoppingList.add(item);
    await _storage.saveShoppingList(_shoppingList);
    notifyListeners();
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    final index = _shoppingList.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _shoppingList[index] = item;
      await _storage.saveShoppingList(_shoppingList);
      notifyListeners();
    }
  }

  Future<void> deleteShoppingItem(String itemId) async {
    _shoppingList.removeWhere((item) => item.id == itemId);
    await _storage.saveShoppingList(_shoppingList);
    notifyListeners();
  }

  Future<void> toggleShoppingItemPurchased(String itemId) async {
    final index = _shoppingList.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _shoppingList[index] = _shoppingList[index].copyWith(
        isPurchased: !_shoppingList[index].isPurchased,
      );
      await _storage.saveShoppingList(_shoppingList);
      notifyListeners();
    }
  }
} 