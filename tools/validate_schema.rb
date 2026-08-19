#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone corpus schema validation - no pubid gem required.
# Validates every tests/{flavor}/*.yaml document against
# schema/test.schema.yaml and asserts the ledger invariants:
#   - every flavor has a _status.yaml
#   - CLEAN flavors have zero known mismatches
# Exit 0 iff all documents validate and invariants hold.

require "yaml"
require "json_schemer"

REPO = File.expand_path("..", __dir__)
SCHEMA = JSONSchemer.schema(YAML.safe_load_file(
  File.join(REPO, "schema", "test.schema.yaml")
))

failures = 0
documents = 0
flavors = Dir[File.join(REPO, "tests", "*")].select { |p| File.directory?(p) }
           .map { |p| File.basename(p) }

flavors.each do |flavor|
  status_path = File.join(REPO, "tests", flavor, "_status.yaml")
  unless File.exist?(status_path)
    puts "MISSING-STATUS #{flavor}"
    failures += 1
    next
  end
  status = YAML.safe_load_file(status_path)
  if status["clean"] && !status["known_mismatches"].to_i.zero?
    puts "INCONSISTENT-STATUS #{flavor}: clean but known_mismatches=#{status["known_mismatches"]}"
    failures += 1
  end

  Dir[File.join(REPO, "tests", flavor, "*.yaml")].sort.each do |path|
    next if File.basename(path).start_with?("_")
    YAML.safe_load_file(path).each do |doc|
      documents += 1
      unless doc.is_a?(Hash) && SCHEMA.valid?(doc)
        failures += 1
        puts "SCHEMA #{flavor}/#{File.basename(path)}"
      end
    end
  end
end

puts "SCHEMA VALIDATION #{failures.zero? ? "PASS" : "FAIL"}: " \
     "#{documents} documents, #{flavors.size} flavors, #{failures} failures"
exit(failures.zero? ? 0 : 1)
