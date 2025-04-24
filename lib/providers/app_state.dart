import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;
  final SupabaseService _supabase = SupabaseService();
  Family? _family;
  FamilyMember? _currentUser;
  List<TaskModel> _tasks = [];
  List<ShoppingItem> _shoppingList = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _currentUserId;

  AppState(this._storage) {
    _initializeApp();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Family? get family => _family;
  FamilyMember? get currentUser => _currentUser;
  String? get currentUserId => _currentUserId;
  bool get isParent => _currentUser?.isParent ?? false;
  List<TaskModel> get tasks => _tasks;
  List<ShoppingItem> get shoppingList => _shoppingList;

  List<TaskModel> get myTasks {
    if (_currentUser == null) return [];
    return _tasks.where((task) => task.assignedTo == _currentUser!.id).toList();
  }

  List<TaskModel> get familyTasks {
    if (_currentUser == null) return [];
    return _tasks.where((task) => task.assignedTo != _currentUser!.id).toList();
  }

  List<TaskModel> get pendingTasks {
    return _tasks.where((task) => !task.isCompleted).toList();
  }

  List<TaskModel> get completedTasks {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  // Authentication
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isParent,
  }) async {
    try {
      final response = await _supabase.signUp(
        email: email,
        password: password,
        name: name,
        isParent: isParent,
      );
      
      if (response.user != null) {
        _currentUser = FamilyMember(
          id: response.user!.id,
          name: name,
          role: isParent ? FamilyRole.parent : FamilyRole.child,
        );
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.signIn(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _loadUserData(response.user!.id);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.signOut();
      _isAuthenticated = false;
      _currentUser = null;
      _family = null;
      _tasks = [];
      _shoppingList = [];
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Data Loading
  Future<void> _initializeApp() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _loadUserData(session.user.id);
        _isAuthenticated = true;
      } else {
        // Initialize with sample data if no session exists
        await _storage.initializeWithSampleDataIfNeeded();
        final family = await _storage.loadFamily();
        if (family != null) {
          _family = family;
          final lastUserId = await _storage.getLastUserId();
          if (lastUserId != null) {
            final member = _family!.getMember(lastUserId);
            if (member != null) {
              _currentUser = member;
              _currentUserId = lastUserId;
            } else {
              _currentUser = _family!.members.first;
              _currentUserId = _family!.members.first.id;
            }
          } else {
            _currentUser = _family!.members.first;
            _currentUserId = _family!.members.first.id;
          }
          _tasks = await _storage.loadTasks();
          _shoppingList = _storage.getShoppingList();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      // Load user profile
      final profile = await _supabase.getProfile(userId);
      _currentUser = FamilyMember(
        id: userId,
        name: profile['name'],
        role: profile['is_parent'] ? FamilyRole.parent : FamilyRole.child,
      );

      // Load family data if user has one
      if (profile['family_id'] != null) {
        final familyData = await _supabase.getFamily(profile['family_id']);
        if (familyData != null) {
          _family = familyData;
        }
      }

      // Load tasks
      _tasks = await _supabase.getTasks();

      // Load shopping list
      _shoppingList = _storage.getShoppingList();

      // Set up real-time subscriptions
      if (_family != null) {
        _supabase.streamTasks(_family!.id).listen((tasks) {
          _tasks = tasks.map((task) => TaskModel.fromJson(task)).toList();
          notifyListeners();
        });

        _supabase.streamFamilyMembers(_family!.id).listen((members) async {
          final familyData = await _supabase.getFamily(_family!.id);
          if (familyData != null) {
            _family = familyData;
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Family Management
  Future<void> createFamily(String name) async {
    if (_currentUser == null) return;

    final family = Family(
      name: name,
      createdBy: _currentUser!.id,
      members: [_currentUser!],
    );

    await _supabase.createFamily(family);
    _family = family;
    notifyListeners();
  }

  Future<void> addFamilyMember(FamilyMember member) async {
    if (_family == null) return;

    final updatedMembers = [..._family!.members, member];
    final updatedFamily = _family!.copyWith(members: updatedMembers);
    await _supabase.updateFamily(updatedFamily);
    _family = updatedFamily;
    notifyListeners();
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    if (_family == null) return;

    final updatedMembers = _family!.members.map((m) {
      if (m.id == member.id) {
        return member;
      }
      return m;
    }).toList();

    final updatedFamily = _family!.copyWith(members: updatedMembers);
    await _supabase.updateFamily(updatedFamily);
    _family = updatedFamily;
    notifyListeners();
  }

  Future<void> deleteFamilyMember(String memberId) async {
    if (_family == null) return;

    final updatedMembers = _family!.members.where((m) => m.id != memberId).toList();
    final updatedFamily = _family!.copyWith(members: updatedMembers);
    await _supabase.updateFamily(updatedFamily);
    _family = updatedFamily;
    notifyListeners();
  }

  Future<void> switchUser(String userId) async {
    if (_family == null) return;
    final member = _family!.getMember(userId);
    if (member == null) return;

    _currentUser = member;
    _currentUserId = userId;
    await _storage.setString('current_user_id', userId);
    notifyListeners();
  }

  // Task Management
  Future<void> addTask(TaskModel task) async {
    final newTask = await _supabase.createTask(task);
    _tasks.add(newTask);
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    final updatedTask = await _supabase.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.deleteTask(taskId);
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      await updateTask(updatedTask);
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