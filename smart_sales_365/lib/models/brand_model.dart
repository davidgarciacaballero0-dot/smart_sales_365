// lib/models/brand_model.dart
import 'package:flutter/foundation.dart';

@immutable
class Brand {
  final int id;
  final String name;
  final int?
  warrantyDurationMonths; // Django lo tiene como 'null=True, blank=True'

  const Brand({
    required this.id,
    required this.name,
    this.warrantyDurationMonths,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as int,
      name: json['name'] as String,
      warrantyDurationMonths: json['warranty_duration_months'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'warranty_duration_months': warrantyDurationMonths,
    };
  }
}
