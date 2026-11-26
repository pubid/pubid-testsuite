# frozen_string_literal: true

# Tool-guard specs for tools/round_freeze.rb - the pure decision logic
# only: argument parsing, delta formatting, the staging path set, and
# ref resolution against real git fixtures (a throwaway repo, not the
# canonical checkout). The orchestration itself is exercised by running
# the round (rake round:check / round:freeze).

require "tmpdir"
require "open3"
require_relative "../tools/round_freeze"

RSpec.describe RoundFreeze do
  def git!(dir, *args)
    out, status = Open3.capture2("git", "-C", dir, *args)
    expect(status).to be_success, "git #{args.join(' ')} failed: #{out}"
    out.strip
  end

  def with_env(hash)
    saved = hash.keys.to_h { |k| [k, ENV[k]] }
    hash.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  describe ".parse_args!" do
    it "defaults the pins to origin/main with CHECK unset" do
      with_env("CHECK" => nil) do
        opts = described_class.parse_args!([])
        expect(opts[:check]).to be(false)
        expect(opts[:ref]).to eq("origin/main")
        expect(opts[:grammar_ref]).to eq("origin/main")
      end
    end

    it "honours CHECK=1 without a flag" do
      with_env("CHECK" => "1") do
        expect(described_class.parse_args!([])[:check]).to be(true)
      end
    end

    it "parses options pairwise" do
      opts = described_class.parse_args!(
        %w[--ref origin/fix/face --grammar-ref origin/other
           --source /tmp/gem --grammar-source /tmp/gram]
      )
      expect(opts[:ref]).to eq("origin/fix/face")
      expect(opts[:grammar_ref]).to eq("origin/other")
      expect(opts[:source]).to eq("/tmp/gem")
      expect(opts[:grammar_source]).to eq("/tmp/gram")
    end

    it "takes --check anywhere and refuses unknown arguments" do
      expect(described_class.parse_args!(%w[--check])[:check]).to be(true)
      expect { described_class.parse_args!(%w[--wat]) }.to raise_error(SystemExit)
      expect { described_class.parse_args!(%w[--ref]) }.to raise_error(SystemExit)
    end
  end

  describe ".round_paths" do
    it "names the round's explicit staging set (never a sweep)" do
      expect(described_class.round_paths("iec")).to contain_exactly(
        "tests/iec", "reference-docs/iec", "README.md",
        "tests/provenance.yaml"
      )
    end
  end

  describe ".delta_line" do
    it "signs the delta and names the unit" do
      expect(described_class.delta_line(10, 13, "cases"))
        .to eq("10 -> 13 (+3 cases)")
      expect(described_class.delta_line(13, 13, "cases"))
        .to eq("13 -> 13 (+0 cases)")
      expect(described_class.delta_line(5, 2, "negatives"))
        .to eq("5 -> 2 (-3 negatives)")
    end
  end

  describe ".resolve_in_source" do
    around do |example|
      Dir.mktmpdir("round-freeze-spec") do |dir|
        @repo = dir
        example.run
      end
    end

    def init_source_repo
      git!(@repo, "init", "--initial-branch=main", "--quiet")
      git!(@repo, "config", "user.email", "spec@example.com")
      git!(@repo, "config", "user.name", "Spec")
      File.write(File.join(@repo, "f.txt"), "one\n")
      git!(@repo, "add", "--", "f.txt")
      git!(@repo, "commit", "--quiet", "-m", "one")
      @parked = git!(@repo, "rev-parse", "HEAD")
      # The upstream tip the source only knows via its remote-tracking
      # ref (fetch never moves local branches).
      File.write(File.join(@repo, "f.txt"), "one\ntwo\n")
      git!(@repo, "add", "--", "f.txt")
      git!(@repo, "commit", "--quiet", "-m", "two")
      @upstream = git!(@repo, "rev-parse", "HEAD")
      git!(@repo, "update-ref", "refs/remotes/origin/main", @upstream)
      git!(@repo, "update-ref", "refs/remotes/origin/fix/face", @parked)
      # Park the local main on the older commit (the stale-sibling shape).
      git!(@repo, "checkout", "--quiet", "--detach", @parked)
    end

    it "resolves origin/<branch> from the remote-tracking ref, not the parked branch" do
      init_source_repo
      expect(described_class.resolve_in_source(@repo, "origin/main"))
        .to eq(@upstream)
    end

    it "resolves origin/<branch> for a fix branch and nil for a missing one" do
      init_source_repo
      expect(described_class.resolve_in_source(@repo, "origin/fix/face"))
        .to eq(@parked)
      expect(described_class.resolve_in_source(@repo, "origin/nope")).to be_nil
    end

    it "falls back to the source's own branch for bare branch names" do
      init_source_repo
      # A bare branch name means THAT branch as the source holds it
      # (its local main advanced to @upstream; only origin/* refs get
      # the remote-tracking treatment).
      expect(described_class.resolve_in_source(@repo, "main")).to eq(@upstream)
    end

    it "resolves shas and rejects unknown tags" do
      init_source_repo
      expect(described_class.resolve_in_source(@repo, @parked)).to eq(@parked)
      expect(described_class.resolve_in_source(@repo, "v99.99.99")).to be_nil
    end
  end

  describe ".mark_round_clone!" do
    it "marks an assembled clone and is idempotent" do
      dir = Dir.mktmpdir("round-clone-")
      marker = File.join(dir, described_class::MARKER)

      described_class.mark_round_clone!(dir)
      expect(File).to exist(marker)

      stamped = File.read(marker)
      described_class.mark_round_clone!(dir)
      expect(File.read(marker)).to eq(stamped)
    ensure
      FileUtils.remove_entry(dir) if dir
    end
  end
end
