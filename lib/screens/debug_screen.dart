import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  List<String> _logs = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _familyMembers = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().split('.').first}: $message');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _addLog('Loading data...');

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final familyId = appState.family?.id;

      if (familyId == null) {
        _addLog('No family found.');
        return;
      }

      _addLog('Loading profiles...');
      final profilesResponse = await Supabase.instance.client
          .from('profiles')
          .select();
      
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(profilesResponse);
      });
      _addLog('Loaded ${_profiles.length} profiles');

      _addLog('Loading family members...');
      final membersResponse = await Supabase.instance.client
          .from('family_members')
          .select()
          .eq('family_id', familyId);
      
      setState(() {
        _familyMembers = List<Map<String, dynamic>>.from(membersResponse);
      });
      _addLog('Loaded ${_familyMembers.length} family members');

    } catch (e) {
      _addLog('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyUser() async {
    if (_emailController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    _addLog('Verifying user: $email');

    try {
      // Find profile by email
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (profileResponse == null) {
        _addLog('No profile found for email: $email');
      } else {
        _addLog('Profile found: ${profileResponse['id']}');
        
        // Check if in family
        final appState = Provider.of<AppState>(context, listen: false);
        final familyId = appState.family?.id;
        
        if (familyId != null) {
          final memberResponse = await Supabase.instance.client
              .from('family_members')
              .select()
              .eq('family_id', familyId)
              .eq('user_id', profileResponse['id'])
              .maybeSingle();
          
          if (memberResponse == null) {
            _addLog('User not in family.');
            
            // Add to family
            await Supabase.instance.client
                .from('family_members')
                .insert({
                  'family_id': familyId,
                  'user_id': profileResponse['id'],
                });
            
            _addLog('Added user to family.');
          } else {
            _addLog('User already in family.');
          }
        }
        
        // Send password reset email
        try {
          final redirectUrl = Uri.base.origin + '/reset-password';
          await Supabase.instance.client.auth.resetPasswordForEmail(
            email,
            redirectTo: redirectUrl,
          );
          _addLog('Password reset email sent.');
        } catch (e) {
          _addLog('Error sending password reset: $e');
        }
      }
    } catch (e) {
      _addLog('Error verifying user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      await _loadData();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Troubleshooting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Tools',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyUser,
                  child: const Text('Verify & Fix'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadData,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: 'Profiles (${_profiles.length})'),
                        Tab(text: 'Family Members (${_familyMembers.length})'),
                        Tab(text: 'Logs (${_logs.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Profiles Tab
                          _buildProfilesTab(),
                          
                          // Family Members Tab
                          _buildFamilyMembersTab(),
                          
                          // Logs Tab
                          _buildLogsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _profiles.length,
            itemBuilder: (context, index) {
              final profile = _profiles[index];
              return ListTile(
                title: Text(profile['name'] ?? 'Unknown'),
                subtitle: Text(profile['email'] ?? 'No email'),
                trailing: Text(profile['is_parent'] == true ? 'Parent' : 'Child'),
                onTap: () {
                  _emailController.text = profile['email'] ?? '';
                },
              );
            },
          );
  }

  Widget _buildFamilyMembersTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _familyMembers.length,
            itemBuilder: (context, index) {
              final member = _familyMembers[index];
              // Find matching profile
              final profile = _profiles.firstWhere(
                (p) => p['id'] == member['user_id'],
                orElse: () => {'name': 'Unknown', 'email': 'No email'},
              );
              
              return ListTile(
                title: Text(profile['name'] ?? 'Unknown'),
                subtitle: Text(profile['email'] ?? 'No email'),
                trailing: Text('Member ID: ${member['user_id']}'),
              );
            },
          );
  }

  Widget _buildLogsTab() {
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            _logs[_logs.length - 1 - index],
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
} 