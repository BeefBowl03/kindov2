import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/password_setup_screen.dart';
import 'screens/password_reset_screen.dart';
// Import other screens...

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuth = Supabase.instance.client.auth.currentSession != null;
    final isLoggingIn = state.matchedLocation == '/login';
    final isPasswordSetup = state.matchedLocation.startsWith('/setup-password');
    final isPasswordReset = state.matchedLocation.startsWith('/reset-password');

    // Allow these routes without authentication
    if (isPasswordSetup || isPasswordReset || isLoggingIn) {
      return null;
    }

    // Redirect to login if not authenticated
    if (!isAuth) {
      return '/login';
    }

    // Allow access to authenticated routes
    if (isAuth && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => PasswordResetScreen(),
    ),
    GoRoute(
      path: '/setup-password',
      redirect: (context, state) => '/reset-password',
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        print('Reset Password Route - Full URI: ${Uri.base}');
        print('Query parameters: ${state.uri.queryParameters}');
        print('Fragment: ${Uri.base.fragment}');
        
        // Get email from query parameters
        final email = state.uri.queryParameters['email'];
        print('Email from query: $email');
        
        // Parse token from fragment for web
        String? token;
        if (Uri.base.hasFragment) {
          // Handle both formats:
          // - Plain fragment with access_token as parameter
          // - Fragment with a path followed by query parameters
          final fragment = Uri.base.fragment;
          
          final pathEndIndex = fragment.indexOf('?');
          final queryString = pathEndIndex != -1 ? fragment.substring(pathEndIndex + 1) : fragment;
          
          print('Extracted query string from fragment: $queryString');
          final params = Uri.splitQueryString(queryString);
          print('Parsed params from fragment: $params');
          
          token = params['access_token'];
          print('Access token from fragment: $token');
        } else {
          token = state.uri.queryParameters['access_token'];
          print('Access token from query params: $token');
        }
        
        if (token == null) {
          // Try 'code' parameter as fallback
          token = state.uri.queryParameters['code'];
          print('Code parameter fallback: $token');
        }
        
        print('Reset Password Route - Final token: $token'); 
        
        return PasswordResetScreen(token: token);
      },
    ),
    // Other routes...
  ],
); 