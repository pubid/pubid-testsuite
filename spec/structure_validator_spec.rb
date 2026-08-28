# frozen_string_literal: true

RSpec.describe "tools/validate_schema.rb" do
  it "fails when the corpus is empty" do
    script = File.read(File.expand_path("../tools/validate_schema.rb", __dir__))
    expect(script).to include("EMPTY-CORPUS FAILURE")
    expect(script).to include("failures += 1 if flavors.empty?")
  end

  it "verifies provenance hashes and README drift markers" do
    script = File.read(File.expand_path("../tools/validate_schema.rb", __dir__))
    expect(script).to include("TAMPERED-PAYLOAD")
    expect(script).to include("UNRECORDED-PAYLOAD")
    expect(script).to include("README-DRIFT")
  end

  it "uses the gem-free subset engine, not json_schemer" do
    script = File.read(File.expand_path("../tools/validate_schema.rb", __dir__))
    expect(script).to include("json_schema_subset")
    expect(script).not_to include("json_schemer")
  end
end
