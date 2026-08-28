# frozen_string_literal: true

module PubidTests
  # Domain model for one raw line from a reference-doc fixture file.
  # Decoding semantics live HERE and nowhere else.
  #
  # '#' lines are comments in pass/full files. Only fail files wrap
  # data as '#ID# Error...' - there (and only there) the input between
  # the first two '#' segments is data. Prose comments that merely
  # contain a '#' (issue refs like pubid/pubid#152, method refs like
  # Builder#split_draft_version) are comments, never data.
  class FixtureLine
    attr_reader :raw, :flavor, :category

    def initialize(raw, flavor:, category:)
      @raw = raw.strip
      @flavor = flavor
      @category = category
    end

    def empty?
      raw.empty?
    end

    def comment?
      return false unless raw.start_with?("#")

      wrapped_data? ? false : true
    end

    def directive?
      raw.start_with?("!")
    end

    def identifier
      return nil if empty? || comment?
      return fixed_half if directive?

      raw.start_with?("#") ? unwrap : raw
    end

    def raw_half
      directive? ? halves.first : nil
    end

    def fixed_half
      directive? ? halves.last : nil
    end

    def normalization_pair
      return nil unless directive? && halves.size == 2

      { "from" => raw_half, "to" => fixed_half }
    end

    private

    def wrapped_data?
      category == :fail && raw.split("#").size >= 3
    end

    def halves
      @halves ||= raw.split("!").map(&:strip).reject(&:empty?)
    end

    def unwrap
      raw.sub(/\A#/, "").split("#", 2).first.to_s.strip.then do |input|
        input.empty? ? nil : input
      end
    end
  end
end
