// lib/models/review_model.dart
import 'package:intl/intl.dart';

class Review {
  final int id;
  final String user; // El serializador devuelve el StringRelatedField
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.user,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  // Helper para formatear la fecha
  String get formattedDate {
    return DateFormat('d \'de\' MMMM, yyyy', 'es_ES').format(createdAt);
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      user: json['user'], // 'user' es un String
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
