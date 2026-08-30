import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/canteen_models.dart';
import '../services/order_service.dart';
import '../widgets/receipt_modal.dart';
import '../theme/app_theme.dart';

class LiveTokenTrackerPage extends StatefulWidget {
  final OrderModel order;

  const LiveTokenTrackerPage({super.key, required this.order});

  @override
  State<LiveTokenTrackerPage> createState() => _LiveTokenTrackerPageState();
}

class _LiveTokenTrackerPageState extends State<LiveTokenTrackerPage> {
  final OrderService _orderService = OrderService();
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _orderService.addListener(_onOrderUpdate);
  }

  @override
  void dispose() {
    _orderService.removeListener(_onOrderUpdate);
    super.dispose();
  }

  void _onOrderUpdate() {
    final updated = _orderService.orders.firstWhere(
      (o) => o.id == _currentOrder.id,
      orElse: () => _currentOrder,
    );
    if (mounted) {
      setState(() {
        _currentOrder = updated;
      });
    }
  }

  void _advanceDemoStatus() {
    final nextStatus = _getNextStatus(_currentOrder.status);
    if (nextStatus != null) {
      _orderService.updateOrderStatus(_currentOrder.id, nextStatus);
    }
  }

  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.placed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.completed;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final queuePos = _orderService.getQueuePosition(_currentOrder.id, _currentOrder.canteenId);
    final servingToken = _orderService.getCurrentlyServingToken(_currentOrder.canteenId);
    final isReady = _currentOrder.status == OrderStatus.ready;
    final isCompleted = _currentOrder.status == OrderStatus.completed;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Live Queue & Token Pass"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Canteen Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentOrder.canteenName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Ordered at ${DateFormat('h:mm a').format(_currentOrder.createdAt)} • ${_currentOrder.pickupType == 'asap' ? 'ASAP Pickup' : 'Scheduled ${_currentOrder.scheduledTime ?? ''}'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Token & Live Status Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isReady
                    ? AppTheme.readyStatusGradient
                    : isCompleted
                        ? const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)])
                        : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: (isReady ? AppTheme.successGreen : AppTheme.primary).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReady
                            ? Icons.notifications_active_rounded
                            : Icons.confirmation_number_outlined,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isReady
                            ? "FOOD READY FOR PICKUP!"
                            : isCompleted
                                ? "ORDER COLLECTED"
                                : "YOUR QUEUE TOKEN",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Giant Token Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Text(
                      _currentOrder.tokenNumber,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Queue Position & Estimates
                  if (!isCompleted && !isReady) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHeroStat(
                          icon: Icons.people_outline,
                          title: "Queue Position",
                          value: queuePos == 0 ? "You're next!" : "$queuePos ahead",
                        ),
                        Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3)),
                        _buildHeroStat(
                          icon: Icons.campaign_outlined,
                          title: "Now Serving",
                          value: servingToken,
                        ),
                        Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3)),
                        _buildHeroStat(
                          icon: Icons.timer_outlined,
                          title: "Est. Ready",
                          value: "~${_getRemainingMinutes(_currentOrder.estimatedReadyTime)}m",
                        ),
                      ],
                    ),
                  ] else if (isReady) ...[
                    const Text(
                      "Please proceed to counter with your QR pass below! 🔔",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "Thank you for dining with QLess! Hope you enjoyed the food.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4-Step Queue Progress Tracker
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Progress",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildProgressStep(
                    stepNumber: 1,
                    title: "Order Placed",
                    subtitle: "Received by canteen kitchen",
                    isDone: _currentOrder.status.index >= OrderStatus.placed.index,
                    isActive: _currentOrder.status == OrderStatus.placed,
                  ),
                  _buildProgressStep(
                    stepNumber: 2,
                    title: "Cooking in Kitchen",
                    subtitle: "Chef is preparing your fresh meal",
                    isDone: _currentOrder.status.index >= OrderStatus.preparing.index,
                    isActive: _currentOrder.status == OrderStatus.preparing,
                  ),
                  _buildProgressStep(
                    stepNumber: 3,
                    title: "Ready for Pickup",
                    subtitle: "Token called! Pick up at counter",
                    isDone: _currentOrder.status.index >= OrderStatus.ready.index,
                    isActive: _currentOrder.status == OrderStatus.ready,
                  ),
                  _buildProgressStep(
                    stepNumber: 4,
                    title: "Collected & Completed",
                    subtitle: "Food handed over",
                    isDone: _currentOrder.status.index >= OrderStatus.completed.index,
                    isActive: _currentOrder.status == OrderStatus.completed,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Digital QR Pickup Pass Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        "Digital Pickup Pass",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Token: ${_currentOrder.tokenNumber}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: QrImageView(
                      data: "QLESS:${_currentOrder.id}:${_currentOrder.tokenNumber}",
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Show this QR code or Token #${_currentOrder.tokenNumber} to counter staff for quick collection",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Itemized Order Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Items",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._currentOrder.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: it.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: it.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "${it.quantity}x ${it.itemName}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            "₹${it.total.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_currentOrder.specialInstructions != null &&
                      _currentOrder.specialInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Note: ${_currentOrder.specialInstructions}",
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 24, color: AppTheme.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Paid",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        "₹${_currentOrder.totalAmount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Action Buttons (Receipt + Cancellation)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ReceiptModal.show(context, order: _currentOrder);
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text("Digital Receipt"),
                  ),
                ),
                if (_currentOrder.status == OrderStatus.placed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Cancel Pre-Order?"),
                            content: Text(
                              "Are you sure you want to cancel Token ${_currentOrder.tokenNumber}?\n\nIf you paid with Campus Wallet, ₹${_currentOrder.totalAmount.toStringAsFixed(0)} will be immediately refunded to your balance.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("No, Keep Order"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _orderService.cancelOrder(_currentOrder.id);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Order cancelled. Amount refunded to wallet! 💳"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                child: const Text("Yes, Cancel"),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
                      label: const Text("Cancel & Refund", style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Demo Simulation Button (Allows instant preview of status progression)
            if (!isCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      "⚡ Demo Mode Quick Simulator",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _advanceDemoStatus,
                      icon: const Icon(Icons.fast_forward_rounded, size: 18),
                      label: Text(
                        _currentOrder.status == OrderStatus.placed
                            ? "Simulate Kitchen Cooking"
                            : _currentOrder.status == OrderStatus.preparing
                                ? "Simulate Food Ready 🔔"
                                : "Simulate Food Collected",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  int _getRemainingMinutes(DateTime estimatedReady) {
    final diff = estimatedReady.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff : 2;
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    final color = isDone
        ? AppTheme.primary
        : AppTheme.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone ? color : AppTheme.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? color : AppTheme.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        "$stepNumber",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? color : AppTheme.divider,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
