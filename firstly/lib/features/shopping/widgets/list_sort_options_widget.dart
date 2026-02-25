import 'package:flutter/material.dart';
import '../../home/screens/home_screen.dart';

class ListSortOptionsWidget extends StatelessWidget {
  final ListSortCriteria currentCriteria;
  final Function(ListSortCriteria) onSortChanged;

  const ListSortOptionsWidget({
    Key? key,
    required this.currentCriteria,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ListSortCriteria>(
      icon: const Icon(Icons.sort),
      tooltip: 'Ordenar listas',
      onSelected: onSortChanged,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.nameAscending,
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                color: currentCriteria == ListSortCriteria.nameAscending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Nome (A-Z)',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.nameAscending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.nameAscending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.nameDescending,
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                color: currentCriteria == ListSortCriteria.nameDescending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Nome (Z-A)',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.nameDescending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.nameDescending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.dateNewest,
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: currentCriteria == ListSortCriteria.dateNewest 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Mais recentes',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.dateNewest 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.dateNewest 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.dateOldest,
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: currentCriteria == ListSortCriteria.dateOldest 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Mais antigas',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.dateOldest 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.dateOldest 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.totalValueAscending,
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward,
                color: currentCriteria == ListSortCriteria.totalValueAscending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Valor (menor → maior)',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.totalValueAscending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.totalValueAscending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.totalValueDescending,
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward,
                color: currentCriteria == ListSortCriteria.totalValueDescending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Valor (maior → menor)',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.totalValueDescending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.totalValueDescending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.itemCountAscending,
          child: Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                color: currentCriteria == ListSortCriteria.itemCountAscending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Itens (menos → mais)',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.itemCountAscending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.itemCountAscending 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ListSortCriteria>(
          value: ListSortCriteria.itemCountDescending,
          child: Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                color: currentCriteria == ListSortCriteria.itemCountDescending 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Itens (mais → menos)',
                style: TextStyle(
                  color: currentCriteria == ListSortCriteria.itemCountDescending 
                      ? Theme.of(context).primaryColor 
                      : null,
                  fontWeight: currentCriteria == ListSortCriteria.itemCountDescending 
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
