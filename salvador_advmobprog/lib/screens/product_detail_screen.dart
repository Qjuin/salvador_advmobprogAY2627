import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  int _quantity = 1;
  bool _isAdding = false;

 Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    try {
      final user = await _userService.getUser();
      
      // Fallback: Prevent DummyJSON error by ensuring the ID is never 0
      final cartUserId = user.id > 0 ? user.id : 1;
      
      await _cartService.addToCart(
        productId: widget.product.id,
        quantity: _quantity,
        userId: cartUserId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.product.title} added to cart')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add item to cart: $error')),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.network(
                  widget.product.thumbnail,
                  width: double.infinity,
                  height: 260.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 260.h,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                widget.product.title,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.product.category,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.star, color: Colors.amber, size: 18.sp),
                  SizedBox(width: 4.w),
                  Text(
                    widget.product.rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                '\$${widget.product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.product.description,
                style: TextStyle(fontSize: 15.sp, height: 1.5),
              ),
              SizedBox(height: 20.h),
              _InfoRow(label: 'Brand', value: widget.product.brand),
              _InfoRow(label: 'Stock', value: '${widget.product.stock} available'),
              _InfoRow(label: 'Shipping', value: widget.product.shippingInformation),
              _InfoRow(label: 'Warranty', value: widget.product.warrantyInformation),
              if (widget.product.tags.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                    children: widget.product.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      )
                      .toList(),
                ),
              ],
              SizedBox(height: 24.h),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity == 1 || _isAdding
                        ? null
                        : () => setState(() => _quantity--),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_quantity', style: TextStyle(fontSize: 16.sp)),
                  IconButton(
                    onPressed: _isAdding
                        ? null
                        : () => setState(() => _quantity++),
                    icon: const Icon(Icons.add),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAdding ? null : _addToCart,
                      icon: _isAdding
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_cart_outlined),
                      label: Text(_isAdding ? 'Adding...' : 'Add to cart'),
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
