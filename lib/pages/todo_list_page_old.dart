import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  // --- CONTROLLERS ---
  final TextEditingController todoController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- STATE VARIABLES ---
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> savedLists = [];
  String? currentListName;
  bool _isSearching = false;
  String _appVersion = 'N/A';

  // For undo functionality
  Map<String, dynamic>? _lastRemovedProduct;
  int? _lastRemovedProductIndex;

  // --- LIFECYCLE METHODS ---

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSavedLists();
    _loadAppVersion();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    todoController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- CORE STATE MANAGEMENT (Products List) ---

  void _addProduct() {
    String text = todoController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        products.add({
          'title': text,
          'completed': false,
          'value': '',
          'quantity': 1,
          'valueController': TextEditingController(text: ''),
          'createdAt': DateTime.now().toIso8601String(),
        });
        _sortProducts();
      });

      todoController.clear();
      _saveProducts();
      _filterProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${text}" adicionado à lista!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
    _saveProducts();
    _filterProducts();
  }

  void _updateValue(int index, String value) {
    setState(() {
      products[index]['value'] = value;
      products[index]['valueController'].text = value;
    });
    _saveProducts();
  }

  void _incrementQuantity(int index) {
    setState(() {
      products[index]['quantity']++;
    });
    _saveProducts();
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (products[index]['quantity'] > 0) {
        products[index]['quantity']--;
      }
    });
    _saveProducts();
  }

  void _sortProducts() {
    products.sort((a, b) {
      final DateTime aDate = DateTime.parse(a['createdAt']);
      final DateTime bDate = DateTime.parse(b['createdAt']);
      return bDate.compareTo(aDate);
    });
  }

  // --- PERSISTENCE LOGIC (SharedPreferences) ---

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'products',
        json.encode(products
            .map((product) => {
          'title': product['title'],
          'completed': product['completed'],
          'value': product['value'],
          'quantity': product['quantity'],
          'createdAt': product['createdAt'],
        })
            .toList()));
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsData = prefs.getString('products');
    if (productsData != null) {
      setState(() {
        products = List<Map<String, dynamic>>.from(
          json.decode(productsData).map((product) {
            final rawQuantity = product['quantity'];
            int quantity = 1;
            if (rawQuantity is int) {
              quantity = rawQuantity;
            } else if (rawQuantity is String) {
              quantity = int.tryParse(rawQuantity) ?? 1;
            }

            return {
              'title': product['title'],
              'completed': product['completed'] ?? false,
              'value': product['value'] ?? '',
              'quantity': quantity,
              'valueController':
              TextEditingController(text: product['value']?.toString() ?? ''),
              'createdAt':
              product['createdAt'] ?? DateTime.now().toIso8601String(),
            };
          }),
        );
        _sortProducts();
        _filterProducts();
      });
    } else {
      setState(() {
        products = [];
      });
      _filterProducts();
    }
  }

  Future<void> _saveCurrentListWithName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'list_$name',
        json.encode(products
            .map((product) => {
          'title': product['title'],
          'completed': product['completed'],
          'value': product['value'],
          'quantity': product['quantity'],
          'createdAt': product['createdAt'],
        })
            .toList()));

    List<String> currentSavedLists = prefs.getStringList('savedLists') ?? [];
    if (!currentSavedLists.contains(name)) {
      currentSavedLists.add(name);
      await prefs.setStringList('savedLists', currentSavedLists);
      _loadSavedLists();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lista "$name" salva com sucesso!')),
    );
  }

  void _loadListByName(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final listData = prefs.getString('list_$listName');
    if (listData != null) {
      final decoded = List<Map<String, dynamic>>.from(
        json.decode(listData).map((product) {
          final rawQuantity = product['quantity'];
          int quantity = 1;
          if (rawQuantity is int) {
            quantity = rawQuantity;
          } else if (rawQuantity is String) {
            quantity = int.tryParse(rawQuantity) ?? 1;
          }

          return {
            'title': product['title'],
            'completed': product['completed'] ?? false,
            'value': product['value'] ?? '',
            'quantity': quantity,
            'valueController':
            TextEditingController(text: product['value']?.toString() ?? ''),
            'createdAt':
            product['createdAt'] ?? DateTime.now().toIso8601String(),
          };
        }),
      );
      setState(() {
        currentListName = listName;
        products = decoded;
        _sortProducts();
      });
      _filterProducts();
    }
  }

  Future<void> _loadSavedLists() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('savedLists') ?? [];
    setState(() {
      savedLists = keys;
    });
  }

  Future<void> _deleteList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('list_$listName');
    List<String> currentSavedLists = prefs.getStringList('savedLists') ?? [];
    currentSavedLists.remove(listName);
    await prefs.setStringList('savedLists', currentSavedLists);
    _loadSavedLists();
  }

  // --- UI HELPERS & LOGIC ---

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = products.where((product) {
        return product['title'].toLowerCase().contains(query);
      }).toList();
    });
  }

  double _calculateTotalValue() {
    return products.fold(0.0, (sum, product) {
      double value =
          double.tryParse(product['value'].toString().replaceAll(',', '.')) ??
              0.0;
      int quantity = product['quantity'];
      return sum + (value * quantity);
    });
  }

  void _showSaveDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar Lista Atual'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nome da lista'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              String listName = nameController.text.trim();
              if (listName.isNotEmpty) {
                _saveCurrentListWithName(listName);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showCreateEmptyListDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Nova Lista'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nome da nova lista'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(context).pop(); // Fecha o dialog
                Navigator.of(context).pop(); // Fecha o drawer

                setState(() {
                  products.clear();
                  currentListName = newName;
                });
                _saveCurrentListWithName(newName);
                _filterProducts();
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  // --- EXPORT & EXTERNAL ACTIONS ---

  Future<void> _exportToCSV() async {
    try {
      List<List<String>> rows = [];
      rows.add(['Produto', 'Quantidade', 'Valor (R\$)']);

      for (var product in products) {
        rows.add([
          product['title'],
          product['quantity'].toString(),
          product['value'].toString(),
        ]);
      }

      rows.add([]);
      rows.add([
        'Total',
        '',
        _calculateTotalValue().toStringAsFixed(2),
      ]);

      String csv = const ListToCsvConverter().convert(rows);
      final String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/lista_compras_$formattedDate.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'Minha lista de compras em CSV');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao exportar CSV.')),
      );
    }
  }

  Future<void> _exportToPDF() async {
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
                    style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Produto', 'Quantidade', 'Valor (R\$)'],
                  data: products.map((product) {
                    return [
                      product['title'],
                      product['quantity'].toString(),
                      product['value'].toString()
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                  },
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total: R\$ ${_calculateTotalValue().toStringAsFixed(2)}',
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao exportar PDF.')),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Não foi possível abrir a URL';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao abrir a URL')),
      );
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        onDrawerChanged: (isOpened) {
          if (isOpened) _loadSavedLists();
        },
        drawer: Drawer(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text("Menu",
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
                ExpansionTile(
                  title: const Text("Minhas Listas"),
                  children: [
                    ListTile(
                      leading: Icon(Icons.add_circle_outline,
                          color: Theme.of(context).primaryColor),
                      title: const Text("Criar nova lista",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: _showCreateEmptyListDialog,
                    ),
                    ...savedLists.map((listName) {
                      return Dismissible(
                        key: Key(listName),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirmar exclusão"),
                              content: Text(
                                  "Deseja apagar a lista \"$listName\"?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Apagar"),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await _deleteList(listName);
                          if (currentListName == listName) {
                            setState(() {
                              currentListName = null;
                              products.clear();
                            });
                            _saveProducts();
                            _filterProducts();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Lista "$listName" apagada')),
                          );
                        },
                        child: ListTile(
                          title: Text(listName),
                          onTap: () {
                            _loadListByName(listName);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("Sobre"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Sobre o aplicativo"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Este é um app de lista de compras desenvolvido por RodrigoCosta-DEV. "
                                  "Você pode criar, salvar, apagar e exportar listas como PDF e CSV.",
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.link),
                              title: const Text("RodrigoCosta-DEV"),
                              onTap: () =>
                                  _launchURL('https://rodrigocosta-dev.com'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                'Versão do App: $_appVersion',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Fechar"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          title: _isSearching
              ? TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Pesquisar produtos...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.black45),
            ),
            style: const TextStyle(color: Colors.black87),
            autofocus: true,
          )
              : Text(
            currentListName != null && currentListName!.isNotEmpty
                ? "Lista (${currentListName!})"
                : "Lista de Compras",
          ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filterProducts();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _showSaveDialog,
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/fundo.webp"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: todoController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Adicione um produto',
                            hintText: 'Ex: Notebook',
                          ),
                          onSubmitted: (value) => _addProduct(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addProduct,
                        child: const Icon(Icons.add, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredProducts.isEmpty && products.isEmpty
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "Sua lista de compras está vazia.\nAdicione um item!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final productIndex = products.indexOf(product);
                        return Dismissible(
                          key: Key(product['title'] +
                              productIndex.toString()), // Chave única
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            ScaffoldMessenger.of(context)
                                .hideCurrentSnackBar();

                            _lastRemovedProduct =
                            Map<String, dynamic>.from(product);
                            _lastRemovedProductIndex =
                                products.indexOf(product);

                            if (_lastRemovedProductIndex != -1) {
                              _removeProduct(_lastRemovedProductIndex!);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '"${_lastRemovedProduct!['title']}" removido.'),
                                action: SnackBarAction(
                                  label: 'Desfazer',
                                  onPressed: () {
                                    if (_lastRemovedProduct != null &&
                                        _lastRemovedProductIndex !=
                                            null) {
                                      setState(() {
                                        products.insert(
                                            _lastRemovedProductIndex!,
                                            _lastRemovedProduct!);
                                        _sortProducts();
                                      });
                                      _saveProducts();
                                      _filterProducts();
                                    }
                                  },
                                ),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              ListTile(
                                leading: Checkbox(
                                  value: product['completed'],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      product['completed'] =
                                          value ?? false;
                                    });
                                    _saveProducts();
                                  },
                                ),
                                title: Text(product['title']),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller:
                                        product['valueController'],
                                        decoration:
                                        const InputDecoration(
                                          labelText: "Valor",
                                          border: OutlineInputBorder(),
                                          prefixText: 'R\$ ',
                                        ),
                                        keyboardType:
                                        const TextInputType
                                            .numberWithOptions(
                                            decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                        onChanged: (text) => _updateValue(
                                            productIndex, text),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Text("Qtd:",
                                              style: TextStyle(
                                                  fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons
                                                .remove_circle_outline),
                                            onPressed: () =>
                                                _decrementQuantity(
                                                    productIndex),
                                            color: Colors.red,
                                          ),
                                          Text(
                                            product['quantity']
                                                .toString(),
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons
                                                .add_circle_outline),
                                            onPressed: () =>
                                                _incrementQuantity(
                                                    productIndex),
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                      'Valor total dos produtos: R\$ ${_calculateTotalValue().toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        products.clear();
                        currentListName = null;
                      });
                      _saveProducts();
                      _filterProducts();
                    },
                    child: const Text('Limpar tudo'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text("CSV"),
                        onPressed: _exportToCSV,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("PDF"),
                        onPressed: _exportToPDF,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}