// lib/shopping_list_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class ShoppingListService {
  // Constantes para evitar "magic strings" e erros de digitação.
  static const _currentProductsKey = 'current_products';
  static const _savedListsKey = 'saved_lists_keys';
  static String _listPrefix(String name) => 'list_$name';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Carrega a lista que estava ativa na última sessão.
  Future<List<Product>> loadCurrentList() async {
    final prefs = await _prefs;
    final String? productsData = prefs.getString(_currentProductsKey);
    if (productsData == null) return [];

    final List<dynamic> decodedData = json.decode(productsData);
    return decodedData.map((item) => Product.fromJson(item)).toList();
  }

  // Salva a lista ativa atual.
  Future<void> saveCurrentList(List<Product> products) async {
    final prefs = await _prefs;
    final String encodedData =
    json.encode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_currentProductsKey, encodedData);
  }

  // Carrega uma lista específica pelo nome e a define como a lista ativa.
  Future<List<Product>> loadListByName(String listName) async {
    final prefs = await _prefs;
    final String? productsData = prefs.getString(_listPrefix(listName));

    // Se a lista não existir, retorna uma lista vazia.
    if (productsData == null) return [];

    // Define a lista carregada como a nova lista ativa.
    await prefs.setString(_currentProductsKey, productsData);

    final List<dynamic> decodedData = json.decode(productsData);
    return decodedData.map((item) => Product.fromJson(item)).toList();
  }

  // Salva a lista de produtos atual com um nome específico.
  Future<void> saveListWithName(String listName, List<Product> products) async {
    final prefs = await _prefs;
    final String encodedData =
    json.encode(products.map((p) => p.toJson()).toList());

    await prefs.setString(_listPrefix(listName), encodedData);

    final List<String> savedLists = await getSavedListNames();
    if (!savedLists.contains(listName)) {
      savedLists.add(listName);
      await prefs.setStringList(_savedListsKey, savedLists);
    }
  }

  // Retorna os nomes de todas as listas salvas.
  Future<List<String>> getSavedListNames() async {
    final prefs = await _prefs;
    return prefs.getStringList(_savedListsKey) ?? [];
  }

  // Deleta uma lista salva pelo nome.
  Future<void> deleteList(String listName) async {
    final prefs = await _prefs;
    await prefs.remove(_listPrefix(listName));

    final List<String> savedLists = await getSavedListNames();
    savedLists.remove(listName);
    await prefs.setStringList(_savedListsKey, savedLists);
  }

  // Dentro da classe ShoppingListService em lib/services/shopping_list_service.dart
  Future<void> saveListNames(List<String> names) async {
    final prefs = await _prefs;
    await prefs.setStringList(_savedListsKey, names);
  }
}