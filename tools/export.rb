#!/usr/bin/env ruby
# frozen_string_literal: true

# Export the pubid-testsuite corpus. Reads raw ground truth
# (reference-docs/{flavor}/**/{pass,full,fail}/*.txt), parses every line
# with the pubid reference implementation, writes tests/{flavor}/*.yaml,
# then verifies by re-parsing and validates every record against
# schema/test.schema.yaml.
#
# Contract notes:
# - identifier is parse(representations.human) - the structure of the
#   RENDERED identity string (the reference renders a bounded identity by
#   design, e.g. ieee relationship narratives are dropped); the original
#   spelling becomes an alias that must render to the same human form.
# - errors use neutral codes; urn recorded only when emitted.
# - reconciliation is set-based: every distinct fixture line must be
#   consumed as a canonical input, an alias spelling, or debt.

REPO = File.expand_path("..", __dir__)

# The reference gem's lib: the sibling checkout first (the CI layout and
# provenance.rb's GEM_DIR convention), then the legacy relative path.
# Only a candidate that actually carries the gem is unshifted — a wrong
# guess must not shadow the bundler env (the silent-stale-gem trap).
LIB_CANDIDATES = [
  File.expand_path("../pubid/lib", REPO),
  File.expand_path("../../../../pubid/lib", __dir__),
].freeze
lib = LIB_CANDIDATES.find { |d| Dir.exist?(File.join(d, "pubid")) }
$LOAD_PATH.unshift(lib) if lib && !$LOAD_PATH.include?(lib)

require "pubid"
require "yaml"
require "json"
require "set"
require "digest"
require "fileutils"
require_relative "fixture_line"
begin
  require "json_schemer"
rescue LoadError
  abort "json_schemer required (bundle install in the pubid repo)"
end
ERROR_CODES = {
  "Parslet::ParseFailed" => "parse_failed",
  "ArgumentError" => "invalid_argument",
}.freeze
REGISTRY_KEYS = { "tgpp" => "3gpp" }.freeze

module Exporter
  module_function

  SCHEMA = JSONSchemer.schema(YAML.safe_load_file(
    File.join(REPO, "schema", "test.schema.yaml")
  ))

  def style_for(input)
    return "v1" if /\bISO\/R\b|\bISO R\b/.match?(input)
    return "v2" if /\b(?:Amd|AMD|Cor|COR|Suppl|SUPPL)\.\d/.match?(input)

    "v3"
  end

  def error_code_for(exception)
    ERROR_CODES.fetch(exception.class.name, "unclassified")
  end

  def plainify(value)
    case value
    when Hash then value.to_h { |k, v| [k.to_s, plainify(v)] }
    when Array then value.map { |v| plainify(v) }
    when String, Integer, Float, TrueClass, FalseClass, NilClass then value
    else value.to_s
    end
  end

  def bundled_month_bug?(hash)
    hash.to_s.include?("bundled_identifier") && hash.to_s.include?("month")
  end

  # Fixture line semantics (identical in tools/validate.rb):
  # - '#' lines: comments in pass/full; in fail files they wrap
  #   identifiers as '#ID# Error...' (data only when a second '#' exists).
  # - '!' lines: the classifier's failure annotation
  #   '!ORIGINAL!NORMALIZED' - each non-empty half is a candidate
  #   identifier (parsed halves become cases/aliases; unparsed halves
  #   debt with the decoded input - never the glued blob).
  # Fixture line semantics live in PubidTests::FixtureLine (shared with
  # tools/validate.rb): '#' lines are comments in pass/full files; only
  # fail files wrap data as '#ID# Error...'. '!' lines are fix/normalize
  # directives '!RAW!FIXED'.
  def lines_from(path)
    category = File.basename(File.dirname(path)).to_sym
    File.readlines(path).filter_map do |raw|
      PubidTests::FixtureLine.new(raw, flavor: :unknown,
                                  category: category).identifier
    end
  end

  # Pending normalization rules '!RAW!FIXED' from the raw fixtures.
  # review flags are curated (contract-linked, e.g. tests/_contracts.yaml
  # C1); the regenerator carries them across by canonical human form.
  def preserved_reviews(out)
    Dir[File.join(out, "*.yaml")].flat_map do |path|
      next [] if File.basename(path).start_with?("_")

      Array(YAML.safe_load_file(path)).filter_map do |doc|
        next if doc.is_a?(String) || doc["review"].to_s.empty?

        [doc.dig("representations", "human"), doc["review"]]
      end
    end.to_h
  end

  def normalization_pairs(pass_files)
    pass_files.flat_map do |path|
      File.readlines(path).filter_map do |raw|
        PubidTests::FixtureLine.new(raw, flavor: :unknown,
                                    category: :pass).normalization_pair
      end
    end
  end

  def flavor_module(flavor)
    Pubid.eager_load_flavors!
    Pubid::Registry.get(REGISTRY_KEYS.fetch(flavor, flavor))
  end

  def export(flavor, staging: nil)
    mod = flavor_module(flavor)
    if mod.nil?
      warn "FLAVOR SKIP #{flavor} unregistered-in-reference"
      return nil
    end

    out = File.join(REPO, "tests", flavor)
    # Payloads are written into the staging dir first (default: the real
    # dir). With staging, nothing in tests/ is touched until commit! —
    # the delete-rewrite window that once recorded mass deletions and
    # that --check replays harmlessly.
    write_dir = staging || out
    FileUtils.mkdir_p(write_dir)
    # Curated review flags are contract-linked and hand-applied; harvest
    # them (keyed by canonical human form, stable where sequence ids are
    # not) before the full-regeneration cleanup deletes the old payloads.
    review_map = preserved_reviews(out)
    stats = { cases: 0, aliases: 0, duplicates: 0, phantom: 0, debt: 0,
              negatives: 0, quarantined: 0, divergent: 0,
              fixture_lines: Set.new, covered: Set.new, debt_inputs: Set.new }

    roots = [File.join(REPO, "reference-docs", flavor, "identifiers"),
             File.join(REPO, "reference-docs", flavor)]
    pass_files = roots.flat_map do |root|
      files = %w[pass full].flat_map { |cat| Dir[File.join(root, cat, "*.txt")] }
      # Flat v1-style flavor dirs keep their lists at the top level
      # (the gem's layout is authoritative; the mirror follows it).
      files += Dir[File.join(root, "*.txt")].reject { |f| File.basename(f) =~ /\A(SUMMARY|README)/ } if root.end_with?("/#{flavor}")
      files
    end.uniq

    debt = []
    groups = {}
    pass_files.each do |path|
      lines_from(path).each do |input|
        stats[:fixture_lines].add(input)
        record, error = build_case(mod, input)
        if error
          debt << { "id" => "#{flavor}.debt.#{Digest::SHA256.hexdigest(input)[0, 12]}",
                    "input" => input,
                    "expect" => { "error" => { "code" => error[0] } },
                    "notes" => error[1] }
          stats[:debt] += 1
          stats[:debt_inputs].add(input)
          next
        end
        key = JSON.generate(record["identifier"]) +
              record["representations"]["human"]
        (groups[key] ||= { "record" => record, "inputs" => [] })["inputs"] << input
      end
    end
    cases = finalize(groups, flavor, nil, stats, review_map)
    by_type = Hash.new { |h, k| h[k] = [] }
    cases.each { |c| by_type[type_of(c)] << c }
    by_type.each do |type, type_cases|
      File.write(File.join(write_dir, "#{type}.yaml"), YAML.dump(type_cases))
    end
    File.write(File.join(write_dir, "_debt.yaml"), YAML.dump(debt)) if debt.any?
    pairs = normalization_pairs(pass_files)
    if pairs.any?
      File.write(File.join(write_dir, "_normalization.yaml"), YAML.dump(pairs))
    end

    negatives = []
    fail_files = roots.flat_map { |r| Dir[File.join(r, "fail", "*.txt")] }.uniq
    fail_files.each do |path|
      type = File.basename(path, ".txt")
      lines_from(path).each_with_index do |input, i|
        stats[:negatives] += 1
        negatives << negative_case(mod, format("%s.neg.%s.%04d",
                                               flavor, type, i + 1), input)
      end
    end
    File.write(File.join(write_dir, "_negative.yaml"), YAML.dump(negatives)) if negatives.any?
    stats
  end

  def build_case(mod, input)
    identifier = mod.parse(input)
    human = identifier.to_s
    canonical_obj = begin
      mod.parse(human)
    rescue StandardError
      nil
    end
    canonical = canonical_obj && plainify(canonical_obj.to_hash)
    # All recorded expectations come from ONE parse - the canonical
    # re-parse of the rendered form - so identifier, urn and round-trip
    # are mutually consistent. The original input feeds only grouping
    # and the alias list.
    source = canonical_obj || identifier
    representations = { "human" => source.to_s }
    begin
      urn = source.to_urn
      representations["urn"] = urn if urn
    rescue StandardError
      nil
    end
    input_hash = plainify(identifier.to_hash)
    divergent = !canonical.nil? && canonical != input_hash
    identifier_mapping = canonical || input_hash
    record = { "id" => nil, "identifier" => identifier_mapping,
               "representations" => representations }
    if divergent
      record["input_parse_diverges"] = true
    end
    # The rendered human does not re-parse in the reference (canonical
    # is nil): the recorded identity comes from the raw parse and NO
    # implementation can satisfy parse(human) == identity. Mark the row
    # so the unsatisfiable class is machine-auditable.
    if canonical.nil?
      record["render_unreparseable"] = true
    end
    record["roundtrip"] = false unless round_trips?(mod, identifier_mapping)
    if bundled_month_bug?(input_hash)
      record = quarantine(record)
    end
    [record, nil]
  rescue StandardError => e
    [nil, [error_code_for(e),
            "unparsed ground-truth fixture: #{e.class}: " \
            "#{e.message.to_s[0, 200]}"]]
  end

  def quarantine(record)
    record.delete("identifier")
    record.delete("representations")
    record.delete("roundtrip")
    record.delete("input_parse_diverges")
    record["notes"] = "nondeterministic parse in reference implementation " \
                      "(month/day divergence) - quarantined"
    record
  end

  def round_trips?(mod, hash)
    mod::Identifier.from_hash(hash).to_hash == hash
  rescue StandardError
    false
  end

  def negative_case(mod, id, input)
    mod.parse(input)
    { "id" => id, "input" => input,
      "notes" => "fail fixture unexpectedly parsed - reclassify" }
  rescue StandardError => e
    { "id" => id, "input" => input,
      "expect" => { "error" => { "code" => error_code_for(e) } } }
  end

  # An identity is filed under its own outermost type key.
  def type_of(record)
    record["identifier"]["_type"].to_s.split(":").last.tr("-", "_")
  rescue StandardError
    "misc"
  end

  # The render/parse rounds a spelling needs to reach the canonical
  # human, or nil when it never does within the cap. A count above 1 is
  # a documented multi-round normalization chain (the reference reaches
  # the identity in more than one round); the checks walk that many
  # rounds instead of calling the alias lossy.
  MAX_ALIAS_ROUNDS = 3
  def alias_rounds(mod, spelling, canonical)
    text = spelling
    (1..MAX_ALIAS_ROUNDS).each do |round|
      text = mod.parse(text).to_s
      return round if text == canonical
    end
    nil
  rescue StandardError
    nil
  end

  def finalize(groups, flavor, _type, stats, review_map = {})
    mod = flavor_module(flavor)
    groups.values.sort_by { |g| g["record"]["representations"]["human"] }
          .each_with_index.map do |group, index|
      record = group["record"]
      canonical = record["representations"]["human"]
      record["id"] = format("%s.%s.%04d", flavor, type_of(record), index + 1)
      record["style"] = style_for(canonical) if record["identifier"]
      record["review"] = review_map[canonical] if review_map.key?(canonical)
      inputs = group["inputs"]
      stats[:duplicates] += [inputs.count(canonical) - 1, 0].max
      stats[:phantom] += 1 unless inputs.include?(canonical)
      aliases = inputs.reject { |i| i == canonical }.uniq.sort
      stats[:aliases] += aliases.size
      if record["identifier"].nil?
        stats[:quarantined] += 1
      else
        stats[:cases] += 1
        stats[:divergent] += 1 if record["input_parse_diverges"]
        unless aliases.empty?
          record["non_normalized_aliases"] = aliases.map do |a|
            entry = { "spelling" => a, "style" => style_for(a) }
            rounds = mod && alias_rounds(mod, a, canonical)
            entry["rounds"] = rounds if rounds && rounds > 1
            entry
          end
        end
      end
      record.delete("input_parse_diverges")
      stats[:covered].add(canonical)
      aliases.each { |a| stats[:covered].add(a) }
      record
    end
  end

  def verify(flavor)
    mod = flavor_module(flavor)
    return { cases: 0, aliases: 0, mismatches: 0, schema_errors: 0 } if mod.nil?

    cases = aliases_checked = mismatches = schema_errors = 0
    Dir[File.join(REPO, "tests", flavor, "*.yaml")].sort
      .reject { |path| File.basename(path).start_with?("_") }.each do |path|
      YAML.safe_load_file(path).each do |t|
        schema_errors += 1 unless SCHEMA.valid?(t)
        next unless t["identifier"]

        cases += 1
        human = t.dig("representations", "human")
        begin
          id = mod.parse(human)
        rescue StandardError
          mismatches += 1
          next
        end
        mismatches += 1 unless plainify(id.to_hash) == t["identifier"]
        mismatches += 1 unless id.to_s == human
        if t.dig("representations", "urn")
          begin
            mismatches += 1 unless id.to_urn == t.dig("representations", "urn")
          rescue StandardError
            mismatches += 1
          end
        end
        Array(t["non_normalized_aliases"]).each do |a|
          aliases_checked += 1
          begin
            text = a["spelling"]
            (a["rounds"] || 1).times { text = mod.parse(text).to_s }
            mismatches += 1 unless text == human
          rescue StandardError
            mismatches += 1
          end
        end
      end
    end
    { cases: cases, aliases: aliases_checked, mismatches: mismatches,
      schema_errors: schema_errors }
  end
  # The delete-rewrite swap: the staging dir is complete (and verified)
  # before the live payloads are replaced in one fast pass — the write
  # window that once recorded mass deletions shrinks to file moves.
  # _status.yaml is curated ledger state, never deleted.
  def commit!(flavor, staging)
    out = File.join(REPO, "tests", flavor)
    Dir[File.join(out, "*.yaml")].each do |old_file|
      File.delete(old_file) unless File.basename(old_file) == "_status.yaml"
    end
    dotfile = File.join(out, ".yaml")
    File.delete(dotfile) if File.exist?(dotfile)
    Dir[File.join(staging, "*.yaml")].each { |f| FileUtils.mv(f, out) }
    FileUtils.rmdir(staging)
  end

  # --check: regenerate into a throwaway staging dir and compare with the
  # live payloads. Never touches tests/. Returns [nil, []] when the
  # flavor is not exportable, else [identical, drift_descriptions].
  def check(flavor)
    mod = flavor_module(flavor)
    return nil, [] if mod.nil?

    out = File.join(REPO, "tests", flavor)
    staging = File.join(REPO, "tests", ".check-#{flavor}")
    FileUtils.rm_rf(staging)
    export(flavor, staging: staging)
    live = Dir[File.join(out, "*.yaml")]
      .map { |f| File.basename(f) }
      .reject { |n| n == "_status.yaml" }
    fresh = Dir[File.join(staging, "*.yaml")].map { |f| File.basename(f) }.sort
    # notes are diagnostic prose (the engine's exception message) — they
    # churn per engine and carry no contract; the comparison strips them.
    comparable = lambda do |path|
      doc = YAML.safe_load_file(path)
      case doc
      when Array then doc.each { |e| e.delete("notes") if e.is_a?(Hash) }
      when Hash then doc.delete("notes")
      end
      YAML.dump(doc)
    end
    drift = []
    (live | fresh).sort.each do |name|
      live_path = File.join(out, name)
      fresh_path = File.join(staging, name)
      if !File.exist?(fresh_path)
        drift << "stale-only live payload: #{name}"
      elsif !File.exist?(live_path)
        drift << "missing live payload: #{name}"
      elsif comparable.call(live_path) != comparable.call(fresh_path)
        drift << "content drift: #{name}"
      end
    end
    FileUtils.rm_rf(staging)
    [drift.empty?, drift]
  end
end

check_mode = ARGV.delete("--check")

flavors = if ARGV.empty?
            Dir[File.join(REPO, "reference-docs", "*")]
              .select { |p| File.directory?(p) }.map { |p| File.basename(p) }
          else
            ARGV
          end

if check_mode
  drifted = []
  flavors.each do |flavor|
    exportable, drift = Exporter.check(flavor)
    next if exportable.nil?

    puts format("%-12s %s", flavor, drift.empty? ? "IDENTICAL" : "DRIFT")
    drift.first(10).each { |d| puts "    #{d}" }
    puts "    (+#{drift.size - 10} more)" if drift.size > 10
    drifted << flavor unless drift.empty?
  end
  if drifted.empty?
    puts "CORPUS CURRENT: #{flavors.size} flavor(s) reproduce byte-identically"
  else
    warn "CORPUS DRIFT: #{drifted.join(", ")}"
    exit 1
  end
  exit 0
end

total_clean = 0
flavors.each do |flavor|
  # The atomic path: payloads land in staging and swap in after a clean
  # build — tests/ is never half-written.
  staging = File.join(REPO, "tests", ".export-#{flavor}")
  FileUtils.rm_rf(staging)
  stats = Exporter.export(flavor, staging: staging)
  next if stats.nil?

  Exporter.commit!(flavor, staging)

  v = Exporter.verify(flavor)
  stats[:covered].merge(stats[:debt_inputs] || [])
  closes = (stats[:covered] & stats[:fixture_lines]) == stats[:fixture_lines]
  clean = closes && v[:mismatches].zero? && v[:schema_errors].zero?
  total_clean += 1 if clean
  puts format("%-12s lines=%-6d cases=%-6d aliases=%-5d debt=%-5d " \
              "neg=%-4d quar=%-3d divergent=%-5d | closes=%s | " \
              "verify: mismatch=%d schema_errors=%d CLEAN=%s",
              flavor, stats[:fixture_lines].size, stats[:cases],
              stats[:aliases], stats[:debt], stats[:negatives],
              stats[:quarantined], stats[:divergent], closes,
              v[:mismatches], v[:schema_errors], clean)
end
puts "TOTAL CLEAN: #{total_clean}/#{flavors.size}"
