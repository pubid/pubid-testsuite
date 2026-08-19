#!/usr/bin/env ruby
# frozen_string_literal: true

# Export the pubid-tests corpus. Reads raw ground truth
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

LIB = File.expand_path("../../../../pubid/lib", __dir__)
$LOAD_PATH.unshift(LIB) unless Dir.exist?(File.join(LIB, "pubid"))

require "pubid"
require "yaml"
require "json"
require "set"
require "fileutils"
begin
  require "json_schemer"
rescue LoadError
  abort "json_schemer required (bundle install in the pubid repo)"
end

REPO = File.expand_path("..", __dir__)
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

  def lines_from(path, fail_format: false)
    File.readlines(path).filter_map do |raw|
      line = raw.strip
      next if line.empty?
      if line.start_with?("#")
        next unless fail_format        # pass/full: comments
        next if line.split("#").size < 3 # fail headers: no wrapped id
        input = line.sub(/\A#/, "").split("#", 2).first.to_s.strip
        next input unless input.empty?
      else
        next line
      end
    end
  end

  def flavor_module(flavor)
    Pubid.eager_load_flavors!
    Pubid::Registry.get(REGISTRY_KEYS.fetch(flavor, flavor))
  end

  def export(flavor)
    mod = flavor_module(flavor)
    if mod.nil?
      warn "FLAVOR SKIP #{flavor} unregistered-in-reference"
      return nil
    end

    out = File.join(REPO, "tests", flavor)
    FileUtils.mkdir_p(out)
    # Full-regeneration semantics: stale files from earlier formats must
    # not survive beside fresh ones.
    Dir[File.join(out, "*.yaml")].each { |old_file| File.delete(old_file) }
    dotfile = File.join(out, ".yaml")
    File.delete(dotfile) if File.exist?(dotfile)
    stats = { cases: 0, aliases: 0, duplicates: 0, phantom: 0, debt: 0,
              negatives: 0, quarantined: 0, divergent: 0,
              fixture_lines: Set.new, covered: Set.new, debt_inputs: Set.new }

    roots = [File.join(REPO, "reference-docs", flavor, "identifiers"),
             File.join(REPO, "reference-docs", flavor)]
    pass_files = roots.flat_map do |root|
      %w[pass full].flat_map { |cat| Dir[File.join(root, cat, "*.txt")] }
    end.uniq

    debt = []
    groups = {}
    pass_files.each do |path|
      lines_from(path).each do |input|
        stats[:fixture_lines].add(input)
        record, error = build_case(mod, input)
        if error
          debt << { "id" => "#{flavor}.debt.#{input.hash.abs}",
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
    cases = finalize(groups, flavor, nil, stats)
    by_type = Hash.new { |h, k| h[k] = [] }
    cases.each { |c| by_type[type_of(c)] << c }
    by_type.each do |type, type_cases|
      File.write(File.join(out, "#{type}.yaml"), YAML.dump(type_cases))
    end
    File.write(File.join(out, "_debt.yaml"), YAML.dump(debt)) if debt.any?

    negatives = []
    fail_files = roots.flat_map { |r| Dir[File.join(r, "fail", "*.txt")] }.uniq
    fail_files.each do |path|
      type = File.basename(path, ".txt")
      lines_from(path, fail_format: true).each_with_index do |input, i|
        stats[:negatives] += 1
        negatives << negative_case(mod, format("%s.neg.%s.%04d",
                                               flavor, type, i + 1), input)
      end
    end
    File.write(File.join(out, "_negative.yaml"), YAML.dump(negatives)) if negatives.any?
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

  def finalize(groups, flavor, _type, stats)
    groups.values.sort_by { |g| g["record"]["representations"]["human"] }
          .each_with_index.map do |group, index|
      record = group["record"]
      canonical = record["representations"]["human"]
      record["id"] = format("%s.%s.%04d", flavor, type_of(record), index + 1)
      record["style"] = style_for(canonical) if record["identifier"]
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
            { "spelling" => a, "style" => style_for(a) }
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
            mismatches += 1 unless mod.parse(a["spelling"]).to_s == human
          rescue StandardError
            mismatches += 1
          end
        end
      end
    end
    { cases: cases, aliases: aliases_checked, mismatches: mismatches,
      schema_errors: schema_errors }
  end
end

flavors = if ARGV.empty?
            Dir[File.join(REPO, "reference-docs", "*")]
              .select { |p| File.directory?(p) }.map { |p| File.basename(p) }
          else
            ARGV
          end

total_clean = 0
flavors.each do |flavor|
  stats = Exporter.export(flavor)
  next if stats.nil?

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
