import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required bool isParent,
    required String familyName,
  }) async {
    try {
      // First check if user already exists
      final existingUser = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        throw 'A user with this email already exists';
      }

      // Only handle the signup, store other data in metadata
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
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          // Check if this is the first time logging in (after email verification)
          final profile = await _supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profile == null) {
            // Create family, profile, and family member records
            final userData = response.user!.userMetadata;
            if (userData != null) {
              // Start a transaction by using RPC
              await _supabase.rpc('create_user_profile', params: {
                'user_id': response.user!.id,
                'user_name': userData['name'],
                'user_email': response.user!.email!,
                'is_parent': userData['is_parent'],
                'family_name': userData['family_name'],
              });
            }
          }
        } catch (e) {
          print('Error creating profile: $e');
          // If profile creation fails, we should sign out the user
          await _supabase.auth.signOut();
          throw 'Failed to create user profile: ${e.toString()}';
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
} 