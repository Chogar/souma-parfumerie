import 'package:flutter/material.dart';

/// Permet la sélection de texte sur bureau (glisser la souris, puis Cmd+C).
/// Utiliser des [Text] à l'intérieur — pas de [SelectableText] imbriqués.
class SelectableContent extends StatelessWidget {
  const SelectableContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SelectionArea(child: child);
}
