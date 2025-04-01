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
    _loadProducts(); // Carrega os produtos salvos ao iniciar o app
  }

  // Método para carregar os produtos armazenados no SharedPreferences
  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsData = prefs.getString('products');
    if (productsData != null) {
      setState(() {
        products = List<Map<String, dynamic>>.from(
          json.decode(productsData).map((product) => {
            'title': product['title'],
            'completed': product['completed'] ?? false,
            'value': product['value'] ?? '', // Mantém o valor salvo
            'quantity': product['quantity'] ?? '', // Mantém a quantidade salva
            'valueController': TextEditingController(text: product['value']?.toString() ?? ''),
            'quantityController': TextEditingController(text: product['quantity']?.toString() ?? ''),
          }),
        );
      });
    }
  }

  // Método para salvar os produtos no SharedPreferences
  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', json.encode(products.map((product) => {
      'title': product['title'],
      'completed': product['completed'],
      'value': product['value'],
      'quantity': product['quantity'],
    }).toList()));
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
      _saveProducts(); // Salva a lista atualizada
    }
  }

  void _updateValue(int index, String value) {
    setState(() {
      products[index]['value'] = value;
      products[index]['valueController'].text = value;
    });
    _saveProducts(); // Salva o valor atualizado
  }

  void _updateQuantity(int index, String quantity) {
    setState(() {
      products[index]['quantity'] = quantity;
      products[index]['quantityController'].text = quantity;
    });
    _saveProducts(); // Salva a quantidade atualizada
  }

  void _removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
    _saveProducts(); // Salva a lista após remoção
  }

  double _calculateTotalValue() {
    return products.fold(0.0, (sum, product) {
      double value = double.tryParse(product['value'].toString().replaceAll(',', '.')) ?? 0.0;
      int quantity = int.tryParse(product['quantity'].toString()) ?? 0;
      return sum + (value * quantity);
    });
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
                                      products[index]['completed'] = value ?? false;
                                    });
                                    _saveProducts();
                                  },
                                ),
                                title: Text(products[index]['title']),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: products[index]['valueController'],
                                        decoration: const InputDecoration(
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
                                        controller: products[index]['quantityController'],
                                        decoration: const InputDecoration(
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
                  Text('Total acumulado dos produtos: R\$ ${_calculateTotalValue().toStringAsFixed(2)}'),
                  Text('  Quantidade total de produtos: ${products.length}'),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
