import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

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
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Check if this is an invited user logging in for the first time
    await handleInvitedUserLogin();

    return response;
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

  Future<Family> createFamily(Family family) async {
    try {
      final response = await client.rpc(
        'create_family_with_member',
        params: {
          'family_name': family.name,
          'user_id': family.createdBy,
          'user_name': family.members.first.name,
          'is_parent': family.members.first.isParent,
        },
      );

      if (response == null) {
        throw 'Failed to create family';
      }

      return Family(
        id: response['id'],
        name: response['name'],
        createdBy: response['created_by'],
        members: family.members,
      );
    } catch (e) {
      print('Error in createFamily: $e');
      rethrow;
    }
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
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      // Get the profile
      final profileResponse = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
      if (profileResponse == null) {
        throw Exception('Profile not found for user: $userId');
      }

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
            
        if (familyResponse == null) {
          throw Exception('Family not found for user: $userId');
        }

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
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final updates = {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (isParent != null) 'is_parent': isParent,
      };

      if (updates.isEmpty) {
        throw Exception('No updates provided');
      }

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      print('Error in updateProfile: $e');
      rethrow;
    }
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> streamTasks(String familyId) {
    if (familyId.isEmpty) {
      throw Exception('Family ID cannot be empty');
    }

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((error) {
          print('Error in task stream: $error');
          return [];
        });
  }

  Stream<List<Map<String, dynamic>>> streamFamilyMembers(String familyId) {
    if (familyId.isEmpty) {
      throw Exception('Family ID cannot be empty');
    }

    return _supabase
        .from('family_members')
        .stream(primaryKey: ['family_id', 'user_id'])
        .eq('family_id', familyId)
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((error) {
          print('Error in family members stream: $error');
          return [];
        });
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
      print('Inviting family member: $email');
      
      // Use the Edge Function instead of client-side user creation
      final response = await _supabase.functions.invoke(
        'invite-user',
        body: {
          'email': email,
          'name': name,
          'isParent': isParent,
          'familyId': familyId,
        },
      );
      
      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        print('Error from Edge Function: $error');
        throw Exception('Failed to invite user: $error');
      }
      
      print('Invitation sent successfully via Edge Function');
      print('Response: ${response.data}');
      
    } catch (e) {
      print('Error in inviteFamilyMember: $e');
      throw Exception('Failed to invite family member: ${e.toString()}');
    }
  }

  // Add a method to handle first-time login for invited users
  Future<void> handleInvitedUserLogin() async {
    try {
      final user = _supabase.auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) return;

      // Check if they already have a profile
      final existingProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile != null) return; // Already set up

      // Get their pending invitation
      final invitation = await _supabase
          .from('pending_invitations')
          .select()
          .eq('email', email)
          .eq('status', 'pending')
          .maybeSingle();

      if (invitation == null) return; // No pending invitation

      // Create their profile
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'name': invitation['name'],
        'is_parent': invitation['is_parent'],
      });

      // Add them to the family
      await _supabase.from('family_members').insert({
        'family_id': invitation['family_id'],
        'user_id': user.id,
      });

      // Mark invitation as used
      await _supabase
          .from('pending_invitations')
          .update({'status': 'used'})
          .eq('id', invitation['id']);

    } catch (e) {
      throw Exception('Failed to set up invited user: ${e.toString()}');
    }
  }

  String _generateSecureToken() {
    // Generate a random UUID for the token
    return const Uuid().v4();
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

  // Shopping List Operations
  Future<List<ShoppingItem>> getShoppingList(String familyId) async {
    final response = await _supabase
        .from('shopping_items')
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: false);

    return response.map((item) => ShoppingItem.fromJson({
      'id': item['id'],
      'title': item['name'],
      'quantity': item['quantity'],
      'is_purchased': item['is_purchased'],
      'added_by': item['created_by'],
    })).toList();
  }

  Future<ShoppingItem> createShoppingItem(ShoppingItem item, String familyId) async {
    final response = await _supabase
        .from('shopping_items')
        .insert({
          'family_id': familyId,
          'name': item.title,
          'quantity': item.quantity,
          'is_purchased': item.isPurchased,
          'created_by': item.addedBy,
        })
        .select()
        .single();

    return ShoppingItem.fromJson({
      'id': response['id'],
      'title': response['name'],
      'quantity': response['quantity'],
      'is_purchased': response['is_purchased'],
      'added_by': response['created_by'],
    });
  }

  Future<ShoppingItem> updateShoppingItem(ShoppingItem item) async {
    final response = await _supabase
        .from('shopping_items')
        .update({
          'name': item.title,
          'quantity': item.quantity,
          'is_purchased': item.isPurchased,
        })
        .eq('id', item.id)
        .select()
        .single();

    return ShoppingItem.fromJson({
      'id': response['id'],
      'title': response['name'],
      'quantity': response['quantity'],
      'is_purchased': response['is_purchased'],
      'added_by': response['created_by'],
    });
  }

  Future<void> deleteShoppingItem(String itemId) async {
    await _supabase
        .from('shopping_items')
        .delete()
        .eq('id', itemId);
  }

  Stream<List<ShoppingItem>> streamShoppingList(String familyId) {
    return _supabase
        .from('shopping_items')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((items) => items.map((item) => ShoppingItem.fromJson({
          'id': item['id'],
          'title': item['name'],
          'quantity': item['quantity'],
          'is_purchased': item['is_purchased'],
          'added_by': item['created_by'],
        })).toList());
  }

  // Helper method to generate a random password
  String generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Test email delivery
  Future<bool> testEmailDelivery(String email) async {
    try {
      print('Testing email delivery to: $email');
      
      final response = await _supabase.functions.invoke(
        'test-email',
        body: {
          'email': email,
        },
      );
      
      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        print('Error from test-email function: $error');
        return false;
      }
      
      print('Test email sent successfully');
      print('Response: ${response.data}');
      return true;
    } catch (e) {
      print('Error in testEmailDelivery: $e');
      return false;
    }
  }
  
  // Invite family member directly without using Edge Functions
  Future<String> inviteFamilyMemberDirect({
    required String email,
    required String name,
    required bool isParent,
    required String familyId,
  }) async {
    try {
      print('Directly inviting family member: $email');
      
      // Generate a temporary password
      final temporaryPassword = generateRandomPassword();
      print('Generated temporary password: $temporaryPassword');
      
      // Check if user already exists
      String userId = '';
      bool userExists = false;
      
      try {
        final existingUser = await _supabase
            .from('profiles')
            .select('id')
            .eq('email', email)
            .maybeSingle();
            
        if (existingUser != null) {
          userId = existingUser['id'];
          userExists = true;
          print('Found existing user ID: $userId');
          
          // Check if they're already in the family
          final existingMember = await _supabase
              .from('family_members')
              .select()
              .eq('family_id', familyId)
              .eq('user_id', userId)
              .maybeSingle();
              
          if (existingMember == null) {
            // Add them to the family
            await _supabase.from('family_members').insert({
              'family_id': familyId,
              'user_id': userId,
            });
            print('Added existing user to family');
          } else {
            print('User already in this family');
            return 'User is already a member of this family.';
          }
        }
      } catch (e) {
        print('Error checking for existing user: $e');
        // Continue to create new user if needed
      }
      
      // If user doesn't exist, create them
      if (!userExists) {
        print('Creating new user account for: $email');
        try {
          final signUpResponse = await _supabase.auth.signUp(
            email: email,
            password: temporaryPassword,
            data: {
              'name': name,
              'is_parent': isParent,
              'family_id': familyId,
              'temp_password': temporaryPassword,
            },
          );
          
          if (signUpResponse.user == null) {
            throw Exception('Failed to create user account');
          }
          
          userId = signUpResponse.user!.id;
          print('User created with ID: $userId');
          
          // Create the profile
          await _supabase.from('profiles').insert({
            'id': userId,
            'email': email,
            'name': name,
            'is_parent': isParent,
          });
          
          print('User profile created');
          
          // Add to family
          await _supabase.from('family_members').insert({
            'family_id': familyId,
            'user_id': userId,
          });
          
          print('User added to family');
        } catch (e) {
          print('Error creating user: $e');
          
          // Check if user already exists error
          if (e.toString().toLowerCase().contains('already registered') ||
              e.toString().toLowerCase().contains('already exists')) {
            
            // Try to get existing user 
            print('User already exists, trying to get existing user info');
            userExists = true;
            
            try {
              // Try to use magic link instead
              await _supabase.auth.signInWithOtp(
                email: email,
              );
              
              print('Sent magic link to existing user');
            } catch (authError) {
              print('Error signing in existing user: $authError');
              // We'll continue and just provide credentials
            }
          } else {
            throw Exception('Failed to create user: $e');
          }
        }
      }
      
      // Try to call the Edge Function (for logging purposes only)
      try {
        final response = await _supabase.functions.invoke(
          'send-invitation-email',
          body: {
            'email': email,
            'name': name,
            'temporaryPassword': temporaryPassword,
            'familyName': 'Your Family',
            'isExistingUser': userExists,
          },
        );
        print('Edge Function response (for logging): ${response.data}');
      } catch (e) {
        print('Edge Function error (non-critical): $e');
      }
      
      print('Invitation process completed for: $email');
      print('Temporary password is: $temporaryPassword');
      
      // For all users, return the login credentials
      if (userExists) {
        return 'Existing user added to your family.\n\nUser Credentials:\nEmail: $email\nPassword: Use existing password OR Temporary Password: $temporaryPassword\n\nPlease share these credentials with the user.';
      } else {
        return 'New user created!\n\nUser Credentials:\nEmail: $email\nTemporary Password: $temporaryPassword\n\nPlease share these credentials with the user. They should log in with these credentials and then change their password in their profile settings.';
      }
      
    } catch (e) {
      print('Error in inviteFamilyMemberDirect: $e');
      throw Exception('Failed to invite family member: ${e.toString()}');
    }
  }
} 