class ProductItem {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final double discountPercentage;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;

  ProductItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.discountPercentage,
    required this.stock,
    required this.brand,
    required this.thumbnail,
    required this.images,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      stock: json['stock'],
      brand: json['brand'] ?? '',
      thumbnail: json['thumbnail'],
      images: List<String>.from(json['images']),
    );
  }
}
