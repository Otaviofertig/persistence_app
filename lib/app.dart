// =============================================================================
// WIDGET RAIZ — ColecaoJogosApp
// -----------------------------------------------------------------------------
// Configura o MaterialApp e gerencia o estado do TEMA (claro/escuro),
// persistindo cada alternância no SharedPreferences via ThemePreferences.
// Repassa à HomePage a ORDENAÇÃO salva (lida no main()).
// =============================================================================
import 'package:flutter/material.dart';

import 'data/i_jogo_repository.dart';
import 'data/theme_preferences.dart';
import 'models/ordem_lista.dart';
import 'ui/home_page.dart';

class ColecaoJogosApp extends StatefulWidget {
  final bool temaInicialEscuro;

  /// Ordenação da lista salva no SharedPreferences.
  final OrdemLista ordemInicial;

  /// Repositório injetável (opcional). Usado nos testes de UI.
  final IJogoRepository? repository;

  const ColecaoJogosApp({
    super.key,
    required this.temaInicialEscuro,
    this.ordemInicial = OrdemLista.tituloAz,
    this.repository,
  });

  @override
  State<ColecaoJogosApp> createState() => _ColecaoJogosAppState();
}

class _ColecaoJogosAppState extends State<ColecaoJogosApp> {
  final ThemePreferences _themePrefs = ThemePreferences();
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.temaInicialEscuro; // valor lido no main()
  }

  /// Alterna o tema e PERSISTE a escolha no SharedPreferences.
  Future<void> _alternarTema() async {
    setState(() => _isDarkMode = !_isDarkMode);
    await _themePrefs.saveIsDarkMode(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    const Color seed = Color(0xFF6A1B9A);

    return MaterialApp(
      title: 'Coleção de Jogos',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(
        isDarkMode: _isDarkMode,
        onAlternarTema: _alternarTema,
        ordemInicial: widget.ordemInicial,
        repository: widget.repository,
      ),
    );
  }
}
