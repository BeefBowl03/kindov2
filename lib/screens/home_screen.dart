import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/task_card.dart';
import 'task_screen.dart';
import 'shopping_screen.dart';
import 'family_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Get the current view based on bottom navigation
        Widget currentView = _buildDashboardView(appState);
        if (_currentIndex == 1) {
          currentView = const TaskScreen();
        } else if (_currentIndex == 2) {
          currentView = const ShoppingScreen();
        } else if (_currentIndex == 3) {
          currentView = const FamilyScreen();
        }

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: currentView,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                label: 'Shopping',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: 'Family',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardView(AppState appState) {
    final currentUser = appState.currentUser;
    final myPendingTasks = appState.myTasks.where((task) => !task.isCompleted).toList();
    final myCompletedTasks = appState.myTasks.where((task) => task.isCompleted).toList();
    final shoppingItems = appState.shoppingList;
    final uncompletedItems = shoppingItems.where((item) => !item.isPurchased).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KinDo',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        radius: 24,
                        child: Icon(
                          currentUser?.isParent ?? false ? Icons.person : Icons.child_care,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome, ${currentUser?.name ?? 'User'}! 👋',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let\'s get things done together!',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            // Task Summary Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildProgressCard(
                            context,
                            'Pending',
                            myPendingTasks.length.toString(),
                            Icons.assignment_outlined,
                            Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          _buildProgressCard(
                            context,
                            'Completed',
                            myCompletedTasks.length.toString(),
                            Icons.task_alt,
                            Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildProgressCard(
                            context,
                            'Shopping',
                            uncompletedItems.length.toString(),
                            Icons.shopping_cart_outlined,
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildActionButton(
                    context,
                    'Add Task',
                    Icons.add_task,
                    Theme.of(context).colorScheme.primary,
                    () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    'Add Item',
                    Icons.add_shopping_cart,
                    Theme.of(context).colorScheme.secondary,
                    () {
                      setState(() {
                        _currentIndex = 2;
                      });
                    },
                  ),
                  if (appState.isParent) ...[  
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      'Family',
                      Icons.people,
                      Theme.of(context).colorScheme.tertiary,
                      () {
                        setState(() {
                          _currentIndex = 3;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Your Upcoming Tasks Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Upcoming Tasks',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 1; // Switch to Tasks tab
                      });
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            if (myPendingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No upcoming tasks',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myPendingTasks.length,
                itemBuilder: (context, index) {
                  final task = myPendingTasks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TaskCard(
                      task: task,
                      onTap: () => _showTaskDetailsBottomSheet(context, task, appState),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetailsBottomSheet(BuildContext context, TaskModel task, AppState appState) {
    final assignee = appState.family?.getMember(task.assignedTo);
    final creator = appState.family?.getMember(task.createdBy);
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description ?? '');
    String? selectedMemberId = task.assignedTo;
    DateTime selectedDate = task.dueDate ?? DateTime.now();
    int points = task.points;
    bool isEditing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle and Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (appState.isParent)
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.close : Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isEditing) {
                              // Reset values when canceling edit
                              titleController.text = task.title;
                              descriptionController.text = task.description ?? '';
                              selectedMemberId = task.assignedTo;
                              selectedDate = task.dueDate ?? DateTime.now();
                              points = task.points;
                            }
                            isEditing = !isEditing;
                          });
                        },
                      )
                    else
                      const SizedBox(width: 48), // Placeholder for alignment
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (appState.isParent && task.createdBy == appState.currentUserId)
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          appState.deleteTask(task.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task deleted')),
                          );
                        },
                      )
                    else
                      const SizedBox(width: 48), // Placeholder for alignment
                  ],
                ),
              ),
              // Task Status
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.isCompleted ? 'Completed' : 'In Progress',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: task.isCompleted
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (!isEditing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (task.isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.tertiary)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Due: ${task.formattedDueDate}',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: task.isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      if (isEditing)
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                          ),
                        )
                      else
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      const SizedBox(height: 16),
                      // Description
                      if (isEditing)
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: null,
                        )
                      else if (task.description?.isNotEmpty == true)
                        Text(
                          task.description ?? '',
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                        ),
                      const SizedBox(height: 16),
                      // Assignee
                      if (isEditing && appState.family != null)
                        DropdownButtonFormField<String>(
                          value: selectedMemberId,
                          decoration: const InputDecoration(
                            labelText: 'Assign To',
                          ),
                          items: appState.family!.members.map((member) {
                            return DropdownMenuItem<String>(
                              value: member.id,
                              child: Text(member.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedMemberId = value;
                              });
                            }
                          },
                        )
                      else if (assignee != null)
                        _buildDetailRow(
                          context,
                          'Assigned to',
                          assignee.name,
                          Icons.person_outline,
                        ),
                      const SizedBox(height: 16),
                      // Due Date
                      if (isEditing)
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                            ),
                            child: Text(
                              TaskModel(
                                id: '',
                                title: '',
                                description: '',
                                assignedTo: '',
                                createdBy: '',
                                dueDate: selectedDate,
                              ).formattedDueDate,
                            ),
                          ),
                        ),
                      // Points
                      if (isEditing)
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Points',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            points = int.tryParse(value) ?? 0;
                          },
                          controller: TextEditingController(text: points.toString()),
                        )
                      else
                        _buildDetailRow(
                          context,
                          'Points',
                          points.toString(),
                          Icons.star_outline,
                        ),
                      if (creator != null && !isEditing)
                        _buildDetailRow(
                          context,
                          'Created by',
                          creator.name,
                          Icons.create_outlined,
                        ),
                    ],
                  ),
                ),
              ),
              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (task.assignedTo == appState.currentUserId || appState.isParent) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            appState.toggleTaskCompletion(task.id);
                            Navigator.pop(context);
                          },
                          icon: Icon(task.isCompleted ? Icons.refresh : Icons.check_circle),
                          label: Text(task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: task.isCompleted
                                ? Theme.of(context).colorScheme.surfaceVariant
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: task.isCompleted
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                    if (isEditing) ...[
                      if (task.assignedTo == appState.currentUserId || appState.isParent)
                        const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final updatedTask = TaskModel(
                              id: task.id,
                              title: titleController.text,
                              description: descriptionController.text,
                              assignedTo: selectedMemberId!,
                              createdBy: task.createdBy,
                              dueDate: selectedDate,
                              points: points,
                              isCompleted: task.isCompleted,
                            );
                            appState.updateTask(updatedTask);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task updated')),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}