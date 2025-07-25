import 'package:flutter/material.dart';
// Corrija o caminho se o arquivo estiver em outro local.
// Por exemplo, se estiver na pasta 'lib', o caminho seria só 'todo_list_page_old.dart'.
import 'package:todo_list/pages/todo_list_page_old.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TodoListPage(), // Usando a página correta
    );
  }
}