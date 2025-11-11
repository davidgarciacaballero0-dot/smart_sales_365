// lib/models/review_model.dart
import 'package:intl/intl.dart';

/// Modelo Review que refleja ReviewSerializer del backend
/// Incluye análisis de sentimiento con Gemini AI
class Review {
  final int id;
  final int productId;
  final String user; // StringRelatedField
  final int rating; // 1-5
  final String? comment;

  // Sentiment Analysis fields (VADER + Gemini AI)
  final String? sentiment; // POSITIVO, NEUTRO, NEGATIVO
  final double? sentimentScore; // -1 a 1
  final double? sentimentConfidence; // 0 a 1
  final String? sentimentSummary;

  // Aspect-based sentiment analysis (Gemini AI)
  final int? aspectQuality; // 1-5
  final int? aspectValue; // 1-5 (relación precio-calidad)
  final int? aspectDelivery; // 1-5

  // Keywords extracted by AI
  final List<String>? keywords;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.productId,
    required this.user,
    required this.rating,
    this.comment,
    this.sentiment,
    this.sentimentScore,
    this.sentimentConfidence,
    this.sentimentSummary,
    this.aspectQuality,
    this.aspectValue,
    this.aspectDelivery,
    this.keywords,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper para formatear la fecha
  String get formattedDate {
    return DateFormat('d \'de\' MMMM, yyyy', 'es_ES').format(createdAt);
  }

  // Helper para mostrar el sentimiento con emoji
  String get sentimentEmoji {
    switch (sentiment) {
      case 'POSITIVO':
        return '😊';
      case 'NEGATIVO':
        return '😞';
      case 'NEUTRO':
      default:
        return '😐';
    }
  }

  // Helper para color del sentimiento
  bool get isPositive => sentiment == 'POSITIVO';
  bool get isNegative => sentiment == 'NEGATIVO';
  bool get isNeutral => sentiment == 'NEUTRO';

  factory Review.fromJson(Map<String, dynamic> json) {
    // Parse keywords JSON array
    List<String>? keywordsList;
    if (json['keywords'] != null && json['keywords'] is List) {
      keywordsList = (json['keywords'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return Review(
      id: json['id'] as int,
      productId: json['product'] as int,
      user: json['user'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      // Sentiment fields
      sentiment: json['sentiment'] as String?,
      sentimentScore: json['sentiment_score'] != null
          ? (json['sentiment_score'] as num).toDouble()
          : null,
      sentimentConfidence: json['sentiment_confidence'] != null
          ? (json['sentiment_confidence'] as num).toDouble()
          : null,
      sentimentSummary: json['sentiment_summary'] as String?,
      // Aspect analysis
      aspectQuality: json['aspect_quality'] as int?,
      aspectValue: json['aspect_value'] as int?,
      aspectDelivery: json['aspect_delivery'] as int?,
      // Keywords
      keywords: keywordsList,
      // Timestamps
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
