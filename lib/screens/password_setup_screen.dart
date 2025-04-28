import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';

class PasswordSetupScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? invitationData;

  const PasswordSetupScreen({
    super.key,
    this.token,
    this.invitationData,
  });

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _invitationData;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _verifyToken();
    } else if (widget.invitationData != null) {
      setState(() => _invitationData = widget.invitationData);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    try {
      setState(() => _isLoading = true);

      if (widget.token == null) {
        throw 'Invalid invitation token';
      }

      final token = widget.token!;

      // Get the invitation data using the token
      final data = await Supabase.instance.client
          .from('pending_invitations')
          .select()
          .eq('token', token)
          .eq('status', 'pending')
          .maybeSingle();

      if (data == null) {
        throw 'Invalid or expired invitation token';
      }

      // Check if invitation has expired
      final expiresAt = DateTime.parse(data['expires_at'] as String);
      if (expiresAt.isBefore(DateTime.now())) {
        // Mark as expired
        await Supabase.instance.client
            .from('pending_invitations')
            .update({'status': 'expired'})
            .eq('token', token)
            .select();
        throw 'This invitation has expired';
      }

      setState(() => _invitationData = data);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setPassword() async {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (_invitationData == null) {
      setState(() => _errorMessage = 'Invalid invitation data');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create the user account
      final response = await Supabase.instance.client.auth.signUp(
        email: _invitationData!['email'] as String,
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw 'Failed to create account';
      }

      // Create the user profile
      await Supabase.instance.client
          .from('profiles')
          .insert({
            'id': response.user!.id,
            'email': _invitationData!['email'],
            'name': _invitationData!['name'],
            'is_parent': _invitationData!['is_parent'],
          })
          .select();

      // Add user to the family
      await Supabase.instance.client
          .from('family_members')
          .insert({
            'family_id': _invitationData!['family_id'],
            'user_id': response.user!.id,
          })
          .select();

      // Mark invitation as used
      if (widget.token != null) {
        final token = widget.token!;
        await Supabase.instance.client
            .from('pending_invitations')
            .update({'status': 'used'})
            .eq('token', token)
            .select();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to the family! You can now log in with your email and password.'),
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      setState(() => _errorMessage = e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _invitationData == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null && _invitationData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to KinDo!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve been invited to join a family! Please set up your password to complete your account.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Enter your password again',
              ),
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _setPassword,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Set Password'),
            ),
          ],
        ),
      ),
    );
  }
} 