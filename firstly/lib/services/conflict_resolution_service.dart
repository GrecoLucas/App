import 'package:flutter/material.dart';
import '../models/item.dart';
import '../exceptions/conflict_exception.dart';
import '../utils/app_theme.dart';

class ConflictResolutionService {
  /// Mostra diálogo para resolver conflito entre versões
  static Future<ConflictResolution?> showItemConflictDialog({
    required BuildContext context,
    required Item localItem,
    required Item remoteItem,
    required ConflictType conflictType,
  }) async {
    return await showDialog<ConflictResolution>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ItemConflictDialog(
        localItem: localItem,
        remoteItem: remoteItem,
        conflictType: conflictType,
      ),
    );
  }

  /// Resolve conflito automaticamente quando possível
  static Item? resolveItemConflictAuto(Item localItem, Item remoteItem) {
    // Se apenas um campo foi alterado, fazer merge automático
    int differences = 0;
    
    if (localItem.name != remoteItem.name) differences++;
    if (localItem.price != remoteItem.price) differences++;
    if (localItem.quantity != remoteItem.quantity) differences++;
    if (localItem.isCompleted != remoteItem.isCompleted) differences++;
    
    // Se há muitas diferenças, requer intervenção manual
    if (differences > 1) return null;
    
    // Merge automático para mudanças simples
    if (localItem.lastModified.isAfter(remoteItem.lastModified)) {
      return localItem.copyWithNewVersion();
    } else {
      return remoteItem.copyWithNewVersion();
    }
  }
}

class _ItemConflictDialog extends StatelessWidget {
  final Item localItem;
  final Item remoteItem;
  final ConflictType conflictType;

  const _ItemConflictDialog({
    required this.localItem,
    required this.remoteItem,
    required this.conflictType,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: const Icon(
              Icons.warning,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          const Expanded(
            child: Text('Conflito Detectado'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getConflictMessage(),
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildVersionComparison(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictResolution.cancel),
          child: const Text('Cancelar'),
        ),
        if (conflictType != ConflictType.deleted) ...[
          TextButton(
            onPressed: () => Navigator.pop(context, ConflictResolution.keepRemote),
            child: const Text('Manter Versão do Servidor'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ConflictResolution.keepLocal),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Manter Minha Versão'),
          ),
        ],
      ],
    );
  }

  String _getConflictMessage() {
    switch (conflictType) {
      case ConflictType.version:
        return 'Este item foi modificado por outro usuário enquanto você o editava. Escolha qual versão manter:';
      case ConflictType.deleted:
        return 'Este item foi removido por outro usuário enquanto você o editava. Sua edição será perdida.';
      case ConflictType.duplicate:
        return 'Um item similar já existe na lista. Escolha como proceder:';
    }
  }

  Widget _buildVersionComparison() {
    return Column(
      children: [
        _buildVersionCard('Sua Versão', localItem, Colors.blue),
        const SizedBox(height: AppConstants.paddingMedium),
        if (conflictType != ConflictType.deleted)
          _buildVersionCard('Versão do Servidor', remoteItem, Colors.green),
      ],
    );
  }

  Widget _buildVersionCard(String title, Item item, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildFieldRow('Nome:', item.name),
          _buildFieldRow('Preço:', 'R\$ ${item.price.toStringAsFixed(2)}'),
          _buildFieldRow('Quantidade:', item.quantity.toString()),
          _buildFieldRow('Concluído:', item.isCompleted ? 'Sim' : 'Não'),
          _buildFieldRow('Modificado em:', 
              '${item.lastModified.day}/${item.lastModified.month} ${item.lastModified.hour}:${item.lastModified.minute.toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppStyles.captionGrey.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
