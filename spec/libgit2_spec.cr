require "spec"
require "file_utils"
require "../src/libgit2"

# Builds a small fixture repo with the git CLI:
#
#   master: a.txt = "one\ntwo\n"        (commit 1)
#           a.txt = "one\ntwo\nthree\n" (commit 2)
#   workdir: a.txt modified, b.txt untracked
private def make_fixture_repo(dir)
  env = {
    "GIT_AUTHOR_NAME"     => "Alice Author",
    "GIT_AUTHOR_EMAIL"    => "alice@example.com",
    "GIT_COMMITTER_NAME"  => "Carol Committer",
    "GIT_COMMITTER_EMAIL" => "carol@example.com",
    "GIT_AUTHOR_DATE"     => "2005-04-07T22:13:13 +0000",
    "GIT_COMMITTER_DATE"  => "2005-04-07T22:13:13 +0000",
  }
  run = ->(args : Array(String)) {
    status = Process.run("git", args, chdir: dir, env: env, output: Process::Redirect::Close, error: Process::Redirect::Close)
    raise "git #{args.first} failed" unless status.success?
  }
  run.call(["init", "--initial-branch=master"])
  File.write(File.join(dir, "a.txt"), "one\ntwo\n")
  run.call(["add", "a.txt"])
  run.call(["commit", "-m", "first commit"])
  File.write(File.join(dir, "a.txt"), "one\ntwo\nthree\n")
  run.call(["add", "a.txt"])
  run.call(["commit", "-m", "second commit"])
  File.write(File.join(dir, "a.txt"), "one changed\ntwo\nthree\n")
  File.write(File.join(dir, "b.txt"), "brand new\n")
end

describe "libgit2 bindings" do
  before_all { LibGit2.git_libgit2_init }

  fixture = File.join(Dir.tempdir, "libgit2_cr_spec_#{Random.rand(1u64..1e12.to_u64)}")
  Dir.mkdir(fixture)
  make_fixture_repo(fixture)

  after_all do
    LibGit2.git_libgit2_shutdown
    FileUtils.rm_rf(fixture) rescue nil
  end

  it "reports the linked libgit2 version" do
    major = uninitialized Int32
    minor = uninitialized Int32
    rev = uninitialized Int32
    LibGit2.git_libgit2_version(pointerof(major), pointerof(minor), pointerof(rev)).should eq(LibGit2::GIT_OK)
    {major, minor}.should eq({1, 9})
  end

  it "converts oids between hex and raw" do
    hex = "0123456789abcdef0123456789abcdef01234567"
    oid = uninitialized LibGit2::Oid
    LibGit2.git_oid_fromstr(pointerof(oid), hex).should eq(LibGit2::GIT_OK)
    String.new(LibGit2.git_oid_tostr_s(pointerof(oid))).should eq(hex)
    String.new(LibGit2.git_oid_tostr_s(pointerof(oid))).size.should eq(LibGit2::OID_HEXSIZE)
  end

  repo = uninitialized LibGit2::Repository*
  it "opens the repository" do
    LibGit2.git_repository_open(pointerof(repo), fixture).should eq(LibGit2::GIT_OK)
    String.new(LibGit2.git_repository_workdir(repo)).should eq("#{fixture}/")
    LibGit2.git_repository_is_bare(repo).should eq(0)
    LibGit2.git_repository_head_unborn(repo).should eq(0)
  end

  it "reports HEAD as the master branch" do
    head = uninitialized LibGit2::Reference*
    LibGit2.git_repository_head(pointerof(head), repo).should eq(LibGit2::GIT_OK)
    LibGit2.git_reference_is_branch(head).should eq(1)
    String.new(LibGit2.git_reference_name(head)).should eq("refs/heads/master")
    String.new(LibGit2.git_reference_shorthand(head)).should eq("master")
    # HEAD resolved to a direct ref, so there is no symbolic target
    LibGit2.git_reference_symbolic_target(head).null?.should be_true
    LibGit2.git_reference_target(head).should_not be_nil
    LibGit2.git_reference_free(head)
  end

  it "looks branches up by name" do
    branch = uninitialized LibGit2::Reference*
    LibGit2.git_branch_lookup(pointerof(branch), repo, "master", LibGit2::GIT_BRANCH_LOCAL).should eq(LibGit2::GIT_OK)
    name = uninitialized UInt8*
    LibGit2.git_branch_name(pointerof(name), branch).should eq(LibGit2::GIT_OK)
    String.new(name).should eq("master")
    LibGit2.git_reference_free(branch)
    LibGit2.git_branch_lookup(pointerof(branch), repo, "nope", LibGit2::GIT_BRANCH_LOCAL)
      .should eq(LibGit2::GIT_ENOTFOUND)
    err = LibGit2.git_error_last.value
    String.new(err.message).should_not be_empty
  end

  it "iterates local branches" do
    iter = uninitialized LibGit2::BranchIterator*
    LibGit2.git_branch_iterator_new(pointerof(iter), repo, LibGit2::GIT_BRANCH_LOCAL).should eq(LibGit2::GIT_OK)
    names = [] of String
    loop do
      ref = uninitialized LibGit2::Reference*
      branch_type = uninitialized Int32
      code = LibGit2.git_branch_next(pointerof(ref), pointerof(branch_type), iter)
      break if code == LibGit2::GIT_ITEROVER
      code.should eq(LibGit2::GIT_OK)
      LibGit2.git_reference_free(ref)
      names << "x"
    end
    LibGit2.git_branch_iterator_free(iter)
    names.size.should eq(1)
  end

  it "parses revisions and reads the commit" do
    obj = uninitialized LibGit2::Object*
    LibGit2.git_revparse_single(pointerof(obj), repo, "HEAD").should eq(LibGit2::GIT_OK)
    LibGit2.git_object_type(obj).should eq(LibGit2::GIT_OBJECT_COMMIT)
    commit = obj.as(LibGit2::Commit*)

    LibGit2.git_commit_parentcount(commit).should eq(1)
    String.new(LibGit2.git_commit_summary(commit)).should eq("second commit")
    String.new(LibGit2.git_commit_message(commit)).should contain("second commit")
    LibGit2.git_commit_time(commit).should eq(1112911993) # 2005-04-07T22:13:13Z

    author = LibGit2.git_commit_author(commit).value
    String.new(author.name).should eq("Alice Author")
    String.new(author.email).should eq("alice@example.com")
    committer = LibGit2.git_commit_committer(commit).value
    String.new(committer.name).should eq("Carol Committer")

    parent = LibGit2.git_commit_parent_id(commit, 0).not_nil!
    parent_obj = uninitialized LibGit2::Object*
    LibGit2.git_object_lookup(pointerof(parent_obj), repo, parent, LibGit2::GIT_OBJECT_COMMIT).should eq(LibGit2::GIT_OK)
    LibGit2.git_commit_parentcount(parent_obj.as(LibGit2::Commit*)).should eq(0)
    LibGit2.git_object_free(parent_obj)

    LibGit2.git_object_free(obj)
  end

  it "reads file content at HEAD via tree and blob" do
    obj = uninitialized LibGit2::Object*
    LibGit2.git_revparse_single(pointerof(obj), repo, "HEAD^{tree}").should eq(LibGit2::GIT_OK)
    tree = obj.as(LibGit2::Tree*)
    LibGit2.git_tree_entrycount(tree).should eq(1)

    entry = LibGit2.git_tree_entry_byname(tree, "a.txt").should_not be_nil
    String.new(LibGit2.git_tree_entry_name(entry)).should eq("a.txt")
    LibGit2.git_tree_entry_type(entry).should eq(LibGit2::GIT_OBJECT_BLOB)

    blob_obj = uninitialized LibGit2::Object*
    LibGit2.git_tree_entry_to_object(pointerof(blob_obj), repo, entry).should eq(LibGit2::GIT_OK)
    blob = blob_obj.as(LibGit2::Blob*)
    size = LibGit2.git_blob_rawsize(blob)
    content = Slice.new(LibGit2.git_blob_rawcontent(blob).as(UInt8*), size)
    String.new(content).should eq("one\ntwo\nthree\n")
    LibGit2.git_object_free(blob_obj)
    LibGit2.git_tree_free(tree)
  end

  it "lists workdir status flags" do
    opts = uninitialized LibGit2::StatusOptions
    LibGit2.git_status_options_init(pointerof(opts), LibGit2::STATUS_OPTIONS_VERSION).should eq(LibGit2::GIT_OK)
    # *_options_init only sets `version`; untracked files must be opted into
    opts.flags = LibGit2::GIT_STATUS_OPT_DEFAULTS

    list = uninitialized LibGit2::StatusList*
    LibGit2.git_status_list_new(pointerof(list), repo, pointerof(opts)).should eq(LibGit2::GIT_OK)
    count = LibGit2.git_status_list_entrycount(list)
    count.should eq(2) # a.txt modified + b.txt untracked

    flags = {} of String => UInt32
    count.times do |i|
      entry = LibGit2.git_status_byindex(list, i).not_nil!.value
      delta = entry.index_to_workdir.not_nil!.value
      flags[String.new(delta.new_file.path)] = entry.status.to_u32!
    end
    LibGit2.git_status_list_free(list)

    flags["a.txt"].should eq(LibGit2::GIT_STATUS_WT_MODIFIED)
    flags["b.txt"].should eq(LibGit2::GIT_STATUS_WT_NEW)
  end

  it "reports single-file status" do
    flags = uninitialized UInt32
    LibGit2.git_status_file(pointerof(flags), repo, "a.txt").should eq(LibGit2::GIT_OK)
    flags.should eq(LibGit2::GIT_STATUS_WT_MODIFIED)
    LibGit2.git_status_file(pointerof(flags), repo, "missing.txt").should eq(LibGit2::GIT_ENOTFOUND)
  end

  it "diffs HEAD against the workdir" do
    opts = uninitialized LibGit2::DiffOptions
    LibGit2.git_diff_options_init(pointerof(opts), LibGit2::DIFF_OPTIONS_VERSION).should eq(LibGit2::GIT_OK)
    opts.flags = LibGit2::GIT_DIFF_INCLUDE_UNTRACKED

    # resolve the HEAD tree: old_tree = NULL means "empty tree", not HEAD
    head_obj = uninitialized LibGit2::Object*
    LibGit2.git_revparse_single(pointerof(head_obj), repo, "HEAD").should eq(LibGit2::GIT_OK)
    head_tree = uninitialized LibGit2::Tree*
    LibGit2.git_tree_lookup(pointerof(head_tree), repo, LibGit2.git_commit_tree_id(head_obj.as(LibGit2::Commit*)))
      .should eq(LibGit2::GIT_OK)
    LibGit2.git_object_free(head_obj)

    diff = uninitialized LibGit2::Diff*
    LibGit2.git_diff_tree_to_workdir_with_index(pointerof(diff), repo, head_tree, pointerof(opts))
      .should eq(LibGit2::GIT_OK)
    LibGit2.git_diff_num_deltas(diff).should eq(2)

    statuses = {} of String => Int32
    LibGit2.git_diff_num_deltas(diff).times do |i|
      delta = LibGit2.git_diff_get_delta(diff, i).not_nil!.value
      statuses[String.new(delta.new_file.path)] = delta.status
    end
    statuses["a.txt"].should eq(LibGit2::GIT_DELTA_MODIFIED)
    statuses["b.txt"].should eq(LibGit2::GIT_DELTA_UNTRACKED)

    LibGit2.git_diff_status_char(LibGit2::GIT_DELTA_MODIFIED).should eq('M'.ord)
    LibGit2.git_diff_status_char(LibGit2::GIT_DELTA_UNTRACKED).should eq('?'.ord)

    stats = uninitialized LibGit2::DiffStats*
    LibGit2.git_diff_get_stats(pointerof(stats), diff).should eq(LibGit2::GIT_OK)
    LibGit2.git_diff_stats_files_changed(stats).should eq(2)
    LibGit2.git_diff_stats_insertions(stats).should be > 0
    LibGit2.git_diff_stats_deletions(stats).should be > 0
    LibGit2.git_diff_stats_free(stats)

    LibGit2.git_diff_free(diff)
    LibGit2.git_tree_free(head_tree)
  end

  it "blames a file line by line" do
    blame = uninitialized LibGit2::Blame*
    LibGit2.git_blame_file(pointerof(blame), repo, "a.txt", nil).should eq(LibGit2::GIT_OK)

    # 3 lines, first two from commit 1, the third from commit 2
    LibGit2.git_blame_hunkcount(blame).should eq(2)

    first = LibGit2.git_blame_hunk_byline(blame, 1).not_nil!.value
    first.final_start_line_number.should eq(1)
    first.lines_in_hunk.should eq(2)
    String.new(first.final_signature.value.name).should eq("Alice Author")
    String.new(first.summary).should eq("first commit")

    second = LibGit2.git_blame_hunk_byline(blame, 3).not_nil!.value
    second.final_start_line_number.should eq(3)
    second.lines_in_hunk.should eq(1)
    String.new(second.summary).should eq("second commit")

    oid_zero = LibGit2::Oid.new
    first_id = first.final_commit_id
    second_id = second.final_commit_id
    first_oid = String.new(LibGit2.git_oid_tostr_s(pointerof(first_id)))
    second_oid = String.new(LibGit2.git_oid_tostr_s(pointerof(second_id)))
    first_oid.should_not eq(second_oid)
    first_oid.should_not eq(String.new(LibGit2.git_oid_tostr_s(pointerof(oid_zero))))

    LibGit2.git_blame_free(blame)
  end
end
