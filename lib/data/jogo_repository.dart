// =============================================================================
// CAMADA DE DADOS — JogoRepository (padrão Repository)
// -----------------------------------------------------------------------------
// Abstrai o SQLite da UI. A tela NÃO sabe que existe `sqflite` — ela só pede
// "insere", "lista", "remove". Isso facilita testes e uma eventual troca de
// fonte de dados (ex.: API, Hive) sem tocar na interface.
// =============================================================================
import '../models/jogo_model.dart';
import '../models/ordem_lista.dart';
import 'database_helper.dart';
import 'i_jogo_repository.dart';

class JogoRepository implements IJogoRepository {
  final DatabaseHelper _helper;

  // Injeção de dependência com default para o Singleton (facilita testes).
  JogoRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  /// CREATE — insere um jogo e retorna o id gerado.
  @override
  Future<int> insert(JogoModel jogo) async {
    final db = await _helper.database;
    return db.insert(DatabaseHelper.tabelaJogos, jogo.toMap());
  }

  /// READ — lê todos os jogos na ordem pedida (ORDER BY feito pelo SQLite).
  @override
  Future<List<JogoModel>> getAll({
    OrdemLista ordem = OrdemLista.tituloAz,
  }) async {
    final db = await _helper.database;
    final linhas = await db.query(
      DatabaseHelper.tabelaJogos,
      orderBy: _orderBy(ordem),
    );
    // Mapeia cada linha (Map) para um objeto do domínio.
    return linhas.map(JogoModel.fromMap).toList();
  }

  /// Traduz a ordenação do domínio para a cláusula ORDER BY do SQL.
  static String _orderBy(OrdemLista ordem) {
    switch (ordem) {
      case OrdemLista.tituloAz:
        return 'titulo COLLATE NOCASE ASC';
      case OrdemLista.tituloZa:
        return 'titulo COLLATE NOCASE DESC';
      case OrdemLista.maiorNota:
        // Empate na nota -> desempata pelo título.
        return 'nota DESC, titulo COLLATE NOCASE ASC';
    }
  }

  /// UPDATE — atualiza um jogo existente (pelo id). Retorna nº de linhas.
  @override
  Future<int> update(JogoModel jogo) async {
    final db = await _helper.database;
    return db.update(
      DatabaseHelper.tabelaJogos,
      jogo.toMap(),
      where: 'id = ?',
      whereArgs: [jogo.id],
    );
  }

  /// DELETE — remove por id. `whereArgs` evita SQL Injection.
  @override
  Future<int> delete(int id) async {
    final db = await _helper.database;
    return db.delete(
      DatabaseHelper.tabelaJogos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
