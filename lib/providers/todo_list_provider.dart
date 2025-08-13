// lib/providers/todo_list_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/models/product_model.dart';
import 'package:todo_list/services/shopping_list_service.dart';

class TodoListProvider with ChangeNotifier {
  final ShoppingListService _service = ShoppingListService();

  List<Product> _products = [];
  List<String> _savedListNames = [];
  String? _currentListName;
  Product? _lastRemovedProduct;
  int? _lastRemovedProductIndex;

  List<Product> get products => _products;
  List<String> get savedListNames => _savedListNames;
  String? get currentListName => _currentListName;

  TodoListProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _runBulletproofMigration();
    await loadCurrentList();
    await loadSavedListNames();
  }

  // --- MIGRAÇÃO FINAL (V6) - À PROVA DE BALA ---
  Future<void> _runBulletproofMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final bool migrationDone = prefs.getBool('migration_v6_bulletproof_done') ?? false;

    if (migrationDone) return;

    print("--- INICIANDO MIGRAÇÃO FINAL E COMPLETA (V6) ---");

    Product _parseOldProduct(Map<String, dynamic> json) {
      int quantity = 1;
      if (json['quantity'] != null) {
        if (json['quantity'] is String) {
          quantity = int.tryParse(json['quantity'] as String) ?? 1;
        } else if (json['quantity'] is int) {
          quantity = json['quantity'];
        }
      }

      double value = 0.0;
      if (json['value'] != null) {
        if (json['value'] is String && (json['value'] as String).isNotEmpty) {
          value = double.tryParse((json['value'] as String).replaceAll(',', '.')) ?? 0.0;
        } else if (json['value'] is num) {
          value = (json['value'] as num).toDouble();
        }
      }

      return Product(
        id: json['id'] as String?,
        title: json['title'] as String,
        completed: json['completed'] as bool? ?? false,
        value: value,
        quantity: quantity,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
    }

    final oldMainListData = prefs.getString('products');
    if (oldMainListData != null) {
      print("Migrando a lista principal antiga...");
      try {
        final List<dynamic> decoded = json.decode(oldMainListData);
        final List<Product> migratedProducts =
        decoded.map((item) => _parseOldProduct(item)).toList();
        await _service.saveCurrentList(migratedProducts);
      } catch (e) {
        print("Erro ao migrar a chave 'products': $e");
      }
    }

    final allKeys = prefs.getKeys();
    final Set<String> allListNames = {};

    final List<String>? oldIndex = prefs.getStringList('savedLists');
    if (oldIndex != null) {
      allListNames.addAll(oldIndex.map((name) => name.trim()));
    }

    for (var key in allKeys) {
      if (key.startsWith('list_')) {
        final listName = key.substring(5).trim();
        allListNames.add(listName);

        final oldListData = prefs.getString(key);
        if (oldListData != null) {
          print("Atualizando conteúdo da lista: $listName");
          try {
            final List<dynamic> decoded = json.decode(oldListData);
            final List<Product> migratedProducts =
            decoded.map((item) => _parseOldProduct(item)).toList();
            await _service.saveListWithName(listName, migratedProducts);
            print("Conteúdo de '$listName' atualizado com sucesso.");
          } catch (e) {
            print("Erro ao migrar conteúdo da lista '$listName': $e");
          }
        }
      }
    }

    if (allListNames.isNotEmpty) {
      print("Salvando índice final de listas: ${allListNames.toList()}");
      await _service.saveListNames(allListNames.toList());
    }

    await prefs.setBool('migration_v6_bulletproof_done', true);
    print("--- MIGRAÇÃO FINALIZADA ---");
  }

  Future<void> debug_readAllRawData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    print('================================================');
    print('--- INÍCIO DA LEITURA DE TODOS OS DADOS BRUTOS ---');
    print('Total de chaves encontradas: ${allKeys.length}');
    print('================================================');

    for (var key in allKeys) {
      final value = prefs.get(key);
      print('CHAVE: "$key"');
      print('VALOR: $value');
      print('------------------------------------');
    }

    print('--- FIM DA LEITURA DE TODOS OS DADOS BRUTOS ---');
  }

  Future<void> loadCurrentList() async {
    _products = await _service.loadCurrentList();
    _sortProducts();
    notifyListeners();
  }

  void _sortProducts() {
    if (_products.isNotEmpty) {
      _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<void> loadSavedListNames() async {
    _savedListNames = await _service.getSavedListNames();
    notifyListeners();
  }

  Future<void> loadListByName(String listName) async {
    _products = await _service.loadListByName(listName);
    _currentListName = listName;
    _sortProducts();
    notifyListeners();
  }

  Future<void> addProduct(String title) async {
    if (title.isEmpty) return;
    final newProduct = Product(title: title);
    _products.add(newProduct);
    _sortProducts();
    await _service.saveCurrentList(_products);
    notifyListeners();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      await _service.saveCurrentList(_products);
      notifyListeners();
    }
  }

  Future<void> removeProduct(Product product) async {
    _lastRemovedProduct = product;
    _lastRemovedProductIndex = _products.indexOf(product);
    _products.remove(product);
    await _service.saveCurrentList(_products);
    notifyListeners();
  }

  void undoRemove() {
    if (_lastRemovedProduct != null && _lastRemovedProductIndex != null) {
      _products.insert(_lastRemovedProductIndex!, _lastRemovedProduct!);
      _service.saveCurrentList(_products);
      notifyListeners();
    }
  }

  Future<void> clearAllProducts() async {
    _products.clear();
    if (_currentListName != null) {
      await _service.saveListWithName(_currentListName!, _products);
    }
    await _service.saveCurrentList(_products);
    notifyListeners();
  }

  Future<void> saveListWithName(String listName) async {
    await _service.saveListWithName(listName, _products);
    _currentListName = listName;
    await loadSavedListNames();
    notifyListeners();
  }

  Future<void> createNewList(String listName) async {
    _products.clear();
    _currentListName = listName;
    await _service.saveListWithName(listName, _products);
    await loadSavedListNames();
    notifyListeners();
  }

  Future<void> deleteList(String listName) async {
    await _service.deleteList(listName);
    if (_currentListName == listName) {
      _products.clear();
      _currentListName = null;
      await _service.saveCurrentList(_products);
    }
    await loadSavedListNames();
    notifyListeners();
  }

  double calculateTotalValue() {
    if (_products.isEmpty) return 0.0;
    return _products.fold(0.0, (sum, product) {
      return sum + (product.value * product.quantity);
    });
  }

  Future<bool> exportToPDF() async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final formattedDate = DateFormat('dd/MM/yyyy – HH:mm').format(now);

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "Lista de Compras ${currentListName != null ? '($currentListName)' : ''}",
                    style: pw.TextStyle(
                        fontSize: 26, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    "Exportado em: $formattedDate",
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey600),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Produto', 'Quantidade', 'Valor (R\$)'],
                  data: products.map((product) {
                    return [
                      product.title,
                      product.quantity.toString(),
                      product.value.toStringAsFixed(2)
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total: R\$ ${calculateTotalValue().toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/lista_compras.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(path)],
          text: 'Minha lista de compras em PDF');
      return true;
    } catch (e) {
      print('Erro ao exportar PDF: $e');
      return false;
    }
  }

  Future<bool> exportToCSV() async {
    try {
      List<List<String>> rows = [];
      rows.add(['Produto', 'Quantidade', 'Valor (R\$)']);

      for (var product in products) {
        rows.add([
          product.title,
          product.quantity.toString(),
          product.value.toStringAsFixed(2),
        ]);
      }

      rows.add([]);
      rows.add(['Total', '', calculateTotalValue().toStringAsFixed(2)]);

      String csv = const ListToCsvConverter().convert(rows);
      final String formattedDate =
      DateFormat('dd-MM-yyyy').format(DateTime.now());
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/lista_compras_$formattedDate.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)],
          text: 'Minha lista de compras em CSV');
      return true;
    } catch (e) {
      print('Erro ao exportar CSV: $e');
      return false;
    }
  }
}