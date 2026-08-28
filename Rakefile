# frozen_string_literal: true

desc "Prove the corpus is identical to the reference-docs fixtures"
task :validate do
  sh "ruby #{File.join(__dir__, "tools", "validate.rb")}"
end

desc "Refresh tests/provenance.yaml (the corpus manifest)"
task :provenance do
  sh "ruby #{File.join(__dir__, "tools", "provenance.rb")}"
end

desc "Validate every corpus document against schema/test.schema.yaml"
task :schema do
  sh "ruby #{File.join(__dir__, "tools", "validate_schema.rb")}"
end

desc "All validations (identity + schema)"
task all: %i[validate schema]
