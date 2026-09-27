// =============================================================================
// WIDGET — JogoCard
// -----------------------------------------------------------------------------
// Representa UM jogo na lista: Card + ListTile + avatar com a sigla da
// plataforma + nota + botões de editar/remover. Recebe callbacks para não
// acoplar à HomePage.
// =============================================================================
import 'package:flutter/material.dart';
import '../../models/jogo_model.dart';

class JogoCard extends StatelessWidget {
  final JogoModel jogo;
  final VoidCallback onRemover;
  final VoidCallback onEditar;

  const JogoCard({
    super.key,
    required this.jogo,
    required this.onRemover,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        // Tocar no card também abre a edição (atalho comum em apps).
        onTap: onEditar,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: Text(
            siglaPlataforma(jogo.plataforma),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(
          jogo.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${jogo.plataforma} • ${jogo.genero}'),
        // Nota + dois botões: editar (lápis) e remover (lixeira).
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 18, color: Colors.amber.shade700),
            Text(
              '${jogo.nota}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              tooltip: 'Editar',
              icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
              onPressed: onEditar,
            ),
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onRemover,
            ),
          ],
        ),
      ),
    );
  }

  /// Gera sigla curta a partir do nome da plataforma para o avatar.
  /// Ex.: "Nintendo Switch" -> "NS"; "PS5" -> "PS"; "PC" -> "PC".
  static String siglaPlataforma(String plataforma) {
    final limpo = plataforma.trim();
    if (limpo.isEmpty) return '?';
    final palavras =
        limpo.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (palavras.length == 1) {
      final unica = palavras.first;
      return unica.substring(0, unica.length >= 2 ? 2 : 1).toUpperCase();
    }
    return palavras.map((w) => w[0].toUpperCase()).take(3).join();
  }
}
