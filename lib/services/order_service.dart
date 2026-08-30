import 'package:flutter/foundation.dart';
import '../models/canteen_models.dart';
import 'mock_data.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;

  OrderService._internal() {
    _initData();
  }

  final List<OrderModel> _orders = [];
  final List<Canteen> _canteens = [];
  final List<MenuItem> _menuItems = [];
  
  StudentProfile _currentStudent = StudentProfile(
    studentId: 'STU9421',
    name: 'Alex Mercer',
    email: 'alex.mercer@campus.edu',
    phone: '+91 98765 43210',
    walletBalance: 480.0,
  );

  int _tokenSequence = 110;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<Canteen> get canteens => List.unmodifiable(_canteens);
  List<MenuItem> get menuItems => List.unmodifiable(_menuItems);
  StudentProfile get currentStudent => _currentStudent;

  void _initData() {
    _canteens.addAll(MockData.canteens);
    _menuItems.addAll(MockData.defaultMenuItems);
    _orders.addAll(MockData.getInitialSampleOrders());
  }

  // --- Student Specific Methods ---
  void setStudentProfile(StudentProfile profile) {
    _currentStudent = profile;
    notifyListeners();
  }

  void topUpWallet(double amount) {
    _currentStudent = StudentProfile(
      studentId: _currentStudent.studentId,
      name: _currentStudent.name,
      email: _currentStudent.email,
      phone: _currentStudent.phone,
      walletBalance: _currentStudent.walletBalance + amount,
    );
    notifyListeners();
  }

  List<OrderModel> getStudentActiveOrders(String studentId) {
    return _orders
        .where((o) =>
            o.studentId == studentId &&
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<OrderModel> getStudentOrderHistory(String studentId) {
    return _orders
        .where((o) =>
            o.studentId == studentId &&
            (o.status == OrderStatus.completed || o.status == OrderStatus.cancelled))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- Queue & Token Generation ---
  String _generateNextToken() {
    _tokenSequence++;
    return 'TK-$_tokenSequence';
  }

  OrderModel placeOrder({
    required String canteenId,
    required String canteenName,
    required List<OrderItem> items,
    required double totalAmount,
    required String paymentMethod,
    String pickupType = 'asap',
    String? scheduledTime,
    String? specialInstructions,
  }) {
    final token = _generateNextToken();
    final now = DateTime.now();
    
    // Estimate wait time: 6 mins base + 2 mins per item in queue
    final queueItemsCount = _orders
        .where((o) => o.canteenId == canteenId && o.status == OrderStatus.preparing)
        .fold(0, (sum, o) => sum + o.totalItemCount);
    final prepMinutes = 6 + (queueItemsCount * 2).clamp(0, 25);

    final newOrder = OrderModel(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      tokenNumber: token,
      canteenId: canteenId,
      canteenName: canteenName,
      studentId: _currentStudent.studentId,
      studentName: _currentStudent.name,
      studentPhone: _currentStudent.phone,
      items: List.from(items),
      totalAmount: totalAmount,
      status: OrderStatus.placed,
      pickupType: pickupType,
      scheduledTime: scheduledTime,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
      createdAt: now,
      estimatedReadyTime: now.add(Duration(minutes: prepMinutes)),
    );

    // Deduct from wallet if selected
    if (paymentMethod == 'Campus Wallet' && _currentStudent.walletBalance >= totalAmount) {
      _currentStudent = StudentProfile(
        studentId: _currentStudent.studentId,
        name: _currentStudent.name,
        email: _currentStudent.email,
        phone: _currentStudent.phone,
        walletBalance: _currentStudent.walletBalance - totalAmount,
      );
    }

    _orders.insert(0, newOrder);
    notifyListeners();
    return newOrder;
  }

  // --- Canteen Owner Methods ---
  List<OrderModel> getCanteenOrders(String canteenId) {
    return _orders.where((o) => o.canteenId == canteenId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<OrderModel> getCanteenActiveOrders(String canteenId) {
    return _orders
        .where((o) =>
            o.canteenId == canteenId &&
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = newStatus;
      notifyListeners();
    }
  }

  // --- Live Queue Statistics ---
  String getCurrentlyServingToken(String canteenId) {
    final readyOrders = _orders
        .where((o) => o.canteenId == canteenId && o.status == OrderStatus.ready)
        .toList();
    if (readyOrders.isNotEmpty) {
      return readyOrders.first.tokenNumber;
    }
    final preparingOrders = _orders
        .where((o) => o.canteenId == canteenId && o.status == OrderStatus.preparing)
        .toList();
    if (preparingOrders.isNotEmpty) {
      return preparingOrders.first.tokenNumber;
    }
    return 'None';
  }

  int getQueuePosition(String orderId, String canteenId) {
    final activeOrders = _orders
        .where((o) =>
            o.canteenId == canteenId &&
            (o.status == OrderStatus.placed || o.status == OrderStatus.preparing))
        .toList();
    final index = activeOrders.indexWhere((o) => o.id == orderId);
    return index == -1 ? 0 : index;
  }

  // --- Menu Item Stock / CRUD Management ---
  List<MenuItem> getMenuItemsForCanteen(String canteenId) {
    return _menuItems.where((item) => item.canteenId == canteenId).toList();
  }

  void toggleItemAvailability(String itemId) {
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final current = _menuItems[index];
      _menuItems[index] = current.copyWith(isAvailable: !current.isAvailable);
      notifyListeners();
    }
  }

  void addMenuItem(MenuItem item) {
    _menuItems.add(item);
    notifyListeners();
  }

  void updateMenuItem(MenuItem updatedItem) {
    final index = _menuItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _menuItems[index] = updatedItem;
      notifyListeners();
    }
  }

  void deleteMenuItem(String itemId) {
    _menuItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // --- Canteen Stats ---
  double getTodayRevenue(String canteenId) {
    return _orders
        .where((o) => o.canteenId == canteenId && o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  int getTodayOrdersCount(String canteenId) {
    return _orders.where((o) => o.canteenId == canteenId).length;
  }
}
