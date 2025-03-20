import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodoListPage extends StatefulWidget {
  TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TextEditingController todoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsData = prefs.getString('products');
    if (productsData != null) {
      setState(() {
        products = List<Map<String, dynamic>>.from(json.decode(productsData));
      });
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', json.encode(products));
  }

  void _addProduct() {
    String text = todoController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        products.add({'title': text, 'completed': false, 'value': 0.0, 'quantity': 1});
      });
      todoController.clear();
      _saveProducts();
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleProductStatus(int index) {
    setState(() {
      products[index]['completed'] = !products[index]['completed'];
    });
    _saveProducts();
  }

  void _updateValue(int index, String value) {
    setState(() {
      products[index]['value'] = double.tryParse(value) ?? 0.0;
    });
    _saveProducts();
  }

  void _updateQuantity(int index, String quantity) {
    setState(() {
      products[index]['quantity'] = int.tryParse(quantity) ?? 1;
    });
    _saveProducts();
  }

  void _removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
    _saveProducts();
  }

  void _clearProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('products');
    setState(() {
      products.clear();
    });
  }

  double _calculateTotalValue() {
    return products.fold(0.0, (sum, product) => sum + (product['value'] * product['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.add, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: products.isEmpty
                        ? const Center(child: Text("Nenhum produto adicionado!"))
                        : ListView.builder(
                      controller: _scrollController,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: Key(products[index]['title']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: EdgeInsets.symmetric(vertical: 2),
                            padding: EdgeInsets.symmetric(vertical: 4),
                            color: Colors.red.shade300,
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
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
                                    _toggleProductStatus(index);
                                  },
                                ),
                                title: Text(
                                  products[index]['title'],
                                  style: TextStyle(
                                    decoration: products[index]['completed']
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          labelText: "Valor do produto",
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (text) => _updateValue(index, text),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          labelText: "Quantidade",
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (text) => _updateQuantity(index, text),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Total acumulado dos produtos: R\$ ${_calculateTotalValue().toStringAsFixed(2)}  '),
                  Text('  Quantidade total de produtos: ${products.length}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Você possui ${products.where((product) => !product['completed']).length} produtos pendentes'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _clearProducts,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const Text('Limpar tudo'),
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
