import 'package:flutter/foundation.dart';
import '../models/canteen_models.dart';

class CartController extends ChangeNotifier {
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  CartController._internal();

  final Map<String, OrderItem> _items = {};
  String? _currentCanteenId;
  String? _currentCanteenName;
  String _pickupType = 'asap'; // 'asap' or 'scheduled'
  String? _scheduledTime;
  String _paymentMethod = 'Campus Wallet';
  String _specialInstructions = '';

  List<OrderItem> get items => _items.values.toList();
  String? get canteenId => _currentCanteenId;
  String? get canteenName => _currentCanteenName;
  String get pickupType => _pickupType;
  String? get scheduledTime => _scheduledTime;
  String get paymentMethod => _paymentMethod;
  String get specialInstructions => _specialInstructions;

  int get totalItemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.total);
  double get taxesAndConvenience => subtotal > 0 ? 5.0 : 0.0;
  double get totalAmount => subtotal + taxesAndConvenience;
  bool get isEmpty => _items.isEmpty;

  void setPickupType(String type, {String? time}) {
    _pickupType = type;
    _scheduledTime = time;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setSpecialInstructions(String notes) {
    _specialInstructions = notes;
    notifyListeners();
  }

  bool addItem({
    MenuItem? menuItem,
    String? canteenName,
    String? itemId,
    String? name,
    num? price,
    int quantity = 1,
    String? specialInstructions,
    bool isVeg = true,
  }) {
    final effectiveId = menuItem?.id ?? itemId ?? '';
    final effectiveName = menuItem?.name ?? name ?? 'Item';
    final effectivePrice = (menuItem?.price ?? price ?? 0.0).toDouble();
    final effectiveCanteenId = menuItem?.canteenId ?? _currentCanteenId ?? 'canteen-01';
    final effectiveCanteenName = canteenName ?? menuItem?.canteenId ?? _currentCanteenName ?? 'Campus Canteen';
    final effectiveVeg = menuItem?.isVeg ?? isVeg;

    // If cart has items from a different canteen, check
    if (_currentCanteenId != null &&
        _currentCanteenId != effectiveCanteenId &&
        _items.isNotEmpty) {
      return false; // Indicates conflict
    }

    _currentCanteenId = effectiveCanteenId;
    _currentCanteenName = effectiveCanteenName;

    if (_items.containsKey(effectiveId)) {
      _items[effectiveId]!.quantity += quantity;
    } else {
      _items[effectiveId] = OrderItem(
        menuItemId: effectiveId,
        itemName: effectiveName,
        price: effectivePrice,
        quantity: quantity,
        isVeg: effectiveVeg,
        specialInstructions: specialInstructions,
      );
    }
    notifyListeners();
    return true;
  }

  void forceAddItem({
    required MenuItem menuItem,
    required String canteenName,
    int quantity = 1,
    String? specialInstructions,
  }) {
    clear();
    addItem(
      menuItem: menuItem,
      canteenName: canteenName,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
  }

  void decreaseQty(String menuItemId) {
    if (!_items.containsKey(menuItemId)) return;

    if (_items[menuItemId]!.quantity > 1) {
      _items[menuItemId]!.quantity--;
    } else {
      _items.remove(menuItemId);
      if (_items.isEmpty) {
        _currentCanteenId = null;
        _currentCanteenName = null;
      }
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    if (_items.isEmpty) {
      _currentCanteenId = null;
      _currentCanteenName = null;
    }
    notifyListeners();
  }

  int getItemQuantity(String menuItemId) {
    return _items[menuItemId]?.quantity ?? 0;
  }

  void clear() {
    _items.clear();
    _currentCanteenId = null;
    _currentCanteenName = null;
    _specialInstructions = '';
    _pickupType = 'asap';
    _scheduledTime = null;
    notifyListeners();
  }
}
