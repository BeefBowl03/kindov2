import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../widgets/common_widgets.dart';

class PasswordResetScreen extends StatefulWidget {
  final String? token;

  const PasswordResetScreen({super.key, this.token});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isResetMode = false;
  String? _errorMessage;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    print('Initializing PasswordResetScreen');
    print('Widget token: ${widget.token}');
    print('Current URL: ${Uri.base}');
    
    // Force user to be logged out first
    Supabase.instance.client.auth.signOut().then((_) {
      print('Signed out existing user to enforce password reset');
    });
    
    // Get route arguments if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.settings.arguments != null) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          print('Route arguments: $args');
          
          // Set token from arguments
          if (args.containsKey('code') && args['code'] != null) {
            final code = args['code'] as String;
            print('Setting token from arguments: $code');
            setState(() {
              _resetToken = code;
              _isResetMode = true;
            });
          }
          
          // Set email from arguments
          if (args.containsKey('email') && args['email'] != null) {
            final email = args['email'] as String;
            print('Setting email from arguments: $email');
            _emailController.text = email;
          }
          
          // Check if we should be in reset mode
          if (args.containsKey('is_reset') && args['is_reset'] == true) {
            print('Forcing reset mode from arguments');
            setState(() {
              _isResetMode = true;
            });
          }
        }
      }
    });
    
    // Use the widget token if provided directly
    if (widget.token != null && widget.token!.isNotEmpty) {
      print('Setting token from widget prop: ${widget.token}');
      setState(() {
        _resetToken = widget.token;
        _isResetMode = true;
      });
    }
    
    // Extract email from URL query parameters
    String? emailFromUrl = Uri.base.queryParameters['email'];
    print('Email from URL query: $emailFromUrl');
    if (emailFromUrl != null && emailFromUrl.isNotEmpty) {
      print('Setting email from URL: $emailFromUrl');
      _emailController.text = emailFromUrl;
    }

    // Extract the reset token from various possible locations
    _extractResetToken();
  }

  void _extractResetToken() {
    // 1. Check for access_token in the fragment (for mobile deep links)
    final fragment = Uri.base.fragment;
    print('Processing fragment: $fragment');
    if (fragment.isNotEmpty) {
      print('Fragment is not empty: $fragment');
      
      // Handle both formats:
      // - Plain fragment with access_token as parameter
      // - Fragment with a path followed by query parameters
      
      // First, check if there's a path in the fragment (e.g., "/reset-password?access_token=...")
      final pathEndIndex = fragment.indexOf('?');
      final queryString = pathEndIndex != -1 ? fragment.substring(pathEndIndex + 1) : fragment;
      
      print('Extracted query string from fragment: $queryString');
      final params = Uri.splitQueryString(queryString);
      print('Parsed params from fragment: $params');
      
      final accessToken = params['access_token'] ?? params['token'];
      print('Access token from fragment: $accessToken');
      
      if (accessToken != null) {
        print('Found token in fragment: $accessToken');
        setState(() {
          _resetToken = accessToken;
          _isResetMode = true;
        });
        
        // Extract email from the fragment if available
        final emailFromFragment = params['email'];
        if (emailFromFragment != null && emailFromFragment.isNotEmpty) {
          print('Found email in fragment: $emailFromFragment');
          _emailController.text = emailFromFragment;
        }
        
        return;
      }
    }

    // 2. Check for 'code' or 'token' in the query parameters (for web)
    final code = Uri.base.queryParameters['code'] ?? Uri.base.queryParameters['token'];
    if (code != null && code.isNotEmpty) {
      print('Found code/token in query params: $code');
      setState(() {
        _resetToken = code;
        _isResetMode = true;
      });
      
      // Extract email from query parameters
      final emailFromQuery = Uri.base.queryParameters['email'];
      if (emailFromQuery != null && emailFromQuery.isNotEmpty) {
        print('Found email in query params: $emailFromQuery');
        _emailController.text = emailFromQuery;
      }
      
      return;
    }
    
    // 3. Check for specific type parameter in query (for recovery)
    final type = Uri.base.queryParameters['type'];
    print('URL type parameter: $type');
    if (type == 'recovery') {
      print('Found recovery type in query params');
      final token = Uri.base.queryParameters['token'] ?? Uri.base.queryParameters['access_token'];
      if (token != null && token.isNotEmpty) {
        print('Found token in query params for recovery: $token');
        setState(() {
          _resetToken = token;
          _isResetMode = true;
        });
        
        // For recovery type, make sure to set the email
        final emailFromQuery = Uri.base.queryParameters['email'];
        if (emailFromQuery != null && emailFromQuery.isNotEmpty) {
          print('Found email in recovery params: $emailFromQuery');
          _emailController.text = emailFromQuery;
        }
        
        return;
      }
    }

    // 4. Fallback to token from widget (for direct navigation)
    if (widget.token != null) {
      print('Using token from widget: ${widget.token}');
      setState(() {
        _resetToken = widget.token;
        _isResetMode = true;
      });
      
      // Try to get the email from arguments after widget builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.arguments != null) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('email') && args['email'] != null) {
            print('Setting email from route arguments: ${args['email']}');
            _emailController.text = args['email'] as String;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        print('Attempting to send password reset email to: $email');
        
        // Determine the appropriate redirect URL based on platform
        final redirectUrl = kIsWeb 
            ? '${Uri.base.origin}/reset-password'
            : 'kindo://reset-password';
            
        print('Using redirect URL: $redirectUrl');

        // Use Supabase's built-in password reset
        await Supabase.instance.client.auth.resetPasswordForEmail(
          email,
          redirectTo: redirectUrl,
        );

        print('Password reset email sent successfully');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('If this email exists in our system, a password reset link has been sent. Please check your inbox and spam folder.'),
            duration: Duration(seconds: 6),
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print('Error sending password reset email: $e');
        String errorMessage = 'Failed to send reset email';
        
        if (e is AuthException) {
          errorMessage = e.message;
        } else if (e is String) {
          errorMessage = e;
        }
        
        setState(() => _errorMessage = errorMessage);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _errorMessage = 'Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        print('Attempting to update password with token');
        
        if (_resetToken == null) {
          throw 'Reset token is missing. Please request a new password reset link.';
        }
        
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          throw 'Email is required to reset your password.';
        }
        
        print('Attempting to update password with token for email: $email');
        
        // Use direct REST API call to update password with the token
        // This avoids creating a session before the password is updated
        final success = await _resetPasswordWithToken(
          token: _resetToken!,
          email: email,
          newPassword: _passwordController.text,
        );

        print('Password update result: $success');

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully. Please log in with your new password.'),
              duration: Duration(seconds: 4),
            ),
          );

          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          // This might not be reached since _resetPasswordWithToken throws on failure
          // but keeping it for robustness
          setState(() => _errorMessage = 'Failed to update password. Please try again.');
        }
      } catch (e) {
        print('Error in reset password process: $e');
        setState(() => _errorMessage = e.toString());
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  Future<bool> _resetPasswordWithToken({
    required String token,
    required String email,
    required String newPassword,
  }) async {
    // Use the direct values from initialization in main.dart
    final supabaseUrl = 'https://cgthmzpuqvxeiwqtscsy.supabase.co';
    final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNndGhtenB1cXZ4ZWl3cXRzY3N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0NTA1ODEsImV4cCI6MjA2MTAyNjU4MX0.UZdzH0XbcTTAXh_6mI2bgTFW0bH2K_1u_y27kFdMM90';
    
    print('Using Supabase URL: $supabaseUrl');
    print('Resetting password for email: $email with token length: ${token.length}');
    
    try {
      // Try all available API endpoints to reset the password
      
      // 1. First - try the type=recovery endpoint directly
      final typedRecoverUrl = '$supabaseUrl/auth/v1/user';
      print('Attempt 1: Calling update user directly with token as Auth');
      
      final typedResponse = await http.put(
        Uri.parse(typedRecoverUrl),
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': newPassword,
        }),
      );
      
      print('Update user API response status code: ${typedResponse.statusCode}');
      print('Update user API response body: ${typedResponse.body}');
      
      if (typedResponse.statusCode >= 200 && typedResponse.statusCode < 300) {
        print('SUCCESS: Password updated via direct user update');
        return true;
      }
      
      // 2. Try the standard password recovery endpoint
      print('Attempt 2: Calling standard recover endpoint with token');
      final recoverUrl = '$supabaseUrl/auth/v1/recover';
      final response = await http.post(
        Uri.parse(recoverUrl),
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'password': newPassword,
          'email': email,
        }),
      );
      
      print('API response status code: ${response.statusCode}');
      print('API response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('SUCCESS: Password updated via standard recover endpoint');
        return true;
      }
      
      // 3. Try with access_token parameter
      print('Attempt 3: Trying with access_token instead of token');
      final alternativeResponse = await http.post(
        Uri.parse(recoverUrl),
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': token,
          'password': newPassword,
          'email': email,
        }),
      );
      
      print('Alternative API response status code: ${alternativeResponse.statusCode}');
      print('Alternative API response body: ${alternativeResponse.body}');
      
      if (alternativeResponse.statusCode >= 200 && alternativeResponse.statusCode < 300) {
        print('SUCCESS: Password updated via alternative recover endpoint');
        return true;
      }
      
      // 4. Try the signup endpoint with recovery flag
      print('Attempt 4: Trying signup with recovery flag');
      final signupUrl = '$supabaseUrl/auth/v1/signup';
      final signupResponse = await http.post(
        Uri.parse(signupUrl),
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': newPassword,
          'recovery_token': token,
        }),
      );
      
      print('Signup API response status code: ${signupResponse.statusCode}');
      print('Signup API response body: ${signupResponse.body}');
      
      if (signupResponse.statusCode >= 200 && signupResponse.statusCode < 300) {
        print('SUCCESS: Password updated via signup with recovery token');
        return true;
      }
      
      // If all attempts fail, try to extract a meaningful error message
      String errorDetail = 'Failed to update password';
      try {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] != null) {
          errorDetail = responseData['error'];
        } else if (responseData['msg'] != null) {
          errorDetail = responseData['msg'];
        } else if (responseData['message'] != null) {
          errorDetail = responseData['message'];
        }
      } catch (e) {
        print('Error parsing response body: $e');
      }
      
      throw errorDetail;
    } catch (e) {
      print('API error: $e');
      throw 'Error updating password: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isResetMode ? 'Reset Password' : 'Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isResetMode ? 'Set New Password' : 'Reset Your Password',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                _isResetMode
                    ? 'Please enter your new password'
                    : 'Enter your email to receive a password reset link',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!_isResetMode) ...[
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestPasswordReset,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Send Reset Link'),
                ),
              ],
              if (_isResetMode) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update Password'),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}