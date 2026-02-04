class CartItem {
  final String itemId;
  final String itemName;
  final num price;
  int quantity;

  CartItem({
    required this.itemId,
    required this.itemName,
    required this.price,
    this.quantity = 1,
  });

  num get total => price * quantity;
}
