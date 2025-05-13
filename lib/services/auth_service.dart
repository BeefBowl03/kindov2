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

      // Handle the signup, store other data in metadata
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'is_parent': isParent,
          'family_name': familyName,
        },
      );
      
      if (response.user == null) {
        throw 'Failed to create user account';
      }
      
      try {
        print('Creating profile and family for user ID: ${response.user!.id}');
        
        // Create profile and family in a single transaction using the stored procedure
        await _supabase.rpc(
          'create_user_profile',
              params: {
                'user_id': response.user!.id,
                'user_name': name,
            'user_email': email,
                'is_parent': isParent,
            'family_name': familyName.isNotEmpty ? familyName : null,
              },
            );
            
        print('User profile and family created successfully');
      } catch (e) {
        print('Error creating profile or family after registration: $e');
        // Try to sign out the user since we couldn't complete the setup
        try {
          await _supabase.auth.signOut();
        } catch (_) {}
        throw 'Registration completed but failed to create profile or family: $e';
      }
      
      return response;
    } catch (e) {
      print('Error in signUp: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to sign in user: $email');
      
      // Attempt to sign in first without checking profile
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('Sign in successful for user: ${response.user!.id}');
        
        try {
          // After sign-in, check if the user has a profile and create one if not
          final profile = await _supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();
          
          if (profile == null) {
            print('User authenticated but profile not found, creating profile...');
            // Create profile based on user metadata
            final metadata = response.user!.userMetadata;
            if (metadata != null) {
              await _supabase.from('profiles').insert({
                'id': response.user!.id,
                'email': email,
                'name': metadata['name'] ?? 'User',
                'is_parent': metadata['is_parent'] ?? false,
              });
              print('Created missing profile for user from metadata');
            } else {
              // If no metadata, still create a basic profile
              await _supabase.from('profiles').insert({
                'id': response.user!.id,
                'email': email,
                'name': 'User',
                'is_parent': false,
              });
              print('Created basic profile for user without metadata');
            }
          }
        } catch (profileError) {
          // Log error but don't prevent sign-in
          print('Error handling user profile after sign-in: $profileError');
        }
      } else {
        print('Sign in response contained no user');
        throw 'Sign in failed for unknown reason.';
      }
      
      return response;
    } catch (e) {
      print('Error in signIn method: $e');
      // Provide more helpful error messages
      if (e is AuthException) {
        if (e.message.contains('Invalid login credentials')) {
          throw 'Invalid password. If you recently reset your password, please ensure you\'re using your new password.';
        }
        // Pass through Supabase auth error messages
        throw e.message;
      }
      // Pass through other errors
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
} 