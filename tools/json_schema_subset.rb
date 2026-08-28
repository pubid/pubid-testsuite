# frozen_string_literal: true

# Gem-free JSON-Schema subset validator (plurimath-testsuite parity).
# Implements exactly the keywords schema/test.schema.yaml uses and fails
# CLOSED: any keyword it does not implement raises, so the schema can
# never silently under-validate. Runs with plain `ruby`, no bundle.

module JsonSchemaSubset
  ANNOTATIONS = %w[$schema $id title description].freeze

  class UnsupportedKeyword < StandardError; end

  module_function

  # @return [Array<String>] error messages; empty when valid
  def validate(schema, instance, path = "$")
    raise UnsupportedKeyword, "schema must be a Hash at #{path}" unless schema.is_a?(Hash)

    errors = []
    schema.each do |keyword, value|
      case keyword
      when *ANNOTATIONS then next
      when "type" then check_type(value, instance, path, errors)
      when "enum" then errors << "#{path}: not in enum" unless value.include?(instance)
      when "const" then errors << "#{path}: != const #{value.inspect}" unless instance == value
      when "pattern"
        return_pattern(value, path) # compile early, or raise
        errors << "#{path}: does not match #{value.inspect}" unless instance.is_a?(String) && regexp(value).match?(instance)
      when "maxLength"
        if instance.is_a?(String) && instance.length > value
          errors << "#{path}: longer than maxLength #{value}"
        end
      when "required"
        value.each do |key|
          errors << "#{path}: missing required '#{key}'" if instance.is_a?(Hash) && !instance.key?(key)
        end
      when "properties"
        next unless instance.is_a?(Hash)
        value.each do |key, subschema|
          next unless instance.key?(key)
          errors.concat(validate(subschema, instance[key], "#{path}.#{key}"))
        end
      when "additionalProperties"
        next unless instance.is_a?(Hash) && value == false
        declared = schema.fetch("properties", {}).keys
        instance.each_key do |key|
          errors << "#{path}: undeclared property '#{key}'" unless declared.include?(key)
        end
      when "items"
        if instance.is_a?(Array)
          instance.each_with_index do |el, i|
            errors.concat(validate(value, el, "#{path}[#{i}]"))
          end
        end
      when "anyOf"
        ok = value.any? { |sub| validate(sub, instance, path).empty? }
        errors << "#{path}: satisfies none of anyOf" unless ok
      else
        raise UnsupportedKeyword, "#{path}: unimplemented keyword #{keyword.inspect} " \
                                  "(fail-closed: extend the subset or simplify the schema)"
      end
    end
    errors
  end

  def check_type(types, instance, path, errors)
    Array(types).each do |t|
      case t
      when "object" then return if instance.is_a?(Hash)
      when "array" then return if instance.is_a?(Array)
      when "string" then return if instance.is_a?(String)
      when "integer" then return if instance.is_a?(Integer)
      when "number" then return if instance.is_a?(Numeric)
      when "boolean" then return if [true, false].include?(instance)
      when "null" then return if instance.nil?
      else raise UnsupportedKeyword, "#{path}: unknown type #{t.inspect}"
      end
    end
    errors << "#{path}: is #{type_name(instance)}, expected #{Array(types).join('/')}"
  end

  def type_name(instance)
    { Hash => "object", Array => "array", String => "string", Integer => "integer",
      Float => "number", TrueClass => "boolean", FalseClass => "boolean",
      NilClass => "null" }.fetch(instance.class, instance.class.name)
  end

  def return_pattern(value, path)
    regexp(value)
  rescue RegexpError => e
    raise UnsupportedKeyword, "#{path}: bad pattern #{value.inspect} (#{e.message})"
  end

  # JSON patterns are ECMA-262; ours are plain ASCII classes, so Ruby
  # Regexp is a faithful translation. Anchors ^ $ keep their meaning.
  def regexp(pattern)
    Regexp.new(pattern)
  end
end
