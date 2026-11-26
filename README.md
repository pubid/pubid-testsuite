# pubid-testsuite

Reference tests for PubID identifiers: the language-neutral, YAML-readable
test library every PubID implementation (Ruby gem, pubid-ts, ...) must pass,
plus the raw ground-truth text it derives from.

## Layout

- `reference-docs/{flavor}/identifiers/{pass,fail}/*.txt` - raw ground
  truth, byte-identical to the source corpus (one identifier per line;
  `#` lines are provenance comments; fail files encode each identifier as
  `#IDENT# Error: ...`).
- `tests/{flavor}/*.yaml` - derived test cases:
  - `{type}.yaml` canonical cases: `id`, `style`, `identifier` (the
    reference implementation's own canonical serialization, embedded as a
    mapping), `representations` (`human` = canonical spelling AND the
    canonical parse input; `urn` where emitted), `non_normalized_aliases`
    (`spelling` + `style` each exactly once), `roundtrip` only on exception.
  - `_debt.yaml` - ground-truth pass lines the reference cannot parse;
    visible, never dropped, never treated as expected failure.
  - `_negative.yaml` - inputs that must fail.

## PFS attestation

The five PFS-compiled flavors (`bsi_pfs`, `calconnect_pfs`, `cen_pfs`,
`doi_pfs`, `etsi_pfs` - pubid#790) attest first-class like every other
flavor. They ship no gem fixtures of their own: the row source is the
coded parent's fixture tree (`tools/fixture_source.rb` maps each `_pfs`
flavor to its parent), mirrored byte-identical at
`reference-docs/<flavor>`. Every recorded identity surface is the
compiled flavor's own parse, and its URNs are byte-identical with the
coded parent's; rows outside the composition surface sit in `_debt.yaml`
as the fail-closed rejection ledger. The per-flavor attestation ledger is
`tests/{flavor}/_status.yaml` (`attestation: pfs-identity`,
`source_flavor`, `unabsorbed_debt`).

## Contract rules

1. `identifier` is the reference serializer's own mapping (framework
   serialization; no hand-rolled models, no re-invented field names).
2. Language independence: no implementation class names anywhere; errors
   use the neutral enum (`parse_failed`, `invalid_argument`, ...). Each
   implementation maps its native exceptions onto the enum.
3. MECE: each fact appears exactly once; the canonical `human` rendering
   is the parse input for canonical cases (`input` exists only on debt,
   negatives, and aliases).
4. Completeness: every `reference-docs` line is accounted for as exactly
   one of: canonical case, alias, counted duplicate, debt, negative.
   The generator reconciles and reports this on every run.

## Tooling

Generation and execution live in the pubid gem (the reference
implementation): `rake conformance:generate[flavor]` and
`rake conformance:run`, targeting this repo (sibling checkout or
PUBID_TESTSUITE_PATH). Regeneration is deterministic; diffs are reviewed in
PRs. Data changes land here via PR; never edit `tests/` by hand without
regeneration parity.

## Validation

The corpus validates itself without the pubid gem:

    rake validate          # identity: corpus == reference-docs fixtures (tools/validate.rb)
    rake schema            # every case against schema/test.schema.yaml (tools/validate_schema.rb)
    rake all               # both

CI (`.github/workflows/validate.yml`) runs both on every push/PR.
Status: VALIDATION PASS 52/52 flavors; SCHEMA VALIDATION PASS (126,024 documents).

### One-command corpus round

`tools/round_freeze.rb` runs the whole round choreography for one flavor
against a pinned gem ref (default origin/main) - the lockstep sequence
(pair assembly, corpus:regen, rawCopy mirror, single-document negative
ledger, README marker bump, gates, provenance LAST) that was previously
hand-run per wave:

    rake 'round:freeze[iec,origin/main]'   # full round (write mode)
    rake 'round:freeze[iec,--check]'       # gates only; writes nothing
    rake 'round:check[iec]'                # same as --check

The gem is assembled into a dedicated `.round-freeze` clone at
`../pubid` (never the real sibling checkout) and probe-verified
in-process for which lib + `Pubid::VERSION` loads; dirty trees are
refused on both sides. The summary block the round PR body can quote
prints at the end; `ROUND_COMMIT=1` commits the round's explicit paths
(`tests/<flavor>`, `reference-docs/<flavor>`, `README.md`,
`tests/provenance.yaml` - never a sweep).

## Consumers

The pubid gem consumes this corpus as its conformance suite:
`PUBID_TESTSUITE_PATH` (or a sibling checkout) + `rake conformance:run`.
CLEAN flavors hard-gate; DIRTY flavors report as the known defect ledger
(`tests/{flavor}/_status.yaml`).

## By the numbers

<!-- counts:flavors=52 --> flavors · <!-- counts:cases=126024 --> cases.
The structure validator recomputes these and fails on drift.
