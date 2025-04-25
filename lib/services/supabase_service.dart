import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Expose the client for auth operations
  SupabaseClient get client => _supabase;

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required bool isParent,
    String? familyName,
  }) async {
    final AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'is_parent': isParent,
        'family_name': familyName,
      },
    );
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
    final profile = await getProfile(_supabase.auth.currentUser!.id);
    final familyId = profile['family_id'];
    
    if (familyId == null) return [];
    
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('family_id', familyId) // Only get tasks for the current family
        .order('created_at', ascending: false);
    
    return (response as List).map((task) => TaskModel.fromJson(task)).toList();
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final profile = await getProfile(_supabase.auth.currentUser!.id);
    final familyId = profile['family_id'];
    
    if (familyId == null) {
      throw Exception('No family found for the current user');
    }
    
    // Add family_id to the task
    final taskJson = {
      ...task.toJson(),
      'family_id': familyId,
    };
    
    final response = await _supabase
        .from('tasks')
        .insert(taskJson)
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
    try {
      // First get the family details
      final familyResponse = await _supabase
          .from('families')
          .select()
          .eq('id', familyId)
          .single();
      
      if (familyResponse == null) return null;

      // Then get the family members with their profiles
      final membersResponse = await _supabase
          .from('family_members')
          .select('''
            user_id,
            profiles!user_id(
              name,
              email,
              is_parent,
              avatar_url
            )
          ''')
          .eq('family_id', familyId);

      // Transform the response to match the Family model structure
      final List<Map<String, dynamic>> memberProfiles = (membersResponse as List<dynamic>)
          .map((member) => <String, dynamic>{
                'id': member['user_id'] as String,
                'name': member['profiles']['name'] as String,
                'email': member['profiles']['email'] as String,
                'is_parent': member['profiles']['is_parent'] as bool,
                'avatar_url': member['profiles']['avatar_url'] as String?,
              })
          .toList();

      return Family(
        id: familyResponse['id'] as String,
        name: familyResponse['name'] as String,
        createdBy: familyResponse['created_by'] as String,
        members: memberProfiles.map((profile) => FamilyMember.fromJson(profile)).toList(),
        createdAt: DateTime.parse(familyResponse['created_at'] as String),
        updatedAt: DateTime.parse(familyResponse['updated_at'] as String),
      );
    } catch (e) {
      print('Error in getFamily: $e');
      rethrow;
    }
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
    try {
      // Get the profile
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      // Get the family member record
      final familyMemberResponse = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (familyMemberResponse != null) {
        final familyResponse = await _supabase
            .from('families')
            .select()
            .eq('id', familyMemberResponse['family_id'])
            .single();
            
        // Combine the data
        return {
          ...profileResponse,
          'family_id': familyMemberResponse['family_id'],
          'family': familyResponse
        };
      }
      
      return profileResponse;
    } catch (e) {
      print('Error in getProfile: $e');
      rethrow;
    }
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

  Future<void> createUserProfile({
    required String userId,
    required String name,
    required bool isParent,
    required String email,
  }) async {
    try {
      await client.from('profiles').insert({
        'id': userId,
        'name': name,
        'is_parent': isParent,
        'email': email,
      });
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Invitation methods
  Future<void> inviteFamilyMember({
    required String email,
    required String name,
    required bool isParent,
    required String familyId,
  }) async {
    try {
      // First clean up any expired invitations
      await _supabase.rpc('expire_old_invitations');

      // Check if user already exists
      final existingUser = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('A user with this email already exists');
      }

      // Check for existing pending invitation
      final existingInvitation = await _supabase
          .from('pending_invitations')
          .select()
          .eq('email', email)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingInvitation != null) {
        throw Exception('There is already a pending invitation for this email');
      }

      // Create a new invitation
      await _supabase.from('pending_invitations').insert({
        'email': email,
        'name': name,
        'is_parent': isParent,
        'family_id': familyId,
        'status': 'pending',
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });

      // Send the magic link for email verification
      final redirectTo = kIsWeb 
          ? '${Uri.base.origin}/verify-email?type=signup'
          : 'kindo://verify-email?type=signup';

      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectTo,
        data: {
          'invitation_type': 'family_member',
          'family_id': familyId,
          'type': 'signup',
        },
      );
    } catch (e) {
      throw Exception('Failed to invite family member: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations(String familyId) async {
    try {
      // First clean up any expired invitations
      await _supabase.rpc('expire_old_invitations');

      // Get pending invitations
      final response = await _supabase
          .from('pending_invitations')
          .select()
          .eq('family_id', familyId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get pending invitations: ${e.toString()}');
    }
  }

  Future<void> cancelInvitation(String invitationId) async {
    try {
      await _supabase
          .from('pending_invitations')
          .update({'status': 'expired'})
          .eq('id', invitationId);
    } catch (e) {
      throw Exception('Failed to cancel invitation: ${e.toString()}');
    }
  }
} 