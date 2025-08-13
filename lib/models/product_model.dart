// lib/models/product_model.dart

import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Product {
  final String id;
  final String title;
  final bool completed;
  final double value;
  final int quantity;
  final DateTime createdAt; // <<< CAMPO ADICIONADO

  Product({
    String? id,
    required this.title,
    this.completed = false,
    this.value = 0.0,
    this.quantity = 1,
    DateTime? createdAt, // <<< CAMPO ADICIONADO
  })  : id = id ?? uuid.v4(),
        createdAt = createdAt ?? DateTime.now(); // <<< VALOR PADRÃO

  Product copyWith({
    String? id,
    String? title,
    bool? completed,
    double? value,
    int? quantity,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      value: value ?? this.value,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      // Lê a data; se não existir, usa a data atual
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'value': value,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(), // <<< CAMPO ADICIONADO
    };
  }
}