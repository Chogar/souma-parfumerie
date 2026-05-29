import 'package:flutter/material.dart';

/// Actions CRUD compactes (icônes + info-bulles).
class CrudIconActions extends StatelessWidget {
  const CrudIconActions({
    super.key,
    this.onEdit,
    this.onDelete,
    this.editTooltip = 'Modifier',
    this.deleteTooltip = 'Supprimer',
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String editTooltip;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            tooltip: editTooltip,
            onPressed: onEdit,
          ),
        if (onDelete != null)
          IconButton(
            icon: Icon(Icons.delete_outline, size: 22, color: Colors.red.shade700),
            tooltip: deleteTooltip,
            onPressed: onDelete,
          ),
      ],
    );
  }
}
