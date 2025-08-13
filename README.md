# 🛒 Lista de Compras Inteligente

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**Versão Final do meu primeiro aplicativo de lista de compras, agora com funcionalidades avançadas, uma interface refinada e uma arquitetura robusta.**

---

*(Sugestão: Grave um GIF rápido a demonstrar a aplicação em ação e coloque-o aqui! Ferramentas como o ScreenToGif no Windows ou o GIPHY Capture no Mac são ótimas para isso.)*

![Demo do App](URL_DO_SEU_GIF_AQUI.gif)
![lista de produtos](https://github.com/user-attachments/assets/7340d7fe-7697-4429-808b-4bbf22dc756c)

---

## ✨ Sobre o Projeto

Este projeto nasceu da necessidade de substituir as velhas listas de papel por uma solução digital, simples e eficiente. [cite_start]O objetivo é facilitar a organização das compras, otimizar o tempo no supermercado e ajudar no controlo dos gastos, evitando esquecimentos e compras por impulso[cite: 1].

## 📌 Funcionalidades Principais

O que começou como um app simples evoluiu para uma ferramenta completa de gestão de compras:

✅ **Listas Dinâmicas:** Adicione, remova, edite e marque itens como comprados com facilidade. [cite_start]A lista é ordenada automaticamente para que os itens mais recentes apareçam no topo[cite: 1].

✅ **Gestão de Múltiplas Listas:** Crie, salve, carregue e apague listas ilimitadas. Ideal para organizar as compras de diferentes supermercados, eventos ou meses.

✅ **Controlo Financeiro em Tempo Real:** Insira o preço e a quantidade de cada item e veja o **valor total da sua compra a ser atualizado instantaneamente** no rodapé da tela.

✅ **Busca Instantânea:** Encontre qualquer produto em listas longas com o filtro de pesquisa em tempo real.

✅ **Exportação Flexível:** Partilhe as suas listas! Exporte para **PDF** para imprimir ou enviar por WhatsApp, ou para **CSV** para analisar os seus gastos em folhas de cálculo como o Excel.
[cite_start]
✅ **Persistência Local:** Todas as suas listas e produtos ficam guardados de forma segura no seu dispositivo, graças ao `SharedPreferences`[cite: 1].

## 🚀 Tecnologias e Arquitetura

A aplicação foi desenvolvida com foco numa base de código limpa e escalável:

- [cite_start]**Linguagem:** Dart [cite: 1]
- [cite_start]**Framework:** Flutter, para uma interface bonita e responsiva em Android e iOS[cite: 1].
- **Arquitetura:** `StatefulWidget` com separação de responsabilidades. A UI é gerida pela própria página, enquanto toda a lógica de persistência de dados (leitura e gravação) é delegada a uma **Camada de Serviço (`ShoppingListService`)**, mantendo o código organizado.
- [cite_start]**Persistência de Dados:** `shared_preferences` [cite: 1] para armazenamento local.
- **Geração de Documentos:** Pacotes `pdf` e `csv` para as funcionalidades de exportação.
- **Ferramentas Adicionais:** `share_plus`, `path_provider`, `package_info_plus`, `url_launcher`.

## 🔥 Desafios e Evolução do Projeto

[cite_start]A construção deste app foi uma jornada de grande aprendizado[cite: 1], que foi muito além do básico:

- **Refatoração de Arquitetura:** O projeto evoluiu de uma gestão de estado inicial com `Provider` para uma arquitetura `StatefulWidget` com uma camada de serviço, de forma a alcançar o controlo e a aparência de UI desejados.
- **Migração de Dados Legados:** Um dos maiores desafios foi criar um script de migração de dados robusto para atualizar o formato de armazenamento dos produtos sem que o utilizador perdesse as suas listas antigas.
- **Depuração de Ambiente:** Investigámos e resolvemos problemas de compilação a nível nativo (Android), corrigindo a configuração do JDK do Gradle para alinhar o ambiente com as ferramentas modernas.

## 📲 Como Executar o Projeto

1.  Clone o repositório: `git clone https://github.com/SEU_USER/SEU_REPO.git`
2.  [cite_start]Instale as dependências: `flutter pub get` [cite: 1]
3.  [cite_start]Execute a aplicação: `flutter run` [cite: 1]

## 🎯 Próximos Passos

O futuro da aplicação inclui:
- [ ] [cite_start]Implementação de categorias de compras (mercearia, limpeza, etc.)[cite: 1].
- [ ] [cite_start]Sincronização de listas com a nuvem (ex: Firebase)[cite: 1].
- [ ] [cite_start]Suporte para múltiplos utilizadores e partilha de listas em tempo real[cite: 1].

---

**Desenvolvido com ❤️ por Rodrigo Costa** 💻🚀

[GitHub](https://github.com/RodrigoCosta1983) | [LinkedIn](https://www.linkedin.com/in/dev-rodrigo-costa/)



========================================================================================================================================================================================



# 🛒 Smart Shopping List

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**The final version of my first shopping list app, now featuring advanced functionalities, a refined UI, and a robust architecture.**

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
✅ **Instant Search:** Find any product in long lists with the real-time search filter.
✅ **Flexible Exporting:** Share your lists! Export to **PDF** to print or send via WhatsApp, or to **CSV** to analyze your spending in spreadsheets like Excel.
✅ **Local Persistence:** All your lists and products are securely saved on your device, thanks to `SharedPreferences`.

## 🚀 Technologies & Architecture

The application was developed with a focus on a clean and scalable codebase:

- **Language:** Dart
- **Framework:** Flutter, for a beautiful and responsive UI on Android & iOS.
- **Architecture:** `StatefulWidget` with separation of concerns. The UI is managed by the page itself, while all data persistence logic (reading and writing) is delegated to a **Service Layer (`ShoppingListService`)**, keeping the code organized.
- **Data Persistence:** `shared_preferences` for local storage.
- **Document Generation:** `pdf` and `csv` packages for the export functionalities.
- **Additional Tools:** `share_plus`, `path_provider`, `package_info_plus`, `url_launcher`.

## 🔥 Challenges & Project Evolution

Building this app was a major learning journey that went far beyond the basics:

- **Architectural Refactoring:** The project evolved from an initial state management approach with `Provider` to a `StatefulWidget` architecture with a service layer to achieve the desired UI control and feel.
- **Legacy Data Migration:** One of the biggest challenges was creating a robust data migration script to update the product storage format without users losing their old, inconsistently formatted lists.
- **Environment Debugging:** We investigated and resolved native-level (Android) build issues, correcting the Gradle JDK configuration to align the build environment with modern tools.

## 📲 How to Run the Project

1.  Clone the repository: `git clone https://github.com/YOUR_USER/YOUR_REPO.git`
2.  Install dependencies: `flutter pub get`
3.  Run the application: `flutter run`

## 🎯 Next Steps

The future of the app includes:
- [ ] Implement shopping categories (groceries, cleaning, etc.).
- [ ] Cloud synchronization for lists (e.g., Firebase).
- [ ] Multi-user support and real-time list sharing.

---

**Developed with ❤️ by Rodrigo Costa** 💻🚀

[GitHub](https://github.com/RodrigoCosta1983) | [LinkedIn](https://www.linkedin.com/in/dev-rodrigo-costa/)
