import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/task_card.dart';
import 'package:uuid/uuid.dart';

class TaskScreen extends StatefulWidget {
  final int initialTabIndex;

  const TaskScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterValue = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Tasks',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              tabs: const [
                Tab(text: 'My Tasks'),
                Tab(text: 'Family Tasks'),
              ],
            ),
            actions: [
              if (appState.isParent || _tabController.index == 0)
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _showAddTaskBottomSheet(context),
                ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMyTasksTab(appState),
              _buildFamilyTasksTab(appState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyTasksTab(AppState appState) {
    final myTasks = appState.myTasks;
    List<TaskModel> filteredTasks = myTasks;

    // Apply filtering
    if (_filterValue == 'complete') {
      filteredTasks = myTasks.where((task) => task.isCompleted).toList();
    } else if (_filterValue == 'incomplete') {
      filteredTasks = myTasks.where((task) => !task.isCompleted).toList();
    } else if (_filterValue == 'all') {
      filteredTasks = myTasks;
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: filteredTasks.isEmpty
              ? EmptyStateWidget(
                  message: 'No tasks assigned to you yet',
                  icon: Icons.assignment_outlined,
                  actionLabel: 'Add Task',
                  onAction: () => _showAddTaskBottomSheet(context),
                )
              : _buildTaskList(filteredTasks, appState),
        ),
      ],
    );
  }

  Widget _buildFamilyTasksTab(AppState appState) {
    final allTasks = appState.tasks;
    List<TaskModel> filteredTasks = allTasks;

    // Apply filtering
    if (_filterValue == 'complete') {
      filteredTasks = allTasks.where((task) => task.isCompleted).toList();
    } else if (_filterValue == 'incomplete') {
      filteredTasks = allTasks.where((task) => !task.isCompleted).toList();
    } else if (_filterValue == 'all') {
      filteredTasks = allTasks;
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: filteredTasks.isEmpty
              ? EmptyStateWidget(
                  message: 'No family tasks yet',
                  icon: Icons.people_outline,
                  actionLabel: appState.isParent ? 'Add Task' : null,
                  onAction: appState.isParent ? () => _showAddTaskBottomSheet(context) : null,
                )
              : _buildTaskList(filteredTasks, appState),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'complete'),
            const SizedBox(width: 8),
            _buildFilterChip('In Progress', 'incomplete'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterValue == value;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _filterValue = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks, AppState appState) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () => _showTaskDetailsBottomSheet(context, task, appState),
        );
      },
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedMemberId = appState.currentUserId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int points = 0;

    if (selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a family member')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                KinDoTextField(
                  label: 'Title',
                  hint: 'Enter task title',
                  controller: titleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                KinDoTextField(
                  label: 'Description',
                  hint: 'Enter task description (optional)',
                  controller: descriptionController,
                  isMultiline: true,
                ),
                const SizedBox(height: 16),
                if (appState.family != null) ...[  
                  Text(
                    'Assign To',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMemberId,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        items: appState.family!.members.map((member) {
                          return DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(
                              member.name,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMemberId = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Due Date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM dd, yyyy').format(selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                KinDoButton(
                  text: 'Create Task',
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }

                    final newTask = TaskModel(
                      id: const Uuid().v4(),
                      title: titleController.text,
                      description: descriptionController.text,
                      assignedTo: selectedMemberId ?? appState.currentUserId!,
                      createdBy: appState.currentUserId!,
                      dueDate: selectedDate,
                      points: points,
                    );

                    appState.addTask(newTask);
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Task created successfully'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                  isPrimary: true,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetailsBottomSheet(BuildContext context, TaskModel task, AppState appState) {
    final FamilyMember? assignee = appState.family?.getMember(task.assignedTo);
    final FamilyMember? creator = appState.family?.getMember(task.createdBy);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            // Handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
            // Task Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            // Task Description
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                ),
              ),
            // Assignment Details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned to',
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignee?.name ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created by',
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          creator?.name ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (task.assignedTo == appState.currentUserId || appState.isParent) ...[  
                    Expanded(
                      child: KinDoButton(
                        text: task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                        onPressed: () {
                          appState.toggleTaskCompletion(task.id);
                          Navigator.pop(context);
                        },
                        isPrimary: !task.isCompleted,
                        icon: task.isCompleted ? Icons.refresh : Icons.check_circle,
                      ),
                    ),
                  ],
                  if (appState.isParent && task.createdBy == appState.currentUserId) ...[  
                    if (task.assignedTo == appState.currentUserId || appState.isParent) 
                      const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        // Delete task
                        Navigator.pop(context);
                        appState.deleteTask(task.id);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Task deleted'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}