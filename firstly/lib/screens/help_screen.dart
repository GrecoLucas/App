import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        title: const Text(
          'Ajuda',
          style: AppStyles.headingMedium,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Seções Expansíveis
            _buildExpansionGroup([
              _buildExpansionTile(
                icon: Icons.add_shopping_cart,
                title: 'Nova Lista de Compras',
                children: [
                   _buildHelpStep('Toque em "Nova Lista" na tela inicial'),
                   _buildHelpStep('Dê um nome e defina um orçamento (opcional)'),
                   _buildHelpStep('Use o botão "+" para adicionar itens manualmente'),
                   _buildHelpStep('Marque itens como favoritos para reuso rápido'),
                ],
              ),
              _buildExpansionTile(
                icon: Icons.favorite, 
                title: 'Favoritos',
                children: [
                  _buildHelpStep('Acesse pela tela inicial em "Favoritos"'),
                  _buildHelpStep('Adicione itens aos favoritos para reuso rápido'),
                  _buildHelpStep('Use a busca para verificar seus favoritos'),
                ],
              ),
              _buildExpansionTile(
                icon: Icons.kitchen, 
                title: 'Despensa Inteligente',
                children: [
                  _buildHelpStep('Acesse pela tela inicial em "Despensa"'),
                  _buildHelpStep('Adicione itens que você já tem em casa'),
                  _buildHelpStep('Defina "Consumo Automático" para que o app reduza a quantidade sozinho (ex: 1 litro de leite a cada 3 dias)'),
                  _buildHelpStep('Use a busca para verificar seu estoque antes de sair'),
                ],
              ),
               _buildExpansionTile(
                icon: Icons.qr_code_scanner,
                title: 'Scanner de Produtos',
                children: [
                  _buildHelpStep('Use o scanner para adicionar itens rapidamente'),
                  _buildHelpStep('Confirme os dados do produto identificado'),
                ],
              ),
              _buildExpansionTile(
                icon: Icons.settings,
                title: 'Configurações e Moeda',
                children: [
                  _buildHelpStep('Acesse Configurações pelo ícone de engrenagem'),
                  _buildHelpStep('Altere a moeda padrão (Reais, Dólares, Euros)'),
                  _buildHelpStep('Gerencie seus itens salvos e favoritos'),
                ],
              ),
            ]),

            const SizedBox(height: AppConstants.paddingXLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Column(
        children: children.map((widget) {
          final isLast = widget == children.last;
          return Column(
            children: [
              widget,
              if (!isLast) 
                Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpansionTile({
    required IconData icon, 
    required String title, 
    required List<Widget> children
  }) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGreen,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
        children: children,
      ),
    );
  }

  Widget _buildHelpStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMedium.copyWith(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
