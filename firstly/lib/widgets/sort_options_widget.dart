import 'package:flutter/material.dart';
import '../models/list.dart';

class SortOptionsWidget extends StatelessWidget {
  final SortCriteria currentCriteria;
  final Function(SortCriteria) onSortChanged;

  const SortOptionsWidget({
    Key? key,
    required this.currentCriteria,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortCriteria>(
      icon: const Icon(Icons.sort),
      tooltip: 'Ordenar itens',
      onSelected: onSortChanged,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<SortCriteria>(
          value: SortCriteria.alphabetical,
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                color: currentCriteria == SortCriteria.alphabetical 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Alfabética (A-Z)',
                style: TextStyle(
                  color: currentCriteria == SortCriteria.alphabetical 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == SortCriteria.alphabetical 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortCriteria>(
          value: SortCriteria.priceAscending,
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward,
                color: currentCriteria == SortCriteria.priceAscending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Preço (menor → maior)',
                style: TextStyle(
                  color: currentCriteria == SortCriteria.priceAscending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == SortCriteria.priceAscending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortCriteria>(
          value: SortCriteria.priceDescending,
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward,
                color: currentCriteria == SortCriteria.priceDescending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Preço (maior → menor)',
                style: TextStyle(
                  color: currentCriteria == SortCriteria.priceDescending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == SortCriteria.priceDescending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortCriteria>(
          value: SortCriteria.quantityAscending,
          child: Row(
            children: [
              Icon(
                Icons.exposure_plus_1,
                color: currentCriteria == SortCriteria.quantityAscending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Quantidade (menor → maior)',
                style: TextStyle(
                  color: currentCriteria == SortCriteria.quantityAscending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == SortCriteria.quantityAscending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortCriteria>(
          value: SortCriteria.quantityDescending,
          child: Row(
            children: [
              Icon(
                Icons.exposure_minus_1,
                color: currentCriteria == SortCriteria.quantityDescending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Quantidade (maior → menor)',
                style: TextStyle(
                  color: currentCriteria == SortCriteria.quantityDescending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == SortCriteria.quantityDescending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortCriteria>(
          value: SortCriteria.totalValueAscending,
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: currentCriteria == SortCriteria.totalValueAscending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Valor Total (menor → maior)',
                style: TextStyle(
                  color: currentCriteria == SortCriteria.totalValueAscending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == SortCriteria.totalValueAscending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortCriteria>(
          value: SortCriteria.totalValueDescending,
          child: Row(
            children: [
              Icon(
                Icons.trending_down,
                color: currentCriteria == SortCriteria.totalValueDescending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Valor Total (maior → menor)',
                style: TextStyle(
                  color: currentCriteria == SortCriteria.totalValueDescending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == SortCriteria.totalValueDescending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget helper para exibir informações sobre o critério de ordenação atual
class SortInfoChip extends StatelessWidget {
  final SortCriteria criteria;

  const SortInfoChip({
    Key? key,
    required this.criteria,
  }) : super(key: key);

  String _getCriteriaDisplayName(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.alphabetical:
        return 'Alfabética';
      case SortCriteria.priceAscending:
        return 'Preço ↑';
      case SortCriteria.priceDescending:
        return 'Preço ↓';
      case SortCriteria.quantityAscending:
        return 'Quantidade ↑';
      case SortCriteria.quantityDescending:
        return 'Quantidade ↓';
      case SortCriteria.totalValueAscending:
        return 'Valor Total ↑';
      case SortCriteria.totalValueDescending:
        return 'Valor Total ↓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.sort, size: 16),
      label: Text(
        _getCriteriaDisplayName(criteria),
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
    );
  }
}
