import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/family_model.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';


class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final family = appState.family;
        if (family == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Family Found',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You should already have a family from registration. Please contact support if this is an error.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Family Banner
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Banner Image
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              family.name,
                              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Members: ${family.members.length}',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Top Bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PopupMenuButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                itemBuilder: (context) => [
                                  if (appState.isParent) ...[
                                    const PopupMenuItem(
                                      value: 'profile',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person),
                                          SizedBox(width: 8),
                                          Text('My Profile'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout),
                                        SizedBox(width: 8),
                                        Text('Logout'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'profile') {
                                    Navigator.pushNamed(context, '/profile');
                                  } else if (value == 'logout') {
                                    appState.signOut();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Current User Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Current User',
                                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                                Text(
                                  appState.currentUser?.name ?? 'Unknown',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  appState.currentUser?.isParent ?? false ? 'Parent' : 'Child',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Family Members Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Family Members',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (appState.isParent)
                        TextButton.icon(
                          onPressed: () => _showAddFamilyMemberBottomSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                    ],
                  ),
                ),
              ),
              // Members List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = family.members[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: member.isParent
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              color: member.isParent
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          title: Text(member.name),
                          subtitle: Text(member.isParent ? 'Parent' : 'Child'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (appState.isParent)
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () => _showEditFamilyMemberBottomSheet(context, member),
                                ),
                              if (appState.isParent && 
                                  !(member.isParent && family.parents.length <= 1))
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () => _showDeleteConfirmationDialog(context, appState, member),
                                ),
                            ],
                          ),
                          onTap: () => _switchUser(context, appState, member),
                        ),
                      ),
                    );
                  },
                  childCount: family.members.length,
                ),
              ),
              // Bottom Padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          ),
        );
      },
    );
  }

  void _showAddFamilyMemberBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    bool isParent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Family Member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Parent?'),
                value: isParent,
                onChanged: (value) => setModalState(() => isParent = value),
              ),
              const SizedBox(height: 16),
              KinDoButton(
                text: 'Send Invitation',
                onPressed: () async {
                  if (nameController.text.isNotEmpty && 
                      emailController.text.isNotEmpty) {
                    try {
                      final appState = Provider.of<AppState>(context, listen: false);
                      final family = appState.family;
                      if (family == null) return;

                      final message = await appState.createFamilyMember(
                        email: emailController.text,
                        name: nameController.text,
                        isParent: isParent,
                      );
                      
                      if (context.mounted) {
                        if (message.contains('already a member')) {
                          // Simple dialog for existing members
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Already a Member'),
                              content: Text(message),
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Force a modal dialog with credentials
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              return WillPopScope(
                                onWillPop: () async => false, // Prevent back button from closing dialog
                                child: AlertDialog(
                                  title: const Text(
                                    'New User Created - Credentials',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Please share these credentials with the user:',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.maxFinite,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                            ),
                                          ),
                                          child: SelectableText(
                                            message,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'The user must change their password after first login.',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Theme.of(context).colorScheme.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        Navigator.of(context).pop(); // Close the invite dialog
                                      },
                                      child: const Text(
                                        'OK, I WILL SHARE THIS',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  actionsAlignment: MainAxisAlignment.center,
                                  actionsPadding: const EdgeInsets.only(bottom: 16),
                                ),
                              );
                            },
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error'),
                            content: Text('Error adding member: ${e.toString()}'),
                            actions: [
                              FilledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  }
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFamilyMemberBottomSheet(BuildContext context, FamilyMember member) {
    // Don't allow changing role of the last parent
    final appState = Provider.of<AppState>(context, listen: false);
    final isLastParent = member.isParent && appState.family?.parents.length == 1;

    final nameController = TextEditingController(text: member.name);
    bool isParent = member.isParent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Family Member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Parent?'),
                value: isParent,
                onChanged: isLastParent ? null : (value) => setModalState(() => isParent = value),
                subtitle: isLastParent 
                  ? const Text('Cannot change role of the last parent', 
                      style: TextStyle(color: Colors.red))
                  : null,
              ),
              const SizedBox(height: 16),
              KinDoButton(
                text: 'Save Changes',
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    try {
                      final updatedMember = member.copyWith(
                        name: nameController.text,
                        role: isParent ? FamilyRole.parent : FamilyRole.child,
                      );
                      await appState.updateFamilyMember(updatedMember);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Member updated successfully'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating member: ${e.toString()}'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, AppState appState, FamilyMember member) {
    // Don't allow deleting the last parent
    if (member.isParent && appState.family?.parents.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last parent in the family'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Don't allow deleting yourself
    if (member.id == appState.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete your own account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to remove ${member.name} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await appState.removeFamilyMember(member.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Family member removed successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing member: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _switchUser(BuildContext context, AppState appState, FamilyMember member) {
    if (member.id == appState.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already logged in as ${member.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch User'),
        content: Text('Do you want to switch to ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              appState.switchUser(member.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to ${member.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}