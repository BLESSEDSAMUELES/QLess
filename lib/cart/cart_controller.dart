import '../models/cart_item.dart';

class CartController {
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  CartController._internal();

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  void addItem({
    required String itemId,
    required String name,
    required num price,
  }) {
    if (_items.containsKey(itemId)) {
      _items[itemId]!.quantity++;
    } else {
      _items[itemId] = CartItem(
        itemId: itemId,
        itemName: name,
        price: price,
      );
    }
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
  }

  void decreaseQty(String itemId) {
    if (!_items.containsKey(itemId)) return;

    if (_items[itemId]!.quantity > 1) {
      _items[itemId]!.quantity--;
    } else {
      _items.remove(itemId);
    }
  }

  num get totalAmount => _items.values.fold(0, (sum, item) => sum + item.total);

  bool get isEmpty => _items.isEmpty;

  void clear() => _items.clear();
}
