// =============================================================================
// MODELO — OrdemLista
// -----------------------------------------------------------------------------
// Opções de ordenação da lista de jogos. É o VALOR da nova preferência
// persistida no SharedPreferences (ver data/ordem_preferences.dart).
// =============================================================================
enum OrdemLista {
  tituloAz('Título (A → Z)'),
  tituloZa('Título (Z → A)'),
  maiorNota('Maior nota primeiro');

  /// Texto exibido no menu de ordenação.
  final String rotulo;

  const OrdemLista(this.rotulo);

  /// Converte o texto salvo no SharedPreferences de volta para o enum.
  /// Valor desconhecido ou ausente -> ordem padrão (A → Z).
  static OrdemLista fromName(String? nome) {
    return OrdemLista.values.firstWhere(
      (o) => o.name == nome,
      orElse: () => OrdemLista.tituloAz,
    );
  }
}
