// lib/models/review_model.dart
class Review {
  final int id;
  final String user; // El backend envía el nombre de usuario como string
  final int product;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.user,
    required this.product,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      user: json['user'], // 'user' es un string (username)
      product: json['product'],
      // El rating puede venir como int (5) o double (4.5)
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
