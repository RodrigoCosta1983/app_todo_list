// lib/todo_list_page_old.dart

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

import 'product_model.dart';
import 'shopping_list_service.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  // --- STATE VARIABLES ---
  final _listService = ShoppingListService();
  final _productNameController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Controllers for each product's value field, mapped by product ID.
  final Map<String, TextEditingController> _valueControllers = {};

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _savedListNames = [];
  String? _currentListName;

  Product? _lastRemovedProduct;
  int? _lastRemovedProductIndex;

  bool _isSearching = false;
  String _appVersion = '...';

  // --- LIFECYCLE METHODS ---
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
    // Dispose all dynamic controllers to prevent memory leaks.
    for (var controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- DATA & LOGIC METHODS ---
  Future<void> _loadInitialData() async {
    _appVersion = (await PackageInfo.fromPlatform()).version;
    await _loadCurrentList();
    await _loadSavedListNames();
    setState(() {});
  }

  Future<void> _loadCurrentList() async {
    _products = await _listService.loadCurrentList();
    _updateValueControllers();
    _filterProducts();
  }

  Future<void> _loadSavedListNames() async {
    _savedListNames = await _listService.getSavedListNames();
    setState(() {});
  }

  Future<void> _saveCurrentList() async {
    await _listService.saveCurrentList(_products);
  }

  void _updateValueControllers() {
    // Dispose old controllers
    for (var controller in _valueControllers.values) {
      controller.dispose();
    }
    _valueControllers.clear();

    // Create new ones for the current products
    for (var product in _products) {
      _valueControllers[product.id] = TextEditingController(
        text: product.value > 0 ? product.value.toStringAsFixed(2) : '',
      );
    }
    setState(() {});
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
      _valueControllers[newProduct.id] = TextEditingController();
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
    _lastRemovedProductIndex = _products.indexWhere((p) => p.id == productToRemove.id);

    if (_lastRemovedProductIndex != -1) {
      setState(() {
        _products.removeAt(_lastRemovedProductIndex!);
        // Dispose and remove the controller for the deleted product.
        _valueControllers[productToRemove.id]?.dispose();
        _valueControllers.remove(productToRemove.id);
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
        _valueControllers[_lastRemovedProduct!.id] = TextEditingController(
            text: _lastRemovedProduct!.value > 0 ? _lastRemovedProduct!.value.toStringAsFixed(2) : ''
        );
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
      for (var controller in _valueControllers.values) {
        controller.dispose();
      }
      _valueControllers.clear();
    });
    _filterProducts();
    _saveCurrentList();
  }

  double _calculateTotalValue() {
    return _products.fold(0.0, (sum, product) {
      return sum + (product.value * product.quantity);
    });
  }

  // --- NAVIGATION & DIALOGS ---
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

  void _showSnackBar(String message, {VoidCallback? onUndo, bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        action: onUndo != null ? SnackBarAction(label: 'Desfazer', onPressed: onUndo) : null,
      ),
    );
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
            onPressed: () async {
              final listName = nameController.text.trim();
              if (listName.isNotEmpty) {
                await _listService.saveListWithName(listName, _products);
                setState(() {
                  _currentListName = listName;
                });
                await _loadSavedListNames();
                Navigator.of(context).pop();
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
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                // Clear current state
                setState(() {
                  _products.clear();
                  _currentListName = newName;
                });
                _updateValueControllers();
                _filterProducts();
                // Save the new empty list
                await _listService.saveListWithName(newName, _products);
                await _loadSavedListNames();
                // Close dialog and drawer
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILD METHODS ---
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
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        autofocus: true,
      )
          : Text(
        _currentListName != null && _currentListName!.isNotEmpty
            ? "Lista: $_currentListName"
            : "Lista de Compras",
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
    // ... O código do Drawer vai aqui, similar ao original, mas usando as novas funções.
    // Este método ficou longo, mas sua lógica é focada apenas no Drawer.
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ExpansionTile(
            title: const Text("Minhas Listas"),
            initiallyExpanded: true,
            children: [
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                title: const Text("Criar nova lista", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: _showCreateEmptyListDialog,
              ),
              ..._savedListNames.map((listName) => _buildSavedListItem(listName)).toList(),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Sobre"),
            onTap: () {
              // ... Lógica do dialog 'Sobre' ...
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavedListItem(String listName) {
    // ... Código do Dismissible para apagar listas salvas ...
    return Dismissible(
      key: Key(listName),
      direction: DismissDirection.endToStart,
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white)),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(context: context, builder: (context) => AlertDialog(
          title: const Text("Confirmar exclusão"),
          content: Text("Deseja apagar a lista \"$listName\"?"),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancelar")),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Apagar")),
          ],
        )) ?? false;
      },
      onDismissed: (direction) async {
        await _listService.deleteList(listName);
        if (_currentListName == listName) {
          _clearAllProducts();
        }
        _loadSavedListNames();
        _showSnackBar('Lista "$listName" apagada');
      },
      child: ListTile(
        title: Text(listName, style: TextStyle(fontWeight: _currentListName == listName ? FontWeight.bold : FontWeight.normal)),
        onTap: () async {
          _products = await _listService.loadListByName(listName);
          setState(() {
            _currentListName = listName;
          });
          _updateValueControllers();
          _filterProducts();
          Navigator.of(context).pop(); // Fecha o drawer
        },
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage("assets/images/fundo.webp"), fit: BoxFit.cover),
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
              fillColor: Colors.white70,
              filled: true,
            ),
            onSubmitted: (_) => _addProduct(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addProduct,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: const Icon(Icons.add, size: 30),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty && _products.isNotEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text("Nenhum produto encontrado na busca.", style: TextStyle(fontSize: 18, color: Colors.white, backgroundColor: Colors.black54)));
    }

    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout_rounded, size: 80, color: Colors.white70),
            SizedBox(height: 16),
            Text("Sua lista está vazia!", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductItem(product);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: ValueKey(product.id),
        direction: DismissDirection.endToStart,
        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white)),
        onDismissed: (_) => _removeProduct(product),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                leading: Checkbox(
                  value: product.completed,
                  onChanged: (value) => _updateProduct(product.copyWith(completed: value)),
                ),
                title: Text(product.title, style: TextStyle(decoration: product.completed ? TextDecoration.lineThrough : TextDecoration.none)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Campo de Valor
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _valueControllers[product.id],
                        decoration: const InputDecoration(
                          labelText: "Valor",
                          border: OutlineInputBorder(),
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        onChanged: (text) {
                          final value = double.tryParse(text) ?? 0.0;
                          // Esta é uma maneira de atualizar sem reconstruir o widget inteiro
                          final index = _products.indexWhere((p) => p.id == product.id);
                          if (index != -1) {
                            _products[index] = product.copyWith(value: value);
                            // Não chama _save aqui para melhor performance, salva ao sair do campo ou em outra ação
                          }
                        },
                        onSubmitted: (_) => _saveCurrentList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Stepper de Quantidade
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Qtd:", style: TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: product.quantity > 1 ? () => _updateProduct(product.copyWith(quantity: product.quantity - 1)) : null,
                            color: Colors.red,
                          ),
                          Text(product.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _updateProduct(product.copyWith(quantity: product.quantity + 1)),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsAndActions() {
    final total = _calculateTotalValue();
    return Column(
      children: [
        Text(
          'Valor total: R\$ ${total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, backgroundColor: Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(icon: const Icon(Icons.delete_sweep), label: const Text("Limpar"), onPressed: _products.isEmpty ? null : _clearAllProducts, style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800])),
            ElevatedButton.icon(icon: const Icon(Icons.share), label: const Text("CSV"), onPressed: _products.isEmpty ? null : _exportToCSV),
            ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf), label: const Text("PDF"), onPressed: _products.isEmpty ? null : _exportToPDF),
          ],
        )
      ],
    );
  }

  // --- EXPORT METHODS ---
  // --- EXPORT METHODS ---
  Future<void> _exportToCSV() async {
    try {
      List<List<String>> rows = [];
      // Cabeçalho
      rows.add(['Produto', 'Quantidade', 'Valor (R\$)']);

      // Itens (usando a variável correta '_products')
      for (var product in _products) {
        rows.add([
          product.title,
          product.quantity.toString(),
          product.value.toStringAsFixed(2),
        ]);
      }

      // Linha do Total
      rows.add([]);
      rows.add(['Total', '', _calculateTotalValue().toStringAsFixed(2)]);

      String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');

      final String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/lista_compras_$formattedDate.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'Minha lista de compras em CSV');
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
                    "Lista de Compras ${ _currentListName != null ? '($_currentListName)' : ''}",
                    style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
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
                  data: _products.map((product) { // Usando a variável correta '_products'
                    return [
                      product.title,
                      product.quantity.toString(),
                      'R\$ ${product.value.toStringAsFixed(2)}'
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(2),
                  },
                ),
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total: R\$ ${_calculateTotalValue().toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
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

      await Share.shareXFiles([XFile(path)], text: 'Minha lista de compras em PDF');
    } catch (e) {
      _showSnackBar('Erro ao exportar PDF.', isError: true);
    }
  }
}