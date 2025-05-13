import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common_widgets.dart';
import '../theme.dart';
import '../providers/app_state.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _familyNameController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _isParent = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        if (_isRegistering) {
          await appState.signUp(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            isParent: _isParent,
            familyName: _familyNameController.text,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully! You can now log in.'),
                duration: Duration(seconds: 10),
              ),
            );
            // Switch back to login mode
            setState(() {
              _isRegistering = false;
              _formKey.currentState?.reset();
            });
          }
        } else {
          await appState.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_isRegistering ? 'Registration' : 'Login'} failed: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and App Name
                  Icon(
                    Icons.family_restroom,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KinDo',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Family Task Management',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Registration fields
                  if (_isRegistering) ...[
                    KinDoTextField(
                      label: 'Name',
                      hint: 'Enter your name',
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    KinDoTextField(
                      label: 'Family Name',
                      hint: 'Enter your family name',
                      controller: _familyNameController,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your family name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Role selection
                    Row(
                      children: [
                        Text('Role:', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Parent'),
                          selected: _isParent,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _isParent = true);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Child'),
                          selected: !_isParent,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _isParent = false);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Login Form
                  KinDoTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
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
                  KinDoTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PasswordResetScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Login/Register Button
                  KinDoButton(
                    text: _isLoading 
                      ? (_isRegistering ? 'Creating account...' : 'Logging in...') 
                      : (_isRegistering ? 'Create Account' : 'Login'),
                    onPressed: _isLoading ? () {} : () => _handleLogin(),
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle Register/Login
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isRegistering 
                        ? 'Already have an account? Login' 
                        : 'Don\'t have an account? Register',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 