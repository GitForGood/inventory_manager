import 'package:flutter/material.dart';

class AssistChip extends StatelessWidget {
  final IconData icon;
  final String labelText;

  const AssistChip({super.key, required this.icon, required this.labelText});
  
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        labelText, 
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface
        )
      ),
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      avatar: Icon(icon, color: Theme.of(context).colorScheme.primary,)
    );
  }
}