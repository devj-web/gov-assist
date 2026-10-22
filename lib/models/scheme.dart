
import 'package:flutter/material.dart';

class Scheme {
  final int id;
  final String name;
  final String category;
  final String level;
  final String state;
  final String description;
  final String? officialUrl;
  final bool isActive;

  const Scheme({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.state,
    required this.description,
    this.officialUrl,
    required this.isActive,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? 'Unnamed scheme').toString(),
      category: (json['category'] ?? 'Other').toString(),
      level: (json['scheme_type'] ?? 'Unknown').toString(),
      state: (json['state'] ?? 'All').toString(),
      description: (json['description'] ?? '').toString(),
      officialUrl: json['official_url']?.toString(),
      isActive: json['is_active'] == true,
    );
  }

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'education':
        return Icons.school_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'pension':
        return Icons.elderly_outlined;
      case 'housing':
        return Icons.home_work_outlined;
      case 'farmer support':
        return Icons.agriculture;
      case 'women welfare':
        return Icons.woman_outlined;
      case 'employment':
        return Icons.work_outline;
      default:
        return Icons.account_balance_outlined;
    }
  }
}
