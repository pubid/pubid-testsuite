# Verification record

Initial commit's "verified" claim was VACUOUS (tooling path bug ran
zero cases). This file records the REAL full-migration status.
Every number below is tools/export.rb output, unedited.

```
amca  lines=108    cases=59     aliases=26   dups=0     phantom=19   debt=38   neg=6    quar=0   | closes=false | verify: cases=39 aliases=12 mismatch=20 schema_errors=0 CLEAN=false
api   lines=426    cases=382    aliases=324  dups=0     phantom=324  debt=39   neg=0    quar=0   | closes=false | verify: cases=382 aliases=1 mismatch=323 schema_errors=1 CLEAN=false
ashrae lines=4233   cases=3709   aliases=3046 dups=8     phantom=2563 debt=32   neg=18   quar=0   | closes=false | verify: cases=1981 aliases=1370 mismatch=283 schema_errors=0 CLEAN=false
asme  lines=1475   cases=1152   aliases=200  dups=0     phantom=90   debt=213  neg=0    quar=0   | closes=true | verify: cases=1152 aliases=175 mismatch=17 schema_errors=0 CLEAN=false
astm  lines=550    cases=484    aliases=12   dups=1     phantom=12   debt=65   neg=0    quar=0   | closes=true | verify: cases=484 aliases=9 mismatch=3 schema_errors=0 CLEAN=false
bsi   lines=3243   cases=1684   aliases=39   dups=1     phantom=39   debt=1558 neg=84   quar=0   | closes=true | verify: cases=934 aliases=17 mismatch=24 schema_errors=0 CLEAN=false
cen_cenelec lines=282    cases=134    aliases=10   dups=4     phantom=10   debt=143  neg=15   quar=0   | closes=false | verify: cases=134 aliases=4 mismatch=6 schema_errors=0 CLEAN=false
csa   lines=1792   cases=1552   aliases=63   dups=4     phantom=63   debt=236  neg=95   quar=0   | closes=true | verify: cases=1552 aliases=62 mismatch=27 schema_errors=0 CLEAN=false
doi   lines=4      cases=4      aliases=3    dups=0     phantom=3    debt=0    neg=4    quar=0   | closes=true | verify: cases=4 aliases=3 mismatch=0 schema_errors=0 CLEAN=true
idf   lines=180    cases=92     aliases=46   dups=0     phantom=46   debt=88   neg=0    quar=0   | closes=true | verify: cases=75 aliases=46 mismatch=0 schema_errors=0 CLEAN=true
iec   lines=39289  cases=37685  aliases=121  dups=1306  phantom=120  debt=297  neg=164  quar=0   | closes=true | verify: cases=37685 aliases=121 mismatch=0 schema_errors=7047 CLEAN=false
ieee  lines=29347  cases=20435  aliases=12139 dups=0     phantom=12113 debt=7987 neg=900  quar=0   | closes=false | verify: cases=20435 aliases=12105 mismatch=14296 schema_errors=0 CLEAN=false
ietf  lines=70     cases=60     aliases=0    dups=0     phantom=0    debt=10   neg=0    quar=0   | closes=true | verify: cases=60 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
iho   lines=131    cases=131    aliases=0    dups=0     phantom=0    debt=0    neg=0    quar=0   | closes=true | verify: cases=131 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
isbn  lines=4      cases=3      aliases=2    dups=0     phantom=1    debt=0    neg=4    quar=0   | closes=true | verify: cases=3 aliases=2 mismatch=0 schema_errors=0 CLEAN=true
iso   lines=22909  cases=22759  aliases=346  dups=10    phantom=301  debt=95   neg=56   quar=0   | closes=true | verify: cases=22759 aliases=346 mismatch=86 schema_errors=0 CLEAN=false
itu   lines=4818   cases=4786   aliases=0    dups=0     phantom=0    debt=32   neg=0    quar=0   | closes=true | verify: cases=2745 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
jcgm  lines=77     cases=59     aliases=0    dups=0     phantom=0    debt=18   neg=0    quar=0   | closes=true | verify: cases=34 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
jis   lines=21114  cases=21110  aliases=0    dups=0     phantom=0    debt=4    neg=0    quar=0   | closes=true | verify: cases=21110 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
nist  lines=61638  cases=59022  aliases=2919 dups=227   phantom=2893 debt=2363 neg=0    quar=0   | closes=true | verify: cases=59022 aliases=2913 mismatch=348 schema_errors=0 CLEAN=false
oasis lines=64     cases=45     aliases=0    dups=0     phantom=0    debt=19   neg=0    quar=0   | closes=true | verify: cases=45 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
ogc   lines=93     cases=88     aliases=0    dups=0     phantom=0    debt=5    neg=8    quar=0   | closes=true | verify: cases=88 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
oiml  lines=136    cases=108    aliases=4    dups=0     phantom=2    debt=26   neg=0    quar=0   | closes=true | verify: cases=108 aliases=4 mismatch=0 schema_errors=0 CLEAN=true
omg   lines=6      cases=6      aliases=0    dups=0     phantom=0    debt=0    neg=4    quar=0   | closes=true | verify: cases=6 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
plateau lines=236    cases=230    aliases=0    dups=0     phantom=0    debt=6    neg=0    quar=0   | closes=true | verify: cases=230 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
tgpp  lines=38     cases=32     aliases=0    dups=0     phantom=0    debt=6    neg=0    quar=0   | closes=true | verify: cases=32 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
un    lines=5      cases=4      aliases=1    dups=0     phantom=0    debt=0    neg=5    quar=0   | closes=true | verify: cases=4 aliases=1 mismatch=0 schema_errors=0 CLEAN=true
w3c   lines=39     cases=29     aliases=0    dups=0     phantom=0    debt=10   neg=0    quar=0   | closes=true | verify: cases=29 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
xsf   lines=52     cases=49     aliases=0    dups=0     phantom=0    debt=3    neg=0    quar=0   | closes=true | verify: cases=49 aliases=0 mismatch=0 schema_errors=0 CLEAN=true
```

## Flavors skipped (fixtures exist, no registered reference flavor):
ans, cga, cgsb - raw text preserved under reference-docs/, no tests generated.

## Reading the numbers

- CLEAN = reconciliation closes AND zero mismatches AND zero schema
  errors: every ground-truth line accounted for and every case/alias
  re-verifies through the reference implementation.
- DIRTY = genuine reference-implementation defects surfaced by the
  corpus (rendered forms that do not re-parse; normalization
  asymmetries; schema deviations). These cases remain in the corpus
  as the defect ledger - fix the gem, re-export, they go CLEAN.
