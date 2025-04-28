import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/task_model.dart';
import '../models/family_model.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/task_card.dart';
import 'package:uuid/uuid.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  String _filterValue = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Apply filtering for the list only
        List<ShoppingItem> items = appState.shoppingList;
        if (_filterValue == 'purchased') {
          items = items.where((item) => item.isPurchased).toList();
        } else if (_filterValue == 'pending') {
          items = items.where((item) => !item.isPurchased).toList();
        }

        // Get total counts for banner (unfiltered)
        final totalItems = appState.shoppingList;
        final pendingCount = totalItems.where((item) => !item.isPurchased).length;
        final purchasedCount = totalItems.where((item) => item.isPurchased).length;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Shopping List Banner
              SliverToBoxAdapter(
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shopping List',
                                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  size: 32,
                                ),
                                onPressed: () => _showAddItemSheet(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Keep track of your family\'s shopping needs',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.8),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              _buildStatCard(
                                context,
                                'Pending',
                                pendingCount.toString(),
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                context,
                                'Purchased',
                                purchasedCount.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Filter Chips
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),
              // Shopping Items List
              if (items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items in shopping list',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 24),
                        KinDoButton(
                          text: 'Add Item',
                          onPressed: () => _showAddItemSheet(context),
                          icon: Icons.add,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return ShoppingItemCard(
                        item: item,
                        onTap: () => _showEditItemSheet(context, item),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
            ],
          ),
          floatingActionButton: items.isNotEmpty ? FloatingActionButton(
            onPressed: () => _showAddItemSheet(context),
            child: const Icon(Icons.add),
          ) : null,
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
            _buildFilterChip('Pending', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Purchased', 'purchased'),
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
                ? theme.colorScheme.onSecondary
                : theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.secondary,
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

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _AddShoppingItemSheet(),
      ),
    );
  }

  void _showEditItemSheet(BuildContext context, ShoppingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _EditShoppingItemSheet(item: item),
      ),
    );
  }
}

class _AddShoppingItemSheet extends StatefulWidget {
  const _AddShoppingItemSheet();

  @override
  State<_AddShoppingItemSheet> createState() => _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends State<_AddShoppingItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Shopping Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                KinDoTextField(
                  label: 'Item Name',
                  controller: _titleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                ),
                KinDoTextField(
                  label: 'Description (Optional)',
                  controller: _descriptionController,
                  maxLines: 2,
                ),
                KinDoTextField(
                  label: 'Quantity',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a quantity';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity < 1) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KinDoButton(
            text: 'Add Item',
            onPressed: _handleSubmit,
            isFullWidth: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;
      if (currentUser == null) return;

      final item = ShoppingItem(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        quantity: int.parse(_quantityController.text),
        addedBy: currentUser.id,
      );

      appState.addShoppingItem(item);
      Navigator.pop(context);
    }
  }
}

class _EditShoppingItemSheet extends StatefulWidget {
  final ShoppingItem item;

  const _EditShoppingItemSheet({required this.item});

  @override
  State<_EditShoppingItemSheet> createState() => _EditShoppingItemSheetState();
}

class _EditShoppingItemSheetState extends State<_EditShoppingItemSheet> {
  late final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.item.title);
  late final _descriptionController = TextEditingController(text: widget.item.description ?? '');
  late final _quantityController = TextEditingController(text: widget.item.quantity.toString());

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Shopping Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                KinDoTextField(
                  label: 'Item Name',
                  controller: _titleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                ),
                KinDoTextField(
                  label: 'Description (Optional)',
                  controller: _descriptionController,
                  maxLines: 2,
                ),
                KinDoTextField(
                  label: 'Quantity',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a quantity';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity < 1) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KinDoButton(
                  text: 'Delete',
                  onPressed: () => _showDeleteConfirmation(context),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KinDoButton(
                  text: 'Save',
                  onPressed: _handleSubmit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${widget.item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              appState.deleteShoppingItem(widget.item.id);
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close edit sheet
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

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);

      final updatedItem = widget.item.copyWith(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        quantity: int.parse(_quantityController.text),
      );

      appState.updateShoppingItem(updatedItem);
      Navigator.pop(context);
    }
  }
}