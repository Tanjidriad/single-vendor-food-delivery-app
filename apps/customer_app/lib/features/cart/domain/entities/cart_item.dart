import 'package:equatable/equatable.dart';

class CartAddon extends Equatable {
  const CartAddon({required this.addonId, required this.name, required this.price});

  final String addonId;
  final String name;
  final double price;

  @override
  List<Object?> get props => [addonId, name, price];

  Map<String, dynamic> toJson() => {
        'addonId': addonId,
        'name': name,
        'price': price,
      };

  factory CartAddon.fromJson(Map<String, dynamic> json) => CartAddon(
        addonId: json['addonId'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
      );
}

class CartItem extends Equatable {
  const CartItem({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.notes,
    this.addons = const [],
  });

  final String menuItemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final String? notes;
  final List<CartAddon> addons;

  double get lineTotal =>
      (unitPrice + addons.fold<double>(0, (s, a) => s + a.price)) * quantity;

  CartItem copyWith({int? quantity, String? notes}) => CartItem(
        menuItemId: menuItemId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl,
        notes: notes ?? this.notes,
        addons: addons,
      );

  Map<String, dynamic> toOrderItemJson() => {
        'menuItemId': menuItemId,
        'quantity': quantity,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (addons.isNotEmpty)
          'addons': addons
              .map((a) => {
                    'addonId': a.addonId,
                    'name': a.name,
                    'price': a.price,
                  })
              .toList(),
      };

  @override
  List<Object?> get props => [menuItemId, quantity, notes, addons];
}
