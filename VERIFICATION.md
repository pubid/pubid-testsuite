# Verification record

Real per-flavor status from tools/export.rb. CLEAN = closes + 0 mismatches
+ 0 schema errors. DIRTY = reference defect ledger. Machine status:
tests/{flavor}/_status.yaml.

## Clean flavors (regenerated 2026-08-19)
```
```

## Dirty flavors (defect ledger)
```
amca         lines=82     cases=39     aliases=26    debt=38    neg=6    quar=0   divergent=2     | closes=true | verify: mismatch=18 schema_errors=0 CLEAN=false
api          lines=223    cases=192    aliases=163   debt=39    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=323 schema_errors=0 CLEAN=false
ashrae       lines=3640   cases=1756   aliases=3046  debt=32    neg=18   quar=0   divergent=38    | closes=true | verify: mismatch=77 schema_errors=0 CLEAN=false
asme         lines=944    cases=621    aliases=200   debt=213   neg=0    quar=0   divergent=1     | closes=true | verify: mismatch=16 schema_errors=0 CLEAN=false
astm         lines=297    cases=248    aliases=12    debt=65    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=3 schema_errors=0 CLEAN=false
bsi          lines=1796   cases=854    aliases=36    debt=1558  neg=84   quar=0   divergent=0     | closes=true | verify: mismatch=23 schema_errors=0 CLEAN=false
cen_cenelec  lines=172    cases=72     aliases=10    debt=143   neg=15   quar=0   divergent=0     | closes=true | verify: mismatch=6 schema_errors=0 CLEAN=false
csa          lines=1050   cases=823    aliases=63    debt=236   neg=95   quar=0   divergent=13    | closes=true | verify: mismatch=14 schema_errors=0 CLEAN=false
ieee         lines=14322  cases=8245   aliases=5267  debt=7987  neg=900  quar=0   divergent=2481  | closes=true | verify: mismatch=7778 schema_errors=0 CLEAN=false
iso          lines=7728   cases=7623   aliases=166   debt=95    neg=56   quar=0   divergent=17    | closes=true | verify: mismatch=86 schema_errors=0 CLEAN=false
nist         lines=23731  cases=19842  aliases=2290  debt=2363  neg=0    quar=0   divergent=100   | closes=true | verify: mismatch=348 schema_errors=0 CLEAN=false
```
