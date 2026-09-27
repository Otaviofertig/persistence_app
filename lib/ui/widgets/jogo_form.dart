// =============================================================================
// WIDGET — JogoForm (BottomSheet de cadastro/edição)
// -----------------------------------------------------------------------------
// Formulário com validação. Funciona em DOIS modos:
//   • CRIAR  -> `jogo` == null  -> campos vazios, título "Cadastrar".
//   • EDITAR -> `jogo` != null  -> campos pré-preenchidos, título "Editar",
//               e o objeto devolvido mantém o `id` original (para o UPDATE).
//
// Ao confirmar, devolve um JogoModel via Navigator.pop(context, model).
// Quem grava no banco (insert/update) é a HomePage — o form só coleta e valida.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/jogo_model.dart';

class JogoForm extends StatefulWidget {
  /// Jogo a editar. Se null, o formulário está em modo de CRIAÇÃO.
  final JogoModel? jogo;

  const JogoForm({super.key, this.jogo});

  /// Abre o formulário como modal e retorna o jogo criado/editado (ou null).
  static Future<JogoModel?> mostrar(
    BuildContext context, {
    JogoModel? jogo,
  }) {
    return showModalBottomSheet<JogoModel>(
      context: context,
      isScrollControlled: true, // acompanha o teclado
      showDragHandle: true,
      builder: (_) => JogoForm(jogo: jogo),
    );
  }

  @override
  State<JogoForm> createState() => _JogoFormState();
}

class _JogoFormState extends State<JogoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _plataformaController;
  late final TextEditingController _generoController;
  late final TextEditingController _notaController;

  bool get _editando => widget.jogo != null;

  @override
  void initState() {
    super.initState();
    // Pré-preenche os campos quando estamos editando.
    _tituloController = TextEditingController(text: widget.jogo?.titulo ?? '');
    _plataformaController =
        TextEditingController(text: widget.jogo?.plataforma ?? '');
    _generoController = TextEditingController(text: widget.jogo?.genero ?? '');
    _notaController =
        TextEditingController(text: widget.jogo?.nota.toString() ?? '');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _plataformaController.dispose();
    _generoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _salvar() {
    // validate() dispara todos os `validator` dos campos.
    if (!_formKey.currentState!.validate()) return;

    final resultado = JogoModel(
      // Preserva o id ao editar (necessário para o UPDATE no banco).
      id: widget.jogo?.id,
      titulo: _tituloController.text.trim(),
      plataforma: _plataformaController.text.trim(),
      genero: _generoController.text.trim(),
      nota: int.parse(_notaController.text.trim()),
    );
    Navigator.pop(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    // Respeita o teclado para o form não ficar oculto.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editando ? 'Editar jogo' : 'Cadastrar jogo',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.sports_esports),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o título.';
                if (v.trim().length < 2) return 'Título muito curto.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plataformaController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Plataforma',
                hintText: 'Ex.: PC, PS5, Nintendo Switch',
                prefixIcon: Icon(Icons.devices),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe a plataforma.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _generoController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Gênero',
                hintText: 'Ex.: RPG, Ação, Corrida',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o gênero.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'De 0 a 10',
                prefixIcon: Icon(Icons.star_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe a nota.';
                final nota = int.tryParse(v.trim());
                if (nota == null || nota < 0 || nota > 10) {
                  return 'A nota deve ser de 0 a 10.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: Icon(_editando ? Icons.check : Icons.save),
              label: Text(
                  _editando ? 'Salvar alterações' : 'Salvar no banco offline'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
