#!/usr/bin/env ruby
# frozen_string_literal: true

# One-command corpus round: rake round:freeze[<flavor>,<gem_ref>].
#
# A corpus round is a lockstep choreography that was hand-run per flavor
# wave (spacing, dot, jis, iala): assemble the paired gem layout at the
# ref under test, regenerate the flavor, mirror the rawCopy twin,
# normalize the negative ledger, bump the README counts markers, run
# every gate, regenerate provenance LAST. Every hand-run risked the same
# error class - a round cut against a STALE sibling (whatever branch the
# shared ../pubid checkout had parked on) and needing a rebase. This
# tool pins the gem tree, verifies IN-PROCESS which lib and Pubid::VERSION
# the exporter will load, and refuses dirty trees on both sides.
#
# Usage:
#   ruby tools/round_freeze.rb <flavor> [--ref <gem_ref>] [--check]
#        [--source <git path|url>] [--grammar-ref <ref>] [--help]
#
#   rake round:freeze[<flavor>,<gem_ref>]    full round (write mode)
#   rake round:freeze[<flavor>,--check]      gates only, writes nothing
#   rake round:check[<flavor>,<gem_ref>]     same as the line above
#   CHECK=1 rake round:freeze[<flavor>]      same as the lines above
#
# The gem layout: the round assembles a dedicated gem clone at
# <testsuite>/../pubid - the sibling position tools/export.rb,
# tools/validate.rb (PUBID_GEM_PATH), tools/provenance.rb (PUBID_PATH)
# and the gem's conformance:run (PUBID_TESTSUITE_PATH) all resolve by
# default, so no env redirection can silently point at a stale tree. The
# clone is marked `.round-freeze`; an unmarked ../pubid (a real
# checkout) is never touched - run the round from a dedicated clone, or
# pass ROUND_GEM_DIR=<tree> (a clean git tree already AT the wanted ref;
# it is verified, never rewritten).
#
# Write mode choreography:
#   1. Preflight: refuse a dirty testsuite tree (rounds commit clean
#      trees), a protected branch (or a detached HEAD), and a dirty gem
#      tree; assemble + pin the gem clone at the ref (default
#      origin/main); probe IN-PROCESS which lib + Pubid::VERSION loads.
#   2. corpus:check FLAVOR - pre-round drift, informational (the round
#      is what resolves drift; a red pre-check is reported, not fatal).
#   3. corpus:regen FLAVOR=<flavor> - the exporter stages and swaps; the
#      interim provenance run inside this task is superseded by the LAST
#      run below.
#   4. Mirror the gem's spec/fixtures/<flavor> into reference-docs/<flavor>
#      byte-identical (diff -r verified; the rawCopy twin).
#   5. Rewrite tests/<flavor>/_negative.yaml as ONE yaml document (a
#      list): per-entry documents read back as empty and leave
#      missF>0 - ledger + fail fixtures + gem twin stay in lockstep.
#   6. rake provenance - after the last payload rewrite (the
#      TAMPERED-PAYLOAD hazard: any file rewrite invalidates hashes).
#   7. Bump the README counts markers from the fresh manifest (the
#      schema gate errors name exact numbers when wrong; this computes
#      them from the actual row delta instead).
#   8. rake provenance LAST - after any file rewrite; the repository
#      block records the round's dirty_paths by convention (commit it
#      with the rows).
#   9. Gates: rake validate, rake schema, conformance:run (run from the
#      pinned gem against this tree). A red gate fails the round AFTER
#      the summary prints, so the log always ends quotable.
#  10. Print a summary block the round PR body can quote. With
#      ROUND_COMMIT=1, stage the round's explicit paths and commit
#      (a zero-delta round stages nothing and says so).
#
# Check mode runs only the gates (validate/schema/conformance) against
# the pinned pair and asserts the testsuite tree is untouched at exit.

require "yaml"
require "fileutils"
require "open3"

module RoundFreeze
  module_function

  REPO = File.expand_path("..", __dir__)
  MARKER = ".round-freeze"
  README_PATH = File.join(REPO, "README.md")
  PROTECTED_BRANCHES = %w[main master].freeze

  USAGE = <<~TEXT
    Usage: round:freeze[<flavor>,<gem_ref>]
       or: ruby tools/round_freeze.rb <flavor> [options]

    Options:
      --ref <gem_ref>        pin the gem tree at this ref (default origin/main;
                             branch names resolve as origin/<branch>)
      --check                gates only (validate/schema/conformance); writes nothing
      --source <path|url>    git source for the assembled gem clone
                             (default ROUND_GEM_SOURCE, else https://github.com/pubid/pubid)
      --grammar-ref <ref>    pubid-grammar ref for the provenance input
                             (default origin/main; omit the block when unresolvable)
      --grammar-source <..>  git source for the grammar clone (default ROUND_GRAMMAR_SOURCE)
      --help                 this text

    Env:
      CHECK=1                same as --check
      ROUND_COMMIT=1         create the round commit (explicit paths only)
      ROUND_GEM_DIR=<tree>   use a PREPARED clean gem tree at the ref instead of
                             assembling one (verified, never rewritten)
      ROUND_GRAMMAR_DIR=<..> same for the grammar tree
      ROUND_GEM_SOURCE / ROUND_GRAMMAR_SOURCE
  TEXT

  # The round's own outputs - the explicit staging set (never `git add
  # -A`); a staged entry outside these paths aborts.
  def round_paths(flavor)
    ["tests/#{flavor}", "reference-docs/#{flavor}",
     "README.md", "tests/provenance.yaml"].freeze
  end

  # --- shell helpers (array-form everywhere; nothing reaches a shell
  # --- string) ---

  def run(cmd, env: {}, chdir: REPO)
    system(env.transform_values(&:to_s), *cmd, chdir: chdir)
    $?.success?
  end

  def run!(what, cmd, env: {}, chdir: REPO)
    return true if run(cmd, env: env, chdir: chdir)

    abort "ROUND ABORT: #{what} failed (exit #{$?.exitstatus})"
  end

  def git(dir, *args)
    out, status = Open3.capture2e("git", "-C", dir, *args)
    [out.strip, status.success?]
  end

  def git!(dir, *args)
    out, ok = git(dir, *args)
    return out if ok

    abort "ROUND ABORT: git -C #{dir} #{args.join(' ')} failed:\n#{out}"
  end

  def porcelain(dir = REPO, ignore: nil)
    lines = git(dir, "status", "--porcelain").first.lines.map(&:strip).reject(&:empty?)
    return lines if ignore.nil?

    lines.reject { |l| path_of(l) == ignore }
  end

  def path_of(status_line)
    status_line.split(/ -> | /).last
  end

  def refuse_dirty_tree!(what, dir, ignore: nil)
    dirty = porcelain(dir, ignore: ignore)
    return if dirty.empty?

    abort "ROUND ABORT: #{what} is dirty:\n  #{dirty.first(10).join("\n  ")}"
  end

  # --- preflight ---

  def check_flavor!(flavor)
    return if %w[tests reference-docs].any? do |root|
      Dir.exist?(File.join(REPO, root, flavor))
    end

    known = Dir[File.join(REPO, "reference-docs", "*")]
            .select { |p| File.directory?(p) }.map { |p| File.basename(p) }
    abort "ROUND ABORT: unknown flavor #{flavor.inspect} " \
          "(known: #{known.join(' ')})"
  end

  # Resolves `ref` to a commit sha inside `dir`, accepting both plain
  # refs (origin/main, a sha) and branch names fetched as origin/*.
  def resolve_ref!(dir, ref)
    [ref, "origin/#{ref}"].each do |candidate|
      sha, ok = git(dir, "rev-parse", "--verify", "--quiet",
                    "#{candidate}^{commit}")
      return sha if ok && !sha.empty?
    end
    abort "ROUND ABORT: cannot resolve #{ref.inspect} in #{dir} " \
          "(fetch it, or pass a full sha)"
  end

  # Assembles (or re-pins) a dedicated clone at `dest`. An existing
  # directory without the marker is a real checkout - refused, never
  # touched. With lenient: true (the grammar pin), any assembly failure
  # returns nil so provenance simply omits the grammar block - only the
  # gem pin is load-bearing.
  def assemble_tree!(kind, source, ref, dest, lenient: false)
    if Dir.exist?(dest)
      unless File.exist?(File.join(dest, MARKER))
        return lenient_failure(kind, dest, "existing tree without the " \
          "#{MARKER} marker (a real checkout - never touched)") if lenient
        abort "ROUND ABORT: #{dest} exists and is not a .round-freeze " \
              "clone (no #{MARKER} marker) - refusing to touch a real " \
              "checkout. Run the round from a dedicated clone, or pass " \
              "ROUND_#{kind.upcase}_DIR=<clean tree at the ref>."
      end
      # Refresh origin refs; a dead origin is survivable if the wanted
      # ref is already local.
      git(dest, "fetch", "--prune", "origin")
    else
      if source.nil? || source.empty?
        return lenient_failure(kind, dest, "no source to clone from " \
          "(pass --#{kind}-source)") if lenient
        abort "ROUND ABORT: no #{kind} source to clone from - pass " \
              "--source <git path|url>"
      end
      FileUtils.mkdir_p(File.dirname(dest))
      unless run(%W[git clone --quiet --shared #{source} #{dest}],
                 chdir: File.dirname(dest))
        return lenient_failure(kind, dest, "clone failed") if lenient
        abort "ROUND ABORT: cloning #{kind} from #{source} failed"
      end
    end
    begin
      sha = resolve_ref!(dest, ref)
      git!(dest, "checkout", "--quiet", "--detach", sha)
    rescue SystemExit
      return lenient_failure(kind, dest, "#{ref.inspect} unresolvable there") if lenient
      raise
    end
    refuse_dirty_tree!("#{kind} tree at #{dest} (after pinning)", dest,
                       ignore: MARKER)
    sha
  end

  def lenient_failure(kind, dest, why)
    warn "round: #{kind} pin skipped - #{why} (#{dest}); " \
         "provenance will omit the #{kind} block"
    nil
  end

  # ROUND_GEM_DIR escape hatch: a tree the caller prepared. It is
  # verified (clean + already at the ref), never rewritten.
  def verify_prepared_tree!(env_name, dir, ref)
    abort "ROUND ABORT: #{env_name}=#{dir} is not a directory" unless Dir.exist?(dir)
    abort "ROUND ABORT: #{env_name}=#{dir} is not a git tree" unless Dir.exist?(File.join(dir, ".git"))
    refuse_dirty_tree!("#{env_name}=#{dir}", dir)
    sha = resolve_ref!(dir, ref)
    head = git!(dir, "rev-parse", "HEAD")
    return sha if head == sha

    abort "ROUND ABORT: #{env_name}=#{dir} is parked at #{head[0, 12]} " \
          "but #{ref.inspect} resolves to #{sha[0, 12]} - park it at the " \
          "ref and rerun; a prepared tree is never rewritten."
  end

  # The gem's bundle must satisfy its lock at the pinned sha (a ref
  # switch can move the lock). Installs on demand; the tree must stay
  # clean afterwards (bundler writes nothing tracked when the lock
  # holds).
  def bundle_ready!(gem_dir)
    return if run(%w[bundle check], chdir: gem_dir)

    run!("bundle install (in #{gem_dir})", %w[bundle install --quiet],
         chdir: gem_dir)
    # The marker and the bundler-written files (Gemfile.lock is
    # gitignored here) must leave the tree otherwise clean.
    refuse_dirty_tree!("gem tree at #{gem_dir} (after bundle install)",
                       gem_dir, ignore: MARKER)
  end

  # The in-process stale-sibling guard: load the gem the way the
  # exporter does (unshift the assembled sibling lib first) and prove
  # WHICH lib and version answered.
  def probe_gem!(gem_dir)
    script = <<~RUBY
      $LOAD_PATH.unshift(File.expand_path("lib", Dir.pwd))
      require "pubid"
      loaded = $LOADED_FEATURES.grep(%r{/pubid\.rb\z}).first
      abort("probe: no pubid.rb in loaded features") unless loaded
      puts "loaded_lib=#{File.expand_path(File.dirname(File.dirname(loaded)))}"
      puts "version=#{Pubid::VERSION}"
    RUBY
    out, status = Open3.capture2e("bundle", "exec", "ruby", "-e", script,
                                  chdir: gem_dir)
    unless status.success?
      abort "ROUND ABORT: gem probe failed in #{gem_dir} " \
            "(bundle install there first?):\n#{out}"
    end
    fields = out.lines.filter_map do |l|
      k, v = l.strip.split("=", 2)
      [k, v] if v
    end.to_h
    lib = fields["loaded_lib"]
    real = File.realpath(gem_dir)
    if lib != real
      abort "ROUND ABORT: the probe loaded #{lib.inspect}, not the pinned " \
            "tree #{real} - the stale-sibling hazard is live; refusing " \
            "to round."
    end
    [fields["version"], real]
  end

  # The parsanol line the oracle provenance records (same lookup
  # provenance.rb does, so the summary quotes what will be committed).
  def parsanol_version(gem_dir)
    lock = File.join(gem_dir, "Gemfile.lock")
    return "unknown" unless File.exist?(lock)

    File.readlines(lock).find { |l| l.include?("parsanol (") }
        &.match(/\(([^)]+)\)/)&.[](1) || "unknown"
  rescue StandardError
    "unknown"
  end

  # --- pre/post state snapshots ---

  def manifest_counts
    path = File.join(REPO, "tests", "provenance.yaml")
    abort "ROUND ABORT: tests/provenance.yaml missing (run rake provenance)" unless File.exist?(path)
    YAML.safe_load_file(path)["counts"] || {}
  end

  # Flavor-scoped numbers for the summary (the same accounting
  # validate.rb uses: non-underscore payloads are cases/aliases,
  # _negative.yaml is the negative ledger).
  def flavor_counts(flavor)
    counts = { cases: 0, aliases: 0, negatives: 0 }
    dir = File.join(REPO, "tests", flavor)
    return counts unless Dir.exist?(dir)

    Dir[File.join(dir, "*.yaml")].sort.each do |path|
      name = File.basename(path)
      docs = YAML.safe_load_file(path)
      if name == "_negative.yaml"
        counts[:negatives] = Array(docs).size
      elsif name.start_with?("_")
        next
      else
        Array(docs).each do |doc|
          next unless doc.is_a?(Hash) && doc["identifier"]

          counts[:cases] += 1
          counts[:aliases] += Array(doc["non_normalized_aliases"]).size
        end
      end
    end
    counts
  end

  # --- choreography steps ---

  # The rawCopy twin: the gem's layout is authoritative; the mirror
  # follows it wholesale (git restores anything). Verified byte-identical.
  def mirror!(flavor, gem_dir)
    src = File.join(gem_dir, "spec", "fixtures", flavor)
    dst = File.join(REPO, "reference-docs", flavor)
    abort "ROUND ABORT: #{src} missing - the gem at this ref carries no " \
          "fixtures for #{flavor}" unless Dir.exist?(src)
    FileUtils.rm_r(dst) if Dir.exist?(dst)
    FileUtils.cp_r(src, dst)
    out, status = Open3.capture2e("diff", "-r", src, dst)
    return true if status.success? && out.empty?

    abort "ROUND ABORT: mirror not byte-identical after copy:\n" \
          "#{out.lines.first(10).join}"
  end

  # The negative ledger must be ONE yaml document (a list). Rewritten
  # per-entry it reads back as its FIRST document only - safe_load_file
  # raises nothing on a multi-document stream, so the remaining entries
  # are silently lost and validate.rb sees neg=0/missF>0. load_stream
  # sees every document; the rewrite collapses them into ONE list.
  def normalize_negative!(flavor)
    path = File.join(REPO, "tests", flavor, "_negative.yaml")
    return "absent (no fail fixtures)" unless File.exist?(path)

    docs = YAML.load_stream(File.read(path))
    entries = docs.flat_map { |d| d.is_a?(Array) ? d : [d] }.compact
    abort "ROUND ABORT: _negative.yaml holds no entries" if entries.empty?
    File.write(path, YAML.dump(entries))
    reread = YAML.safe_load_file(path)
    abort "ROUND ABORT: _negative.yaml rewrite lost entries " \
          "(#{entries.size} -> #{Array(reread).size})" unless reread == entries
    shape = docs.size > 1 ? "#{docs.size} documents flattened, " : ""
    "#{shape}#{entries.size} entries, one document"
  end

  # Bump the README counts markers from the manifest - computed from
  # the actual row delta, not from a gate error message.
  def bump_readme!(counts)
    text = File.read(README_PATH)
    bumps = {}
    %w[flavors cases].each do |key|
      want = counts[key].to_i
      m = text.match(/<!-- counts:#{key}=(\d+) -->/)
      if m.nil?
        abort "ROUND ABORT: README.md has no <!-- counts:#{key}=N --> " \
              "marker; add <!-- counts:#{key}=#{want} -->"
      end
      have = m[1].to_i
      next if have == want

      text = text.sub("<!-- counts:#{key}=#{have} -->",
                      "<!-- counts:#{key}=#{want} -->")
      bumps[key] = [have, want]
    end
    File.write(README_PATH, text) if bumps.any?
    bumps
  end

  # --- gates (output streams through; the log keeps the evidence) ---

  def gate_validate!(gem_dir)
    run(%w[rake validate], env: { "PUBID_GEM_PATH" => gem_dir })
  end

  def gate_schema!
    run(%w[rake schema])
  end

  def gate_conformance!(gem_dir)
    run(%w[bundle exec rake conformance:run],
        env: { "PUBID_TESTSUITE_PATH" => REPO }, chdir: gem_dir)
  end

  # --- commit (opt-in; explicit paths, staged set verified) ---

  def commit_round!(flavor, sha, bumps)
    wanted = round_paths(flavor)
    paths = wanted.select do |p|
      File.exist?(File.join(REPO, p)) &&
        porcelain.any? { |l| path_of(l) == p }
    end
    return "zero-diff: nothing to commit" if paths.empty?

    git!(REPO, "add", "--", *paths)
    staged = porcelain.map { |l| path_of(l) }
    unexpected = staged - wanted
    abort "ROUND ABORT: staged set has entries outside the round's " \
          "paths (#{wanted.join(' ')}): #{unexpected.join(' ')}" if unexpected.any?
    msg = commit_message_file(flavor, sha, bumps)
    git!(REPO, "commit", "--quiet", "-F", msg)
    FileUtils.rm_f(msg)
    "committed #{staged.size} path(s): #{staged.sort.join(' ')}"
  end

  def commit_message_file(flavor, sha, bumps)
    msg = File.join(git!(REPO, "rev-parse", "--absolute-git-dir"),
                    "ROUND_COMMIT_MSG")
    delta = bumps.map { |k, (a, b)| "#{k} #{a}->#{b}" }.join(", ")
    File.write(msg, <<~TEXT)
      round:freeze #{flavor} at pubid #{sha[0, 12]}

      Corpus round generated by rake round:freeze[#{flavor}] against the
      pinned gem tree; provenance.yaml carries the exact oracle commit.
      #{delta.empty? ? "No row delta (README markers unchanged)." : "README markers bumped: #{delta}."}
      Gates: rake validate, rake schema, conformance:run.
    TEXT
    msg
  end

  # --- summary ---

  def delta_line(before, after, key)
    d = after - before
    "#{before} -> #{after} (#{d >= 0 ? '+' : ''}#{d} #{key})"
  end

  def print_summary(fields)
    puts
    puts "=== ROUND FREEZE SUMMARY ==="
    fields.each { |k, v| puts format("%-16s %s", "#{k}:", v) }
    puts "============================"
  end

  # --- entry point ---

  def parse_args!(args)
    opts = { check: ENV["CHECK"] == "1", ref: "origin/main",
             grammar_ref: "origin/main",
             source: ENV["ROUND_GEM_SOURCE"],
             grammar_source: ENV["ROUND_GRAMMAR_SOURCE"] }
    until args.empty?
      a = args.shift
      case a
      when "--check" then opts[:check] = true
      when "--ref", "--grammar-ref", "--source", "--grammar-source"
        key = a.delete_prefix("--").tr("-", "_").to_sym
        opts[key] = args.shift
        abort "ROUND ABORT: #{a} needs a value" if opts[key].nil?
      when "--help" then abort USAGE.to_s
      else abort "ROUND ABORT: unknown argument #{a.inspect}\n\n#{USAGE}"
      end
    end
    opts
  end

  # Entry point (named main - `run` is the shell helper above; a same-
  # named later definition would shadow it inside every module method).
  def main(argv)
    flavor = argv.shift
    if flavor.nil? || flavor.start_with?("-") || flavor !~ /\A[a-z0-9_]+\z/
      abort "ROUND ABORT: flavor must look like a flavor id " \
            "(got #{flavor.inspect})\n\n#{USAGE}"
    end
    opts = parse_args!(argv)

    # Realpath normalization happens AFTER assembly - the sibling may
    # not exist yet when the round assembles it (macOS /tmp is a
    # symlink; the probe compares physical paths).
    gem_dir = File.expand_path(ENV["ROUND_GEM_DIR"] ||
                               File.expand_path("../pubid", REPO))
    grammar_dir = File.expand_path(ENV["ROUND_GRAMMAR_DIR"] ||
                                   File.expand_path("../pubid-grammar", REPO))

    check_flavor!(flavor)

    mode = opts[:check] ? "--check, gates only" : "write mode"
    puts "== round:freeze #{flavor} (#{mode})"
    puts "gem ref:   #{opts[:ref]}   source: " \
         "#{ENV['ROUND_GEM_DIR'] ? 'ROUND_GEM_DIR (prepared tree)' : opts[:source] || 'default (https://github.com/pubid/pubid)'}"

    # --- 1. preflight ---
    refuse_dirty_tree!("the testsuite tree (#{opts[:check] ? 'check mode gates the committed contract' : 'rounds commit clean trees'})", REPO)
    unless opts[:check]
      branch = git!(REPO, "branch", "--show-current")
      if branch.empty?
        abort "ROUND ABORT: detached HEAD - land rounds on a branch."
      elsif PROTECTED_BRANCHES.include?(branch)
        abort "ROUND ABORT: refusing to round on #{branch} - rounds land " \
              "through a PR branch."
      end
    end

    gem_sha =
      if ENV["ROUND_GEM_DIR"]
        verify_prepared_tree!("ROUND_GEM_DIR", gem_dir, opts[:ref])
      else
        assemble_tree!("gem", opts[:source], opts[:ref], gem_dir)
      end
    bundle_ready!(gem_dir)
    gem_dir = File.realpath(gem_dir)
    version, lib = probe_gem!(gem_dir)
    puts "gem tree:  #{gem_dir}"
    puts "gem pin:   #{opts[:ref]} @ #{gem_sha} (pubid #{version}, " \
         "parsanol #{parsanol_version(gem_dir)})"
    puts "gem lib:   #{lib} (probe-verified in-process)"

    grammar_sha = nil
    unless opts[:check]
      grammar_sha = assemble_tree!("grammar", opts[:grammar_source],
                                   opts[:grammar_ref], grammar_dir,
                                   lenient: true)
      puts "grammar:   #{opts[:grammar_ref]} @ #{grammar_sha} (provenance input)" if grammar_sha
    end

    pre_manifest = manifest_counts
    pre_flavor = flavor_counts(flavor)

    # --- write-mode choreography ---
    bumps = {}
    pre_check_ok = nil
    neg_note = nil
    unless opts[:check]
      puts "-- corpus:check (pre-round drift, informational)"
      pre_check_ok = run(%w[rake corpus:check],
                         env: { "FLAVOR" => flavor,
                                "CORPUS_GEM_DIR" => gem_dir })
      puts "   pre-round corpus:check: " \
           "#{pre_check_ok ? 'IDENTICAL' : 'DRIFT (this round resolves it)'}"

      puts "-- corpus:regen FLAVOR=#{flavor} (gem #{gem_sha[0, 12]})"
      run!("corpus:regen FLAVOR=#{flavor}", %w[rake corpus:regen],
           env: { "FLAVOR" => flavor, "CORPUS_GEM_DIR" => gem_dir })

      puts "-- mirror rawCopy twin " \
           "(gem spec/fixtures/#{flavor} -> reference-docs/#{flavor})"
      mirror!(flavor, gem_dir)

      puts "-- normalize _negative.yaml (single-document ledger)"
      neg_note = normalize_negative!(flavor)
      puts "   negative ledger: #{neg_note}"

      puts "-- provenance (after the last payload rewrite)"
      run!("provenance (post-payload)", %w[rake provenance],
           env: { "PUBID_PATH" => gem_dir })

      puts "-- README counts markers (from the fresh manifest)"
      bumps = bump_readme!(manifest_counts)

      puts "-- provenance LAST (after any file rewrite)"
      run!("provenance (LAST)", %w[rake provenance],
           env: { "PUBID_PATH" => gem_dir })
    end

    # --- gates ---
    puts "-- gates"
    verdicts = {
      "validate" => gate_validate!(gem_dir),
      "schema" => gate_schema!,
      "conformance" => gate_conformance!(gem_dir),
    }

    post_manifest = manifest_counts
    post_flavor = flavor_counts(flavor)

    # --- commit / write assertion ---
    commit_note =
      if opts[:check]
        after = porcelain
        abort "ROUND ABORT: check mode wrote to the tree:\n  " \
              "#{after.first(10).join("\n  ")}" if after.any?
        "nothing written (tree clean)"
      elsif ENV["ROUND_COMMIT"] == "1"
        commit_round!(flavor, gem_sha, bumps)
      else
        ready = round_paths(flavor).select do |p|
          File.exist?(File.join(REPO, p)) &&
            porcelain.any? { |l| path_of(l) == p }
        end
        if ready.empty?
          "zero-diff: nothing to commit (ROUND_COMMIT=1 to commit)"
        else
          "commit-ready: #{ready.join(' ')} (ROUND_COMMIT=1 to commit)"
        end
      end

    print_summary(
      "flavor" => flavor,
      "gem" => "#{opts[:ref]} @ #{gem_sha} (pubid #{version}, " \
               "parsanol #{parsanol_version(gem_dir)})",
      "gem tree" => "#{gem_dir} (clean, probe-verified)",
      "grammar" => grammar_sha ? "#{opts[:grammar_ref]} @ #{grammar_sha}" : \
                                 "omitted (pin unresolvable)",
      "row delta" => "#{delta_line(pre_manifest['cases'].to_i, post_manifest['cases'].to_i, 'cases corpus-wide')}; " \
                     "flavor #{delta_line(pre_flavor[:cases], post_flavor[:cases], 'cases')}, " \
                     "#{delta_line(pre_flavor[:negatives], post_flavor[:negatives], 'negatives')}, " \
                     "#{delta_line(pre_flavor[:aliases], post_flavor[:aliases], 'aliases')}",
      "readme markers" => bumps.empty? ? "unchanged" : bumps.map { |k, (a, b)| "#{k}=#{a}->#{b}" }.join(" "),
      "corpus:check" => opts[:check] ? "not run (check mode)" : (pre_check_ok ? "IDENTICAL (pre-round)" : "DRIFT pre-round (resolved by this round)"),
      "negative ledger" => neg_note || "not rewritten (check mode)",
      "validate" => verdicts["validate"] ? "PASS" : "FAIL",
      "schema" => verdicts["schema"] ? "PASS" : "FAIL",
      "conformance" => verdicts["conformance"] ? "PASS" : "FAIL",
      "write" => commit_note,
    )

    # A red gate fails the round AFTER the summary, so the log always
    # ends with the quotable block.
    failed = verdicts.reject { |_, ok| ok }
    warn "ROUND FAILED GATES: #{failed.keys.join(', ')}" unless failed.empty?
    exit(failed.empty? ? 0 : 1)
  end
end

RoundFreeze.main(ARGV) if $PROGRAM_NAME == __FILE__
