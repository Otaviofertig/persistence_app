// =============================================================================
// MINHA COLEÇÃO DE JOGOS (OFFLINE)
// -----------------------------------------------------------------------------
// Ponto de entrada do app. Responsabilidade ÚNICA: inicializar o binding,
// carregar as PREFERÊNCIAS salvas (tema + ordenação) e subir o app.
//
// Arquitetura em camadas (cada arquivo tem uma responsabilidade):
//   lib/
//   ├── main.dart                     -> bootstrap (este arquivo)
//   ├── app.dart                      -> MaterialApp + gestão de tema
//   ├── models/
//   │   ├── jogo_model.dart           -> entidade imutável (toMap/fromMap)
//   │   └── ordem_lista.dart          -> opções de ordenação da lista
//   ├── data/
//   │   ├── database_helper.dart      -> Singleton SQLite (abertura + schema)
//   │   ├── jogo_repository.dart      -> CRUD (isola o sqflite da UI)
//   │   ├── theme_preferences.dart    -> SharedPreferences (tema)
//   │   └── ordem_preferences.dart    -> SharedPreferences (ordenação)
//   └── ui/
//       ├── home_page.dart            -> FutureBuilder + lista + busca
//       └── widgets/                  -> Card, formulário, estado vazio
// =============================================================================
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/ordem_preferences.dart';
import 'data/theme_preferences.dart';

Future<void> main() async {
  // Obrigatório: usamos código assíncrono (SharedPreferences) antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega a preferência de tema persistida (default = Modo Claro).
  final bool isDark = await ThemePreferences().loadIsDarkMode();

  // Carrega a ordenação persistida da lista (default = Título A → Z).
  final ordem = await OrdemPreferences().loadOrdem();

  runApp(ColecaoJogosApp(temaInicialEscuro: isDark, ordemInicial: ordem));
}
