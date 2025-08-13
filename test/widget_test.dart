// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/main.dart'; // Importa o main.dart
import 'package:todo_list/providers/todo_list_provider.dart'; // Importa o Provider

void main() {
  testWidgets('App smoke test: finds initial title and empty list message', (WidgetTester tester) async {
    // ATENÇÃO: O teste agora precisa do Provider para funcionar,
    // assim como no main.dart real.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => TodoListProvider(),
        child: const MyApp(),
      ),
    );

    // Verifica se o título inicial do AppBar está na tela.
    expect(find.text('Lista de Compras'), findsOneWidget);

    // Verifica se a mensagem de lista vazia aparece inicialmente.
    expect(find.text('Sua lista está vazia!'), findsOneWidget);

    // Verifica que não há nenhum produto com o título 'Item 1'
    expect(find.text('Item 1'), findsNothing);
  });
}