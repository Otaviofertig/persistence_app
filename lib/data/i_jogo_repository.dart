// =============================================================================
// CONTRATO — IJogoRepository
// -----------------------------------------------------------------------------
// Interface (contrato) da camada de dados. A UI depende DESTA abstração, não da
// implementação concreta com SQLite. Isso permite:
//   • trocar a fonte de dados (SQLite, API, memória) sem tocar na UI;
//   • testar a UI com um repositório "fake" em memória.
// =============================================================================
import '../models/jogo_model.dart';
import '../models/ordem_lista.dart';

abstract class IJogoRepository {
  Future<int> insert(JogoModel jogo);
  Future<List<JogoModel>> getAll({OrdemLista ordem = OrdemLista.tituloAz});
  Future<int> update(JogoModel jogo);
  Future<int> delete(int id);
}
