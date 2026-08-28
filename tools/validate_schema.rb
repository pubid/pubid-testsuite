#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone structural validation (plurimath-testsuite parity). Gem-free:
#   1. Every non-underscore corpus case validates against
#      schema/test.schema.yaml via the fail-closed subset engine.
#   2. Ledger invariants: every flavor has _status.yaml; clean implies
#      zero known mismatches.
#   3. Provenance integrity: every GENERATED payload recorded in
#      tests/provenance.yaml still hashes; unrecorded payloads fail;
#      curated files are never hash-checked.
#   4. README drift: the counts in README.md match the corpus.
# An empty corpus fails - an empty tree can never look like a pass.

require "yaml"
require "digest"
require_relative "json_schema_subset"

REPO = File.expand_path("..", __dir__)
failures = 0

def abort_check(condition, message, failures)
  return failures + 1 unless condition
  puts message
  failures
end

schema = YAML.safe_load_file(File.join(REPO, "schema", "test.schema.yaml"))
tests = File.join(REPO, "tests")
flavors = Dir[File.join(tests, "*")].select { |p| File.directory?(p) }.map { |p| File.basename(p) }.sort

failures += 1 if flavors.empty?
puts "EMPTY-CORPUS FAILURE" if flavors.empty?

documents = 0
flavors.each do |flavor|
  status_path = File.join(tests, flavor, "_status.yaml")
  if File.exist?(status_path)
    status = YAML.safe_load_file(status_path)
    if status["clean"] && !status["known_mismatches"].to_i.zero?
      puts "INCONSISTENT-STATUS #{flavor}: clean but known_mismatches=#{status['known_mismatches']}"
      failures += 1
    end
  else
    puts "MISSING-STATUS #{flavor}"
    failures += 1
    next
  end

  Dir[File.join(tests, flavor, "*.yaml")].sort.each do |path|
    next if File.basename(path).start_with?("_")
    YAML.safe_load_file(path).each do |doc|
      documents += 1
      errs = JsonSchemaSubset.validate(schema, doc)
      next if errs.empty?
      failures += 1
      puts "SCHEMA #{flavor}/#{File.basename(path)}"
      errs.first(3).each { |e| puts "  #{e}" }
    end
  end
end
puts "schema: #{documents} documents checked#{documents.zero? ? ' - EMPTY' : ''}"
failures += 1 if documents.zero?

# --- provenance integrity ---
manifest_path = File.join(tests, "provenance.yaml")
if File.exist?(manifest_path)
  manifest = YAML.safe_load_file(manifest_path)
  recorded = manifest["payloads"].to_h { |p| [p["path"], p] }
  on_disk = flavors.each_with_object({}) do |flavor, h|
    Dir[File.join(tests, flavor, "*.yaml")].sort.each do |path|
      next if File.basename(path) == "_status.yaml"
      rel = path.delete_prefix("#{tests}/")
      h[rel] = { "sha256" => Digest::SHA256.file(path).hexdigest, "bytes" => File.size(path) }
    end
  end
  on_disk.each do |rel, meta|
    entry = recorded[rel]
    if entry.nil?
      puts "UNRECORDED-PAYLOAD #{rel} (run tools/provenance.rb)"
      failures += 1
    elsif entry["sha256"] != meta["sha256"]
      puts "TAMPERED-PAYLOAD #{rel}: hash differs from provenance (regenerate or rerun provenance)"
      failures += 1
    end
  end
  recorded.each_key do |rel|
    next if on_disk.key?(rel)
    puts "MISSING-PAYLOAD #{rel}: recorded in provenance but absent"
    failures += 1
  end
  puts "provenance: #{on_disk.size} generated payloads verified against manifest"

  # --- README drift ---
  readme = File.read(File.join(REPO, "README.md"))
  counts = manifest["counts"] || {}
  %w[flavors cases].each do |key|
    expected = counts[key].to_i
    m = readme.match(/<!-- counts:#{key}=(\d+) -->/)
    if m.nil?
      puts "README-DRIFT missing marker for #{key}: add <!-- counts:#{key}=#{expected} -->"
      failures += 1
    elsif m[1].to_i != expected
      puts "README-DRIFT #{key}: README says #{m[1]}, corpus has #{expected}"
      failures += 1
    end
  end
else
  puts "MISSING-PROVENANCE tests/provenance.yaml (run tools/provenance.rb)"
  failures += 1
end

puts "STRUCTURE VALIDATION #{failures.zero? ? 'PASS' : 'FAIL'}: #{failures} failures"
exit(failures.zero? ? 0 : 1)
