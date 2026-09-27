// =============================================================================
// TESTES — Minha Coleção de Jogos
// -----------------------------------------------------------------------------
// Provam que o app funciona SEM device físico, cobrindo as duas camadas:
//
//   1) CAMADA DE DADOS (SQLite real, em memória via `sqflite_common_ffi`):
//      testa o CRUD do JogoRepository, a ordenação (ORDER BY) e o
//      mapeamento do modelo.
//
//   2) SHAREDPREFERENCES (mock em memória): testa a nova preferência de
//      ORDENAÇÃO (padrão, gravação e leitura).
//
//   3) CAMADA DE UI (FutureBuilder + estados): usa um repositório FAKE em
//      memória (Dart puro). Fazemos isso porque o SQLite via FFI usa I/O
//      assíncrono real, incompatível com o "fake async" do testWidgets —
//      então injetamos um fake, que é a prática recomendada para testar UI.
//
// Para rodar: flutter test
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:persistence_app/app.dart';
import 'package:persistence_app/data/i_jogo_repository.dart';
import 'package:persistence_app/data/jogo_repository.dart';
import 'package:persistence_app/data/ordem_preferences.dart';
import 'package:persistence_app/models/jogo_model.dart';
import 'package:persistence_app/models/ordem_lista.dart';

/// Repositório FAKE em memória — implementa o mesmo contrato do real.
/// Resolve os Futures instantaneamente, o que funciona com o testWidgets.
class FakeJogoRepository implements IJogoRepository {
  final List<JogoModel> _dados = [];
  int _seq = 0;

  @override
  Future<int> insert(JogoModel jogo) async {
    _seq++;
    _dados.add(jogo.copyWith(id: _seq));
    return _seq;
  }

  @override
  Future<List<JogoModel>> getAll({
    OrdemLista ordem = OrdemLista.tituloAz,
  }) async {
    int porTitulo(JogoModel a, JogoModel b) =>
        a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
    final copia = [..._dados];
    switch (ordem) {
      case OrdemLista.tituloAz:
        copia.sort(porTitulo);
      case OrdemLista.tituloZa:
        copia.sort((a, b) => porTitulo(b, a));
      case OrdemLista.maiorNota:
        copia.sort((a, b) {
          final porNota = b.nota.compareTo(a.nota);
          return porNota != 0 ? porNota : porTitulo(a, b);
        });
    }
    return copia;
  }

  @override
  Future<int> update(JogoModel jogo) async {
    final i = _dados.indexWhere((j) => j.id == jogo.id);
    if (i < 0) return 0;
    _dados[i] = jogo;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    final antes = _dados.length;
    _dados.removeWhere((j) => j.id == id);
    return antes - _dados.length;
  }
}

void main() {
  // -------------------------------------------------------------------------
  // 1) CAMADA DE DADOS — SQLite REAL em memória
  // -------------------------------------------------------------------------
  group('CRUD no SQLite real (Repository)', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test('insere, lista e remove um jogo', () async {
      final repo = JogoRepository();
      // Limpa qualquer resíduo.
      for (final j in await repo.getAll()) {
        await repo.delete(j.id!);
      }

      // CREATE
      final id = await repo.insert(
        const JogoModel(
            titulo: 'Hollow Knight',
            plataforma: 'PC',
            genero: 'Metroidvania',
            nota: 10),
      );
      expect(id, greaterThan(0));

      // READ
      var lista = await repo.getAll();
      expect(lista.length, 1);
      expect(lista.first.titulo, 'Hollow Knight');
      expect(lista.first.plataforma, 'PC');
      expect(lista.first.genero, 'Metroidvania');
      expect(lista.first.nota, 10);

      // DELETE
      final removidos = await repo.delete(lista.first.id!);
      expect(removidos, 1);
      lista = await repo.getAll();
      expect(lista, isEmpty);
    });

    test('atualiza (UPDATE) um jogo existente', () async {
      final repo = JogoRepository();
      for (final j in await repo.getAll()) {
        await repo.delete(j.id!);
      }

      final id = await repo.insert(
        const JogoModel(
            titulo: 'Titulo Antigo',
            plataforma: 'PS4',
            genero: 'Ação',
            nota: 6),
      );

      // Atualiza mantendo o mesmo id.
      final linhas = await repo.update(
        JogoModel(
            id: id,
            titulo: 'Titulo Novo',
            plataforma: 'PS5',
            genero: 'RPG',
            nota: 9),
      );
      expect(linhas, 1);

      final lista = await repo.getAll();
      expect(lista.length, 1);
      expect(lista.first.id, id); // mesmo registro
      expect(lista.first.titulo, 'Titulo Novo');
      expect(lista.first.plataforma, 'PS5');
      expect(lista.first.genero, 'RPG');
      expect(lista.first.nota, 9);
    });

    test('getAll respeita a ordenação pedida (ORDER BY)', () async {
      final repo = JogoRepository();
      for (final j in await repo.getAll()) {
        await repo.delete(j.id!);
      }

      await repo.insert(const JogoModel(
          titulo: 'celeste', plataforma: 'PC', genero: 'Plataforma', nota: 9));
      await repo.insert(const JogoModel(
          titulo: 'Among Us', plataforma: 'PC', genero: 'Social', nota: 7));
      await repo.insert(const JogoModel(
          titulo: 'Zelda', plataforma: 'Switch', genero: 'Aventura', nota: 10));
      await repo.insert(const JogoModel(
          titulo: 'Braid', plataforma: 'PC', genero: 'Puzzle', nota: 9));

      List<String> titulos(List<JogoModel> l) =>
          l.map((j) => j.titulo).toList();

      // A -> Z (sem diferenciar maiúsculas/minúsculas).
      expect(titulos(await repo.getAll(ordem: OrdemLista.tituloAz)),
          ['Among Us', 'Braid', 'celeste', 'Zelda']);
      // Z -> A.
      expect(titulos(await repo.getAll(ordem: OrdemLista.tituloZa)),
          ['Zelda', 'celeste', 'Braid', 'Among Us']);
      // Maior nota; empate desempata pelo título.
      expect(titulos(await repo.getAll(ordem: OrdemLista.maiorNota)),
          ['Zelda', 'Braid', 'celeste', 'Among Us']);

      for (final j in await repo.getAll()) {
        await repo.delete(j.id!);
      }
    });
  });

  // -------------------------------------------------------------------------
  // MAPEAMENTO DO MODELO
  // -------------------------------------------------------------------------
  group('Mapeamento do modelo', () {
    test('toMap/fromMap são simétricos', () {
      const original = JogoModel(
          id: 7,
          titulo: 'Celeste',
          plataforma: 'Switch',
          genero: 'Plataforma',
          nota: 9);
      final recriado = JogoModel.fromMap(original.toMap());
      expect(recriado.id, 7);
      expect(recriado.titulo, 'Celeste');
      expect(recriado.plataforma, 'Switch');
      expect(recriado.genero, 'Plataforma');
      expect(recriado.nota, 9);
    });
  });

  // -------------------------------------------------------------------------
  // 2) SHAREDPREFERENCES — nova preferência de ORDENAÇÃO
  // -------------------------------------------------------------------------
  group('OrdemPreferences (SharedPreferences)', () {
    test('primeira execução usa Título (A → Z)', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await OrdemPreferences().loadOrdem(), OrdemLista.tituloAz);
    });

    test('salva e recarrega a ordenação escolhida', () async {
      SharedPreferences.setMockInitialValues({});
      await OrdemPreferences().saveOrdem(OrdemLista.maiorNota);

      // Uma NOVA instância lê o mesmo valor (como ao reabrir o app).
      expect(await OrdemPreferences().loadOrdem(), OrdemLista.maiorNota);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ordem_lista'), 'maiorNota');
    });

    test('valor inválido salvo cai no padrão', () async {
      SharedPreferences.setMockInitialValues({'ordem_lista': 'xyz'});
      expect(await OrdemPreferences().loadOrdem(), OrdemLista.tituloAz);
    });
  });

  // -------------------------------------------------------------------------
  // 3) CAMADA DE UI — com repositório FAKE
  // -------------------------------------------------------------------------
  group('UI (FutureBuilder)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('mostra estado vazio quando não há jogos', (tester) async {
      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: FakeJogoRepository(),
      ));
      await tester.pumpAndSettle(); // aguarda o FutureBuilder resolver

      expect(find.text('Coleção de Jogos'), findsOneWidget); // AppBar
      expect(find.text('SQLite ativo'), findsOneWidget); // indicador do banco
      expect(find.text('Nenhum jogo salvo offline'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('exibe jogo salvo na lista', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(
        const JogoModel(
            titulo: 'Hades', plataforma: 'PC', genero: 'Roguelike', nota: 10),
      );

      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hades'), findsOneWidget);
      expect(find.text('PC • Roguelike'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // nota no card
    });

    testWidgets('filtra a lista pela busca', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
          titulo: 'Stardew Valley',
          plataforma: 'PC',
          genero: 'Simulação',
          nota: 9));
      await fake.insert(const JogoModel(
          titulo: 'Mario Kart 8',
          plataforma: 'Switch',
          genero: 'Corrida',
          nota: 8));

      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      // Ambos aparecem inicialmente.
      expect(find.text('Stardew Valley'), findsOneWidget);
      expect(find.text('Mario Kart 8'), findsOneWidget);

      // Digita na busca (pelo gênero) -> filtra.
      await tester.enterText(find.byType(TextField), 'corrida');
      await tester.pumpAndSettle();

      expect(find.text('Stardew Valley'), findsNothing);
      expect(find.text('Mario Kart 8'), findsOneWidget);
    });

    // REGRESSÃO: garante que, ao cadastrar pelo formulário, a lista atualiza
    // SEM precisar reabrir o app.
    testWidgets('cadastrar pelo formulário atualiza a lista na hora',
        (tester) async {
      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: FakeJogoRepository(),
      ));
      await tester.pumpAndSettle();

      // Começa vazio.
      expect(find.text('Nenhum jogo salvo offline'), findsOneWidget);

      // Abre o formulário (FAB).
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Preenche os campos.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), 'Minecraft');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plataforma'), 'PC');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Gênero'), 'Sandbox');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nota'), '9');

      // Salva.
      await tester.tap(find.text('Salvar no banco offline'));
      await tester.pumpAndSettle();

      // A lista atualizou sem reabrir o app.
      expect(find.text('Nenhum jogo salvo offline'), findsNothing);
      expect(find.text('Minecraft'), findsOneWidget);
      expect(find.text('PC • Sandbox'), findsOneWidget);
    });

    testWidgets('formulário rejeita nota fora de 0 a 10', (tester) async {
      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: FakeJogoRepository(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), 'Tetris');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plataforma'), 'Game Boy');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Gênero'), 'Puzzle');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nota'), '11');

      await tester.tap(find.text('Salvar no banco offline'));
      await tester.pumpAndSettle();

      // O formulário continua aberto, mostrando o erro de validação.
      expect(find.text('A nota deve ser de 0 a 10.'), findsOneWidget);
    });

    testWidgets('editar pelo formulário atualiza o card', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(
        const JogoModel(
            titulo: 'Titulo Antigo',
            plataforma: 'PS4',
            genero: 'Ação',
            nota: 6),
      );

      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Titulo Antigo'), findsOneWidget);

      // Abre a edição pelo botão de lápis.
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // O formulário abre em modo edição, pré-preenchido.
      expect(find.text('Editar jogo'), findsOneWidget);

      // Altera o título e salva.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), 'Titulo Novo');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      // O card reflete a alteração, sem duplicar registros.
      expect(find.text('Titulo Antigo'), findsNothing);
      expect(find.text('Titulo Novo'), findsOneWidget);
    });

    testWidgets('remover pede confirmação e apaga o jogo', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(
        const JogoModel(
            titulo: 'Portal 2', plataforma: 'PC', genero: 'Puzzle', nota: 10),
      );

      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Remover jogo?'), findsOneWidget);

      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(find.text('Portal 2'), findsNothing);
      expect(find.text('Nenhum jogo salvo offline'), findsOneWidget);
    });

    testWidgets('menu de ordenação reordena a lista e persiste a escolha',
        (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
          titulo: 'Asteroids', plataforma: 'Atari', genero: 'Arcade', nota: 6));
      await fake.insert(const JogoModel(
          titulo: 'Zelda', plataforma: 'Switch', genero: 'Aventura', nota: 10));

      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      // Padrão: A -> Z.
      expect(find.text('Ordenado por: Título (A → Z)'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Asteroids')).dy,
          lessThan(tester.getTopLeft(find.text('Zelda')).dy));

      // Escolhe "Z -> A" no menu da AppBar.
      await tester.tap(find.byTooltip('Ordenar lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          CheckedPopupMenuItem<OrdemLista>, 'Título (Z → A)'));
      await tester.pumpAndSettle();

      expect(find.text('Ordenado por: Título (Z → A)'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Zelda')).dy,
          lessThan(tester.getTopLeft(find.text('Asteroids')).dy));

      // A escolha foi gravada no SharedPreferences.
      expect(await OrdemPreferences().loadOrdem(), OrdemLista.tituloZa);
    });

    testWidgets('abre o app com a ordenação salva anteriormente',
        (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
          titulo: 'Asteroids', plataforma: 'Atari', genero: 'Arcade', nota: 6));
      await fake.insert(const JogoModel(
          titulo: 'Zelda', plataforma: 'Switch', genero: 'Aventura', nota: 10));

      // Simula o main(): ordem lida do SharedPreferences ao reabrir o app.
      await tester.pumpWidget(ColecaoJogosApp(
        temaInicialEscuro: false,
        ordemInicial: OrdemLista.maiorNota,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ordenado por: Maior nota primeiro'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Zelda')).dy,
          lessThan(tester.getTopLeft(find.text('Asteroids')).dy));
    });
  });
}
