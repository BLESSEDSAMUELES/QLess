import 'package:flutter/material.dart';
import '../cart/cart_controller.dart';
import '../theme/app_theme.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = CartController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Your Cart"),
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text(
                "Cart is empty",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      return ListTile(
                        title: Text(item.itemName),
                        subtitle: Text("₹${item.price.toStringAsFixed(0)} x ${item.quantity}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  cart.decreaseQty(item.menuItemId);
                                });
                              },
                            ),
                            Text(
                              item.quantity.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                              onPressed: () {
                                setState(() {
                                  cart.addItem(
                                    itemId: item.menuItemId,
                                    name: item.itemName,
                                    price: item.price,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Total + Place Order
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Total: ₹${cart.totalAmount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Proceed to Phase 2 for full checkout & queue token generation!"),
                            ),
                          );
                        },
                        child: const Text("Place Order"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
