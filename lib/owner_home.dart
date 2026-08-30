import 'package:flutter/material.dart';
import 'models/canteen_models.dart';
import 'services/order_service.dart';
import 'role_selection_page.dart';
import 'widgets/qr_scanner_dialog.dart';
import 'theme/app_theme.dart';

class OwnerHome extends StatefulWidget {
  final Canteen canteen;

  OwnerHome({super.key, Canteen? canteen, String? canteenName})
      : canteen = canteen ??
            Canteen(
              id: 'canteen-01',
              name: canteenName ?? 'Main Food Court (Central)',
              code: 'MAIN101',
            );

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  int _currentTabIndex = 0;
  final OrderService _orderService = OrderService();

  // KDS Filter
  String _kdsFilter = 'active'; // 'all', 'active', 'placed', 'preparing', 'ready', 'completed'

  // Token Verification Controller
  final _tokenVerifyController = TextEditingController();

  // Menu Search
  String _menuSearchQuery = '';
  final _menuSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _orderService.addListener(_rebuild);
  }

  @override
  void dispose() {
    _orderService.removeListener(_rebuild);
    _tokenVerifyController.dispose();
    _menuSearchController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildKdsTab(),
          _buildTokenCallingTab(),
          _buildMenuStockTab(),
          _buildAnalyticsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.kitchen_rounded, color: Color(0xFF0F766E), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.canteen.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  "Kitchen Terminal • ${widget.canteen.code}",
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
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          tooltip: "Sign Out",
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  // ================= 1. KITCHEN DISPLAY SYSTEM (KDS) =================

  Widget _buildKdsTab() {
    final allCanteenOrders = _orderService.getCanteenOrders(widget.canteen.id);

    final filteredOrders = allCanteenOrders.where((order) {
      if (_kdsFilter == 'active') {
        return order.status != OrderStatus.completed && order.status != OrderStatus.cancelled;
      }
      if (_kdsFilter == 'placed') return order.status == OrderStatus.placed;
      if (_kdsFilter == 'preparing') return order.status == OrderStatus.preparing;
      if (_kdsFilter == 'ready') return order.status == OrderStatus.ready;
      if (_kdsFilter == 'completed') return order.status == OrderStatus.completed;
      return true;
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Filter Chips Strip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Live Kitchen Kanban",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${allCanteenOrders.where((o) => o.status != OrderStatus.completed).length} in queue",
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // KDS Filter Horizontal Scroll
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildKdsFilterChip('active', 'Active Orders (${_getCount(allCanteenOrders, 'active')})'),
                        const SizedBox(width: 8),
                        _buildKdsFilterChip('placed', 'Incoming (${_getCount(allCanteenOrders, 'placed')})'),
                        const SizedBox(width: 8),
                        _buildKdsFilterChip('preparing', 'Cooking (${_getCount(allCanteenOrders, 'preparing')})'),
                        const SizedBox(width: 8),
                        _buildKdsFilterChip('ready', 'Ready for Pickup (${_getCount(allCanteenOrders, 'ready')})'),
                        const SizedBox(width: 8),
                        _buildKdsFilterChip('completed', 'Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders List
          if (filteredOrders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 60, color: Color(0xFF0F766E)),
                    const SizedBox(height: 14),
                    const Text(
                      "No orders in this queue",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "New incoming pre-orders will appear here instantly",
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = filteredOrders[index];
                    return _buildKdsOrderCard(order);
                  },
                  childCount: filteredOrders.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getCount(List<OrderModel> orders, String filter) {
    if (filter == 'active') {
      return orders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).length;
    }
    if (filter == 'placed') return orders.where((o) => o.status == OrderStatus.placed).length;
    if (filter == 'preparing') return orders.where((o) => o.status == OrderStatus.preparing).length;
    if (filter == 'ready') return orders.where((o) => o.status == OrderStatus.ready).length;
    return orders.length;
  }

  Widget _buildKdsFilterChip(String key, String label) {
    final isSelected = _kdsFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        color: isSelected ? const Color(0xFF0F766E) : AppTheme.textPrimary,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _kdsFilter = key);
      },
    );
  }

  Widget _buildKdsOrderCard(OrderModel order) {
    final isReady = order.status == OrderStatus.ready;
    final isPreparing = order.status == OrderStatus.preparing;
    final isPlaced = order.status == OrderStatus.placed;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isReady
              ? AppTheme.successGreen
              : isPreparing
                  ? Colors.amber.shade700
                  : AppTheme.border,
          width: isReady || isPreparing ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Big Token + Elapsed Time + Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isReady
                        ? AppTheme.successGreen
                        : isPreparing
                            ? const Color(0xFFF59E0B)
                            : AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.tokenNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _getElapsedTime(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: order.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Student Name & Pickup Slot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Student: ${order.studentName} (${order.studentId})",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.pickupType == 'asap' ? '⚡ ASAP' : '⏰ ${order.scheduledTime ?? 'Scheduled'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Itemized List for Kitchen Staff
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                        const SizedBox(width: 8),
                        Text(
                          "${it.quantity}x",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            it.itemName,
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
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Chef Special Instructions Alert
            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Chef Note: ${order.specialInstructions}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Order Action Progression Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Paid: ₹${order.totalAmount.toStringAsFixed(0)} • ${order.paymentMethod}",
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),

                // Action Button based on status
                if (isPlaced)
                  ElevatedButton.icon(
                    onPressed: () {
                      _orderService.updateOrderStatus(order.id, OrderStatus.preparing);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Token ${order.tokenNumber} marked as In Preparation 🍳"),
                          backgroundColor: Colors.amber.shade800,
                        ),
                      );
                    },
                    icon: const Icon(Icons.outdoor_grill_rounded, size: 16),
                    label: const Text("Accept & Cook"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  )
                else if (isPreparing)
                  ElevatedButton.icon(
                    onPressed: () {
                      _orderService.updateOrderStatus(order.id, OrderStatus.ready);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Token ${order.tokenNumber} is READY FOR PICKUP! 🔔"),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_rounded, size: 16),
                    label: const Text("Call Token / Mark Ready"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  )
                else if (isReady)
                  ElevatedButton.icon(
                    onPressed: () {
                      _orderService.updateOrderStatus(order.id, OrderStatus.completed);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Token ${order.tokenNumber} collected & completed! ✅"),
                          backgroundColor: AppTheme.textPrimary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text("Hand Over / Deliver"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Completed", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getElapsedTime(DateTime time) {
    final diff = DateTime.now().difference(time).inMinutes;
    if (diff <= 0) return "Just now";
    return "${diff}m ago";
  }

  // ================= 2. TOKEN CALLING BOARD & VERIFICATION =================

  Widget _buildTokenCallingTab() {
    final allCanteenOrders = _orderService.getCanteenOrders(widget.canteen.id);
    final readyOrders = allCanteenOrders.where((o) => o.status == OrderStatus.ready).toList();
    final preparingOrders = allCanteenOrders.where((o) => o.status == OrderStatus.preparing).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Token Calling & Verification",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Counter pickup verification and audio-visual token board",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Token Verification Scanner Card
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
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0F766E), size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Verify Student Token Pass",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tokenVerifyController,
                          decoration: const InputDecoration(
                            hintText: "Enter Token (e.g. TK-108)",
                            prefixIcon: Icon(Icons.tag),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _verifyAndCompleteToken,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        child: const Text("Verify Pass"),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          padding: const EdgeInsets.all(14),
                        ),
                        tooltip: "Scan Camera QR",
                        onPressed: () => QrScannerDialog.show(context, canteenId: widget.canteen.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ready for Collection LED Board
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active_rounded, color: Colors.amberAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "READY AT COUNTER NOW",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (readyOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        "No orders currently waiting for collection",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: readyOrders.map((o) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                o.tokenNumber,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF064E3B),
                                ),
                              ),
                              Text(
                                o.studentName.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cooking in Kitchen Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Currently Cooking in Kitchen",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (preparingOrders.isEmpty)
                    const Text(
                      "Kitchen is clear. No active meals being cooked.",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    )
                  else
                    ...preparingOrders.map((o) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            o.tokenNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        title: Text("${o.totalItemCount} items for ${o.studentName}"),
                        subtitle: Text("Cooking since ${_getElapsedTime(o.createdAt)}"),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _orderService.updateOrderStatus(o.id, OrderStatus.ready);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text("Call 🔔", style: TextStyle(fontSize: 12)),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyAndCompleteToken() {
    final token = _tokenVerifyController.text.trim().toUpperCase();
    if (token.isEmpty) return;

    final allOrders = _orderService.getCanteenOrders(widget.canteen.id);
    final match = allOrders.firstWhere(
      (o) => o.tokenNumber.toUpperCase() == token,
      orElse: () => allOrders.firstWhere(
        (o) => o.id == token,
        orElse: () => OrderModel(
          id: '',
          tokenNumber: '',
          canteenId: '',
          canteenName: '',
          studentId: '',
          studentName: '',
          items: [],
          totalAmount: 0,
          createdAt: DateTime.now(),
          estimatedReadyTime: DateTime.now(),
        ),
      ),
    );

    if (match.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Token '$token' not found for ${widget.canteen.name}"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _orderService.updateOrderStatus(match.id, OrderStatus.completed);
    _tokenVerifyController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppTheme.successGreen),
            SizedBox(width: 8),
            Text("Pass Verified!"),
          ],
        ),
        content: Text(
          "Token ${match.tokenNumber} for ${match.studentName} verified & handed over successfully!",
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

  // ================= 3. MENU & STOCK MANAGEMENT (CRUD) =================

  Widget _buildMenuStockTab() {
    final menuItems = _orderService.getMenuItemsForCanteen(widget.canteen.id);
    final filtered = menuItems.where((item) {
      if (_menuSearchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_menuSearchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Menu & Stock Manager",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            "Live stock toggle & menu editing",
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddNewItemDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add Dish"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search field
                  TextField(
                    controller: _menuSearchController,
                    onChanged: (val) => setState(() => _menuSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search dishes in menu...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _menuSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _menuSearchController.clear();
                                setState(() => _menuSearchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filtered[index];
                  return _buildOwnerMenuItemCard(item);
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerMenuItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${item.price.toStringAsFixed(0)} • ${item.category} • ~${item.prepTimeMinutes}m prep",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Stock Toggle Switch
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.isAvailable ? "In Stock" : "Sold Out",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: item.isAvailable ? AppTheme.successGreen : Colors.redAccent,
                ),
              ),
              Switch(
                value: item.isAvailable,
                activeThumbColor: AppTheme.successGreen,
                onChanged: (val) {
                  _orderService.toggleItemAvailability(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${item.name} is now ${val ? 'IN STOCK' : 'OUT OF STOCK'}",
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddNewItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prepCtrl = TextEditingController(text: '8');
    String selectedCategory = 'Quick Bites';
    bool isVeg = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Text("Add New Food Item"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Dish Name"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Price (₹)"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: prepCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Prep Time (minutes)"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Dietary:"),
                      ChoiceChip(
                        label: const Text("Veg"),
                        selected: isVeg,
                        onSelected: (val) => setDialogState(() => isVeg = true),
                      ),
                      ChoiceChip(
                        label: const Text("Non-Veg"),
                        selected: !isVeg,
                        onSelected: (val) => setDialogState(() => isVeg = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text.trim()) ?? 50.0;
                  final prep = int.tryParse(prepCtrl.text.trim()) ?? 8;
                  if (name.isNotEmpty) {
                    _orderService.addMenuItem(
                      MenuItem(
                        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
                        canteenId: widget.canteen.id,
                        name: name,
                        description: descCtrl.text.trim(),
                        price: price,
                        category: selectedCategory,
                        prepTimeMinutes: prep,
                        isVeg: isVeg,
                        isAvailable: true,
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$name added to canteen menu! 🍔")),
                    );
                  }
                },
                child: const Text("Add Dish"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= 4. SALES & ANALYTICS DASHBOARD =================

  Widget _buildAnalyticsTab() {
    final revenue = _orderService.getTodayRevenue(widget.canteen.id);
    final count = _orderService.getTodayOrdersCount(widget.canteen.id);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kitchen Analytics & Sales",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Daily operational metrics & order volume",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Revenue Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Gross Sales",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${revenue.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$count Total Orders Served",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Avg Prep: 8.5m",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    title: "Campus Pay",
                    value: "75%",
                    subtitle: "Fastest checkout",
                    icon: Icons.bolt,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatTile(
                    title: "Peak Hour",
                    value: "1:15 PM",
                    subtitle: "Lunch break rush",
                    icon: Icons.access_time,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Canteen Settings & Branch Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Canteen Branch Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow("Branch Name", widget.canteen.name),
                  _buildDetailRow("Access PIN", widget.canteen.code),
                  _buildDetailRow("Location", widget.canteen.location),
                  _buildDetailRow("Operating Hours", widget.canteen.openingHours),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  // ================= NAVIGATION =================

  Widget _buildBottomNav() {
    final activeOrdersCount = _orderService
        .getCanteenOrders(widget.canteen.id)
        .where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled)
        .length;

    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (idx) => setState(() => _currentTabIndex = idx),
      selectedItemColor: const Color(0xFF0F766E),
      items: [
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: activeOrdersCount > 0,
            label: Text('$activeOrdersCount'),
            backgroundColor: Colors.amber.shade800,
            child: const Icon(Icons.kitchen_rounded),
          ),
          label: 'Live KDS',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.notifications_active_outlined),
          label: 'Token Board',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_rounded),
          label: 'Menu & Stock',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'Analytics',
        ),
      ],
    );
  }
}
