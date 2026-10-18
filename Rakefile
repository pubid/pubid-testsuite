# frozen_string_literal: true

GEM_DIR = ENV.fetch("CORPUS_GEM_DIR", File.expand_path("../pubid", __dir__))

desc "Prove the corpus is identical to the reference-docs fixtures"
task :validate do
  sh "ruby #{File.join(__dir__, 'tools', 'validate.rb')}"
end

desc "Refresh tests/provenance.yaml (the corpus manifest)"
task :provenance do
  sh "ruby #{File.join(__dir__, 'tools', 'provenance.rb')}"
end

desc "Validate every corpus document against schema/test.schema.yaml"
task :schema do
  sh "ruby #{File.join(__dir__, 'tools', 'validate_schema.rb')}"
end

desc "All validations (identity + schema)"
task all: %i[validate schema]

namespace :corpus do
  def corpus_flavors
    ENV["FLAVOR"] ? ENV["FLAVOR"].split(",") : []
  end

  desc "Regenerate the corpus from the reference gem (FLAVOR=ieee,iso or all)"
  task :regen do
    args = corpus_flavors.join(" ")
    sh "cd #{GEM_DIR} && bundle exec ruby #{File.join(__dir__, 'tools', 'export.rb')} #{args}".strip
    sh "ruby #{File.join(__dir__, 'tools', 'provenance.rb')}"
  end

  desc "Fail if the corpus drifts from the reference (FLAVOR=ieee,iso or all)"
  task :check do
    args = corpus_flavors.join(" ")
    sh "cd #{GEM_DIR} && bundle exec ruby #{File.join(__dir__, 'tools', 'export.rb')} --check #{args}".strip
  end
end
