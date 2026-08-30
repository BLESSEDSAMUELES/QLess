import 'package:flutter/material.dart';
import '../cart/cart_controller.dart';
import '../services/order_service.dart';
import '../order/live_token_tracker_page.dart';
import '../theme/app_theme.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = CartController();
  final OrderService _orderService = OrderService();
  final _instructionsController = TextEditingController();

  String _selectedPickupType = 'asap';
  String _selectedScheduledTime = '1:15 PM (Lunch Break)';
  String _selectedPaymentMethod = 'Campus Wallet';
  bool _isSubmitting = false;

  final List<String> _breakTimes = [
    '1:15 PM (Lunch Break)',
    '1:45 PM (Post Lunch)',
    '3:45 PM (Short Break)',
    '5:00 PM (Evening Break)',
  ];

  @override
  void initState() {
    super.initState();
    cart.addListener(_rebuild);
    _instructionsController.text = cart.specialInstructions;
  }

  @override
  void dispose() {
    cart.removeListener(_rebuild);
    _instructionsController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _placeOrder() async {
    if (cart.isEmpty) return;

    final student = _orderService.currentStudent;
    final total = cart.totalAmount;

    // If paying with campus wallet, check sufficient balance
    if (_selectedPaymentMethod == 'Campus Wallet' && student.walletBalance < total) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text("Insufficient Wallet Balance"),
          content: Text(
            "Your Campus Wallet has ₹${student.walletBalance.toStringAsFixed(0)}, but your order total is ₹${total.toStringAsFixed(0)}.\n\nWould you like to top up ₹200 now or switch payment method?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Change Payment"),
            ),
            ElevatedButton(
              onPressed: () {
                _orderService.topUpWallet(200.0);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("₹200 added to Campus Wallet!"),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
                setState(() {});
              },
              child: const Text("Top Up ₹200"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 600)); // Smooth UX feel

    final newOrder = _orderService.placeOrder(
      canteenId: cart.canteenId ?? 'canteen-01',
      canteenName: cart.canteenName ?? 'Campus Canteen',
      items: cart.items,
      totalAmount: total,
      paymentMethod: _selectedPaymentMethod,
      pickupType: _selectedPickupType,
      scheduledTime: _selectedPickupType == 'scheduled' ? _selectedScheduledTime : null,
      specialInstructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
    );

    cart.clear();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Navigate to Live Token Tracker
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTokenTrackerPage(order: newOrder),
      ),
    );
  }

  Widget _buildRadioDot(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
          width: 2,
        ),
      ),
      child: Center(
        child: isSelected
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = _orderService.currentStudent;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Checkout & Pre-Order"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Clear Cart",
              onPressed: () {
                cart.clear();
              },
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyCart()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Canteen Info Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Ordering from: ${cart.canteenName ?? 'Main Food Court'}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section 1: Itemized Cart List
                  _buildSectionHeader("Your Selected Items", "${cart.totalItemCount} items"),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Veg / Non-Veg Indicator
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: item.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: item.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "₹${item.price.toStringAsFixed(0)} each",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (item.specialInstructions != null &&
                                        item.specialInstructions!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "Note: ${item.specialInstructions}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Stepper
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                                    color: AppTheme.textSecondary,
                                    onPressed: () => cart.decreaseQty(item.menuItemId),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, size: 22),
                                    color: AppTheme.primary,
                                    onPressed: () => cart.addItem(
                                      itemId: item.menuItemId,
                                      name: item.itemName,
                                      price: item.price,
                                      isVeg: item.isVeg,
                                    ),
                                  ),
                                ],
                              ),

                              // Total for item
                              SizedBox(
                                width: 55,
                                child: Text(
                                  "₹${item.total.toStringAsFixed(0)}",
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section 2: Pickup Timing Selection
                  _buildSectionHeader("Pickup Time Slot", "Avoid waiting"),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _selectedPickupType = 'asap'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              children: [
                                _buildRadioDot(_selectedPickupType == 'asap'),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "⚡ ASAP (10 - 15 mins)",
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      Text(
                                        "Kitchen starts preparing immediately",
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 16, color: AppTheme.divider),
                        InkWell(
                          onTap: () => setState(() => _selectedPickupType = 'scheduled'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              children: [
                                _buildRadioDot(_selectedPickupType == 'scheduled'),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "⏰ Schedule for Break Time",
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      Text(
                                        "Fresh & hot right when your bell rings",
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedPickupType == 'scheduled') ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedScheduledTime,
                                items: _breakTimes.map((time) {
                                  return DropdownMenuItem(
                                    value: time,
                                    child: Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedScheduledTime = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section 3: Kitchen Cooking Instructions
                  _buildSectionHeader("Special Instructions for Kitchen", "Optional"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      hintText: "e.g. Less spicy, extra onions, keep drinks cold...",
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section 4: Payment Method Selection
                  _buildSectionHeader("Payment Method", "Instant token pass"),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        // Campus Wallet Option
                        InkWell(
                          onTap: () => setState(() => _selectedPaymentMethod = 'Campus Wallet'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'Campus Wallet'
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'Campus Wallet'
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Text(
                                            "Campus Pay Wallet",
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(Icons.bolt, color: Colors.amber, size: 16),
                                        ],
                                      ),
                                      Text(
                                        "Balance: ₹${student.walletBalance.toStringAsFixed(0)} • 1-tap checkout",
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildRadioDot(_selectedPaymentMethod == 'Campus Wallet'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // UPI Option
                        InkWell(
                          onTap: () => setState(() => _selectedPaymentMethod = 'UPI / GPay'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'UPI / GPay'
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'UPI / GPay'
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, color: Color(0xFF1976D2)),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "UPI (GPay / PhonePe / Paytm)",
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      Text(
                                        "Pay instantly via UPI QR",
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildRadioDot(_selectedPaymentMethod == 'UPI / GPay'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Pay at Counter
                        InkWell(
                          onTap: () => setState(() => _selectedPaymentMethod = 'Counter Cash'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'Counter Cash'
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'Counter Cash'
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_outlined, color: Color(0xFF0F766E)),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pay at Counter on Pickup",
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      Text(
                                        "Cash or Card when receiving food",
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildRadioDot(_selectedPaymentMethod == 'Counter Cash'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section 5: Bill Summary
                  _buildSectionHeader("Bill Summary", "Itemized breakdown"),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildBillRow("Subtotal", "₹${cart.subtotal.toStringAsFixed(0)}"),
                        const SizedBox(height: 8),
                        _buildBillRow("Platform & Digital Queue Fee", "₹${cart.taxesAndConvenience.toStringAsFixed(0)}"),
                        const Divider(height: 20, color: AppTheme.divider),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Payable",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              "₹${cart.totalAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Place Pre-Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  "Confirm Pre-Order • ₹${cart.totalAmount.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 70,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your Cart is Empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Explore canteen menus and pre-order your favorite food without waiting in queues!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text("Browse Canteen Menus"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
