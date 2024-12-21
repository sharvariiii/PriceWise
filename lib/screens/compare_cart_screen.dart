//compare_cart_screen.dart --> to compare shopping carts across three platforms
import 'package:flutter/material.dart';
import '../models/product.dart';

class CompareCartScreen extends StatefulWidget {
  final List<Product> compareCartBlinkit;
  final List<Product> compareCartInstamart;
  final List<Product> compareCartZepto;

  const CompareCartScreen({
    super.key,
    required this.compareCartBlinkit,
    required this.compareCartInstamart,
    required this.compareCartZepto,
  });

  @override
  _CompareCartScreenState createState() => _CompareCartScreenState();
}

class _CompareCartScreenState extends State<CompareCartScreen> {
  //-----------------Update the state of the compare cart
  List<Product> compareCartBlinkit = [];
  List<Product> compareCartInstamart = [];
  List<Product> compareCartZepto = [];

  @override
  void initState() {
    super.initState();
    compareCartBlinkit = widget.compareCartBlinkit;
    compareCartInstamart = widget.compareCartInstamart;
    compareCartZepto = widget.compareCartZepto;
  }

  double _calculateTotal(List<Product> products) {
    return products.fold(0.0, (total, product) => total + product.price);
  }

  void _removeProduct(String platform, Product product) {
    setState(() {
      if (platform == 'Blinkit') {
        compareCartBlinkit.remove(product);
      } else if (platform == 'Instamart') {
        compareCartInstamart.remove(product);
      } else if (platform == 'Zepto') {
        compareCartZepto.remove(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compare Cart',
          style: TextStyle(
            color: Color(0xFF4E377A), // Purple color for the title
            fontSize: 18,
            fontWeight: FontWeight.bold,
            // letterSpacing: 1.2, // Adds spacing between letters
          ),
        ),
        backgroundColor: const Color(0xFFEBDDFF), // Light purple background
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildPlatformSection(
                'Blinkit',
                compareCartBlinkit,
                _calculateTotal(compareCartBlinkit),
              ),
              const Divider(),
              _buildPlatformSection(
                'Instamart',
                compareCartInstamart,
                _calculateTotal(compareCartInstamart),
              ),
              const Divider(),
              _buildPlatformSection(
                'Zepto',
                compareCartZepto,
                _calculateTotal(compareCartZepto),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //--------Builds a section for a specific platform's cart----------
  Widget _buildPlatformSection(
      String platform, List<Product> products, double totalPrice) {
    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(platform),
          Text(
            'Total Price: ₹ ${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      leading: Icon(platform == 'Blinkit'
              ? Icons.shopping_cart
              : platform == 'Instamart'
                  ? Icons.shopping_cart
                  : Icons.shopping_cart
          //: Colors.purple,
          ),
      children: [
        for (var product in products)
          ListTile(
            leading: Image.network(
              product.image,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported),
            ),
            title: Text(product.name),
            subtitle:
                Text('Price: ₹ ${product.price} \nQty: ${product.quantity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _removeProduct(platform, product);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
