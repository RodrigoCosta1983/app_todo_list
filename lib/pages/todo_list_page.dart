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
  List<Map<String, dynamic>> products = [];
  List<String> savedLists = [];
  String? currentListName;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSavedLists();
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

      // Cabeçalhos
      rows.add(['Produto', 'Quantidade', 'Valor (R\$)']);

      // Produtos
      for (var product in products) {
        rows.add([
          product['title'],
          product['quantity'].toString(),
          product['value'].toString(),
        ]);
      }

      // Linha em branco + total
      rows.add([]);
      rows.add([
        'Total',
        '',
        _calculateTotalValue().toStringAsFixed(2),
      ]);

      // Converter para CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Caminho do arquivo
      final String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/lista_compras_$formattedDate.csv';
      final file = File(path);
      await file.writeAsString(csv);

      // Compartilhar
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
      });
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

                // Tabela com os produtos
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
                const Divider(), // opcional, só se quiser separar visualmente

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
          title: Text("Lista de Compras"),
          actions: [
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
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: Key(products[index]['title']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            _removeProduct(index);
                          },
                          child: Column(
                            children: [
                              ListTile(
                                leading: Checkbox(
                                  value: products[index]['completed'],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      products[index]['completed'] =
                                          value ?? false;
                                    });
                                    _saveProducts();
                                  },
                                ),
                                title: Text(products[index]['title']),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: products[index]
                                            ['valueController'],
                                        decoration: const InputDecoration(
                                          labelText: "Valor do produto",
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (text) =>
                                            _updateValue(index, text),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: products[index]
                                            ['quantityController'],
                                        decoration: const InputDecoration(
                                          labelText: "Quantidade",
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (text) =>
                                            _updateQuantity(index, text),
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
                  //   Text('  Quantidade total de produtos: ${products.length}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        products.clear();
                      });
                      _saveProducts();
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

                  // ElevatedButton(
                  //   onPressed: () async {
                  //     final directory = await getTemporaryDirectory();
                  //     final path = '${directory.path}/teste.txt';
                  //     final file = File(path);
                  //     await file
                  //         .writeAsString("Arquivo de teste salvo com sucesso!");
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(
                  //           content: Text('Arquivo de teste salvo em:\n$path')),
                  //     );
                  //     await Share.shareXFiles([XFile(path)],
                  //         text: 'Arquivo de teste compartilhado');
                  //   },
                  //   child: Text('Testar gravação'),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
