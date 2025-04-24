import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required bool isParent,
  }) async {
    final AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'is_parent': isParent,
      },
    );
    
    if (response.user != null) {
      // Create user profile in the profiles table
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'is_parent': isParent,
      });
    }
    
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Task methods
  Future<List<TaskModel>> getTasks() async {
    final response = await _supabase
        .from('tasks')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((task) => TaskModel.fromJson(task)).toList();
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final response = await _supabase
        .from('tasks')
        .insert(task.toJson())
        .select()
        .single();
    
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final response = await _supabase
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();
    
    return TaskModel.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }

  // Family methods
  Future<Family?> getFamily(String familyId) async {
    final response = await _supabase
        .from('families')
        .select('*, profiles(*)')
        .eq('id', familyId)
        .single();
    
    return response != null ? Family.fromJson(response) : null;
  }

  Future<void> createFamily(Family family) async {
    await _supabase
        .from('families')
        .insert(family.toJson());
  }

  Future<void> updateFamily(Family family) async {
    await _supabase
        .from('families')
        .update(family.toJson())
        .eq('id', family.id);
  }

  Future<void> addFamilyMember(String familyId, String userId) async {
    await _supabase
        .from('family_members')
        .insert({
          'family_id': familyId,
          'user_id': userId,
        });
  }

  Future<void> removeFamilyMember(String familyId, String userId) async {
    await _supabase
        .from('family_members')
        .delete()
        .eq('family_id', familyId)
        .eq('user_id', userId);
  }

  // Profile methods
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return response;
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? email,
    bool? isParent,
  }) async {
    final updates = {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (isParent != null) 'is_parent': isParent,
    };

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> streamTasks(String familyId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at');
  }

  Stream<List<Map<String, dynamic>>> streamFamilyMembers(String familyId) {
    return _supabase
        .from('family_members')
        .stream(primaryKey: ['family_id', 'user_id'])
        .eq('family_id', familyId);
  }
} 