import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;
  final SupabaseService _supabase = SupabaseService();
  final AuthService _auth = AuthService();
  
  // Add supabase getter
  SupabaseClient get supabase => _supabase.client;

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
    required String familyName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        name: name,
        isParent: isParent,
        familyName: familyName,
      );
      
      if (response.user != null) {
        // Don't set authenticated until email is verified
        _isAuthenticated = false;
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
      final response = await _auth.signIn(
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
      await _auth.signOut();
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
        try {
        await _loadUserData(session.user.id);
        _isAuthenticated = true;
        } catch (e) {
          debugPrint('Error loading user data: $e');
          _isAuthenticated = false;
          await Supabase.instance.client.auth.signOut();
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('Error in _initializeApp: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      // Load user profile
      final profile = await _supabase.getProfile(userId);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      _currentUser = FamilyMember(
        id: userId,
        name: profile['name'],
        role: profile['is_parent'] ? FamilyRole.parent : FamilyRole.child,
      );
      _currentUserId = userId;

      // Load family data if user has one
      if (profile['family_id'] != null) {
        final familyData = await _supabase.getFamily(profile['family_id']);
        if (familyData != null) {
          _family = familyData;
          
          // Set up real-time subscriptions
          _supabase.streamTasks(_family!.id).listen((tasks) {
            _tasks = tasks.map((task) => TaskModel.fromJson(task)).toList();
            notifyListeners();
          });

          _supabase.streamFamilyMembers(_family!.id).listen((members) async {
            final updatedFamilyData = await _supabase.getFamily(_family!.id);
            if (updatedFamilyData != null) {
              _family = updatedFamilyData;
              notifyListeners();
            }
          });

          // Load shopping list
          await loadShoppingList();

          // Set up shopping list subscription
          _supabase.streamShoppingList(_family!.id).listen((items) {
            _shoppingList = items;
            _storage.saveShoppingList(items);
            notifyListeners();
          });
        }
      }

      // Load tasks
      _tasks = await _supabase.getTasks();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow;
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
    if (_family != null && isParent) {
      try {
        // First create a user profile
        await _supabase.updateProfile(
          userId: member.id,
          name: member.name,
          isParent: member.isParent,
        );

        // Then add the member to the family
        await _supabase.addFamilyMember(_family!.id, member.id);
        
        // Refresh family data
        _family = await _supabase.getFamily(_family!.id);
    notifyListeners();
      } catch (e) {
        debugPrint('Error adding family member: $e');
        rethrow;
      }
    }
  }

  Future<void> removeFamilyMember(String memberId) async {
    if (_family != null && isParent) {
      try {
        await _supabase.removeFamilyMember(_family!.id, memberId);
        
        // Refresh family data
        _family = await _supabase.getFamily(_family!.id);
        notifyListeners();
      } catch (e) {
        debugPrint('Error removing family member: $e');
        rethrow;
      }
    }
  }

  Future<void> updateFamilyMember(FamilyMember updatedMember) async {
    if (_family != null && isParent) {
      try {
        // Update the profile
        await _supabase.updateProfile(
          userId: updatedMember.id,
          name: updatedMember.name,
          isParent: updatedMember.isParent,
        );
        
        // Refresh family data
        _family = await _supabase.getFamily(_family!.id);
    notifyListeners();
      } catch (e) {
        debugPrint('Error updating family member: $e');
        rethrow;
      }
    }
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
    if (_family == null) return;
    
    final newItem = await _supabase.createShoppingItem(item, _family!.id);
    _shoppingList.add(newItem);
    await _storage.saveShoppingList(_shoppingList);
    notifyListeners();
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    final index = _shoppingList.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      final updatedItem = await _supabase.updateShoppingItem(item);
      _shoppingList[index] = updatedItem;
      await _storage.saveShoppingList(_shoppingList);
      notifyListeners();
    }
  }

  Future<void> deleteShoppingItem(String itemId) async {
    await _supabase.deleteShoppingItem(itemId);
    _shoppingList.removeWhere((item) => item.id == itemId);
    await _storage.saveShoppingList(_shoppingList);
    notifyListeners();
  }

  Future<void> toggleShoppingItemPurchased(String itemId) async {
    final index = _shoppingList.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final item = _shoppingList[index];
      final updatedItem = await _supabase.updateShoppingItem(
        item.copyWith(isPurchased: !item.isPurchased),
      );
      _shoppingList[index] = updatedItem;
      await _storage.saveShoppingList(_shoppingList);
      notifyListeners();
    }
  }

  Future<void> loadShoppingList() async {
    if (_family == null) return;
    
    try {
      _shoppingList = await _supabase.getShoppingList(_family!.id);
      await _storage.saveShoppingList(_shoppingList);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading shopping list: $e');
      rethrow;
    }
  }

  Future<void> loadFamily() async {
    if (_currentUser == null) return;
    
    try {
      final profile = await _supabase.getProfile(_currentUser!.id);
      if (profile['family_id'] != null) {
        final familyData = await _supabase.getFamily(profile['family_id']);
        if (familyData != null) {
          _family = familyData;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading family data: $e');
      rethrow;
    }
  }

  Future<String> createFamilyMember({
    required String email,
    required String name,
    required bool isParent,
  }) async {
    try {
      // Send invitation email through Supabase
      await _supabase.inviteFamilyMember(
        email: email,
        name: name,
        isParent: isParent,
        familyId: family!.id,
      );

      return 'Invitation sent! The new member will need to verify their email to join.';
    } catch (e) {
      throw Exception('Failed to invite family member: ${e.toString()}');
    }
  }

  Future<void> setPasswordWithToken(String token, String password) async {
    try {
      // Verify the invitation token and get the invitation ID
      final invitationId = await supabase.rpc('verify_invitation_token', params: {
        'token': token,
      });

      // Get the invitation details
      final invitationData = await supabase
          .from('pending_invitations')
          .select()
          .eq('id', invitationId)
          .single();

      // Create the user with email and password
      final response = await supabase.auth.signUp(
        email: invitationData['email'],
        password: password,
      );

      if (response.user == null) {
        throw 'Failed to create user';
      }

      // Create the profile and add to family in a single transaction
      await supabase.rpc('create_user_profile', params: {
        'user_id': response.user!.id,
        'user_name': invitationData['name'],
        'user_email': invitationData['email'],
        'is_parent': invitationData['is_parent'],
        'family_name': null  // Don't create a new family since they're joining an existing one
      });

      // Add to family
      await supabase
          .from('family_members')
          .insert({
            'family_id': invitationData['family_id'],
            'user_id': response.user!.id,
          });

      // Mark invitation as accepted
      await supabase
          .from('pending_invitations')
          .update({'status': 'accepted'})
          .eq('id', invitationId);

    } catch (e) {
      throw 'Failed to set password: ${e.toString()}';
    }
  }

  Future<void> completeInvitation(Map<String, dynamic> invitationData) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'No authenticated user';
      final email = user.email;
      if (email == null) throw 'User email not found';

      // Create the profile
      await supabase.from('profiles').insert({
        'id': user.id,
        'name': invitationData['name'],
        'email': email,
        'is_parent': invitationData['is_parent'],
      });

      // Add to family
      await supabase.from('family_members').insert({
        'family_id': invitationData['family_id'],
        'user_id': user.id,
      });

      // Get and update the pending invitation
      final invitation = await supabase
          .from('pending_invitations')
          .select()
          .eq('email', email)
          .eq('status', 'pending')
          .single();

      await supabase
          .from('pending_invitations')
          .update({'status': 'accepted'})
          .eq('id', invitation['id']);

    } catch (e) {
      throw 'Failed to complete invitation: ${e.toString()}';
    }
  }
} 