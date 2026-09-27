# 🎮 Minha Coleção de Jogos (Offline)

Aplicativo Flutter para montar a sua **coleção pessoal de jogos** — com título, plataforma, gênero e a sua nota de 0 a 10 — tudo salvo **offline** no dispositivo.

Feito a partir do app de exemplo [ADSSTech/persistence_app](https://github.com/ADSSTech/persistence_app) (Tutoria 4 — Persistência), trocando o domínio de "políticos" por **jogos** e acrescentando uma **nova preferência persistida**: a **ordenação da lista**.

| Tecnologia | Para quê usamos | Pacote |
|---|---|---|
| **SQLite** | Dados estruturados: o CRUD de jogos (tabela `jogos`) | [`sqflite`](https://pub.dev/packages/sqflite) + [`path`](https://pub.dev/packages/path) |
| **SharedPreferences** | Configurações chave-valor: **tema** (claro/escuro) e **ordenação da lista** | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |

---

## 🎬 Demonstração

<!-- Salve o GIF do app rodando em docs/demo.gif e remova este comentário:
<p align="center">
  <img src="docs/demo.gif" alt="Demonstração da Coleção de Jogos" width="300"/>
</p>
-->

---

## 📱 O que o app faz

1. **Lista** os jogos salvos no banco local (título, plataforma, gênero e nota ⭐).
2. **Cadastra** um novo jogo por um formulário (BottomSheet) com validação — a nota precisa estar entre 0 e 10.
3. **Pesquisa** por título, plataforma ou gênero (filtro em tempo real).
4. **Edita** um jogo (toque no lápis ou no card) — mesmo formulário, pré-preenchido.
5. **Remove** um jogo (com diálogo de confirmação).
6. **Ordena** a lista pelo menu da AppBar (ícone ↕): **Título A → Z**, **Título Z → A** ou **Maior nota primeiro** — e **lembra a escolha** ao fechar e reabrir o app. ⭐ *nova preferência*
7. **Alterna o tema** claro/escuro pela AppBar — e também **lembra a escolha**.
8. Mostra um indicador **"SQLite ativo"** na AppBar, a ordenação ativa acima da lista e **SnackBars** de feedback ao salvar/editar/remover.

O avatar de cada card mostra a **sigla da plataforma** (ex.: "Nintendo Switch" → **NS**, "PC" → **PC**).

### Estados da tela (via `FutureBuilder`)

| Estado | O que aparece |
|---|---|
| ⏳ Carregando | `CircularProgressIndicator()` |
| 🎮 Vazio | Ícone de controle + "Nenhum jogo salvo offline" |
| 📋 Com dados | `ListView` de `Card`s com sigla da plataforma, nota e botões de editar/remover |
| ⚠️ Erro | Mensagem de erro amigável |

---

## ⭐ A nova SharedPreference: ordenação da lista

Além do tema (que já existia), o app salva **qual ordenação o usuário escolheu**:

| Chave | Tipo | Valores | Padrão |
|---|---|---|---|
| `is_dark_mode` | `bool` | `true` / `false` | `false` (claro) |
| `ordem_lista` | `String` | `tituloAz`, `tituloZa`, `maiorNota` | `tituloAz` |

Como funciona:

1. **`models/ordem_lista.dart`** — `enum OrdemLista` com as três opções e o texto mostrado no menu.
2. **`data/ordem_preferences.dart`** — `OrdemPreferences` com `loadOrdem()` / `saveOrdem()`, seguindo o mesmo padrão do `ThemePreferences`. O enum é gravado como `String` (o `name`), porque o SharedPreferences só guarda tipos primitivos. Um valor desconhecido volta para o padrão.
3. **`main.dart`** — antes do `runApp`, carrega o tema **e** a ordenação salvos.
4. **`ui/home_page.dart`** — o `PopupMenuButton` da AppBar troca a ordenação, **grava no SharedPreferences** e relê o banco.
5. **`data/jogo_repository.dart`** — `getAll(ordem: ...)` traduz a escolha para o `ORDER BY` do SQL:

| Opção | `ORDER BY` |
|---|---|
| Título (A → Z) | `titulo COLLATE NOCASE ASC` |
| Título (Z → A) | `titulo COLLATE NOCASE DESC` |
| Maior nota primeiro | `nota DESC, titulo COLLATE NOCASE ASC` |

---

## 🧱 Arquitetura (em camadas)

```
lib/
├── main.dart                       # Bootstrap: carrega tema + ordenação salvos e sobe o app
├── app.dart                        # MaterialApp + gestão do tema (claro/escuro)
│
├── models/
│   ├── jogo_model.dart             # Entidade IMUTÁVEL. toMap() / fromMap() / copyWith()
│   └── ordem_lista.dart            # Opções de ordenação (valor da nova preferência)
│
├── data/                           # Camada de dados (persistência)
│   ├── database_helper.dart        # Singleton do SQLite (abre banco + cria schema)
│   ├── i_jogo_repository.dart      # Contrato (interface) do repositório
│   ├── jogo_repository.dart        # CRUD + ORDER BY (isola o SQL da UI)
│   ├── theme_preferences.dart      # SharedPreferences: tema
│   └── ordem_preferences.dart      # SharedPreferences: ordenação da lista
│
└── ui/                             # Camada de apresentação
    ├── home_page.dart              # Tela principal (FutureBuilder + busca + ordenação)
    └── widgets/
        ├── jogo_card.dart          # Card/ListTile de um jogo
        ├── jogo_form.dart          # Formulário (BottomSheet) com validação
        └── empty_state.dart        # Estado vazio amigável
```

- **`DatabaseHelper` (Singleton):** garante **uma única conexão** com o arquivo `colecao_jogos.db`.
- **`Repository`:** a tela **não sabe** que existe SQL — pede "insere", "lista", "atualiza", "remove". Isso permite testar a UI com um repositório fake.
- **`Model` imutável:** `toMap()` grava no banco; `fromMap()` reconstrói o objeto ao ler.

### Esquema da tabela `jogos`

```sql
CREATE TABLE jogos (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  titulo     TEXT NOT NULL,
  plataforma TEXT NOT NULL,
  genero     TEXT NOT NULL,
  nota       INTEGER NOT NULL CHECK (nota BETWEEN 0 AND 10)
);
```

---

## ▶️ Como rodar

Pré-requisitos: [Flutter 3.10+](https://docs.flutter.dev/get-started/install) (`flutter doctor` sem erros) e um emulador Android, simulador iOS ou dispositivo físico.

```bash
flutter pub get
flutter devices
flutter run            # ou: flutter run -d <id-do-dispositivo>
```

> O `sqflite` roda nativamente em **Android** e **iOS**. Em desktop/web ele precisa do `sqflite_common_ffi` (usado aqui só nos testes).

---

## ✅ Testes e análise estática

```bash
flutter analyze     # No issues found!
flutter test        # 00:04 +16: All tests passed!
```

Os 16 testes cobrem:

1. **CRUD real no SQLite** (em memória via `sqflite_common_ffi`): insere → lista → atualiza → remove.
2. **Ordenação no SQLite**: A → Z, Z → A e maior nota (com desempate pelo título).
3. **Modelo**: `toMap`/`fromMap` simétricos.
4. **Nova SharedPreference**: padrão na 1ª execução, salvar e recarregar, valor inválido volta ao padrão.
5. **UI** (com repositório fake): estado vazio, lista com dados, busca, cadastro, validação da nota, edição, remoção com confirmação, menu de ordenação (reordena **e** grava a preferência) e abertura do app com a ordenação salva.

---

## 📦 Dependências principais

```yaml
dependencies:
  sqflite: ^2.3.3+1          # Banco relacional embarcado (SQLite)
  path: ^1.9.0               # Monta o caminho do arquivo do banco por SO
  shared_preferences: ^2.2.3 # Armazenamento chave-valor (tema + ordenação)

dev_dependencies:
  sqflite_common_ffi: ^2.4.0+3 # SQLite em memória para os testes
```

---

Projeto acadêmico — SENAI, Desenvolvimento Mobile · Tutoria 4 (Persistência).
