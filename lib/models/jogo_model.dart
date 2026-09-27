// =============================================================================
// MODELO DE DADOS — JogoModel
// -----------------------------------------------------------------------------
// Entidade IMUTÁVEL (campos `final`). É a ponte entre o mundo Dart (objetos que
// a UI entende) e o SQLite (linhas = Map<String, Object?>).
//
//   • toMap()   -> objeto  -> Map  (para GRAVAR no banco)
//   • fromMap() -> Map      -> objeto (para LER do banco)
// =============================================================================
class JogoModel {
  final int? id; // Nulo antes de inserir; o SQLite gera via AUTOINCREMENT.
  final String titulo;
  final String plataforma;
  final String genero;
  final int nota; // Avaliação pessoal de 0 a 10.

  const JogoModel({
    this.id,
    required this.titulo,
    required this.plataforma,
    required this.genero,
    required this.nota,
  });

  /// Converte o objeto em Map compatível com as colunas da tabela.
  /// As CHAVES devem ser idênticas aos nomes das colunas no SQLite.
  Map<String, Object?> toMap() {
    return {
      // Omitimos `id` quando null para deixar o AUTOINCREMENT agir.
      if (id != null) 'id': id,
      'titulo': titulo,
      'plataforma': plataforma,
      'genero': genero,
      'nota': nota,
    };
  }

  /// Factory que reconstrói um JogoModel a partir de uma linha do banco.
  factory JogoModel.fromMap(Map<String, Object?> map) {
    return JogoModel(
      id: map['id'] as int?,
      titulo: (map['titulo'] as String?) ?? '',
      plataforma: (map['plataforma'] as String?) ?? '',
      genero: (map['genero'] as String?) ?? '',
      nota: (map['nota'] as int?) ?? 0,
    );
  }

  /// Cópia com alterações pontuais (útil para editar mantendo imutabilidade).
  JogoModel copyWith({
    int? id,
    String? titulo,
    String? plataforma,
    String? genero,
    int? nota,
  }) {
    return JogoModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      plataforma: plataforma ?? this.plataforma,
      genero: genero ?? this.genero,
      nota: nota ?? this.nota,
    );
  }

  @override
  String toString() => 'JogoModel(id: $id, titulo: $titulo, '
      'plataforma: $plataforma, genero: $genero, nota: $nota)';
}
