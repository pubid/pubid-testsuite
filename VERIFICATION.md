# Verification record

Real per-flavor status from tools/export.rb (ALL 40 registered flavors).
CLEAN = reconciliation closes + zero re-verify mismatches + zero schema
errors. DIRTY = known reference-implementation defects (the ledger):
fix the gem, re-run tools/export.rb, the flavor goes CLEAN.

```
amca         lines=82     cases=39     aliases=26    debt=38    neg=6    quar=0   divergent=2     | closes=true | verify: mismatch=18 schema_errors=0 CLEAN=false
ansi         lines=179    cases=175    aliases=0     debt=4     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
api          lines=223    cases=192    aliases=163   debt=39    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=323 schema_errors=1 CLEAN=false
ashrae       lines=3640   cases=1756   aliases=3046  debt=32    neg=18   quar=0   divergent=38    | closes=true | verify: mismatch=77 schema_errors=0 CLEAN=false
asme         lines=944    cases=621    aliases=200   debt=213   neg=0    quar=0   divergent=1     | closes=true | verify: mismatch=16 schema_errors=0 CLEAN=false
astm         lines=297    cases=248    aliases=12    debt=65    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=3 schema_errors=0 CLEAN=false
bipm         lines=133    cases=90     aliases=0     debt=47    neg=9    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
bsi          lines=1796   cases=854    aliases=36    debt=1558  neg=84   quar=0   divergent=0     | closes=true | verify: mismatch=23 schema_errors=0 CLEAN=false
calconnect   lines=191    cases=189    aliases=0     debt=2     neg=10   quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ccsds        lines=495    cases=490    aliases=0     debt=6     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
cen_cenelec  lines=172    cases=72     aliases=10    debt=143   neg=15   quar=0   divergent=0     | closes=true | verify: mismatch=6 schema_errors=0 CLEAN=false
cie          lines=411    cases=362    aliases=0     debt=61    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
csa          lines=1050   cases=823    aliases=63    debt=236   neg=95   quar=0   divergent=13    | closes=true | verify: mismatch=14 schema_errors=0 CLEAN=false
doi          lines=4      cases=3      aliases=3     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
easc         lines=0      cases=0      aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ecma         lines=44     cases=38     aliases=0     debt=8     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
etsi         lines=24735  cases=24724  aliases=0     debt=13    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
gb           lines=10     cases=8      aliases=0     debt=2     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
gost         lines=0      cases=0      aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iana         lines=36     cases=30     aliases=0     debt=6     neg=12   quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
idf          lines=146    cases=65     aliases=46    debt=88    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iec          lines=12547  cases=12329  aliases=57    debt=297   neg=164  quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ieee         lines=14322  cases=8247   aliases=5267  debt=7987  neg=900  quar=0   divergent=2483  | closes=true | verify: mismatch=7778 schema_errors=0 CLEAN=false
ietf         lines=68     cases=60     aliases=0     debt=10    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iho          lines=131    cases=131    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
isbn         lines=4      cases=3      aliases=2     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iso          lines=7728   cases=7623   aliases=166   debt=95    neg=56   quar=0   divergent=17    | closes=true | verify: mismatch=86 schema_errors=0 CLEAN=false
itu          lines=2777   cases=2745   aliases=0     debt=32    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
jcgm         lines=45     cases=29     aliases=0     debt=18    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
jis          lines=10559  cases=10555  aliases=0     debt=4     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
nist         lines=23731  cases=19846  aliases=2290  debt=2363  neg=0    quar=0   divergent=104   | closes=true | verify: mismatch=348 schema_errors=0 CLEAN=false
oasis        lines=64     cases=45     aliases=0     debt=19    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ogc          lines=93     cases=88     aliases=0     debt=5     neg=8    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
oiml         lines=75     cases=55     aliases=4     debt=26    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
omg          lines=6      cases=6      aliases=0     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
plateau      lines=120    cases=115    aliases=0     debt=6     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
tgpp         lines=37     cases=32     aliases=0     debt=6     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
un           lines=5      cases=4      aliases=1     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
w3c          lines=39     cases=29     aliases=0     debt=10    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
xsf          lines=52     cases=49     aliases=0     debt=3     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
```

Tallies: 29 CLEAN, 11 DIRTY.
Per-flavor machine-readable status: tests/{flavor}/_status.yaml
