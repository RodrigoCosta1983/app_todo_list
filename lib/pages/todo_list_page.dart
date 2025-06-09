import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class TodoListPage extends StatefulWidget {
  TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Não foi possível abrir a URL';
      }
    } catch (e) {
      print('Erro ao abrir a URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir a URL')),
      );
    }
  }

  final TextEditingController todoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> savedLists = [];
  String? currentListName;
  bool _isSearching = false;

  Map<String, dynamic>? _lastRemovedProduct;
  int? _lastRemovedProductIndex;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSavedLists();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = products.where((product) {
        return product['title'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadSavedLists() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('savedLists') ?? [];
    setState(() {
      savedLists = keys;
    });
  }

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
      print('Erro ao exportar CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar CSV.')),
      );
    }
  }


  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsData = prefs.getString('products');
    if (productsData != null) {
      setState(() {
        products = List<Map<String, dynamic>>.from(
          json.decode(productsData).map((product) => {
            'title': product['title'],
            'completed': product['completed'] ?? false,
            'value': product['value'] ?? '',
            'quantity': product['quantity'] ?? '',
            'valueController': TextEditingController(
                text: product['value']?.toString() ?? ''),
            'quantityController': TextEditingController(
                text: product['quantity']?.toString() ?? ''),
          }),
        );
        _filterProducts();
      });
    } else {
      setState(() {
        products = [];
      });
      _filterProducts();
    }
  }

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
        })
            .toList()));
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
        })
            .toList()));

    List<String> savedLists = prefs.getStringList('savedLists') ?? [];
    if (!savedLists.contains(name)) {
      savedLists.add(name);
      await prefs.setStringList('savedLists', savedLists);
      _loadSavedLists();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lista "$name" salva com sucesso!')),
    );
  }

  Future<List<String>> _getSavedLists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('savedLists') ?? [];
  }

  Future<void> _deleteList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('list_$listName');
    List<String> savedLists = prefs.getStringList('savedLists') ?? [];
    savedLists.remove(listName);
    await prefs.setStringList('savedLists', savedLists);
    _loadSavedLists();
  }

  void _loadListByName(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final listData = prefs.getString('list_$listName');
    if (listData != null) {
      final decoded = List<Map<String, dynamic>>.from(
        json.decode(listData).map((product) => {
          'title': product['title'],
          'completed': product['completed'] ?? false,
          'value': product['value'] ?? '',
          'quantity': product['quantity'] ?? '',
          'valueController': TextEditingController(
              text: product['value']?.toString() ?? ''),
          'quantityController': TextEditingController(
              text: product['quantity']?.toString() ?? ''),
        }),
      );
      setState(() {
        currentListName = listName;
        products = decoded;
      });
      _filterProducts();
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
                    "Lista de Compras ${currentListName != null ? '(${currentListName})' : ''}",
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    "Exportado em: $formattedDate",
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
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
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
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
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
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
      print('Erro ao exportar PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar PDF.')),
      );
    }
  }


  void _addProduct() {
    String text = todoController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        products.add({
          'title': text,
          'completed': false,
          'value': '',
          'quantity': '',
          'valueController': TextEditingController(text: ''),
          'quantityController': TextEditingController(text: ''),
        });
      });
      todoController.clear();
      _saveProducts();
      _filterProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${text}" adicionado à lista!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateValue(int index, String value) {
    setState(() {
      products[index]['value'] = value;
      products[index]['valueController'].text = value;
    });
    _saveProducts();
  }

  void _updateQuantity(int index, String quantity) {
    setState(() {
      products[index]['quantity'] = quantity;
      products[index]['quantityController'].text = quantity;
    });
    _saveProducts();
  }

  void _removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
    _saveProducts();
    _filterProducts();
  }

  double _calculateTotalValue() {
    return products.fold(0.0, (sum, product) {
      double value =
          double.tryParse(product['value'].toString().replaceAll(',', '.')) ??
              0.0;
      int quantity = int.tryParse(product['quantity'].toString()) ?? 0;
      return sum + (value * quantity);
    });
  }

  void _showSaveDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Salvar Lista'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: 'Nome da lista'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveCurrentListWithName(nameController.text);
              Navigator.of(context).pop();
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

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
                  children: savedLists.map((listName) {
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
                            content:
                            Text("Deseja apagar a lista \"$listName\"?"),
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
                          SnackBar(content: Text('Lista "$listName" apagada')),
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
                              leading: Icon(Icons.link),
                              title: Text("RodrigoCosta-DEV"),
                              onTap: () =>
                                  _launchURL('https://rodrigocosta-dev.com'),
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
            decoration: InputDecoration(
              hintText: 'Pesquisar produtos...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.black38),
            ),
            style: TextStyle(color: Colors.black87),
            autofocus: true,
          )
              : Text(
            currentListName != null && currentListName!.isNotEmpty
                ? "Lista de Compras (${currentListName!})"
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
              icon: Icon(Icons.save),
              onPressed: _showSaveDialog,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
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
                    child: _filteredProducts.isEmpty && !_isSearching
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "Sua lista de compras está vazia.\nAdicione um item!",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return Dismissible(
                          key: Key(product['title']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            _lastRemovedProduct = Map<String, dynamic>.from(product);
                            _lastRemovedProductIndex = products.indexOf(product);

                            if (_lastRemovedProductIndex != -1) {
                              _removeProduct(_lastRemovedProductIndex!);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${_lastRemovedProduct!['title']}" removido.'),
                                action: SnackBarAction(
                                  label: 'Desfazer',
                                  onPressed: () {
                                    if (_lastRemovedProduct != null && _lastRemovedProductIndex != null) {
                                      setState(() {
                                        products.insert(_lastRemovedProductIndex!, _lastRemovedProduct!);
                                      });
                                      _saveProducts();
                                      _filterProducts();
                                    }
                                  },
                                ),
                                duration: Duration(seconds: 5),
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
                                      product['completed'] = value ?? false;
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
                                      child: TextField(
                                        controller: product[
                                        'valueController'],
                                        decoration: const InputDecoration(
                                          labelText: "Valor do produto",
                                          border: OutlineInputBorder(),
                                          prefixText: 'R\$ ', // Adiciona o prefixo monetário
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true), // Altera para permitir decimais
                                        onChanged: (text) =>
                                            _updateValue(products.indexOf(product), text),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: product[
                                        'quantityController'],
                                        decoration: const InputDecoration(
                                          labelText: "Quantidade",
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (text) =>
                                            _updateQuantity(products.indexOf(product), text),
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
                        icon: Icon(Icons.share),
                        label: Text("CSV"),
                        onPressed: _exportToCSV,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text("PDF"),
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