# Pure Crystal bindings to the libgit2 C API (git2.h).
#
# Level 1 only: `lib LibGit2` mirrors git2.h — structs, constants and
# `fun` declarations with the exact C names. No wrappers, no memory
# management, no error handling. Higher layers are expected to build
# on top of this (see README).
#
# Generated/checked against libgit2 v1.9.0 headers. Struct layouts are
# ABI-compatible only with the non-experimental SHA1 build of libgit2.
@[Link("git2")]
lib LibGit2
  # ## Basics (git2/common.h, git2/global.h, git2/types.h)

  alias SizeT = LibC::SizeT
  alias OffT = Int64     # git_off_t
  alias TimeT = Int64    # git_time_t
  alias ObjSize = UInt64 # git_object_size_t

  # git_object_t
  GIT_OBJECT_ANY       = -2
  GIT_OBJECT_INVALID   = -1
  GIT_OBJECT_COMMIT    =  1
  GIT_OBJECT_TREE      =  2
  GIT_OBJECT_BLOB      =  3
  GIT_OBJECT_TAG       =  4
  GIT_OBJECT_OFS_DELTA =  6
  GIT_OBJECT_REF_DELTA =  7

  fun git_libgit2_init : Int32
  fun git_libgit2_shutdown : Int32
  fun git_libgit2_version(major : Int32*, minor : Int32*, rev : Int32*) : Int32
  fun git_libgit2_prerelease : UInt8*
  fun git_object_type2string(type : Int32) : UInt8*

  # ## Errors (git2/errors.h)

  GIT_OK              =   0
  GIT_ERROR           =  -1
  GIT_ENOTFOUND       =  -3
  GIT_EEXISTS         =  -4
  GIT_EAMBIGUOUS      =  -5
  GIT_EBUFS           =  -6
  GIT_EUSER           =  -7
  GIT_EBAREREPO       =  -8
  GIT_EUNBORNBRANCH   =  -9
  GIT_EUNMERGED       = -10
  GIT_ENONFASTFORWARD = -11
  GIT_EINVALIDSPEC    = -12
  GIT_ECONFLICT       = -13
  GIT_ELOCKED         = -14
  GIT_EMODIFIED       = -15
  GIT_EAUTH           = -16
  GIT_ECERTIFICATE    = -17
  GIT_EAPPLIED        = -18
  GIT_EPEEL           = -19
  GIT_EEOF            = -20
  GIT_EINVALID        = -21
  GIT_EUNCOMMITTED    = -22
  GIT_EDIRECTORY      = -23
  GIT_EMERGECONFLICT  = -24
  GIT_PASSTHROUGH     = -30
  GIT_ITEROVER        = -31
  GIT_RETRY           = -32
  GIT_EMISMATCH       = -33
  GIT_EINDEXDIRTY     = -34
  GIT_EAPPLYFAIL      = -35
  GIT_EOWNER          = -36
  GIT_TIMEOUT         = -37
  GIT_EUNCHANGED      = -38
  GIT_ENOTSUPPORTED   = -39
  GIT_EREADONLY       = -40

  struct Error
    message : UInt8*
    klass : Int32 # git_error_t
  end

  fun git_error_last : Error*

  # ## Object ids (git2/oid.h)

  OID_RAWSIZE      = 20 # GIT_OID_SHA1_SIZE
  OID_HEXSIZE      = 40 # GIT_OID_SHA1_HEXSIZE
  OID_MINPREFIXLEN =  4

  struct Oid
    id : UInt8[OID_RAWSIZE]
  end

  fun git_oid_fromstr(out : Oid*, str : UInt8*) : Int32
  fun git_oid_tostr(out : UInt8*, n : SizeT, id : Oid*) : UInt8*
  # NOTE: returns a pointer to a static thread-local buffer
  fun git_oid_tostr_s(id : Oid*) : UInt8*
  fun git_oid_cmp(a : Oid*, b : Oid*) : Int32
  fun git_oid_equal(a : Oid*, b : Oid*) : Int32

  # ## Shared small types (git2/strarray.h, git2/buffer.h, git2/types.h)

  struct StrArray
    strings : UInt8**
    count : SizeT
  end

  fun git_strarray_dispose(array : StrArray*) : Void

  struct Buf
    ptr : UInt8*
    reserved : SizeT
    size : SizeT
  end

  fun git_buf_dispose(buffer : Buf*) : Void

  struct Time      # git_time
    time : TimeT   # seconds from epoch
    offset : Int32 # timezone offset in minutes
    sign : Int8
  end

  struct Signature # git_signature
    name : UInt8*
    email : UInt8*
    when : Time
  end

  fun git_signature_free(sig : Signature*) : Void

  # ## Repository (git2/repository.h)

  # git_repository_open_flag_t
  GIT_REPOSITORY_OPEN_NO_SEARCH = (1 << 0)
  GIT_REPOSITORY_OPEN_CROSS_FS  = (1 << 1)
  GIT_REPOSITORY_OPEN_BARE      = (1 << 2)
  GIT_REPOSITORY_OPEN_NO_DOTGIT = (1 << 3)
  GIT_REPOSITORY_OPEN_FROM_ENV  = (1 << 4)

  type Repository = Void

  fun git_repository_open(out : Repository**, path : UInt8*) : Int32
  fun git_repository_open_ext(out : Repository**, path : UInt8*, flags : UInt32, ceiling_dirs : UInt8*) : Int32
  fun git_repository_free(repo : Repository*) : Void
  fun git_repository_head(out : Reference**, repo : Repository*) : Int32
  fun git_repository_head_detached(repo : Repository*) : Int32
  fun git_repository_head_unborn(repo : Repository*) : Int32
  fun git_repository_workdir(repo : Repository*) : UInt8*
  fun git_repository_is_bare(repo : Repository*) : Int32

  # ## Objects (git2/object.h, git2/revparse.h)

  type Object = Void

  fun git_object_lookup(out : Object**, repo : Repository*, id : Oid*, type : Int32) : Int32
  fun git_object_id(obj : Object*) : Oid*
  fun git_object_type(obj : Object*) : Int32
  fun git_object_owner(obj : Object*) : Repository*
  fun git_object_free(object : Object*) : Void
  fun git_revparse_single(out : Object**, repo : Repository*, spec : UInt8*) : Int32

  # ## Commits (git2/commit.h)

  type Commit = Void

  fun git_commit_lookup(out : Commit**, repo : Repository*, id : Oid*) : Int32
  fun git_commit_free(commit : Commit*) : Void
  fun git_commit_id(commit : Commit*) : Oid*
  fun git_commit_message(commit : Commit*) : UInt8*
  fun git_commit_message_raw(commit : Commit*) : UInt8*
  fun git_commit_summary(commit : Commit*) : UInt8*
  fun git_commit_time(commit : Commit*) : TimeT
  fun git_commit_time_offset(commit : Commit*) : Int32
  fun git_commit_committer(commit : Commit*) : Signature*
  fun git_commit_author(commit : Commit*) : Signature*
  fun git_commit_tree_id(commit : Commit*) : Oid*
  fun git_commit_parentcount(commit : Commit*) : UInt32
  fun git_commit_parent_id(commit : Commit*, n : UInt32) : Oid*

  # ## References and branches (git2/refs.h, git2/branch.h)

  # git_reference_t
  GIT_REFERENCE_INVALID  = 0
  GIT_REFERENCE_DIRECT   = 1
  GIT_REFERENCE_SYMBOLIC = 2
  GIT_REFERENCE_ALL      = 3

  # git_branch_t
  GIT_BRANCH_LOCAL  = 1
  GIT_BRANCH_REMOTE = 2
  GIT_BRANCH_ALL    = 3

  type Reference = Void
  type ReferenceIterator = Void
  type BranchIterator = Void

  fun git_reference_lookup(out : Reference**, repo : Repository*, name : UInt8*) : Int32
  fun git_reference_free(ref : Reference*) : Void
  fun git_reference_name(ref : Reference*) : UInt8*
  fun git_reference_shorthand(ref : Reference*) : UInt8*
  fun git_reference_symbolic_target(ref : Reference*) : UInt8*
  fun git_reference_target(ref : Reference*) : Oid*
  fun git_reference_type(ref : Reference*) : Int32
  fun git_reference_resolve(out : Reference**, ref : Reference*) : Int32
  fun git_reference_is_branch(ref : Reference*) : Int32
  fun git_reference_is_remote(ref : Reference*) : Int32
  fun git_reference_is_tag(ref : Reference*) : Int32

  fun git_branch_iterator_new(out : BranchIterator**, repo : Repository*, list_flags : Int32) : Int32
  fun git_branch_next(out : Reference**, out_type : Int32*, iter : BranchIterator*) : Int32
  fun git_branch_iterator_free(iter : BranchIterator*) : Void
  fun git_branch_name(out : UInt8**, ref : Reference*) : Int32
  fun git_branch_lookup(out : Reference**, repo : Repository*, branch_name : UInt8*, branch_type : Int32) : Int32
  fun git_branch_upstream_name(out : Buf*, repo : Repository*, refname : UInt8*) : Int32

  # ## Trees and blobs (git2/tree.h, git2/blob.h)

  type Tree = Void
  type TreeEntry = Void
  type Blob = Void

  fun git_tree_lookup(out : Tree**, repo : Repository*, id : Oid*) : Int32
  fun git_tree_free(tree : Tree*) : Void
  fun git_tree_entrycount(tree : Tree*) : SizeT
  fun git_tree_entry_byname(tree : Tree*, filename : UInt8*) : TreeEntry*
  fun git_tree_entry_byindex(tree : Tree*, idx : SizeT) : TreeEntry*
  fun git_tree_entry_name(entry : TreeEntry*) : UInt8*
  fun git_tree_entry_type(entry : TreeEntry*) : Int32
  fun git_tree_entry_filemode(entry : TreeEntry*) : UInt16
  fun git_tree_entry_to_object(out : Object**, repo : Repository*, entry : TreeEntry*) : Int32

  fun git_blob_lookup(out : Blob**, repo : Repository*, id : Oid*) : Int32
  fun git_blob_free(blob : Blob*) : Void
  fun git_blob_rawcontent(blob : Blob*) : Void*
  fun git_blob_rawsize(blob : Blob*) : ObjSize

  # ## Blame (git2/blame.h)

  GIT_BLAME_NORMAL                          = 0
  GIT_BLAME_TRACK_COPIES_SAME_FILE          = (1 << 0) # not implemented upstream
  GIT_BLAME_TRACK_COPIES_SAME_COMMIT_MOVES  = (1 << 1) # not implemented upstream
  GIT_BLAME_TRACK_COPIES_SAME_COMMIT_COPIES = (1 << 2) # not implemented upstream
  GIT_BLAME_TRACK_COPIES_ANY_COMMIT_COPIES  = (1 << 3) # not implemented upstream
  GIT_BLAME_FIRST_PARENT                    = (1 << 4)
  GIT_BLAME_USE_MAILMAP                     = (1 << 5)
  GIT_BLAME_IGNORE_WHITESPACE               = (1 << 6)

  BLAME_OPTIONS_VERSION = 1 # GIT_BLAME_OPTIONS_VERSION

  struct BlameOptions
    version : UInt32
    flags : UInt32 # git_blame_flag_t
    min_match_characters : UInt16
    newest_commit : Oid # default HEAD
    oldest_commit : Oid
    min_line : SizeT # 1-based, default 1
    max_line : SizeT # default last line
  end

  struct BlameHunk
    lines_in_hunk : SizeT
    final_commit_id : Oid
    final_start_line_number : SizeT # 1-based in final version
    final_signature : Signature*
    final_committer : Signature*
    orig_commit_id : Oid
    orig_path : UInt8*
    orig_start_line_number : SizeT
    orig_signature : Signature*
    orig_committer : Signature*
    summary : UInt8*
    boundary : Int8
  end

  type Blame = Void

  fun git_blame_options_init(opts : BlameOptions*, version : UInt32) : Int32
  fun git_blame_file(out : Blame**, repo : Repository*, path : UInt8*, options : BlameOptions*) : Int32
  fun git_blame_buffer(out : Blame**, base : Blame*, buffer : UInt8*, buffer_len : SizeT) : Int32
  fun git_blame_free(blame : Blame*) : Void
  fun git_blame_hunkcount(blame : Blame*) : SizeT
  fun git_blame_hunk_byindex(blame : Blame*, index : SizeT) : BlameHunk*
  fun git_blame_hunk_byline(blame : Blame*, lineno : SizeT) : BlameHunk*

  # ## Diff (git2/diff.h)

  # git_diff_option_t (subset in active use; see git2/diff.h for the rest)
  GIT_DIFF_NORMAL                          = 0
  GIT_DIFF_REVERSE                         = (1 << 0)
  GIT_DIFF_INCLUDE_IGNORED                 = (1 << 1)
  GIT_DIFF_RECURSE_IGNORED_DIRS            = (1 << 2)
  GIT_DIFF_INCLUDE_UNTRACKED               = (1 << 3)
  GIT_DIFF_RECURSE_UNTRACKED_DIRS          = (1 << 4)
  GIT_DIFF_INCLUDE_UNMODIFIED              = (1 << 5)
  GIT_DIFF_INCLUDE_TYPECHANGE              = (1 << 6)
  GIT_DIFF_INCLUDE_TYPECHANGE_TREES        = (1 << 7)
  GIT_DIFF_IGNORE_FILEMODE                 = (1 << 8)
  GIT_DIFF_IGNORE_SUBMODULES               = (1 << 9)
  GIT_DIFF_IGNORE_CASE                     = (1 << 10)
  GIT_DIFF_INCLUDE_CASECHANGE              = (1 << 11)
  GIT_DIFF_DISABLE_PATHSPEC_MATCH          = (1 << 12)
  GIT_DIFF_SKIP_BINARY_CHECK               = (1 << 13)
  GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS      = (1 << 14)
  GIT_DIFF_UPDATE_INDEX                    = (1 << 15)
  GIT_DIFF_INCLUDE_UNREADABLE              = (1 << 16)
  GIT_DIFF_INCLUDE_UNREADABLE_AS_UNTRACKED = (1 << 17)
  GIT_DIFF_INDENT_HEURISTIC                = (1 << 18)
  GIT_DIFF_IGNORE_BLANK_LINES              = (1 << 19)
  GIT_DIFF_FORCE_TEXT                      = (1 << 20)
  GIT_DIFF_FORCE_BINARY                    = (1 << 21)
  GIT_DIFF_IGNORE_WHITESPACE               = (1 << 22)
  GIT_DIFF_IGNORE_WHITESPACE_CHANGE        = (1 << 23)
  GIT_DIFF_IGNORE_WHITESPACE_EOL           = (1 << 24)
  GIT_DIFF_SHOW_UNTRACKED_CONTENT          = (1 << 25)
  GIT_DIFF_SHOW_UNMODIFIED                 = (1 << 26)
  GIT_DIFF_PATIENCE                        = (1 << 28)
  GIT_DIFF_MINIMAL                         = (1 << 29)
  GIT_DIFF_SHOW_BINARY                     = (1 << 30)

  # git_diff_flag_t
  GIT_DIFF_FLAG_BINARY     = (1 << 0)
  GIT_DIFF_FLAG_NOT_BINARY = (1 << 1)
  GIT_DIFF_FLAG_VALID_ID   = (1 << 2)
  GIT_DIFF_FLAG_EXISTS     = (1 << 3)
  GIT_DIFF_FLAG_VALID_SIZE = (1 << 4)

  # git_delta_t
  GIT_DELTA_UNMODIFIED =  0
  GIT_DELTA_ADDED      =  1
  GIT_DELTA_DELETED    =  2
  GIT_DELTA_MODIFIED   =  3
  GIT_DELTA_RENAMED    =  4
  GIT_DELTA_COPIED     =  5
  GIT_DELTA_IGNORED    =  6
  GIT_DELTA_UNTRACKED  =  7
  GIT_DELTA_TYPECHANGE =  8
  GIT_DELTA_UNREADABLE =  9
  GIT_DELTA_CONFLICTED = 10

  DIFF_OPTIONS_VERSION = 1 # GIT_DIFF_OPTIONS_VERSION

  type Diff = Void
  type DiffStats = Void

  struct DiffFile
    id : Oid
    path : UInt8*
    size : ObjSize
    flags : UInt32 # git_diff_flag_t
    mode : UInt16
    id_abbrev : UInt16
  end

  struct DiffDelta
    status : Int32      # git_delta_t
    flags : UInt32      # git_diff_flag_t
    similarity : UInt16 # 0-100, for RENAMED/COPIED
    nfiles : UInt16
    old_file : DiffFile
    new_file : DiffFile
  end

  type DiffNotifyCallback = (Diff*, DiffDelta*, UInt8*, Void*) -> Int32
  type DiffProgressCallback = (Diff*, UInt8*, UInt8*, Void*) -> Int32

  struct DiffOptions
    version : UInt32
    flags : UInt32            # git_diff_option_t
    ignore_submodules : Int32 # git_submodule_ignore_t; -1 = UNSPECIFIED
    pathspec : StrArray
    notify_cb : DiffNotifyCallback
    progress_cb : DiffProgressCallback
    payload : Void*
    context_lines : UInt32
    interhunk_lines : UInt32
    oid_type : Int32 # git_oid_t
    id_abbrev : UInt16
    max_size : OffT
    old_prefix : UInt8*
    new_prefix : UInt8*
  end

  fun git_diff_options_init(opts : DiffOptions*, version : UInt32) : Int32
  fun git_diff_free(diff : Diff*) : Void
  fun git_diff_tree_to_tree(out : Diff**, repo : Repository*, old_tree : Tree*, new_tree : Tree*, opts : DiffOptions*) : Int32
  fun git_diff_tree_to_index(out : Diff**, repo : Repository*, old_tree : Tree*, index : Void*, opts : DiffOptions*) : Int32
  fun git_diff_index_to_workdir(out : Diff**, repo : Repository*, index : Void*, opts : DiffOptions*) : Int32
  fun git_diff_tree_to_workdir(out : Diff**, repo : Repository*, old_tree : Tree*, opts : DiffOptions*) : Int32
  fun git_diff_tree_to_workdir_with_index(out : Diff**, repo : Repository*, old_tree : Tree*, opts : DiffOptions*) : Int32
  fun git_diff_num_deltas(diff : Diff*) : SizeT
  fun git_diff_num_deltas_of_type(diff : Diff*, type : Int32) : SizeT
  fun git_diff_get_delta(diff : Diff*, idx : SizeT) : DiffDelta*
  fun git_diff_status_char(status : Int32) : Int8
  fun git_diff_is_sorted_icase(diff : Diff*) : Int32
  fun git_diff_get_stats(out : DiffStats**, diff : Diff*) : Int32
  fun git_diff_stats_files_changed(stats : DiffStats*) : SizeT
  fun git_diff_stats_insertions(stats : DiffStats*) : SizeT
  fun git_diff_stats_deletions(stats : DiffStats*) : SizeT
  fun git_diff_stats_free(stats : DiffStats*) : Void

  # ## Status (git2/status.h)

  # git_status_t
  GIT_STATUS_CURRENT          = 0
  GIT_STATUS_INDEX_NEW        = (1 << 0)
  GIT_STATUS_INDEX_MODIFIED   = (1 << 1)
  GIT_STATUS_INDEX_DELETED    = (1 << 2)
  GIT_STATUS_INDEX_RENAMED    = (1 << 3)
  GIT_STATUS_INDEX_TYPECHANGE = (1 << 4)
  GIT_STATUS_WT_NEW           = (1 << 7)
  GIT_STATUS_WT_MODIFIED      = (1 << 8)
  GIT_STATUS_WT_DELETED       = (1 << 9)
  GIT_STATUS_WT_TYPECHANGE    = (1 << 10)
  GIT_STATUS_WT_RENAMED       = (1 << 11)
  GIT_STATUS_WT_UNREADABLE    = (1 << 12)
  GIT_STATUS_IGNORED          = (1 << 14)
  GIT_STATUS_CONFLICTED       = (1 << 15)

  # git_status_show_t
  GIT_STATUS_SHOW_INDEX_AND_WORKDIR = 0
  GIT_STATUS_SHOW_INDEX_ONLY        = 1
  GIT_STATUS_SHOW_WORKDIR_ONLY      = 2

  # git_status_opt_t
  GIT_STATUS_OPT_INCLUDE_UNTRACKED               = (1 << 0)
  GIT_STATUS_OPT_INCLUDE_IGNORED                 = (1 << 1)
  GIT_STATUS_OPT_INCLUDE_UNMODIFIED              = (1 << 2)
  GIT_STATUS_OPT_EXCLUDE_SUBMODULES              = (1 << 3)
  GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS          = (1 << 4)
  GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH          = (1 << 5)
  GIT_STATUS_OPT_RECURSE_IGNORED_DIRS            = (1 << 6)
  GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX           = (1 << 7)
  GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR        = (1 << 8)
  GIT_STATUS_OPT_SORT_CASE_SENSITIVELY           = (1 << 9)
  GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY         = (1 << 10)
  GIT_STATUS_OPT_RENAMES_FROM_REWRITES           = (1 << 11)
  GIT_STATUS_OPT_NO_REFRESH                      = (1 << 12)
  GIT_STATUS_OPT_UPDATE_INDEX                    = (1 << 13)
  GIT_STATUS_OPT_INCLUDE_UNREADABLE              = (1 << 14)
  GIT_STATUS_OPT_INCLUDE_UNREADABLE_AS_UNTRACKED = (1 << 15)
  GIT_STATUS_OPT_DEFAULTS                        = 0x17 # INCLUDE_IGNORED | INCLUDE_UNTRACKED | RECURSE_UNTRACKED_DIRS

  STATUS_OPTIONS_VERSION = 1 # GIT_STATUS_OPTIONS_VERSION

  struct StatusOptions
    version : UInt32
    show : Int32   # git_status_show_t
    flags : UInt32 # git_status_opt_t
    pathspec : StrArray
    baseline : Tree* # defaults to HEAD
    rename_threshold : UInt16
  end

  struct StatusEntry
    status : Int32 # git_status_t
    head_to_index : DiffDelta*
    index_to_workdir : DiffDelta*
  end

  type StatusList = Void

  fun git_status_options_init(opts : StatusOptions*, version : UInt32) : Int32
  fun git_status_list_new(out : StatusList**, repo : Repository*, opts : StatusOptions*) : Int32
  fun git_status_list_entrycount(statuslist : StatusList*) : SizeT
  fun git_status_byindex(statuslist : StatusList*, idx : SizeT) : StatusEntry*
  fun git_status_list_free(statuslist : StatusList*) : Void
  fun git_status_file(status_flags : UInt32*, repo : Repository*, path : UInt8*) : Int32
end
