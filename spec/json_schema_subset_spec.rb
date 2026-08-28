# frozen_string_literal: true

RSpec.describe JsonSchemaSubset do
  it "accepts annotations without checking them" do
    expect(described_class.validate({ "$schema" => "x", "title" => "t" }, "anything")).to be_empty
  end

  it "checks type" do
    expect(described_class.validate({ "type" => "object" }, {})).to be_empty
    expect(described_class.validate({ "type" => "object" }, [])).not_to be_empty
  end

  it "checks enum and const" do
    expect(described_class.validate({ "enum" => %w[a b] }, "a")).to be_empty
    expect(described_class.validate({ "enum" => %w[a b] }, "c")).not_to be_empty
    expect(described_class.validate({ "const" => false }, false)).to be_empty
    expect(described_class.validate({ "const" => false }, true)).not_to be_empty
  end

  it "checks pattern and maxLength" do
    expect(described_class.validate({ "pattern" => "^a+$" }, "aa")).to be_empty
    expect(described_class.validate({ "pattern" => "^a+$" }, "ab")).not_to be_empty
    expect(described_class.validate({ "maxLength" => 2 }, "ab")).to be_empty
    expect(described_class.validate({ "maxLength" => 2 }, "abc")).not_to be_empty
  end

  it "checks required, properties and additionalProperties" do
    schema = { "type" => "object", "required" => %w[id],
               "properties" => { "id" => { "type" => "string" } },
               "additionalProperties" => false }
    expect(described_class.validate(schema, { "id" => "x" })).to be_empty
    expect(described_class.validate(schema, {})).not_to be_empty
    expect(described_class.validate(schema, { "id" => "x", "rogue" => 1 })).not_to be_empty
  end

  it "checks items and anyOf" do
    expect(described_class.validate({ "items" => { "type" => "integer" } }, [1, 2])).to be_empty
    expect(described_class.validate({ "items" => { "type" => "integer" } }, [1, "x"])).not_to be_empty
    any = { "anyOf" => [{ "required" => %w[a] }, { "required" => %w[b] }] }
    expect(described_class.validate(any, { "a" => 1 })).to be_empty
    expect(described_class.validate(any, { "c" => 1 })).not_to be_empty
  end

  it "fails closed on an unimplemented keyword" do
    expect { described_class.validate({ "minLength" => 1 }, "x") }
      .to raise_error(JsonSchemaSubset::UnsupportedKeyword, /minLength/)
  end
end
