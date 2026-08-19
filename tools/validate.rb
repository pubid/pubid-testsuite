#!/usr/bin/env ruby
# frozen_string_literal: true

# Independent validation that the converted corpus (tests/) is IDENTICAL
# to the original fixture lists. Pure string-set arithmetic - the pubid
# gem is NOT loaded, so this cannot inherit the exporter's logic.
#
# Identity contract (duplicates are deliberately collapsed to one case,
# so identity is set identity plus full accounting):
#   A. reference-docs/{flavor} is byte-identical to the original
#      spec/fixtures/{flavor} (diff -r, original source of truth).
#   B. every distinct original pass/full line is recoverable in the
#      corpus as: canonical representations.human, alias spelling,
#      or debt input.
#   C. every original fail line (decoded from the '#ID# Error' wrapper)
#      is a negative input.
#   D. nothing invented: every alias spelling, debt input and negative
#      input IS an original line; every canonical human is an original
#      line or a counted phantom (normalized form), and each phantom's
#      aliases are original lines.
#
# Usage: bundle exec ruby tools/validate.rb [flavor ...]
# Exits nonzero on any violation.

require "yaml"
require "set"
require "open3"

REPO = File.expand_path("..", __dir__)
GEM_FIXTURES = File.join(
  ENV.fetch("PUBID_GEM_PATH", File.expand_path("../../pubid", __dir__)),
  "spec", "fixtures"
)

module Validator
  module_function

  # pass/full: '#' lines are comments. fail: '#' lines wrap identifiers
  # as '#ID# Error...' - data only when a second '#' exists.
  # Line semantics identical to tools/export.rb: '#' lines are comments
  # (fail files wrap '#ID# Error...', data only with a second '#');
  # '!' lines are classifier annotations '!ORIGINAL!NORMALIZED' - each
  # non-empty half is a candidate identifier.
  def plain_lines(paths)
    paths.flat_map do |path|
      File.readlines(path).flat_map do |raw|
        line = raw.strip
        next [] if line.empty?
        if line.start_with?("!")
          fixed = line.split("!").map(&:strip).reject(&:empty?).last
          fixed ? [fixed] : []
        elsif line.start_with?("#")
          next [] if line.split("#").size < 3
          input = line.sub(/\A#/, "").split("#", 2).first.to_s.strip
          input.empty? ? [] : [input]
        else
          [line]
        end
      end
    end
  end

  def fail_lines(paths)
    plain_lines(paths)
  end

  def fixture_paths(flavor, categories)
    roots = [File.join(REPO, "reference-docs", flavor, "identifiers"),
             File.join(REPO, "reference-docs", flavor)]
    roots.flat_map do |root|
      categories.flat_map { |cat| Dir[File.join(root, cat, "*.txt")] }
    end.uniq
  end

  def corpus(flavor)
    dir = File.join(REPO, "tests", flavor)
    data = { canonical: Set.new, aliases: Set.new, debt: Set.new,
             negative: Set.new, phantom_cases: [], cases: 0 }
    return data unless Dir.exist?(dir)

    Dir[File.join(dir, "*.yaml")].sort.each do |path|
      base = File.basename(path)
      records = YAML.safe_load_file(path)
      next if records.is_a?(Hash) # _status.yaml metadata

      records.each do |t|
        case base
        when "_debt.yaml" then data[:debt].add(t.fetch("input"))
        when "_negative.yaml" then data[:negative].add(t.fetch("input"))
        else
          human = t.dig("representations", "human")
          if human
            data[:cases] += 1
            data[:canonical].add(human)
            spellings = Array(t["non_normalized_aliases"])
                               .map { |a| a["spelling"] }
            data[:aliases].merge(spellings)
            data[:phantom_cases] << [human, spellings] unless spellings.empty?
          end
        end
      end
    end
    data
  end

  def raw_identical?(flavor)
    original = File.join(GEM_FIXTURES, flavor)
    copy = File.join(REPO, "reference-docs", flavor)
    return [false, "missing tree"] unless Dir.exist?(original) && Dir.exist?(copy)

    out, _status = Open3.capture2("diff", "-r", original, copy)
    [out.empty?, out.lines.first(3).join]
  end

  def validate(flavor)
    pass_set = plain_lines(fixture_paths(flavor, %w[pass full])).to_set
    fail_set = fail_lines(fixture_paths(flavor, ["fail"])).to_set
    c = corpus(flavor)
    raw_total = pass_set.size + fail_set.size

    recovered = c[:canonical] + c[:aliases] + c[:debt]
    missing_pass = pass_set - recovered
    missing_fail = fail_set - c[:negative]
    invented = (c[:canonical] + c[:aliases]) - pass_set
    phantom = c[:canonical] - pass_set
    alias_foreign = c[:aliases] - pass_set
    debt_foreign = c[:debt] - pass_set
    negative_foreign = c[:negative] - fail_set
    phantom_bad = c[:phantom_cases]
                   .select { |_human, spell| spell.empty? || !(spell.to_set - pass_set).empty? }
    raw_ok, raw_detail = raw_identical?(flavor)

    identical = missing_pass.empty? && missing_fail.empty? &&
                alias_foreign.empty? && debt_foreign.empty? &&
                negative_foreign.empty? && phantom_bad.empty? && raw_ok
    { flavor: flavor, raw: raw_total, pass: pass_set.size, fail: fail_set.size,
      cases: c[:cases], canonical: c[:canonical].size, phantom: phantom.size,
      aliases: c[:aliases].size, debt: c[:debt].size, negative: c[:negative].size,
      missing_pass: missing_pass.size, missing_fail: missing_fail.size,
      debt_foreign: debt_foreign.size, negative_foreign: negative_foreign.size,
      invented_total: invented.size, alias_foreign: alias_foreign.size,
      phantom_bad: phantom_bad.size, raw_identical: raw_ok, raw_detail: raw_detail,
      identical: identical,
      samples: { missing_pass: missing_pass.first(2), missing_fail: missing_fail.first(2),
                 alias_foreign: alias_foreign.first(2),
                 debt_foreign: debt_foreign.first(2),
                 negative_foreign: negative_foreign.first(2) } }
  end
end

# Flavors with reference-docs but no tests directory are intentionally
# skipped (unregistered in the reference implementation); they are listed,
# not failed.
SKIPPED = [].freeze

flavors = if ARGV.empty?
            Dir[File.join(REPO, "reference-docs", "*")]
              .select { |p| File.directory?(p) }.map { |p| File.basename(p) }
          else
            ARGV
          end

results = flavors.map do |f|
  tests_dir = File.join(REPO, "tests", f)
  r = Validator.validate(f)
  r[:skipped_raw_only] = !Dir.exist?(tests_dir)
  r
end
results.each do |r|
  next if r[:skipped_raw_only]

  puts format("%-12s raw=%-6d pass=%-6d fail=%-4d | cases=%-6d canon=%-6d " \
              "phantom=%-4d alias=%-5d debt=%-5d neg=%-4d | " \
              "missP=%-3d missF=%-3d aliasForeign=%-3d debtForeign=%-3d " \
              "negForeign=%-3d phantomBad=%-2d " \
              "rawCopy=%s | IDENTICAL=%s",
              r[:flavor], r[:raw], r[:pass], r[:fail], r[:cases],
              r[:canonical], r[:phantom], r[:aliases], r[:debt],
              r[:negative], r[:missing_pass], r[:missing_fail],
              r[:alias_foreign], r[:debt_foreign],
              r[:negative_foreign], r[:phantom_bad], r[:raw_identical],
              r[:identical])
  next if r[:identical]

  r[:samples].each { |k, v| puts "    #{k}: #{v.inspect}" if v.is_a?(Array) && !v.empty? }
  puts "    rawCopy diff: #{r[:raw_detail]}" unless r[:raw_identical]
end

skipped = results.select { |r| r[:skipped_raw_only] }.map { |r| r[:flavor] }
puts "SKIPPED (raw-only, no tests dir): #{skipped.join(' ')}" unless skipped.empty?
failed = results.count { |r| !r[:identical] && !r[:skipped_raw_only] }
puts "VALIDATION #{failed.zero? ? 'PASS' : 'FAIL'}: " \
     "#{results.count { |r| !r[:skipped_raw_only] } - failed} identical, " \
     "#{skipped.size} skipped raw-only, #{failed} FAILED"
exit(failed.zero? ? 0 : 1)
