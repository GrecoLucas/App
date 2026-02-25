import 'package:flutter/material.dart';
import '../models/expense_list.dart';
import '../../scanner/services/barcode_service.dart';
import '../../../core/theme/app_theme.dart';
import './expense_list_detail_screen.dart';

class ExpenseListsScreen extends StatefulWidget {
  const ExpenseListsScreen({super.key});

  @override
  State<ExpenseListsScreen> createState() => _ExpenseListsScreenState();
}

class _ExpenseListsScreenState extends State<ExpenseListsScreen> {
  List<ExpenseList> _expenseLists = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadExpenseLists();
    _loadStats();
  }

  Future<void> _loadExpenseLists() async {
    setState(() => _isLoading = true);
    final lists = await BarcodeService.loadExpenseLists();
    setState(() {
      _expenseLists = lists;
      _isLoading = false;
    });
  }

  Future<void> _loadStats() async {
    final stats = await BarcodeService.getExpenseStats();
    setState(() => _stats = stats);
  }

  void _createNewExpenseList() {
    showDialog(
      context: context,
      builder: (context) {
        String listName = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              const Text('Nova Lista de Gastos'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => listName = value,
                decoration: InputDecoration(
                  labelText: 'Nome da Lista',
                  hintText: 'Ex: Compras do Mês, Supermercado...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  filled: true,
                  fillColor: AppTheme.softGrey,
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta lista é para acompanhar gastos através de código de barras.',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (listName.trim().isNotEmpty) {
                  final newList = ExpenseList.create(name: listName.trim());
                  
                  setState(() {
                    _expenseLists.add(newList);
                  });
                  
                  await BarcodeService.saveExpenseLists(_expenseLists);
                  await _loadStats();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpenseList(int index) {
    final list = _expenseLists[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppTheme.warningRed,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Text('Excluir Lista'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir a lista "${list.name}"? Esta ação não pode ser desfeita.',
          style: AppStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _expenseLists.removeAt(index);
              });
              
              await BarcodeService.saveExpenseLists(_expenseLists);
              await _loadStats();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Text('Listas de Gastos'),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            )
          : Column(
              children: [
                if (_stats.isNotEmpty) _buildStatsCard(),
                Expanded(
                  child: _expenseLists.isEmpty
                      ? _buildEmptyState()
                      : _buildExpenseListsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewExpenseList,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Lista'),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.mediumShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.primaryGreen,
                size: AppConstants.iconMedium,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumo dos Gastos',
                style: AppStyles.headingMedium.copyWith(
                  color: AppTheme.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Gasto',
                  '€${(_stats['totalSpent'] as double).toStringAsFixed(2)}',
                  Icons.euro,
                  AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildStatItem(
                  'Itens Escaneados',
                  '${_stats['totalItems']}',
                  Icons.qr_code,
                  AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Listas Criadas',
                  '${_stats['totalLists']}',
                  Icons.list_alt,
                  AppTheme.warningRed,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildStatItem(
                  'Média por Lista',
                  '€${(_stats['averagePerList'] as double).toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppConstants.iconMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppStyles.captionGrey.copyWith(
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingXLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
                boxShadow: const [AppStyles.softShadow],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: AppConstants.iconXLarge,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  const Text(
                    'Nenhuma lista de gastos ainda',
                    style: AppStyles.headingMedium,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  const Text(
                    'Crie listas para acompanhar seus gastos escaneando códigos de barras',
                    style: AppStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  const Text(
                    'Toque em "Nova Lista" para começar!',
                    style: AppStyles.captionGrey,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseListsList() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: ListView.builder(
        itemCount: _expenseLists.length,
        itemBuilder: (context, index) {
          final list = _expenseLists[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              boxShadow: const [AppStyles.softShadow],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpenseListDetailScreen(
                        expenseList: list,
                        onUpdate: () {
                          _loadExpenseLists();
                          _loadStats();
                        },
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: AppConstants.iconMedium,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingLarge),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list.name,
                              style: AppStyles.bodyLarge.copyWith(
                                color: AppTheme.darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  list.formattedTotal,
                                  style: AppStyles.priceStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: AppConstants.paddingMedium),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreen,
                                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                                  ),
                                  child: Text(
                                    '${list.totalItems} ${list.totalItems == 1 ? 'item' : 'itens'}',
                                    style: AppStyles.captionGrey.copyWith(
                                      color: AppTheme.darkGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              list.formattedCreatedAt,
                              style: AppStyles.captionGrey,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteExpenseList(index);
                          }
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: AppTheme.warningRed),
                                SizedBox(width: 12),
                                Text('Excluir Lista'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
