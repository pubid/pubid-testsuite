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
  #
  # '!' lines are directives, in two shapes:
  # - '!RAW!FIXED' (2-half): the classifier's fix annotation - FIXED is
  #   the identifier input, (RAW, FIXED) a pending normalization pair.
  # - '!CITATION!EXPECTED!URN' (triple, the gem #776 iho format): the
  #   citation is the raw source spelling, EXPECTED the rendered form
  #   (the identifier input), the URN the ATTESTED expectation - a
  #   representation of the identity, never an input (feeding it to the
  #   parser was the #124 debt incident). A 3-half directive whose last
  #   half is not a URN is NOT a triple: ieee alias chains carry a
  #   third spelling ('!A!B!C' with C another input, urn:-less).
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

    # A URN-bearing 3-half directive. The urn: guard keeps non-URN
    # 3-half lines (ieee alias chains) on the 2-half path unchanged.
    def triple?
      directive? && halves.size == 3 && halves.last.match?(/\Aurn:/i)
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
      return nil unless directive?

      triple? ? halves[1] : halves.last
    end

    # The attested URN expectation of a triple - recorded as the
    # corpus row's urn representation, never parsed as input.
    def attested_urn
      triple? ? halves.last : nil
    end

    def normalization_pair
      return nil unless directive?
      return { "from" => raw_half, "to" => fixed_half } if halves.size == 2
      # A triple only carries a pending normalization when the citation
      # differs from the expected render (from == to is no rule).
      return { "from" => raw_half, "to" => fixed_half } if triple? && raw_half != fixed_half

      nil
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
