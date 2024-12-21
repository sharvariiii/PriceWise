// product.dart -> class represents a Product with attributes
// like ID, name, image, price, quantity, platform, and product URL.

class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String quantity;
  final String platform;
  final String productUrl;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.platform,
    required this.productUrl,
  });
}
