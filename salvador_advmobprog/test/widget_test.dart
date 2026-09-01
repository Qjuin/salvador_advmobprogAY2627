import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salvador_advmobprog/main.dart';
import 'package:salvador_advmobprog/models/product.dart';
import 'package:salvador_advmobprog/screens/chat_screen.dart';
import 'package:salvador_advmobprog/screens/home_screen.dart';
import 'package:salvador_advmobprog/screens/product_detail_screen.dart';
import 'package:salvador_advmobprog/screens/product_screen.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SalvadorAdvMobProg());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('product screen includes a search field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductScreen()),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('product detail screen shows product information', (WidgetTester tester) async {
    final product = Product(
      id: 1,
      title: 'Wireless Mouse',
      description: 'Smooth and responsive mouse',
      category: 'Accessories',
      price: 39.99,
      discountPercentage: 12.5,
      rating: 4.8,
      stock: 25,
      tags: ['wireless', 'computer'],
      brand: 'LogiTech',
      sku: 'MOUSE-01',
      weight: 0.5,
      dimensions: ProductDimensions(width: 12, height: 6, depth: 4),
      warrantyInformation: '1 year warranty',
      shippingInformation: 'Ships within 2 days',
      availabilityStatus: 'In Stock',
      reviews: const [],
      returnPolicy: '30-day return policy',
      minimumOrderQuantity: 1,
      meta: ProductMeta(
        createdAt: '2024-01-01',
        updatedAt: '2024-02-01',
        barcode: '1234',
        qrCode: 'abcd',
      ),
      images: ['https://example.com/mouse.jpg'],
      thumbnail: 'https://example.com/mouse.jpg',
    );

    await tester.pumpWidget(MaterialApp(home: ProductDetailScreen(product: product)));

    expect(find.text('Wireless Mouse'), findsOneWidget);
    expect(find.text('\$39.99'), findsOneWidget);
  });

  testWidgets('chat floating action button opens the chat screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        routes: {
          '/chat': (context) => const ChatScreen(),
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.chat));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
  });
}
