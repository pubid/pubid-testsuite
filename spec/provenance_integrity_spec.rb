# frozen_string_literal: true

RSpec.describe "provenance manifest" do
  let(:manifest) { YAML.safe_load_file(File.expand_path("../tests/provenance.yaml", __dir__)) }

  it "exists and stamps its schema" do
    expect(manifest["schema"]).to eq("pubid-testsuite/provenance/1")
  end

  it "records the oracle gem and the generator" do
    expect(manifest["oracle"]["gem"]).to eq("pubid")
    expect(manifest["generator"]["exporter_sha256"]).to match(/\A[0-9a-f]{64}\z/)
  end

  it "hashes every generated payload with sha256 + bytes" do
    expect(manifest["payloads"]).not_to be_empty
    manifest["payloads"].each do |p|
      expect(p["sha256"]).to match(/\A[0-9a-f]{64}\z/)
      expect(p["bytes"]).to be_a(Integer)
    end
  end

  it "keeps curated _status.yaml files out of the hashed set" do
    expect(manifest["payloads"]).to all(satisfy { |p| !p["path"].end_with?("_status.yaml") })
    expect(manifest["curated"]).to all(satisfy { |p| p["path"].end_with?("_status.yaml") })
  end
end
