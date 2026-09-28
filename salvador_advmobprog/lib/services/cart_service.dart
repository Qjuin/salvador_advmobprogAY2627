import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

/// Enhancement 3: Cart Service with User-specific Cart Fetching and Add-to-Cart
/// Integrates with DummyJSON Cart API (https://dummyjson.com/docs/carts).
/// Provides methods to:
/// - Fetch all carts
/// - Get a specific user's cart by userId
/// - Add products to a user's cart with quantity
/// - Update cart with new quantities (merge with existing)
/// - Delete cart items
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  Cart? _cachedCart;

  factory CartService() => _instance;

  CartService._internal();

  Cart? get cachedCart => _cachedCart;

  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  /// Fetch cart for a specific user by userId
  /// Based on DummyJSON Cart API: https://dummyjson.com/docs/carts
  Future<Cart> getCartByUserId(int userId) async {
    if (_cachedCart != null && _cachedCart!.userId == userId) {
      return _cachedCart!;
    }
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final carts = data['carts'] as List? ?? [];
      if (carts.isEmpty) {
        final emptyCart = Cart(
          id: 0,
          products: [],
          total: 0,
          discountedTotal: 0,
          userId: userId,
          totalProducts: 0,
          totalQuantity: 0,
        );
        _cachedCart = emptyCart;
        notifyListeners();
        return emptyCart;
      }
      _cachedCart = Cart.fromJson(carts.first as Map<String, dynamic>);
      notifyListeners();
      return _cachedCart!;
    } else {
      throw Exception('Failed to load cart for user $userId');
    }
  }

  /// Add item to user's cart
  /// Based on DummyJSON Cart API: https://dummyjson.com/docs/carts/add
  Future<Cart> addToCart({
    required int productId,
    required int quantity,
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {
            'id': productId,
            'quantity': quantity,
          }
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final addedCart = Cart.fromJson(data);
      final existingProducts = _cachedCart?.products ?? [];
      final addedProducts = addedCart.products;
      final mergedProducts = [...existingProducts];
      for (final addedProduct in addedProducts) {
        final index = mergedProducts.indexWhere((p) => p.id == addedProduct.id);
        if (index == -1) {
          mergedProducts.add(addedProduct);
        } else {
          mergedProducts[index] = _copyProduct(
            mergedProducts[index],
            quantity: mergedProducts[index].quantity + addedProduct.quantity,
          );
        }
      }
      _cachedCart = _copyCart(_cachedCart ?? addedCart, mergedProducts);
      notifyListeners();
      return _cachedCart!;
    } else {
      throw Exception('Failed to add item to cart');
    }
  }

  /// Update cart with new products (merge with existing)
  /// Based on DummyJSON Cart API: https://dummyjson.com/docs/carts/update
  Future<Cart> updateCart({
    required int cartId,
    required List<Map<String, int>> products,
    bool merge = true,
  }) async {
    final response = await http.put(
      Uri.parse('$host/carts/$cartId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merge': merge,
        'products': products,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final current = _cachedCart;
      if (current == null) return Cart.fromJson(data);
      final updatedProducts = <CartProduct>[];
      final sourceProducts = merge
          ? current.products
          : current.products
              .where((product) => products.any((item) => item['id'] == product.id))
              .toList();
      for (final product in sourceProducts) {
        Map<String, int>? update;
        for (final item in products) {
          if (item['id'] == product.id) {
            update = item;
            break;
          }
        }
        updatedProducts.add(update == null
            ? product
            : _copyProduct(product, quantity: update['quantity']!));
      }
      _cachedCart = _copyCart(current, updatedProducts);
      notifyListeners();
      return _cachedCart!;
    } else {
      throw Exception('Failed to update cart');
    }
  }

  /// Delete cart (marks as deleted)
  /// Based on DummyJSON Cart API: https://dummyjson.com/docs/carts/delete
  Future<Map<String, dynamic>> deleteCart(int cartId) async {
    final response = await http.delete(
      Uri.parse('$host/carts/$cartId'),
    );

    if (response.statusCode == 200) {
      final deleted = jsonDecode(response.body);
      if (_cachedCart?.id == cartId) {
        _cachedCart = _copyCart(_cachedCart!, []);
        notifyListeners();
      }
      return deleted;
    } else {
      throw Exception('Failed to delete cart');
    }
  }

  Cart _copyCart(Cart cart, List<CartProduct> products) {
    final total = products.fold<double>(
      0,
      (sum, product) => sum + product.price * product.quantity,
    );
    final discountedTotal = products.fold<double>(
      0,
      (sum, product) =>
          sum + product.price * product.quantity * (1 - product.discountPercentage / 100),
    );
    return Cart(
      id: cart.id,
      products: products,
      total: total,
      discountedTotal: discountedTotal,
      userId: cart.userId,
      totalProducts: products.length,
      totalQuantity: products.fold(0, (sum, product) => sum + product.quantity),
    );
  }

  CartProduct _copyProduct(CartProduct product, {required int quantity}) {
    return CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: quantity,
      total: product.price * quantity,
      discountPercentage: product.discountPercentage,
      discountedTotal:
          product.price * quantity * (1 - product.discountPercentage / 100),
      thumbnail: product.thumbnail,
    );
  }
}
