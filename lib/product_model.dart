// lib/product_model.dart

import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Product {
  final String id;
  final String title;
  final bool completed;
  final double value;
  final int quantity;

  Product({
    String? id,
    required this.title,
    this.completed = false,
    this.value = 0.0,
    this.quantity = 1,
  }) : id = id ?? uuid.v4(); // Gera um ID único se não for fornecido

  // Método auxiliar para criar cópias modificadas do objeto, mantendo a imutabilidade.
  Product copyWith({
    String? id,
    String? title,
    bool? completed,
    double? value,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      value: value ?? this.value,
      quantity: quantity ?? this.quantity,
    );
  }

  // Converte um Map (geralmente vindo de um JSON) em um objeto Product.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      // Garante que o valor seja lido como double, independentemente do tipo numérico.
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  // Converte um objeto Product em um Map para ser salvo como JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'value': value,
      'quantity': quantity,
    };
  }
}