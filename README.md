# libgit2.cr

[![CI](https://github.com/OrelSokolov/libgit2.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/OrelSokolov/libgit2.cr/actions/workflows/ci.yml)

Raw Crystal bindings to the [libgit2](https://libgit2.org) C API.

`LibGit2` is a single `lib` that mirrors `git2.h` one-to-one: structs,
constants and `fun` declarations keep their exact C names, so any
libgit2 documentation or example translates directly. There are no
wrappers, no automatic memory management and no error handling — this
is deliberately the thinnest maintainable layer, intended as a base for
higher-level code (editors, tooling, git UIs).

Checked against **libgit2 1.9** (standard SHA-1 build). Every bound
symbol is verified against the exported symbols of the actual shared
library, and the specs exercise all of it against real repositories.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     libgit2:
       github: OrelSokolov/libgit2.cr
   ```

2. Install libgit2 itself, e.g. `sudo apt install libgit2-dev`,
   `brew install libgit2`, etc.

3. `require "libgit2"`

### No dev package installed?

If only the runtime library is present (e.g. `libgit2.so.1.9` without
the `-dev` package), link against a local symlink instead:

```sh
mkdir -p ext
ln -s /lib/x86_64-linux-gnu/libgit2.so.1.9 ext/libgit2.so
LIBRARY_PATH=$PWD/ext crystal spec
```

## Usage

```crystal
require "libgit2"

LibGit2.git_libgit2_init
begin
  repo = uninitialized LibGit2::Repository*
  LibGit2.git_repository_open(pointerof(repo), ".")

  # Current branch
  head = uninitialized LibGit2::Reference*
  LibGit2.git_repository_head(pointerof(head), repo)
  puts String.new(LibGit2.git_reference_shorthand(head)) # => "main"
  LibGit2.git_reference_free(head)

  # Blame: who wrote this line?
  blame = uninitialized LibGit2::Blame*
  opts = uninitialized LibGit2::BlameOptions
  LibGit2.git_blame_options_init(pointerof(opts), LibGit2::BLAME_OPTIONS_VERSION)
  LibGit2.git_blame_file(pointerof(blame), repo, "src/app.cr", pointerof(opts))
  hunk = LibGit2.git_blame_hunk_byline(blame, 42).not_nil!.value
  sig = hunk.final_signature.value
  puts "#{String.new(sig.name)} — #{String.new(hunk.summary)}"
  LibGit2.git_blame_free(blame)
ensure
  LibGit2.git_repository_free(repo)
  LibGit2.git_libgit2_shutdown
end
```

Line-level diff — the basis for highlighting modified lines in an editor:

```crystal
patch = uninitialized LibGit2::Patch*
LibGit2.git_patch_from_buffers(
  pointerof(patch),
  old_text, old_text.bytesize, "file.cr",
  new_text, new_text.bytesize, "file.cr", nil)

added = [] of Int32
0.times do |hunk_idx|
  break if hunk_idx >= LibGit2.git_patch_num_hunks(patch)
  LibGit2.git_patch_num_lines_in_hunk(patch, hunk_idx).times do |i|
    line = uninitialized LibGit2::DiffLine*
    LibGit2.git_patch_get_line_in_hunk(pointerof(line), patch, hunk_idx, i)
    l = line.value
    added << l.new_lineno if l.origin == LibGit2::GIT_DIFF_LINE_ADDITION.to_i8!
  end
end
LibGit2.git_patch_free(patch)
```

## API coverage

Bound so far, grouped by the `git2/*.h` header each section follows:

| Header | Bound |
|---|---|
| `global.h`, `common.h`, `errors.h` | init/shutdown, version, `git_error_last`, all error codes |
| `oid.h` | hex↔raw conversion, compare, `is_zero` |
| `strarray.h`, `buffer.h` | `git_strarray`, `git_buf` + dispose |
| `signature.h` | `git_signature` struct, dup, free |
| `config.h` | open/snapshot/free, get_string/int32/bool |
| `index.h` | entrycount, get_byindex, get_bypath, `git_index_entry` |
| `repository.h` | open/open_ext, head, workdir/path/state, config, index |
| `object.h`, `revparse.h` | lookup, id, type, owner, peel, `git_revparse_single` |
| `revwalk.h` | push/hide/next/sorting — full history walk |
| `commit.h` | lookup, author/committer, message, time, tree, parents |
| `refs.h`, `branch.h` | lookup, name/shorthand/target, resolve, iterators, create/rename/delete; branch lookup/name/upstream/is_head |
| `tag.h` | annotated tags: name, message, tagger, target, list |
| `tree.h`, `blob.h` | tree walk by name/index, blob raw and filtered content |
| `remote.h` | lookup, list, name/url (read-only, no network ops) |
| `blame.h` | file blame, hunks by line/index, buffer re-blame |
| `diff.h` | all diff generators, deltas, stats, find_similar (renames) |
| `patch.h` | from diff/blobs/buffers, hunks, lines, line_stats, to_buf |
| `status.h` | status list, single-file status, all flags |

Not bound (yet): network operations (fetch/push/clone), worktree
mutations (checkout/merge/rebase/stash), ODB internals, mailmap,
submodules, packfiles. Adding a missing function is a one-line `fun`
copied from the header — contributions welcome.

## libgit2 gotchas (found the hard way, covered by specs)

- `git_*_options_init` fills **only** `version`; every other field is
  zero. Opt into what you need, e.g.
  `opts.flags = LibGit2::GIT_STATUS_OPT_DEFAULTS` to see untracked files.
- In `git_diff_tree_to_workdir_with_index`, `old_tree = NULL` means the
  **empty tree**, not HEAD. Resolve HEAD explicitly:
  `HEAD` → `git_commit_tree_id` → `git_tree_lookup`.
- `git_config_get_string` rejects a live config: call
  `git_config_snapshot` first.
- `git_oid_tostr_s` returns a pointer into a static thread-local
  buffer — wrap it in `String.new` immediately.
- `git_buf` must be zero-initialized (`LibGit2::Buf.new`) before use.
- Strings and structs returned by blame/commit/tag belong to their
  parent object and die with it.

## Development

```sh
make test   # LIBRARY_PATH=$PWD/ext crystal spec
```

The specs build a throwaway git repository with the `git` CLI (no
fixtures committed) and run every bound feature against it: blame,
status, diff, patches and line parsing, rename detection, revwalk,
tags, remotes, config, index, references.

## License

MIT — see [LICENSE](LICENSE). libgit2 itself is GPLv2 with a linking
exception; using it from a closed-source Crystal application is
permitted by that exception.
