import 'package:flutter/material.dart';
import '../models/canteen_models.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';

class QrScannerDialog extends StatefulWidget {
  final String canteenId;

  const QrScannerDialog({super.key, required this.canteenId});

  static Future<void> show(BuildContext context, {required String canteenId}) {
    return showDialog(
      context: context,
      builder: (ctx) => QrScannerDialog(canteenId: canteenId),
    );
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _onPassScanned(OrderModel order) {
    _orderService.updateOrderStatus(order.id, OrderStatus.completed);
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
            SizedBox(width: 10),
            Text("QR Pass Verified!"),
          ],
        ),
        content: Text(
          "Token ${order.tokenNumber} for ${order.studentName} (${order.totalItemCount} items • ₹${order.totalAmount.toStringAsFixed(0)}) successfully handed over!",
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readyOrders = _orderService
        .getCanteenOrders(widget.canteenId)
        .where((o) => o.status == OrderStatus.ready)
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF14B8A6), size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Camera QR Scanner",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Viewfinder Scanner Box
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF14B8A6), width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner graphics
                    const Icon(Icons.crop_free, size: 200, color: Colors.white24),

                    // Animated Laser Beam
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + (_laserController.value * 170),
                          child: Container(
                            width: 180,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const Positioned(
                      bottom: 12,
                      child: Text(
                        "Point at Student Pass",
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Available Passes Quick Scan List
              const Text(
                "Or Tap Ready Pass to Instant-Scan:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              if (readyOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "No orders currently marked Ready for Pickup.\nMark an order ready in KDS first.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                )
              else
                ...readyOrders.map((o) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: Colors.white.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          o.tokenNumber,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                      title: Text(
                        o.studentName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        "${o.totalItemCount} items • ₹${o.totalAmount.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _onPassScanned(o),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text("Scan Pass"),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
