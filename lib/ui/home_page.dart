// =============================================================================
// TELA PRINCIPAL — HomePage
// -----------------------------------------------------------------------------
// Orquestra a UI: dispara a leitura do banco (Future) e a desenha com
// FutureBuilder, abre o formulário, filtra a busca e remove registros.
// Toda persistência é delegada ao JogoRepository — a tela não conhece SQL.
// =============================================================================
import 'package:flutter/material.dart';

import '../data/i_jogo_repository.dart';
import '../data/jogo_repository.dart';
import '../models/jogo_model.dart';
import 'widgets/empty_state.dart';
import 'widgets/jogo_card.dart';
import 'widgets/jogo_form.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final Future<void> Function() onAlternarTema;

  /// Repositório injetável. Em produção usa o SQLite; em testes, um fake.
  final IJogoRepository? repository;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onAlternarTema,
    this.repository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final IJogoRepository _repository =
      widget.repository ?? JogoRepository();

  // O Future observado pelo FutureBuilder. Trocá-lo força uma releitura.
  late Future<List<JogoModel>> _futureJogos;

  String _termoBusca = '';
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureJogos = _repository.getAll(); // primeira leitura
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  /// Reatribui o Future -> o FutureBuilder relê o banco.
  void _recarregar() {
    // IMPORTANTE: usar corpo de bloco `{ }` e NÃO `=>`.
    // Com arrow (`=> _futureJogos = ...`) o callback RETORNA o valor da
    // atribuição (um Future), e o setState rejeita callbacks que retornam
    // Future — lançando exceção e deixando de aplicar a atualização.
    setState(() {
      _futureJogos = _repository.getAll();
    });
  }

  void _mostrarSnack(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _abrirFormulario() async {
    final novo = await JogoForm.mostrar(context);
    if (novo == null) return;
    await _repository.insert(novo);
    _mostrarSnack('✅ "${novo.titulo}" salvo no banco offline.');
    _recarregar();
  }

  /// Abre o formulário em modo EDIÇÃO (pré-preenchido) e aplica o UPDATE.
  Future<void> _editar(JogoModel jogo) async {
    final editado = await JogoForm.mostrar(context, jogo: jogo);
    if (editado == null) return;
    await _repository.update(editado);
    _mostrarSnack('✏️ "${editado.titulo}" atualizado no banco offline.');
    _recarregar();
  }

  Future<void> _confirmarRemocao(JogoModel jogo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover jogo?'),
        content:
            Text('Deseja remover "${jogo.titulo}" do banco de dados local?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar == true && jogo.id != null) {
      await _repository.delete(jogo.id!);
      _mostrarSnack('🗑️ "${jogo.titulo}" removido do banco offline.');
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        title: const Text('Coleção de Jogos'),
        actions: [
          // Indicador visual de banco local ativo.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Chip(
              avatar: Icon(Icons.storage,
                  size: 18, color: theme.colorScheme.primary),
              label: const Text('SQLite ativo'),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Alternar tema (persiste no SharedPreferences via callback).
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Mudar para Modo Claro'
                : 'Mudar para Modo Escuro',
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onAlternarTema,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa (filtro em memória sobre o resultado do banco).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por título, plataforma ou gênero...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _termoBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _termoBusca = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _termoBusca = v),
            ),
          ),

          // ------------------------------------------------------------------
          // FUTUREBUILDER — leitura assíncrona do banco com seus 4 estados.
          // ------------------------------------------------------------------
          Expanded(
            child: FutureBuilder<List<JogoModel>>(
              future: _futureJogos,
              builder: (context, snapshot) {
                // 1) CARREGANDO
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2) ERRO
                if (snapshot.hasError) {
                  return EmptyState(
                    icone: Icons.error_outline,
                    titulo: 'Erro ao ler o banco',
                    subtitulo: '${snapshot.error}',
                  );
                }

                // Filtro de busca em memória.
                final todos = snapshot.data ?? const <JogoModel>[];
                final termo = _termoBusca.trim().toLowerCase();
                final lista = termo.isEmpty
                    ? todos
                    : todos
                        .where((j) =>
                            j.titulo.toLowerCase().contains(termo) ||
                            j.plataforma.toLowerCase().contains(termo) ||
                            j.genero.toLowerCase().contains(termo))
                        .toList();

                // 3) VAZIO
                if (lista.isEmpty) {
                  return EmptyState(
                    icone: termo.isEmpty
                        ? Icons.videogame_asset_outlined
                        : Icons.search_off,
                    titulo: termo.isEmpty
                        ? 'Nenhum jogo salvo offline'
                        : 'Nenhum resultado para "$_termoBusca"',
                    subtitulo: termo.isEmpty
                        ? 'Toque no botão + para cadastrar o primeiro.'
                        : null,
                  );
                }

                // 4) COM DADOS
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final jogo = lista[index];
                    return JogoCard(
                      jogo: jogo,
                      onEditar: () => _editar(jogo),
                      onRemover: () => _confirmarRemocao(jogo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Novo jogo'),
      ),
    );
  }
}
