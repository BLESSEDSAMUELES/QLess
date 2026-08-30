import 'package:flutter/material.dart';

enum OrderStatus {
  placed,
  preparing,
  ready,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.preparing:
        return 'In Kitchen';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Collected';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.placed:
        return const Color(0xFF3B82F6); // Blue
      case OrderStatus.preparing:
        return const Color(0xFFF59E0B); // Amber
      case OrderStatus.ready:
        return const Color(0xFF10B981); // Emerald Green
      case OrderStatus.completed:
        return const Color(0xFF6B7280); // Slate Gray
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.placed:
        return Icons.receipt_long;
      case OrderStatus.preparing:
        return Icons.outdoor_grill;
      case OrderStatus.ready:
        return Icons.notifications_active;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class Canteen {
  final String id;
  final String name;
  final String code;
  final String location;
  final double rating;
  final int averagePrepMinutes;
  final bool isOpen;
  final String bannerUrl;
  final List<String> categories;
  final String openingHours;

  Canteen({
    required this.id,
    required this.name,
    required this.code,
    this.location = 'Main Campus Block',
    this.rating = 4.6,
    this.averagePrepMinutes = 12,
    this.isOpen = true,
    this.bannerUrl = '',
    this.categories = const ['All', 'Meals', 'Snacks', 'Beverages', 'Quick Bites'],
    this.openingHours = '8:00 AM - 7:30 PM',
  });

  factory Canteen.fromMap(Map<String, dynamic> map) {
    return Canteen(
      id: map['id']?.toString() ?? '',
      name: map['canteen_name']?.toString() ?? 'Campus Canteen',
      code: map['canteen_code']?.toString() ?? '',
      location: map['location']?.toString() ?? 'Central Food Court',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.7,
      averagePrepMinutes: (map['prep_time_minutes'] as num?)?.toInt() ?? 10,
      isOpen: map['is_open'] as bool? ?? true,
      bannerUrl: map['banner_url']?.toString() ?? '',
      openingHours: map['opening_hours']?.toString() ?? '8:00 AM - 8:00 PM',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'canteen_name': name,
      'canteen_code': code,
      'location': location,
      'rating': rating,
      'prep_time_minutes': averagePrepMinutes,
      'is_open': isOpen,
      'banner_url': bannerUrl,
      'opening_hours': openingHours,
    };
  }
}

class MenuItem {
  final String id;
  final String canteenId;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isVeg;
  final bool isAvailable;
  final int prepTimeMinutes;
  final String imageUrl;
  final double rating;
  final bool isBestSeller;
  final int spicyLevel; // 0: Mild, 1: Medium, 2: Spicy
  final String? calories;

  MenuItem({
    required this.id,
    required this.canteenId,
    required this.name,
    required this.description,
    required this.price,
    this.category = 'Quick Bites',
    this.isVeg = true,
    this.isAvailable = true,
    this.prepTimeMinutes = 8,
    this.imageUrl = '',
    this.rating = 4.5,
    this.isBestSeller = false,
    this.spicyLevel = 1,
    this.calories = '250 kcal',
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id']?.toString() ?? '',
      canteenId: map['canteen_id']?.toString() ?? '',
      name: map['item_name']?.toString() ?? 'Food Item',
      description: map['description']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? 'Quick Bites',
      isVeg: map['is_veg'] as bool? ?? true,
      isAvailable: map['is_available'] as bool? ?? true,
      prepTimeMinutes: (map['prep_time_minutes'] as num?)?.toInt() ?? 8,
      imageUrl: map['image_url']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.6,
      isBestSeller: map['is_bestseller'] as bool? ?? false,
      spicyLevel: (map['spice_level'] as num?)?.toInt() ?? 1,
      calories: map['calories']?.toString() ?? '220 kcal',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'canteen_id': canteenId,
      'item_name': name,
      'description': description,
      'price': price,
      'category': category,
      'is_veg': isVeg,
      'is_available': isAvailable,
      'prep_time_minutes': prepTimeMinutes,
      'image_url': imageUrl,
      'rating': rating,
      'is_bestseller': isBestSeller,
      'spice_level': spicyLevel,
      'calories': calories,
    };
  }

  MenuItem copyWith({
    String? id,
    String? canteenId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isVeg,
    bool? isAvailable,
    int? prepTimeMinutes,
    String? imageUrl,
    double? rating,
    bool? isBestSeller,
    int? spicyLevel,
    String? calories,
  }) {
    return MenuItem(
      id: id ?? this.id,
      canteenId: canteenId ?? this.canteenId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isVeg: isVeg ?? this.isVeg,
      isAvailable: isAvailable ?? this.isAvailable,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      calories: calories ?? this.calories,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String itemName;
  final double price;
  int quantity;
  final bool isVeg;
  final String? specialInstructions;

  OrderItem({
    required this.menuItemId,
    required this.itemName,
    required this.price,
    this.quantity = 1,
    this.isVeg = true,
    this.specialInstructions,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menu_item_id': menuItemId,
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
      'is_veg': isVeg,
      'special_instructions': specialInstructions,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menu_item_id']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      isVeg: map['is_veg'] as bool? ?? true,
      specialInstructions: map['special_instructions']?.toString(),
    );
  }
}

class OrderModel {
  final String id;
  final String tokenNumber; // e.g. "TK-108"
  final String canteenId;
  final String canteenName;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final List<OrderItem> items;
  final double totalAmount;
  OrderStatus status;
  final String pickupType; // 'asap' or 'scheduled'
  final String? scheduledTime; // e.g. "1:15 PM"
  final String paymentMethod; // 'Campus Wallet', 'UPI', 'Counter Cash'
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime estimatedReadyTime;

  OrderModel({
    required this.id,
    required this.tokenNumber,
    required this.canteenId,
    required this.canteenName,
    required this.studentId,
    required this.studentName,
    this.studentPhone = '',
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.placed,
    this.pickupType = 'asap',
    this.scheduledTime,
    this.paymentMethod = 'Campus Wallet',
    this.specialInstructions,
    required this.createdAt,
    required this.estimatedReadyTime,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'token_number': tokenNumber,
      'canteen_id': canteenId,
      'canteen_name': canteenName,
      'student_id': studentId,
      'student_name': studentName,
      'student_phone': studentPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'total_amount': totalAmount,
      'status': status.name,
      'pickup_type': pickupType,
      'scheduled_time': scheduledTime,
      'payment_method': paymentMethod,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'estimated_ready_time': estimatedReadyTime.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      tokenNumber: map['token_number']?.toString() ?? 'TK-000',
      canteenId: map['canteen_id']?.toString() ?? '',
      canteenName: map['canteen_name']?.toString() ?? 'Canteen',
      studentId: map['student_id']?.toString() ?? '',
      studentName: map['student_name']?.toString() ?? 'Student',
      studentPhone: map['student_phone']?.toString() ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.placed,
      ),
      pickupType: map['pickup_type']?.toString() ?? 'asap',
      scheduledTime: map['scheduled_time']?.toString(),
      paymentMethod: map['payment_method']?.toString() ?? 'Campus Wallet',
      specialInstructions: map['special_instructions']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estimatedReadyTime: map['estimated_ready_time'] != null
          ? DateTime.tryParse(map['estimated_ready_time'].toString()) ??
              DateTime.now().add(const Duration(minutes: 12))
          : DateTime.now().add(const Duration(minutes: 12)),
    );
  }
}

class StudentProfile {
  final String studentId;
  final String name;
  final String email;
  final String phone;
  final double walletBalance;

  StudentProfile({
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    this.walletBalance = 450.0,
  });
}
