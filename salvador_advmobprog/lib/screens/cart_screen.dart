import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';

/// Enhancement: Cart Screen with Full DummyJSON API Integration
/// Renders the cart API endpoint using DummyJSON Cart API.
/// Items on the cart screen are clickable and navigate to the product detail screen.
/// Implements increase/decrease quantity, remove item, and confirm order functionality.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart> _cartFuture;
  late Future<List<Product>> _productsFuture;
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  void _refreshCart() {
    setState(() {
      // Fetch user 1's cart (using hardcoded userId for now)
      _cartFuture = _loadUserCart();
      _productsFuture = ProductService().getAllProducts();
    });
  }

  Future<Cart> _loadUserCart() async {
    final user = await _userService.getUser();
    final cartUserId = user.id > 0 ? user.id : 1; // Default to userId 1 if not found
    return _cartService.getCartByUserId(cartUserId);
  }

  Future<void> _updateQuantity(int productId, int newQuantity, int cartId) async {
    setState(() => _isLoading = true);
    try {
      // Create updated products list with new quantity
      final products = [
        {
          'id': productId,
          'quantity': newQuantity,
        }
      ];
      
      await _cartService.updateCart(
        cartId: cartId,
        products: products,
        merge: true, // Keep existing items
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(int productId, int cartId, List<CartProduct> currentProducts) async {
    setState(() => _isLoading = true);
    try {
      // Filter out the product to remove and create new products list
      final updatedProducts = currentProducts
          .where((p) => p.id != productId)
          .map((p) => {
            'id': p.id,
            'quantity': p.quantity,
          })
          .toList();
      
      if (updatedProducts.isEmpty) {
        // If cart is empty, delete it
        await _cartService.deleteCart(cartId);
      } else {
        // Otherwise update with remaining items
        await _cartService.updateCart(
          cartId: cartId,
          products: updatedProducts,
          merge: false, // Replace all items
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmOrder(int cartId) async {
    setState(() => _isLoading = true);
    try {
      // Mark cart as deleted to simulate order confirmation
      await _cartService.deleteCart(cartId);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order Confirmed'),
            content: const Text('Your order has been successfully placed!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cartService,
      builder: (context, _) => SafeArea(
        child: FutureBuilder<Cart>(
        future: _cartFuture,
        builder: (context, cartSnapshot) {
          if (cartSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }

          if (cartSnapshot.hasError) {
            return Center(
              child: CustomText(
                text: 'Error: ${cartSnapshot.error}',
                fontSize: 14.sp,
              ),
            );
          }

          final cart = _cartService.cachedCart ?? cartSnapshot.data;
          if (cart == null || cart.products.isEmpty) {
            return Center(
              child: CustomText(
                text: 'Your cart is empty',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            );
          }

          return FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, productsSnapshot) {
              if (productsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                );
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'Cart',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 16.h),
                        for (final cartProduct in cart.products)
                          _buildCartProductCard(
                            context,
                            cartProduct,
                            productsSnapshot,
                            cart.id,
                            cart.products,
                          ),
                        SizedBox(height: 24.h),
                        _buildSummaryContainer(cart),
                        SizedBox(height: 24.h),
                        _buildConfirmButton(cart.id),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
        ),
      ),
    );
  }

  Widget _buildCartProductCard(
    BuildContext context,
    CartProduct cartProduct,
    AsyncSnapshot<List<Product>> productsSnapshot,
    int cartId,
    List<CartProduct> allProducts,
  ) {
    final product = productsSnapshot.data?.firstWhere(
      (p) => p.id == cartProduct.id,
      orElse: () => Product(
        id: cartProduct.id,
        title: cartProduct.title,
        description: '',
        category: '',
        price: cartProduct.price,
        discountPercentage: cartProduct.discountPercentage,
        rating: 0,
        stock: 0,
        tags: [],
        brand: '',
        sku: '',
        weight: 0,
        dimensions: ProductDimensions(
          width: 0,
          height: 0,
          depth: 0,
        ),
        warrantyInformation: '',
        shippingInformation: '',
        availabilityStatus: '',
        reviews: [],
        returnPolicy: '',
        minimumOrderQuantity: 0,
        meta: ProductMeta(
          createdAt: '',
          updatedAt: '',
          barcode: '',
          qrCode: '',
        ),
        images: [],
        thumbnail: cartProduct.thumbnail,
      ),
    );

    return GestureDetector(
      onTap: () {
        if (product != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        }
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16.h),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  cartProduct.thumbnail,
                  width: 80.w,
                  height: 80.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80.w,
                    height: 80.h,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: cartProduct.title,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '\$${cartProduct.price.toStringAsFixed(2)}',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              _removeItem(cartProduct.id, cartId, allProducts);
                            },
                      child: CustomText(
                        text: 'Remove',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _isLoading || cartProduct.quantity <= 1
                              ? null
                              : () {
                                  _updateQuantity(
                                    cartProduct.id,
                                    cartProduct.quantity - 1,
                                    cartId,
                                  );
                                },
                          child: Icon(
                            Icons.remove,
                            size: 16.sp,
                            color: (_isLoading || cartProduct.quantity <= 1)
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        CustomText(
                          text: '${cartProduct.quantity}',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  _updateQuantity(
                                    cartProduct.id,
                                    cartProduct.quantity + 1,
                                    cartId,
                                  );
                                },
                          child: Icon(
                            Icons.add,
                            size: 16.sp,
                            color: _isLoading ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContainer(Cart cart) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Subtotal:',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              CustomText(
                text: '\$${cart.total.toStringAsFixed(2)}',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Total:',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              CustomText(
                text: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(int cartId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: _isLoading ? null : () => _confirmOrder(cartId),
        child: CustomText(
          text: 'Confirm Order',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}
