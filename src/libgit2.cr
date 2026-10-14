# libgit2.cr — raw Crystal bindings to libgit2.
#
# Exposes a single `lib LibGit2` (see `src/libgit2/lib.cr`) mapping the
# libgit2 C API one-to-one. Require this file and call the C functions
# directly; management of ownership, return codes and strings is the
# caller's job.
#
#   require "libgit2"
#
#   LibGit2.git_libgit2_init
#   repo = uninitialized LibGit2::Repository*
#   LibGit2.git_repository_open(pointerof(repo), "/path/to/repo")
#   head = uninitialized LibGit2::Reference*
#   LibGit2.git_repository_head(pointerof(head), repo)
#   puts String.new(LibGit2.git_reference_shorthand(head))
#   LibGit2.git_reference_free(head)
#   LibGit2.git_repository_free(repo)
#   LibGit2.git_libgit2_shutdown
require "./libgit2/lib"
