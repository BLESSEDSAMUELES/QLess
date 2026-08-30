import 'package:flutter/material.dart';
import '../models/canteen_models.dart';
import '../cart/cart_controller.dart';
import '../theme/app_theme.dart';

class ItemDetailBottomSheet extends StatefulWidget {
  final MenuItem item;
  final String canteenName;

  const ItemDetailBottomSheet({
    super.key,
    required this.item,
    required this.canteenName,
  });

  static Future<void> show(
    BuildContext context, {
    required MenuItem item,
    required String canteenName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ItemDetailBottomSheet(
        item: item,
        canteenName: canteenName,
      ),
    );
  }

  @override
  State<ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends State<ItemDetailBottomSheet> {
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existingQty = CartController().getItemQuantity(widget.item.id);
    if (existingQty > 0) {
      _quantity = existingQty;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addToCart() {
    final cart = CartController();
    final success = cart.addItem(
      menuItem: widget.item,
      canteenName: widget.canteenName,
      quantity: _quantity,
      specialInstructions: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (!success) {
      // Canteen conflict dialog
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text("Replace Cart Items?"),
          content: Text(
            "Your cart contains items from ${cart.canteenName}. You can only pre-order from one canteen at a time.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                cart.forceAddItem(
                  menuItem: widget.item,
                  canteenName: widget.canteenName,
                  quantity: _quantity,
                  specialInstructions: _notesController.text.trim().isNotEmpty
                      ? _notesController.text.trim()
                      : null,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${widget.item.name} added to cart!"),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
              child: const Text("Clear & Add"),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added $_quantity x ${widget.item.name} to cart"),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final total = item.price * _quantity;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Top Badges (Veg/Non-Veg + Category + Prep Time)
            Row(
              children: [
                // Veg / Non-Veg symbol
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: item.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.isVeg ? 'Pure Veg' : 'Non-Veg',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '~${item.prepTimeMinutes} mins prep',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Nutrition & Spiciness Pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.calories != null)
                  _buildTag(Icons.local_fire_department_outlined, item.calories!, Colors.orange),
                _buildTag(
                  Icons.whatshot,
                  item.spicyLevel == 0
                      ? 'Mild Spice'
                      : item.spicyLevel == 1
                          ? 'Medium Spice'
                          : 'Spicy 🔥',
                  item.spicyLevel == 2 ? Colors.red : Colors.amber.shade800,
                ),
                if (item.isBestSeller)
                  _buildTag(Icons.star_rounded, 'Campus Bestseller', Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(color: AppTheme.divider),
            const SizedBox(height: 12),

            // Special Instructions Field
            const Text(
              "Special Cooking Requests / Notes",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: "e.g. Less spicy, extra sauce on side, no ice...",
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quantity Stepper + Add Button Bar
            Row(
              children: [
                // Stepper
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        color: AppTheme.primary,
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Add to Cart Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: item.isAvailable ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.isAvailable ? 'Add to Cart' : 'Sold Out',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
