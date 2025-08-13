// lib/pages/todo_list_page.dart

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
import 'package:url_launcher/url_launcher.dart';
import 'package:todo_list/models/product_model.dart';
import 'package:todo_list/services/shopping_list_service.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _listService = ShoppingListService();
  final _productNameController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, TextEditingController> _valueControllers = {};

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _savedListNames = [];
  String? _currentListName;
  Product? _lastRemovedProduct;
  int? _lastRemovedProductIndex;
  bool _isSearching = false;
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadInitialData();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    for (var controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _appVersion = (await PackageInfo.fromPlatform()).version;
    await _loadCurrentList();
    await _loadSavedListNames();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCurrentList() async {
    _products = await _listService.loadCurrentList();
    _sortProducts();
    _filterProducts();
  }

  Future<void> _loadSavedListNames() async {
    _savedListNames = await _listService.getSavedListNames();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveCurrentList() async {
    await _listService.saveCurrentList(_products);
  }

  void _sortProducts() {
    if (_products.isNotEmpty) {
      _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addProduct() {
    final text = _productNameController.text.trim();
    if (text.isEmpty) return;
    final newProduct = Product(title: text);
    setState(() {
      _products.add(newProduct);
      _sortProducts();
    });
    _productNameController.clear();
    _filterProducts();
    _saveCurrentList();
    _showSnackBar('"${newProduct.title}" adicionado!');
  }

  void _updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      setState(() {
        _products[index] = updatedProduct;
      });
      _filterProducts();
      _saveCurrentList();
    }
  }

  void _removeProduct(Product productToRemove) {
    _lastRemovedProduct = productToRemove;
    _lastRemovedProductIndex =
        _products.indexWhere((p) => p.id == productToRemove.id);

    if (_lastRemovedProductIndex != -1) {
      setState(() {
        _products.removeAt(_lastRemovedProductIndex!);
      });
      _filterProducts();
      _saveCurrentList();
      _showSnackBar(
        '"${_lastRemovedProduct!.title}" removido.',
        onUndo: _undoRemove,
      );
    }
  }

  void _undoRemove() {
    if (_lastRemovedProduct != null && _lastRemovedProductIndex != null) {
      setState(() {
        _products.insert(_lastRemovedProductIndex!, _lastRemovedProduct!);
      });
      _filterProducts();
      _saveCurrentList();
      _lastRemovedProduct = null;
      _lastRemovedProductIndex = null;
    }
  }

  void _clearAllProducts() {
    setState(() {
      _products.clear();
      _currentListName = null;
    });
    _filterProducts();
    _saveCurrentList();
  }

  double _calculateTotalValue() {
    return _products.fold(0.0, (sum, product) {
      return sum + (product.value * product.quantity);
    });
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Não foi possível abrir a URL';
      }
    } catch (e) {
      _showSnackBar('Erro ao abrir a URL.', isError: true);
    }
  }

  void _showSnackBar(String message,
      {VoidCallback? onUndo, bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        action: onUndo != null
            ? SnackBarAction(label: 'Desfazer', onPressed: onUndo)
            : null,
      ),
    );
  }

  void _showSaveDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salvar Lista Atual'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nome da lista'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final listName = nameController.text.trim();
              if (listName.isNotEmpty) {
                await _listService.saveListWithName(listName, _products);
                if (!mounted) return; // CORREÇÃO de async gap
                setState(() {
                  _currentListName = listName;
                });
                await _loadSavedListNames();
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                _showSnackBar('Lista "$listName" salva com sucesso!');
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Criar Nova Lista'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nome da nova lista'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _products.clear();
                  _currentListName = newName;
                });
                _filterProducts();
                await _listService.saveListWithName(newName, _products);
                await _loadSavedListNames();
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Criar'),
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
          if (isOpened) _loadSavedListNames();
        },
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Pesquisar produtos...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.black54),
        ),
        style: const TextStyle(color: Colors.black87, fontSize: 18),
        autofocus: true,
      )
          : Text(
        _currentListName ?? "Lista de Compras",
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _showSaveDialog,
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
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
            initiallyExpanded: true,
            children: [
              ListTile(
                leading: Icon(Icons.add_circle_outline,
                    color: Theme.of(context).primaryColor),
                title: const Text("Criar nova lista",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: _showCreateEmptyListDialog,
              ),
              // CORREÇÃO: Removido o .toList() desnecessário
              ..._savedListNames.map((listName) => _buildSavedListItem(listName)),
            ],
          ),

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
    );
  }

  Widget _buildSavedListItem(String listName) {
    return Dismissible(
      key: Key(listName),
      direction: DismissDirection.endToStart,
      background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete, color: Colors.white)),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text("Confirmar exclusão"),
              content: Text("Deseja apagar a lista \"$listName\"?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text("Cancelar")),
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text("Apagar")),
              ],
            )) ??
            false;
      },
      onDismissed: (direction) async {
        await _listService.deleteList(listName);
        if (_currentListName == listName) {
          _clearAllProducts();
        }
        await _loadSavedListNames();
        if (!mounted) return;
        _showSnackBar('Lista "$listName" apagada');
      },
      child: ListTile(
        title: Text(listName,
            style: TextStyle(
                fontWeight:
                _currentListName == listName ? FontWeight.bold : FontWeight.normal)),
        onTap: () async {
          _products = await _listService.loadListByName(listName);
          if (!mounted) return;
          setState(() {
            _currentListName = listName;
          });
          _sortProducts();
          _filterProducts();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/fundo.webp"), fit: BoxFit.cover),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputArea(),
            const SizedBox(height: 16),
            Expanded(child: _buildProductList()),
            const SizedBox(height: 8),
            _buildTotalsAndActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _productNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Adicione um produto',
              hintText: 'Ex: Arroz',
            ),
            onSubmitted: (_) => _addProduct(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addProduct,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.add, size: 30),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty &&
        _products.isNotEmpty &&
        _searchController.text.isNotEmpty) {
      return const Center(
          child: Text("Nenhum produto encontrado.",
              style: TextStyle(fontSize: 18)));
    }

    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout_rounded,
                size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("Sua lista está vazia!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        _valueControllers.putIfAbsent(
            product.id,
                () => TextEditingController(
                text: product.value > 0
                    ? product.value.toStringAsFixed(2)
                    : ''));
        return _buildProductItem(product);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Dismissible(
        key: ValueKey(product.id),
        direction: DismissDirection.endToStart,
        background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white)),
        onDismissed: (_) => _removeProduct(product),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: product.completed,
                  onChanged: (value) =>
                      _updateProduct(product.copyWith(completed: value)),
                ),
                Expanded(
                  child: Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: product.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 48), // Align with Checkbox
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _valueControllers[product.id],
                    decoration: const InputDecoration(
                      labelText: "Valor",
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    onChanged: (text) {
                      final value =
                          double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
                      final index =
                      _products.indexWhere((p) => p.id == product.id);
                      if (index != -1) {
                        _products[index] = product.copyWith(value: value);
                      }
                    },
                    onSubmitted: (_) => _saveCurrentList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text("Qtd:", style: TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: product.quantity > 1
                            ? () => _updateProduct(
                            product.copyWith(quantity: product.quantity - 1))
                            : null,
                        // Usamos 'style' para definir as cores
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.red, // Cor para o ícone quando ATIVADO
                          disabledForegroundColor: Colors.grey.withOpacity(0.5), // Cor para o ícone quando DESATIVADO
                        ),
                      ),

                      Text(product.quantity.toString(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),

                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () => _updateProduct(
                            product.copyWith(quantity: product.quantity + 1)),
                        // Também aplicamos o estilo aqui para consistência
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsAndActions() {
    final total = _calculateTotalValue();
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
            'Valor total dos produtos: R\$ ${_calculateTotalValue().toStringAsFixed(2)}'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _products.isEmpty ? null : _clearAllProducts,
          child: const Text("Limpar tudo"),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text("CSV"),
              onPressed: _products.isEmpty ? null : _exportToCSV,
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("PDF"),
              onPressed: _products.isEmpty ? null : _exportToPDF,
            ),
          ],
        )
      ],
    );
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<String>> rows = [];
      rows.add(['Produto', 'Quantidade', 'Valor (R\$)']);
      for (var product in _products) {
        rows.add([
          product.title,
          product.quantity.toString(),
          product.value.toStringAsFixed(2),
        ]);
      }
      rows.add([]);
      rows.add(['Total', '', _calculateTotalValue().toStringAsFixed(2)]);

      String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');
      final String formattedDate =
      DateFormat('dd-MM-yyyy').format(DateTime.now());
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/lista_compras_$formattedDate.csv';
      final file = File(path);
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(path)],
          text: 'Minha lista de compras em CSV');
    } catch (e) {
      _showSnackBar('Erro ao exportar CSV.', isError: true);
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
                    "Lista de Compras ${_currentListName != null ? '($_currentListName)' : ''}",
                    style: pw.TextStyle(
                        fontSize: 26, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                    child: pw.Text("Exportado em: $formattedDate",
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey600))),
                pw.SizedBox(height: 20),
                // CORREÇÃO: `Table.fromTextArray` -> `TableHelper.fromTextArray`
                pw.TableHelper.fromTextArray(
                  headers: ['Produto', 'Quantidade', 'Valor (R\$)'],
                  data: _products.map((product) {
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
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total: R\$ ${_calculateTotalValue().toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
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
      _showSnackBar('Erro ao exportar PDF.', isError: true);
    }
  }
}