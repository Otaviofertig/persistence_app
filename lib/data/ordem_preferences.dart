// =============================================================================
// CAMADA DE DADOS — OrdemPreferences (SharedPreferences)
// -----------------------------------------------------------------------------
// Encapsula o acesso ao SharedPreferences para a ORDENAÇÃO da lista.
// Segue o mesmo padrão do ThemePreferences: a UI não lida com chaves de string
// soltas — pede load()/save() num tipo claro (o enum OrdemLista).
//
// O enum é salvo como String (o `name`: "tituloAz", "tituloZa", "maiorNota"),
// já que o SharedPreferences só guarda tipos primitivos.
// =============================================================================
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ordem_lista.dart';

class OrdemPreferences {
  // Chave centralizada (evita erro de digitação espalhado).
  static const String _kOrdemLista = 'ordem_lista';

  /// Carrega a ordenação salva. Default = Título (A → Z) na 1ª execução.
  Future<OrdemLista> loadOrdem() async {
    final prefs = await SharedPreferences.getInstance();
    return OrdemLista.fromName(prefs.getString(_kOrdemLista));
  }

  /// Persiste a ordenação escolhida.
  Future<void> saveOrdem(OrdemLista ordem) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOrdemLista, ordem.name);
  }
}
