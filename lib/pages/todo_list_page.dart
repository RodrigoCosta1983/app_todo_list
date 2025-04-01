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
    _loadProducts(); // Carrega os produtos salvos ao iniciar a tela
  }

  // Método para carregar os produtos armazenados no SharedPreferences
  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsData = prefs.getString('products');
    if (productsData != null) {
      setState(() {
        products = List<Map<String, dynamic>>.from(json.decode(productsData));
      });
    }
  }

  // Método para salvar os produtos no SharedPreferences
  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', json.encode(products));
  }

  // Adiciona um novo produto à lista
  void _addProduct() {
    String text = todoController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        products.add({'title': text, 'completed': false, 'value': 0.0, 'quantity': 1});
      });
      todoController.clear();
      _saveProducts();

      // Rola a lista para o final após adicionar um item
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  // Alterna o status de conclusão do produto
  void _toggleProductStatus(int index) {
    setState(() {
      products[index]['completed'] = !products[index]['completed'];
    });
    _saveProducts();
  }

  // Atualiza o valor do produto
  void _updateValue(int index, String value) {
    setState(() {
      products[index]['value'] = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    });
    _saveProducts();
  }

  // Atualiza a quantidade do produto
  void _updateQuantity(int index, String quantity) {
    setState(() {
      products[index]['quantity'] = int.tryParse(quantity) ?? 1;
    });
    _saveProducts();
  }

  // Remove um produto da lista
  void _removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
    _saveProducts();
  }

  // Remove todos os produtos da lista
  void _clearProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('products');
    setState(() {
      products.clear();
    });
  }

  // Calcula o valor total dos produtos na lista
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
              image: AssetImage("assets/images/fundo.webp"), // Fundo da tela
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
                            color: Colors.red.shade300,
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
                  ElevatedButton(
                    onPressed: _clearProducts,
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
