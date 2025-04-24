import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/family_model.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';


class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final family = appState.family;
        if (family == null) {
          return const Center(child: Text('No family found'));
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                family.name,
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (appState.isParent)
                                IconButton(
                                  icon: const Icon(Icons.person_add, color: Colors.white),
                                  onPressed: () => _showAddFamilyMemberBottomSheet(context),
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
    bool isParent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Family Member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              KinDoTextField(
                controller: nameController,
                label: 'Name',
                hint: 'Enter name',
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => SwitchListTile(
                  title: const Text('Is Parent?'),
                  value: isParent,
                  onChanged: (value) {
                    setState(() {
                      isParent = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              KinDoButton(
                text: 'Add Member',
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    final newMember = FamilyMember(
                      name: nameController.text,
                      role: isParent ? FamilyRole.parent : FamilyRole.child,
                    );
                    appState.addFamilyMember(newMember);
                    Navigator.pop(context);
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
    final nameController = TextEditingController(text: member.name);
    bool isParent = member.isParent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Family Member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              KinDoTextField(
                controller: nameController,
                label: 'Name',
                hint: 'Enter name',
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => SwitchListTile(
                  title: const Text('Is Parent?'),
                  value: isParent,
                  onChanged: (value) {
                    setState(() {
                      isParent = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              KinDoButton(
                text: 'Save Changes',
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    final updatedMember = member.copyWith(
                      name: nameController.text,
                      role: isParent ? FamilyRole.parent : FamilyRole.child,
                    );
                    appState.updateFamilyMember(updatedMember);
                    Navigator.pop(context);
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
            onPressed: () {
              Navigator.pop(context);
              appState.deleteFamilyMember(member.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Family member removed'),
                  duration: Duration(seconds: 2),
                ),
              );
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