# pubid-tests

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
PUBID_TESTS_PATH). Regeneration is deterministic; diffs are reviewed in
PRs. Data changes land here via PR; never edit `tests/` by hand without
regeneration parity.

## Validation

The corpus validates itself without the pubid gem:

    rake validate          # identity: corpus == reference-docs fixtures (tools/validate.rb)
    rake schema            # every case against schema/test.schema.yaml (tools/validate_schema.rb)
    rake all               # both

CI (`.github/workflows/validate.yml`) runs both on every push/PR.
Status: VALIDATION PASS 40/40 flavors; SCHEMA VALIDATION PASS (94,095 documents).

## Consumers

The pubid gem consumes this corpus as its conformance suite:
`PUBID_TESTS_PATH` (or a sibling checkout) + `rake conformance:run`.
CLEAN flavors hard-gate; DIRTY flavors report as the known defect ledger
(`tests/{flavor}/_status.yaml`).

## By the numbers

<!-- counts:flavors=40 --> flavors · <!-- counts:cases=94089 --> cases.
The structure validator recomputes these and fails on drift.
