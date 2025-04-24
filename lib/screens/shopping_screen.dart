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
        // Apply filtering
        List<ShoppingItem> items = appState.shoppingList;
        if (_filterValue == 'purchased') {
          items = items.where((item) => item.isPurchased).toList();
        } else if (_filterValue == 'pending') {
          items = items.where((item) => !item.isPurchased).toList();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Shopping List',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _showAddItemBottomSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: items.isEmpty
                    ? EmptyStateWidget(
                        message: 'Your shopping list is empty',
                        icon: Icons.shopping_cart_outlined,
                        actionLabel: 'Add Item',
                        onAction: () => _showAddItemBottomSheet(context),
                      )
                    : _buildShoppingList(items, appState),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddItemBottomSheet(context),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        );
      },
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

  Widget _buildShoppingList(List<ShoppingItem> items, AppState appState) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ShoppingItemCard(
          item: item,
          onEdit: () => _showEditItemBottomSheet(context, item),
          onDelete: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Item'),
                content: Text('Are you sure you want to delete "${item.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      appState.deleteShoppingItem(item.id);
                      Navigator.pop(context);
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Item deleted'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemBottomSheet(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'Add to Shopping List',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              KinDoTextField(
                label: 'Item Name',
                hint: 'Enter item name',
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              KinDoTextField(
                label: 'Quantity',
                hint: 'How many? (e.g., 2, 1 gallon, 500g)',
                controller: quantityController,
              ),
              const SizedBox(height: 24),
              KinDoButton(
                text: 'Add Item',
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an item name')),
                    );
                    return;
                  }

                  final newItem = ShoppingItem(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    quantity: int.tryParse(quantityController.text) ?? 1,
                    addedBy: appState.currentUserId!,
                  );

                  appState.addShoppingItem(newItem);
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item added to shopping list'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                },
                isPrimary: true,
                isFullWidth: true,
                icon: Icons.add_shopping_cart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditItemBottomSheet(BuildContext context, ShoppingItem item) {
    final appState = Provider.of<AppState>(context, listen: false);
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'Edit Shopping Item',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              KinDoTextField(
                label: 'Item Name',
                hint: 'Enter item name',
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              KinDoTextField(
                label: 'Quantity',
                hint: 'How many? (e.g., 2, 1 gallon, 500g)',
                controller: quantityController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: item.isPurchased,
                    onChanged: (value) {
                      appState.toggleShoppingItemPurchased(item.id);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mark as purchased',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              KinDoButton(
                text: 'Update Item',
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an item name')),
                    );
                    return;
                  }

                  final updatedItem = item.copyWith(
                    name: nameController.text,
                    quantity: int.tryParse(quantityController.text) ?? 1,
                  );

                  appState.updateShoppingItem(updatedItem);
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item updated'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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
    );
  }
}