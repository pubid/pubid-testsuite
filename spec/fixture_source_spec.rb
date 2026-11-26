# frozen_string_literal: true

# Tool-guard specs for tools/fixture_source.rb - the pfs row-source
# mapping (pubid/pubid-testsuite#129, umbrella pubid#790): a `*_pfs`
# flavor's corpus derives from the coded parent's gem fixtures, and the
# round tooling (round_freeze) and the validator (validate.rb) both
# resolve the rawCopy source through this one table.

require_relative "../tools/fixture_source"

RSpec.describe PubidTests::FixtureSource do
  it "maps exactly the five _pfs flavors of issue #129" do
    expect(described_class::PFS_PARENTS.keys).to contain_exactly(
      "bsi_pfs", "calconnect_pfs", "cen_pfs", "doi_pfs", "etsi_pfs"
    )
  end

  it "maps each _pfs flavor to its coded parent's fixture tree" do
    expect(described_class.source_flavor("bsi_pfs")).to eq("bsi")
    expect(described_class.source_flavor("calconnect_pfs"))
      .to eq("calconnect")
    expect(described_class.source_flavor("cen_pfs")).to eq("cen_cenelec")
    expect(described_class.source_flavor("doi_pfs")).to eq("doi")
    expect(described_class.source_flavor("etsi_pfs")).to eq("etsi")
  end

  it "keeps a coded flavor its own row source" do
    expect(described_class.source_flavor("bsi")).to eq("bsi")
    expect(described_class.source_flavor("cen_cenelec")).to eq("cen_cenelec")
    expect(described_class.pfs_flavor?("bsi")).to be(false)
    expect(described_class.pfs_flavor?("wmo")).to be(false)
  end
end
