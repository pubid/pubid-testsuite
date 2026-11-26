# frozen_string_literal: true

module PubidTests
  # The fixture row-source mapping for the PFS-compiled flavors
  # (pubid/pubid-testsuite#129, umbrella pubid/pubid#790).
  #
  # A `*_pfs` flavor ships no gem fixtures of its own: it is the
  # PFS-compiled twin of a coded flavor, and its corpus derives from the
  # CODED parent's fixtures (the same raw rows the gem's parity
  # harnesses measure). The rawCopy twin still follows the layout
  # convention - reference-docs/<pfs-flavor> is a byte-identical mirror
  # of spec/fixtures/<parent> - so the exporter, the validator and the
  # round tooling all keep treating the flavor like any other; only the
  # GEM-SIDE source of the mirror is the parent's tree. The rows attest
  # the identity explicitly: every recorded identity surface is the
  # compiled flavor's own parse, whose URNs are byte-identical with the
  # coded parent's.
  module FixtureSource
    # pfs flavor => the coded flavor whose fixtures are its row source.
    PFS_PARENTS = {
      "bsi_pfs" => "bsi",
      "calconnect_pfs" => "calconnect",
      "cen_pfs" => "cen_cenelec",
      "doi_pfs" => "doi",
      "etsi_pfs" => "etsi",
    }.freeze

    class << self
      # The gem fixture flavor a flavor's rawCopy twin mirrors:
      # spec/fixtures/<source>. Identity for every coded flavor; the
      # coded parent for every _pfs flavor.
      def source_flavor(flavor)
        PFS_PARENTS.fetch(flavor, flavor)
      end

      # True when the flavor is a PFS-compiled one (its rows attest
      # identity with a coded parent).
      def pfs_flavor?(flavor)
        PFS_PARENTS.key?(flavor)
      end
    end
  end
end
