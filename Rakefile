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

namespace :round do
  def round_freeze_cmd(flavor, extra)
    ["ruby", File.join(__dir__, "tools", "round_freeze.rb"), flavor, *extra]
  end

  desc "Freeze one corpus round against a pinned gem ref: assemble the " \
       "paired gem tree, corpus:regen, mirror the rawCopy twin, normalize " \
       "the negative ledger, bump the README markers, run every gate, " \
       "provenance LAST. ROUND_COMMIT=1 commits the round's explicit paths."
  task :freeze, [:flavor, :gem_ref] do |_t, args|
    extra = if args[:gem_ref] == "--check"
              %w[--check]
            elsif args[:gem_ref]
              %W[--ref #{args[:gem_ref]}]
            else
              []
            end
    sh(*round_freeze_cmd(args[:flavor], extra))
  end

  desc "Round gates only (validate/schema/conformance) against a pinned " \
       "gem ref - assembles the pair, writes nothing"
  task :check, [:flavor, :gem_ref] do |_t, args|
    extra = args[:gem_ref] ? %W[--ref #{args[:gem_ref]}] : []
    sh(*round_freeze_cmd(args[:flavor], %w[--check] + extra))
  end
end
