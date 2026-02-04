import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cart/cart_controller.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  bool _loading = true;

  /// UUIDs are STRING
  List<Map<String, dynamic>> _canteens = [];
  Map<String, List<Map<String, dynamic>>> _menusByCanteen = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final supabase = Supabase.instance.client;

    try {
      // 1️⃣ Fetch canteens
      final canteenRes =
          await supabase.from('canteens').select().order('canteen_name');

      final canteens = List<Map<String, dynamic>>.from(canteenRes);

      // 2️⃣ Fetch menu items per canteen
      final Map<String, List<Map<String, dynamic>>> menus = {};

      for (final canteen in canteens) {
        final String canteenId = canteen['id'] as String;

        final menuRes = await supabase
            .from('menu_items')
            .select()
            .eq('canteen_id', canteenId)
            .eq('is_available', true)
            .order('item_name');

        menus[canteenId] = List<Map<String, dynamic>>.from(menuRes);
      }

      if (!mounted) return;
      setState(() {
        _canteens = canteens;
        _menusByCanteen = menus;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              ),
            )
          else if (_canteens.isEmpty)
            _buildEmptyState()
          else
            _buildCanteenList(),
        ],
      ),
    );
  }

  // ================= UI =================

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "Browse Canteens",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF8C00),
                Color(0xFFFFB347),
                Color(0xFFFFD700),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverFillRemaining _buildEmptyState() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No canteens available",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildCanteenList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final canteen = _canteens[index];
            final String canteenId = canteen['id'] as String;

            final menuItems = _menusByCanteen[canteenId] ?? [];

            return _buildCanteenCard(
              canteenName: canteen['canteen_name'] ?? '',
              menuItems: menuItems,
            );
          },
          childCount: _canteens.length,
        ),
      ),
    );
  }

  Widget _buildCanteenCard({
    required String canteenName,
    required List<Map<String, dynamic>> menuItems,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    canteenName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  "${menuItems.length} items",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          // Menu items
          if (menuItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "No menu items available",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _buildMenuItem(
                    item, Colors.amberAccent, Colors.blueAccent);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    Map<String, dynamic> item,
    Color accentColor,
    Color veryLightColor,
  ) {
    final String itemId = item['id'] as String; // UUID → String
    final String itemName = item['item_name'] ?? 'Unknown Item';
    final String? description = item['description'];
    final num price = item['price'] ?? 0;
    final bool isAvailable = item['is_available'] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: veryLightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fastfood,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price + Add Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${price.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 6),
              if (isAvailable)
                ElevatedButton(
                  onPressed: () {
                    CartController().addItem(
                      itemId: itemId,
                      name: itemName,
                      price: price,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$itemName added to cart"),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Add",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Unavailable",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
