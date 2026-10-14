# libgit2.cr

Тонкие (уровень 1) биндинги Crystal к C-API [libgit2](https://libgit2.org).
Один файл `src/libgit2/lib.cr` — один `lib LibGit2`, отражающий `git2.h`:
структуры, константы и `fun`-декларации с точными C-именами. Никаких
обёрток, управления памятью или обработки ошибок — это задача слоя выше
(например, подсветка изменений и авторство строк в редакторе).

Проверено против libgit2 **1.9** (не-SHA256-экспериментальная сборка).

## Установка

```yaml
dependencies:
  libgit2:
    path: ../myshards/libgit2.cr
```

Нужна собственно libgit2:

```sh
sudo apt install libgit2-dev   # или иное: brew install libgit2, ...
```

Если dev-пакета нет, а есть только рантайм-библиотека (например
`libgit2.so.1.9`), можно собрать локальный симлинк и не трогать систему:

```sh
mkdir -p ext && ln -s /lib/x86_64-linux-gnu/libgit2.so.1.9 ext/libgit2.so
LIBRARY_PATH=$PWD/ext crystal spec
```

`ext/` в гите не хранится.

## Использование

```crystal
require "libgit2"

LibGit2.git_libgit2_init
begin
  repo = uninitialized LibGit2::Repository*
  LibGit2.git_repository_open(pointerof(repo), ".")

  # текущая ветка
  head = uninitialized LibGit2::Reference*
  LibGit2.git_repository_head(pointerof(head), repo)
  puts String.new(LibGit2.git_reference_shorthand(head)) # "master"
  LibGit2.git_reference_free(head)

  # blame: кто автор строки
  blame = uninitialized LibGit2::Blame*
  opts = uninitialized LibGit2::BlameOptions
  LibGit2.git_blame_options_init(pointerof(opts), LibGit2::BLAME_OPTIONS_VERSION)
  LibGit2.git_blame_file(pointerof(blame), repo, "src/app.cr", pointerof(opts))
  hunk = LibGit2.git_blame_hunk_byline(blame, 42).not_nil!.value
  sig = hunk.final_signature.value
  puts "#{String.new(sig.name)}: #{String.new(hunk.summary)}"
  LibGit2.git_blame_free(blame)

  LibGit2.git_repository_free(repo)
ensure
  LibGit2.git_libgit2_shutdown
end
```

## Покрытие API

Подмножество, нужное для редактора (kodkod): blame, diff, status,
repository, references/branches, commits, trees/blobs, revparse, oid,
ошибки. Это принципиальное решение: покрывать весь `git2.h` (~1500
функций) нет смысла, а маленькое подмножество легко сверять с
заголовками при обновлении. Дополнение — это просто ещё несколько
`fun`-строк, скопированных из `include/git2/*.h`.

## Подводные камни libgit2 (выяснены спеками)

- `git_*_options_init` заполняет **только** `version` — остальные поля
  нули. «Дефолтные» флаги (например, показ untracked-файлов в статусе)
  нужно выставлять самому: `opts.flags = LibGit2::GIT_STATUS_OPT_DEFAULTS`.
- В `git_diff_tree_to_workdir_with_index` `old_tree = NULL` означает
  **пустое дерево**, а не HEAD. HEAD-дерево надо резолвить явно:
  `HEAD` → `git_commit_tree_id` → `git_tree_lookup`.
- `git_oid_tostr_s` возвращает указатель на статический thread-local
  буфер: сразу оборачивайте в `String.new` и не храните указатель.
- Строки и структуры (`git_signature`, `git_blame_hunk.summary` …),
  возвращаемые из blame/commit, принадлежат родительскому объекту и
  освобождаются вместе с ним.

## Тесты

```sh
make test   # или: LIBRARY_PATH=$PWD/ext crystal spec
```

Спеки собирают временный git-репозиторий через CLI (`git` должен быть в
PATH) и прогоняют все описанные сценарии: blame построчно, статус,
diff HEAD↔workdir, дерево/блоб, ветки.
