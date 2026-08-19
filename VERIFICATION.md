# Verification record

Independent proof: tools/validate.rb (pure set arithmetic, gem not
loaded) certifies tests/ IDENTICAL to the original fixture lists:
every original line recoverable (canonical | alias | debt |
negative), nothing invented, reference-docs byte-identical.

```
amca         raw=80     pass=76     fail=4    | cases=39     canon=39     phantom=19   alias=26    debt=30    neg=4    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
ansi         raw=175    pass=175    fail=0    | cases=175    canon=175    phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
api          raw=196    pass=196    fail=0    | cases=192    canon=31     phantom=2    alias=163   debt=4     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
ashrae       raw=3631   pass=3619   fail=12   | cases=1756   canon=1755   phantom=1182 alias=3046  debt=0     neg=12   | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
asme         raw=931    pass=931    fail=0    | cases=621    canon=621    phantom=90   alias=200   debt=200   neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
astm         raw=260    pass=260    fail=0    | cases=248    canon=248    phantom=12   alias=12    debt=12    neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
bipm         raw=95     pass=90     fail=5    | cases=90     canon=90     phantom=0    alias=0     debt=0     neg=5    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
bsi          raw=1794   pass=1712   fail=82   | cases=854    canon=854    phantom=35   alias=36    debt=857   neg=82   | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
calconnect   raw=197    pass=189    fail=8    | cases=189    canon=189    phantom=0    alias=0     debt=0     neg=8    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
ccsds        raw=490    pass=490    fail=0    | cases=490    canon=490    phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
cen_cenelec  raw=150    pass=137    fail=13   | cases=72     canon=72     phantom=10   alias=10    debt=65    neg=13   | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
cie          raw=363    pass=363    fail=0    | cases=362    canon=362    phantom=0    alias=0     debt=1     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
csa          raw=1085   pass=998    fail=87   | cases=823    canon=823    phantom=63   alias=63    debt=175   neg=87   | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
doi          raw=8      pass=4      fail=4    | cases=3      canon=3      phantom=2    alias=3     debt=0     neg=4    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
easc         raw=0      pass=0      fail=0    | cases=0      canon=0      phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
ecma         raw=38     pass=38     fail=0    | cases=38     canon=38     phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
etsi         raw=24725  pass=24725  fail=0    | cases=24724  canon=24724  phantom=0    alias=0     debt=1     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
gb           raw=13     pass=8      fail=5    | cases=8      canon=8      phantom=0    alias=0     debt=0     neg=5    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
gost         raw=0      pass=0      fail=0    | cases=0      canon=0      phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
iana         raw=35     pass=30     fail=5    | cases=30     canon=30     phantom=0    alias=0     debt=0     neg=5    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
idf          raw=113    pass=113    fail=0    | cases=65     canon=65     phantom=44   alias=46    debt=46    neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
iec          raw=12624  pass=12466  fail=158  | cases=12329  canon=12329  phantom=56   alias=57    debt=136   neg=158  | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
ieee         raw=15178  pass=14304  fail=874  | cases=8245   canon=8244   phantom=5231 alias=5267  debt=6024  neg=874  | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
ietf         raw=60     pass=60     fail=0    | cases=60     canon=60     phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
iho          raw=131    pass=131    fail=0    | cases=131    canon=131    phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
isbn         raw=8      pass=4      fail=4    | cases=3      canon=3      phantom=1    alias=2     debt=0     neg=4    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
iso          raw=7762   pass=7712   fail=50   | cases=7623   canon=7623   phantom=142  alias=166   debt=65    neg=50   | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
itu          raw=2745   pass=2745   fail=0    | cases=2745   canon=2745   phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
jcgm         raw=29     pass=29     fail=0    | cases=29     canon=29     phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
jis          raw=10555  pass=10555  fail=0    | cases=10555  canon=10555  phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
nist         raw=23697  pass=23697  fail=0    | cases=19840  canon=19840  phantom=740  alias=2288  debt=2309  neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
oasis        raw=45     pass=45     fail=0    | cases=45     canon=45     phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
ogc          raw=94     pass=88     fail=6    | cases=88     canon=88     phantom=0    alias=0     debt=0     neg=6    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
oiml         raw=65     pass=65     fail=0    | cases=55     canon=55     phantom=2    alias=4     debt=8     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
omg          raw=10     pass=6      fail=4    | cases=6      canon=6      phantom=0    alias=0     debt=0     neg=4    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
plateau      raw=115    pass=115    fail=0    | cases=115    canon=115    phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
tgpp         raw=32     pass=32     fail=0    | cases=32     canon=32     phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
un           raw=10     pass=5      fail=5    | cases=4      canon=4      phantom=0    alias=1     debt=0     neg=5    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
w3c          raw=29     pass=29     fail=0    | cases=29     canon=29     phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
xsf          raw=49     pass=49     fail=0    | cases=49     canon=49     phantom=0    alias=0     debt=0     neg=0    | missP=0   missF=0   aliasForeign=0   debtForeign=0   negForeign=0   phantomBad=0  rawCopy=true | IDENTICAL=true
SKIPPED (raw-only, no tests dir): ans cga cgsb
VALIDATION PASS: 40 identical, 3 skipped raw-only, 0 FAILED
```

Export statuses (tools/export.rb):
```
amca         lines=76     cases=39     aliases=26    debt=30    neg=4    quar=0   divergent=2     | closes=true | verify: mismatch=16 schema_errors=0 CLEAN=false
ansi         lines=175    cases=175    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
api          lines=196    cases=192    aliases=163   debt=4     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=162 schema_errors=0 CLEAN=false
ashrae       lines=3619   cases=1756   aliases=3046  debt=0     neg=12   quar=0   divergent=38    | closes=true | verify: mismatch=29 schema_errors=0 CLEAN=false
asme         lines=931    cases=621    aliases=200   debt=200   neg=0    quar=0   divergent=1     | closes=true | verify: mismatch=15 schema_errors=0 CLEAN=false
astm         lines=260    cases=248    aliases=12    debt=12    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=3 schema_errors=0 CLEAN=false
bipm         lines=90     cases=90     aliases=0     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
bsi          lines=1712   cases=854    aliases=36    debt=1444  neg=82   quar=0   divergent=0     | closes=true | verify: mismatch=22 schema_errors=0 CLEAN=false
calconnect   lines=189    cases=189    aliases=0     debt=0     neg=8    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ccsds        lines=490    cases=490    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
cen_cenelec  lines=137    cases=72     aliases=10    debt=97    neg=13   quar=0   divergent=0     | closes=true | verify: mismatch=6 schema_errors=0 CLEAN=false
cie          lines=363    cases=362    aliases=0     debt=2     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
csa          lines=998    cases=823    aliases=63    debt=176   neg=87   quar=0   divergent=13    | closes=true | verify: mismatch=14 schema_errors=0 CLEAN=false
doi          lines=4      cases=3      aliases=3     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
easc         lines=0      cases=0      aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ecma         lines=38     cases=38     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
etsi         lines=24725  cases=24724  aliases=0     debt=1     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
gb           lines=8      cases=8      aliases=0     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
gost         lines=0      cases=0      aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iana         lines=30     cases=30     aliases=0     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
idf          lines=113    cases=65     aliases=46    debt=52    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iec          lines=12466  cases=12329  aliases=57    debt=138   neg=158  quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ieee         lines=14304  cases=8245   aliases=5267  debt=7953  neg=896  quar=0   divergent=2481  | closes=true | verify: mismatch=527 schema_errors=0 CLEAN=false
ietf         lines=60     cases=60     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iho          lines=131    cases=131    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
isbn         lines=4      cases=3      aliases=2     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iso          lines=7712   cases=7623   aliases=166   debt=66    neg=50   quar=0   divergent=17    | closes=true | verify: mismatch=4 schema_errors=0 CLEAN=false
itu          lines=2745   cases=2745   aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
jcgm         lines=29     cases=29     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
jis          lines=10555  cases=10555  aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
nist         lines=23697  cases=19840  aliases=2288  debt=2309  neg=0    quar=0   divergent=100   | closes=true | verify: mismatch=23 schema_errors=0 CLEAN=false
oasis        lines=45     cases=45     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ogc          lines=88     cases=88     aliases=0     debt=0     neg=6    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
oiml         lines=65     cases=55     aliases=4     debt=8     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
omg          lines=6      cases=6      aliases=0     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
plateau      lines=115    cases=115    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
tgpp         lines=32     cases=32     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
un           lines=5      cases=4      aliases=1     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
w3c          lines=29     cases=29     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
xsf          lines=49     cases=49     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
```
