# 🛒 Lista de Compras Inteligente

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**Versão Final do meu primeiro aplicativo de lista de compras, agora com funcionalidades avançadas, uma interface refinada e uma arquitetura robusta.**

---

*(GIF rápido a demonstrar a aplicação em ação aqui!)*

<img src="https://github.com/user-attachments/assets/f5fea7fe-dd89-48fa-9263-276558c9b85e" alt="lista de produtos" width="300"/>

****************************************************************************** <img src="https://github.com/user-attachments/assets/7340d7fe-7697-4429-808b-4bbf22dc756c" alt="lista de produtos" width="300"/>
<img src="https://github.com/user-attachments/assets/ac0aed60-3216-4abb-a540-fe3590686e2c" alt="lista de produtos" width="300"/>

---

## ✨ Sobre o Projeto

Este projeto nasceu da necessidade de substituir as velhas listas de papel por uma solução digital, simples e eficiente. O objetivo é facilitar a organização das compras, otimizar o tempo no supermercado e ajudar no controlo dos gastos, evitando esquecimentos e compras por impulso.

## 📌 Funcionalidades Principais

O que começou como um app simples evoluiu para uma ferramenta completa de gestão de compras:

✅ **Listas Dinâmicas:** Adicione, remova, edite e marque itens como comprados com facilidade. A lista é ordenada automaticamente para que os itens mais recentes apareçam no topo.

✅ **Gestão de Múltiplas Listas:** Crie, salve, carregue e apague listas ilimitadas. Ideal para organizar as compras de diferentes supermercados, eventos ou meses.

✅ **Controlo Financeiro em Tempo Real:** Insira o preço e a quantidade de cada item e veja o **valor total da sua compra a ser atualizado instantaneamente** no rodapé da tela.

✅ **Partilha Offline Inteligente (Extensão .lsc):** Exporte a sua lista num formato personalizado (`.lsc`) e envie via WhatsApp. Quem receber, só precisa clicar no ficheiro para o app abrir automaticamente e importar todos os produtos!

✅ **Exportação Flexível:** Exporte relatórios em **PDF** (múltiplas páginas) para imprimir ou em **CSV** para analisar os seus gastos em folhas de cálculo como o Excel.

✅ **Salvamento Automático (Auto-Save):** Nunca perca as suas listas! O aplicativo deteta quando vai para segundo plano e guarda automaticamente qualquer alteração pendente.

✅ **Busca Instantânea:** Encontre qualquer produto em listas longas com o filtro de pesquisa em tempo real.

✅ **Persistência Local:** Todas as suas listas e produtos ficam guardados de forma segura no seu dispositivo, graças ao `SharedPreferences`.

## 🚀 Tecnologias e Arquitetura

A aplicação foi desenvolvida com foco numa base de código limpa e escalável:

- **Linguagem:** Dart
- **Framework:** Flutter, para uma interface bonita e responsiva em Android e iOS.
- **Arquitetura:** `StatefulWidget` com separação de responsabilidades. A UI é gerida pela própria página, enquanto a lógica de persistência é delegada a uma **Camada de Serviço (`ShoppingListService`)**.
- **Integração Nativa Android:** Uso de `Intent Filters` no `AndroidManifest.xml` para associar ficheiros `.lsc` diretamente à aplicação.
- **Armazenamento:** `shared_preferences` para armazenamento local JSON.
- **Geração de Relatórios:** Pacotes `pdf` e `csv` para exportação de dados.
- **Ferramentas Adicionais:** `receive_sharing_intent`, `share_plus`, `path_provider`, `package_info_plus`, `url_launcher`.

## 🔥 Desafios e Evolução do Projeto

A construção deste app foi uma jornada de grande aprendizado, que foi muito além do básico:

- **Associação de Ficheiros e Intents Nativo:** Criar uma extensão própria (`.lsc`) exigiu a manipulação profunda de Intent Filters do Android e gestão de ficheiros em cache do WhatsApp para garantir a abertura perfeita do app.
- **Refatoração de Arquitetura:** O projeto evoluiu para uma arquitetura com uma camada de serviço, isolando a lógica de negócio da interface UI.
- **Resolução de Conflitos do Gradle (Android):** Enfrentámos e resolvemos incompatibilidades complexas de versões do `JVM Target` (Java 1.8 vs Java 17) entre pacotes modernos e antigos no ambiente de compilação do Android (`build.gradle`), forçando o alinhamento de dependências via `projectsEvaluated`.

## 📲 Como Executar o Projeto

1.  Clone o repositório: `git clone https://github.com/SEU_USER/SEU_REPO.git`
2.  Instale as dependências: `flutter pub get`
3.  Execute a aplicação: `flutter run`

## 🎯 Próximos Passos

O futuro da aplicação inclui:
- [ ] Implementação de categorias de compras (mercearia, limpeza, etc.).
- [ ] Sincronização de listas com a nuvem (Firebase Firestore).
- [ ] Suporte para múltiplos utilizadores e partilha de listas em tempo real via Cloud.

---

**Desenvolvido com ❤️ por Rodrigo Costa** 💻🚀

[GitHub](https://github.com/RodrigoCosta1983) | [LinkedIn](https://www.linkedin.com/in/dev-rodrigo-costa/)  | [Site](https://rodrigocosta1983.github.io/rodrigocosta-dev.com/)


========================================================================================================================================================================================


# 🛒 Smart Shopping List

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**The final version of my first shopping list app, now featuring advanced functionalities, seamless offline sharing, a refined UI, and a robust architecture.**

---

*(Suggestion: Record a quick GIF demonstrating the app in action and place it here! Tools like ScreenToGif on Windows or GIPHY Capture on Mac are great for this.)*

![App Demo](URL_FOR_YOUR_GIF_HERE.gif)

---

## ✨ About the Project

This project was born from the need to replace old paper lists with a simple and efficient digital solution. The goal is to make shopping easier to organize, optimize time at the supermarket, and help control spending by preventing forgotten items and impulse buys.

## 📌 Key Features

What began as a simple app has evolved into a complete shopping management tool:

✅ **Dynamic Lists:** Easily add, remove, edit, and check off items. The list is automatically sorted to show the most recent items at the top.

✅ **Multi-List Management:** Create, save, load, and delete unlimited lists. Ideal for organizing shopping for different stores, events, or months.

✅ **Real-Time Cost Tracking:** Input the price and quantity for each item and watch the **total cost of your purchase update instantly** at the bottom of the screen.

✅ **Smart Offline Sharing (.lsc Extension):** Export your list into a custom `.lsc` file and share it via WhatsApp. The receiver simply taps the file, and the app automatically opens and imports all products!

✅ **Flexible Exporting:** Export multi-page reports to **PDF** for printing or **CSV** to analyze your spending in spreadsheets like Excel.

✅ **Auto-Save Functionality:** Never lose your data! The app detects when it goes to the background and automatically saves any pending changes.

✅ **Instant Search:** Find any product in long lists with the real-time search filter.

✅ **Local Persistence:** All your lists and products are securely saved on your device, thanks to `SharedPreferences`.

## 🚀 Technologies & Architecture

The application was developed with a focus on a clean and scalable codebase:

- **Language:** Dart
- **Framework:** Flutter, for a beautiful and responsive UI on Android & iOS.
- **Architecture:** `StatefulWidget` with separation of concerns. The UI is managed by the page itself, while all data persistence logic is delegated to a **Service Layer (`ShoppingListService`)**.
- **Native Android Integration:** Used `Intent Filters` in `AndroidManifest.xml` to associate `.lsc` files directly with the app.
- **Data Persistence:** `shared_preferences` for local JSON storage.
- **Document Generation:** `pdf` and `csv` packages for the export functionalities.
- **Additional Tools:** `receive_sharing_intent`, `share_plus`, `path_provider`, `package_info_plus`, `url_launcher`.

## 🔥 Challenges & Project Evolution

Building this app was a major learning journey that went far beyond the basics:

- **Custom File Association & Native Intents:** Creating a proprietary extension (`.lsc`) required deep manipulation of Android Intent Filters and handling WhatsApp cached files to ensure flawless app launching.
- **Architectural Refactoring:** The project evolved to an architecture with a service layer, isolating business logic from the UI.
- **Resolving Gradle (Android) Conflicts:** We investigated and resolved complex `JVM Target` version mismatches (Java 1.8 vs Java 17) between modern and legacy packages in the Android build environment (`build.gradle`), forcing dependency alignment via `projectsEvaluated`.

## 📲 How to Run the Project

1.  Clone the repository: `git clone https://github.com/YOUR_USER/YOUR_REPO.git`
2.  Install dependencies: `flutter pub get`
3.  Run the application: `flutter run`

## 🎯 Next Steps

The future of the app includes:
- [ ] Implement shopping categories (groceries, cleaning, etc.).
- [ ] Cloud synchronization for lists (e.g., Firebase Firestore).
- [ ] Multi-user support and real-time list sharing via Cloud.

---

**Developed with ❤️ by Rodrigo Costa** 💻🚀

[GitHub](https://github.com/RodrigoCosta1983) | [LinkedIn](https://www.linkedin.com/in/dev-rodrigo-costa/)  | [Site](https://rodrigocosta1983.github.io/rodrigocosta-dev.com/)