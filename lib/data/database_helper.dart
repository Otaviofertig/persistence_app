// =============================================================================
// CAMADA DE INFRAESTRUTURA — DatabaseHelper (PADRÃO SINGLETON)
// -----------------------------------------------------------------------------
// Por que Singleton?
//   Abrir o mesmo arquivo de banco várias vezes em paralelo pode CORROMPER o
//   arquivo. O Singleton garante UMA instância do helper e UMA conexão
//   (`Database`) reutilizada em todo o app.
//
// Responsabilidade ÚNICA desta classe: abrir/criar o banco e expor a conexão.
// O CRUD fica no Repository (separação de responsabilidades).
// =============================================================================
import 'package:sqflite/sqflite.dart';
// Prefixo `p` deixa explícito que `join` vem do pacote `path`.
import 'package:path/path.dart' as p;

class DatabaseHelper {
  // Construtor privado — inacessível fora deste arquivo.
  DatabaseHelper._internal();

  // Instância única e estática.
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // Cache da conexão (lazy). Nula até a primeira abertura.
  static Database? _database;

  // Metadados centralizados (sem "strings mágicas" espalhadas).
  static const String _dbName = 'colecao_jogos.db';
  static const int _dbVersion = 1;
  static const String tabelaJogos = 'jogos';

  /// Getter ASSÍNCRONO da conexão.
  /// Reutiliza o cache se já aberto; senão abre uma única vez.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Abre o arquivo do banco no diretório padrão do dispositivo.
  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath(); // pasta de bancos do SO
    final String caminhoCompleto = p.join(dbPath, _dbName); // separador correto

    return openDatabase(
      caminhoCompleto,
      version: _dbVersion,
      onCreate: _onCreate, // roda só na primeira vez (banco novo)
    );
  }

  /// Cria o schema na primeira execução.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tabelaJogos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        plataforma TEXT NOT NULL,
        genero TEXT NOT NULL,
        nota INTEGER NOT NULL CHECK (nota BETWEEN 0 AND 10)
      )
    ''');
  }
}
