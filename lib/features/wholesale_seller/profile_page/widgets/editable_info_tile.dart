// lib/features/profile/widgets/editable_info_tile.dart
import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class EditableInfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool editable;
  final VoidCallback? onEdit;

  const EditableInfoTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.editable,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(title),
        subtitle: Text(value),
        trailing: editable
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              )
            : null,
      ),
    );
  }
}