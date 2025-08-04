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
          'Como usar o SmartShop',
          style: AppStyles.headingMedium,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introdução
            _buildWelcomeCard(),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Seções de ajuda
            _buildHelpSection(
              icon: Icons.add_shopping_cart,
              title: 'Criando uma Nova Lista',
              content: [
                '• Toque no botão "Nova Lista de Compras" na tela principal',
                '• Digite um nome para sua lista (ex: Supermercado, Farmácia)',
                '• Defina um orçamento opcional para controlar gastos',
                '• Escolha copiar produtos de uma lista existente (opcional)',
                '• Toque em "Criar" para finalizar',
              ],
            ),
            
            _buildHelpSection(
              icon: Icons.shopping_basket,
              title: 'Adicionando Produtos',
              content: [
                '• Entre numa lista tocando sobre ela',
                '• Use o botão "+" para adicionar produtos manualmente',
                '• Use o scanner QR para adicionar produtos automaticamente',
                '• Digite nome, quantidade e preço de cada produto',
                '• Marque produtos como favoritos para reutilizar',
              ],
            ),
            
            _buildHelpSection(
              icon: Icons.qr_code_scanner,
              title: 'Scanner QR',
              content: [
                '• Toque no ícone de scanner na lista de produtos',
                '• Aponte a câmera para o código de barras do produto',
                '• O app tentará identificar o produto automaticamente',
                '• Confirme ou edite as informações se necessário',
                '• O produto será adicionado à sua lista',
              ],
            ),
            
            _buildHelpSection(
              icon: Icons.share,
              title: 'Compartilhando Listas',
              content: [
                '• Entre numa lista e toque no ícone de compartilhar',
                '• Escolha "Gerar Código" para criar um código de acesso',
                '• Compartilhe o código com familiares ou amigos',
                '• Eles podem usar "Entrar em Lista" para acessar',
                '• Todos podem editar/adicionar produtos em tempo real',
              ],
            ),
            
            _buildHelpSection(
              icon: Icons.favorite,
              title: 'Produtos Favoritos',
              content: [
                '• Toque no botão "Favoritos" na tela principal',
                '• Veja todos os produtos marcados como favoritos',
                '• Edite ou remova favoritos quando necessário',
              ],
            ),
            
            _buildHelpSection(
              icon: Icons.account_balance_wallet,
              title: 'Controle de Orçamento',
              content: [
                '• Defina um orçamento ao criar uma lista',
                '• O app mostra quanto você já gastou em tempo real',
                '• Veja quanto ainda resta do seu orçamento',
              ],
            ),
            
            _buildHelpSection(
              icon: Icons.sort,
              title: 'Organizando Listas',
              content: [
                '• Use o ícone de ordenação para organizar suas listas no canto superior esquerdo',
                '• Ordene por nome, data, valor total ou número de itens',
                '• Copie listas existentes para economizar tempo',
                '• Marque produtos como concluídos durante as compras',
                '• Exclua ou saia de listas quando não precisar mais',
              ],
            ),
            
            _buildHelpSection(
              icon: Icons.settings,
              title: 'Configurações',
              content: [
                '• Toque no ícone de configurações para personalizar o app',
                '• Altere a moeda padrão (Euro, Real, Dólar, etc.)',
                '• Remova produtos scaneados e favoritos',
              ],
            ),
            
            // Dicas importantes
            const SizedBox(height: AppConstants.paddingLarge),
            _buildTipsCard(),
            
            const SizedBox(height: AppConstants.paddingXLarge),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: AppConstants.iconXLarge,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'Bem-vindo ao SmartShop!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          const Text(
            'Organize suas compras de forma inteligente com scanner QR, controle de orçamento e compartilhamento em tempo real.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpSection({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryGreen,
                    size: AppConstants.iconMedium,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ...content.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
              child: Text(
                item,
                style: AppStyles.bodyMedium.copyWith(
                  height: 1.5,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.darkGreen,
                size: AppConstants.iconMedium,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Text(
                'Dicas Importantes',
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Text(
            '💡 Puxe para baixo na tela principal para atualizar suas listas\n\n'
            '💡 Use favoritos para produtos que compra frequentemente\n\n'
            '💡 Compartilhe listas com a família para compras colaborativas\n\n'
            '💡 Defina orçamentos para controlar melhor seus gastos\n\n'
            '💡 Use o scanner QR para adicionar produtos rapidamente',
            style: AppStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
