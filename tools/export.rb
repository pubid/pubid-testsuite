#!/usr/bin/env ruby
# frozen_string_literal: true

# Export the pubid-tests corpus. Reads the raw ground truth
# (reference-docs/{flavor}/identifiers/{pass,full,fail}/*.txt), parses
# every line with the pubid reference implementation, and writes
# tests/{flavor}/*.yaml. NOTHING is invented: the identifier in each
# case is the gem's own canonical to_hash as a plain YAML mapping;
# errors use neutral codes; every input line is accounted for
# (case | alias | duplicate | phantom | debt | negative).
#
# Usage: bundle exec ruby tools/export.rb [flavor ...]
# Run from a checkout of the pubid gem (or a sibling; the gem is loaded
# from ../pubid/lib). Verify mode runs automatically after export.

LIB = File.expand_path("../../../../pubid/lib", __dir__)
$LOAD_PATH.unshift(LIB) unless Dir.exist?(File.join(LIB, "pubid"))

require "pubid"
require "yaml"
begin
  require "json_schemer"
rescue LoadError
  abort "json_schemer required for schema validation (bundle install)"
end
require "json"
require "fileutils"

REPO = File.expand_path("..", __dir__)
ERROR_CODES = {
  "Parslet::ParseFailed" => "parse_failed",
  "ArgumentError" => "invalid_argument",
}.freeze

module Exporter
  module_function

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
      next line unless fail_format
      next line unless line.start_with?("#")

      input = line.sub(/\A#/, "").split("#", 2).first.to_s.strip
      input unless input.empty?
    end
  end

  def export(flavor)
    Pubid.eager_load_flavors!
    registry_key = { "tgpp" => "3gpp" }.fetch(flavor, flavor)
    mod = Pubid::Registry.get(registry_key)
    if mod.nil?
      warn "FLAVOR SKIP #{flavor} unregistered-in-reference"
      return nil
    end

    out = File.join(REPO, "tests", flavor)
    FileUtils.mkdir_p(out)
    stats = { cases: 0, aliases: 0, duplicates: 0, phantom: 0, debt: 0,
              negatives: 0, quarantined: 0, lines: 0 }

    roots = [File.join(REPO, "reference-docs", flavor, "identifiers"),
             File.join(REPO, "reference-docs", flavor)]
    pass_files = roots.flat_map do |root|
      %w[pass full].flat_map do |cat|
        Dir[File.join(root, cat, "*.txt")]
      end
    end.uniq
    debt = []
    pass_files.each do |path|
      type = File.basename(path, ".txt")
      groups = {}
      lines_from(path).each do |input|
        stats[:lines] += 1
        record = build_case(mod, input)
        if record.nil? # debt: carries [input, code, message]
          debt << { "id" => "#{flavor}.debt.#{input.hash.abs}",
                    "input" => input,
                    "expect" => { "error" => { "code" => @code } },
                    "notes" => @message }
          stats[:debt] += 1
          next
        end
        key = JSON.generate(record["identifier"]) + record["representations"]["human"]
        (groups[key] ||= { "record" => record, "inputs" => [] })["inputs"] << input
      end
      cases = finalize(groups, flavor, type, stats)
      File.write(File.join(out, "#{type}.yaml"), YAML.dump(cases)) if cases.any?
    end
    File.write(File.join(out, "_debt.yaml"), YAML.dump(debt)) if debt.any?

    negatives = []
    fail_files = roots.flat_map do |root|
      Dir[File.join(root, "fail", "*.txt")]
    end.uniq
    fail_files.each do |path|
      type = File.basename(path, ".txt")
      lines_from(path, fail_format: true).each_with_index do |input, i|
        stats[:negatives] += 1
        negatives << negative_case(mod, format("%s.neg.%s.%04d", flavor, type, i + 1), input)
      end
    end
    File.write(File.join(out, "_negative.yaml"), YAML.dump(negatives)) if negatives.any?
    stats
  end

  def build_case(mod, input)
    identifier = mod.parse(input)
    hash = identifier.to_hash
    representations = { "human" => identifier.to_s }
    begin
      representations["urn"] = identifier.to_urn
    rescue StandardError
      nil
    end
    record = { "id" => nil, "identifier" => plainify(hash),
               "representations" => representations }
    record["roundtrip"] = false unless round_trips?(mod, hash)
    if bundled_month_bug?(hash)
      stats_note_quarantine(record)
    end
    record
  rescue StandardError => e
    @code = error_code_for(e)
    @message = "unparsed ground-truth fixture: #{e.class}: #{e.message.to_s[0, 200]}"
    nil
  end

  def stats_note_quarantine(record)
    record.delete("identifier")
    record.delete("representations")
    record.delete("roundtrip")
    record["notes"] = "nondeterministic parse in reference implementation " \
                      "(month/day divergence) - quarantined"
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

  def finalize(groups, flavor, type, stats)
    groups.values.sort_by { |g| g["record"]["representations"]["human"] }
          .each_with_index.map do |group, index|
      record = group["record"]
      canonical = record["representations"]["human"]
      record["id"] = format("%s.%s.%04d", flavor, type, index + 1)
      record["style"] = style_for(canonical)
      inputs = group["inputs"]
      stats[:duplicates] += [inputs.count(canonical) - 1, 0].max
      stats[:phantom] += 1 unless inputs.include?(canonical)
      aliases = inputs.reject { |i| i == canonical }.uniq.sort
      stats[:aliases] += aliases.size
      unless aliases.empty? || record["identifier"].nil?
        record["non_normalized_aliases"] = aliases.map do |a|
          { "spelling" => a, "style" => style_for(a) }
        end
      end
      if record["identifier"].nil?
        stats[:quarantined] += 1
      else
        stats[:cases] += 1
      end
      record
    end
  end

  SCHEMA = JSONSchemer.schema(YAML.safe_load_file(
    File.join(REPO, "schema", "test.schema.yaml")
  ))

  def verify(flavor)
    Pubid.eager_load_flavors!
    mod = Pubid::Registry.get({ "tgpp" => "3gpp" }.fetch(flavor, flavor))
    return { cases: 0, aliases: 0, mismatches: 0, schema_errors: 0 } if mod.nil?

    cases = aliases_checked = mismatches = schema_errors = 0
    Dir[File.join(REPO, "tests", flavor, "*.yaml")].sort.each do |path|
      YAML.safe_load_file(path).each do |t|
        schema_errors += 1 unless SCHEMA.valid?(t)
        next unless t["identifier"]

        cases += 1
        begin
          id = mod.parse(t.dig("representations", "human"))
        rescue StandardError
          mismatches += 1
          next
        end
        mismatches += 1 unless plainify(id.to_hash) == t["identifier"]
        mismatches += 1 unless id.to_s == t.dig("representations", "human")
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
            mismatches += 1 unless mod.parse(a["spelling"]).to_s == t.dig("representations", "human")
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

flavors = ARGV.empty? ? Dir[File.join(REPO, "reference-docs", "*")]
                            .select { |p| File.directory?(p) }
                            .map { |p| File.basename(p) } : ARGV
flavors.each do |flavor|
  stats = Exporter.export(flavor)
  next warn "FLAVOR SKIP #{flavor}" if stats.nil?

  v = Exporter.verify(flavor)
  fixture_derived = stats[:cases] - stats[:phantom]
  formula = stats[:lines] ==
            fixture_derived + stats[:aliases] + stats[:duplicates] +
            stats[:debt]
  clean = formula && v[:mismatches].zero? && v[:schema_errors].zero?
  puts format("%-5s lines=%-6d cases=%-6d aliases=%-4d dups=%-5d " \
              "phantom=%-4d debt=%-4d neg=%-4d quar=%-3d | closes=%s | " \
              "verify: cases=%d aliases=%d mismatch=%d schema_errors=%d " \
              "CLEAN=%s",
              flavor, stats[:lines], stats[:cases], stats[:aliases],
              stats[:duplicates], stats[:phantom], stats[:debt],
              stats[:negatives], stats[:quarantined], formula, v[:cases],
              v[:aliases], v[:mismatches], v[:schema_errors], clean)
  warn "FLAVOR DONE #{flavor} #{clean ? 'CLEAN' : 'DIRTY'}"
end
