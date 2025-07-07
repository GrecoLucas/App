# SmartShop - Lista de Compras (Europa Edition) 🇪🇺

Um aplicativo Flutter para gerenciar listas de compras de forma simples e eficiente, com preços em euros.

## 📱 Funcionalidades

- ✅ Criar múltiplas listas de compras
- ✅ Adicionar produtos com nome e preço em euros (€)
- ✅ Editar produtos existentes (nome e preço)
- ✅ Marcar produtos como comprados
- ✅ Calcular valor total da lista automaticamente
- ✅ Remover produtos e listas
- ✅ Interface moderna e intuitiva
- ✅ Preços formatados em euros para mercado europeu

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                           # Ponto de entrada do app
├── models/                             # Modelos de dados
│   ├── item.dart                       # Modelo do produto (com ID único)
│   └── list.dart                       # Modelo da lista de compras (com edição)
├── screens/                            # Telas do aplicativo
│   ├── home_screen.dart                # Tela principal com todas as listas
│   └── shopping_list_detail_screen.dart # Tela de detalhes com edição
└── widgets/                            # Widgets reutilizáveis
    └── product_widgets.dart            # Widgets para produtos (cards e dialogs)
```

## 🎯 Organização e Boas Práticas

### ✅ **Pontos Positivos da Organização Atual:**

1. **Separação por Responsabilidades**
   - `models/`: Contém apenas modelos de dados
   - `screens/`: Contém as telas da aplicação
   - `widgets/`: Preparado para componentes reutilizáveis

2. **Nomenclatura Clara**
   - Arquivos com nomes descritivos
   - Classes bem nomeadas
   - Métodos com propósito claro

3. **Modularidade**
   - Cada arquivo tem uma responsabilidade específica
   - Fácil manutenção e extensibilidade
   - Imports organizados

4. **Escalabilidade**
   - Estrutura preparada para crescimento
   - Fácil adição de novas funcionalidades
   - Padrão seguido em projetos Flutter profissionais

### 🚀 **Melhorias Futuras Sugeridas:**

1. **Persistência de Dados**
   ```
   lib/
   ├── services/
   │   └── storage_service.dart    # SharedPreferences ou Hive
   ```

2. **Gerenciamento de Estado**
   ```
   lib/
   ├── providers/ ou blocs/
   │   └── shopping_list_provider.dart
   ```

3. **Componentes Reutilizáveis**
   ```
   lib/
   ├── widgets/
   │   ├── custom_button.dart
   │   ├── product_card.dart
   │   └── empty_state.dart
   ```

4. **Utilities e Helpers**
   ```
   lib/
   ├── utils/
   │   ├── constants.dart
   │   ├── themes.dart
   │   └── formatters.dart
   ```

## 🎨 Funcionalidades do App

### Tela Principal (HomeScreen)
- Lista todas as listas de compras criadas
- Mostra resumo (quantidade de produtos e valor total)
- Permite criar novas listas
- Permite excluir listas existentes
- Navegação para detalhes da lista

### Tela de Detalhes (ShoppingListDetailScreen)
- Mostra todos os produtos da lista
- Exibe valor total da lista em euros (€)
- Permite adicionar novos produtos
- **NOVO!** Permite editar produtos existentes (botão azul de edição)
- Permite marcar produtos como comprados
- Permite remover produtos (botão vermelho de exclusão)
- Checkbox para controle de produtos comprados
- Interface intuitiva com botões de ação claros

## 🔧 Novas Funcionalidades Adicionadas

### ✨ Edição de Produtos
- Botão de edição (ícone azul) em cada produto
- Dialog intuitivo para editar nome e preço
- Validação de dados
- Feedback visual com mensagens de sucesso

### 💶 Suporte a Euros
- Todos os preços exibidos em euros (€)
- Formatação adequada para mercado europeu
- Interface adaptada para moeda europeia

## 🔧 Como Executar

1. Certifique-se de ter o Flutter instalado
2. Clone o projeto
3. Execute: `flutter pub get`
4. Execute: `flutter run`

## 📊 Exemplo de Uso

1. Abra o app
2. Toque no "+" para criar uma nova lista (ex: "Supermercado")
3. Na lista criada, adicione produtos:
   - Nome: "Pão", Preço: €2.50
   - Nome: "Leite", Preço: €1.20
4. O total será calculado automaticamente: €3.70
5. **NOVO!** Toque no ícone azul para editar um produto
6. Marque os produtos conforme for comprando
7. Use o ícone vermelho para remover produtos

---

**Esta organização é considerada uma boa prática para projetos Flutter de médio a grande porte!** 🎉
