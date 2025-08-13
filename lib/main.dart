// lib/main.dart

import 'package:flutter/material.dart';
import 'package:todo_list/pages/todo_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color beigeBackground = Color(0xFFF3EFEA);
    const Color primaryButtonColor = Colors.white;
    const Color darkTextColor = Colors.black87;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lista de Compras',
      theme: ThemeData(
        scaffoldBackgroundColor: beigeBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          // CORREÇÃO AQUI: 'background' -> 'surface'
          surface: beigeBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: darkTextColor,
          elevation: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryButtonColor,
            foregroundColor: darkTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: darkTextColor),
          bodyMedium: TextStyle(color: darkTextColor),
          titleLarge: TextStyle(color: darkTextColor),
        ),
        iconTheme: const IconThemeData(
          color: Colors.deepPurple,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const TodoListPage(),
    );
  }
}