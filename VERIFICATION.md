# Verification record

Independent proof (tools/validate.rb, pure set arithmetic, gem not
loaded): tests/ identical to the original fixture lists. Clean/dirty
from tools/export.rb.

```
../pubid-tests/tools/validate.rb:49:in 'block (2 levels) in Validator.plain_lines': undefined method 'start_with!' for an instance of String (NoMethodError)

        if line.start_with!("!")
               ^^^^^^^^^^^^
Did you mean?  start_with?
	from ../pubid-tests/tools/validate.rb:46:in 'Array#each'
	from ../pubid-tests/tools/validate.rb:46:in 'Enumerable#flat_map'
	from ../pubid-tests/tools/validate.rb:46:in 'block in Validator.plain_lines'
	from ../pubid-tests/tools/validate.rb:45:in 'Array#each'
	from ../pubid-tests/tools/validate.rb:45:in 'Enumerable#flat_map'
	from ../pubid-tests/tools/validate.rb:45:in 'Validator.plain_lines'
	from ../pubid-tests/tools/validate.rb:125:in 'Validator.validate'
	from ../pubid-tests/tools/validate.rb:174:in 'block in <main>'
	from ../pubid-tests/tools/validate.rb:172:in 'Array#map'
	from ../pubid-tests/tools/validate.rb:172:in '<main>'
```

## Export results
```
amca         lines=69     cases=39     aliases=28    debt=18    neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=16 schema_errors=0 CLEAN=false
ansi         lines=175    cases=175    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
api          lines=197    cases=192    aliases=164   debt=3     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=162 schema_errors=0 CLEAN=false
ashrae       lines=3251   cases=1756   aliases=1528  debt=297   neg=12   quar=0   divergent=1     | closes=true | verify: mismatch=29 schema_errors=0 CLEAN=false
asme         lines=821    cases=621    aliases=200   debt=25    neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=15 schema_errors=0 CLEAN=false
astm         lines=263    cases=248    aliases=12    debt=6     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=3 schema_errors=0 CLEAN=false
bipm         lines=93     cases=90     aliases=0     debt=3     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
bsi          lines=1663   cases=874    aliases=36    debt=1411  neg=82   quar=0   divergent=0     | closes=true | verify: mismatch=22 schema_errors=0 CLEAN=false
calconnect   lines=189    cases=189    aliases=0     debt=0     neg=8    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ccsds        lines=490    cases=490    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
cen_cenelec  lines=131    cases=72     aliases=10    debt=93    neg=13   quar=0   divergent=0     | closes=true | verify: mismatch=6 schema_errors=0 CLEAN=false
cie          lines=365    cases=365    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
csa          lines=977    cases=829    aliases=76    debt=109   neg=87   quar=0   divergent=0     | closes=true | verify: mismatch=14 schema_errors=0 CLEAN=false
doi          lines=4      cases=3      aliases=3     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
easc         lines=0      cases=0      aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ecma         lines=38     cases=38     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
etsi         lines=24724  cases=24724  aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
gb           lines=8      cases=8      aliases=0     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
gost         lines=0      cases=0      aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iana         lines=30     cases=30     aliases=0     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
idf          lines=111    cases=65     aliases=46    debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iec          lines=12465  cases=12335  aliases=57    debt=131   neg=158  quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ieee         lines=13833  cases=9384   aliases=6721  debt=1497  neg=896  quar=0   divergent=2394  | closes=true | verify: mismatch=993 schema_errors=0 CLEAN=false
ietf         lines=60     cases=60     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iho          lines=131    cases=131    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
isbn         lines=4      cases=3      aliases=2     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
iso          lines=7698   cases=7623   aliases=167   debt=4     neg=50   quar=0   divergent=4     | closes=true | verify: mismatch=4 schema_errors=0 CLEAN=false
itu          lines=2746   cases=2745   aliases=0     debt=1     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
jcgm         lines=29     cases=29     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
jis          lines=10555  cases=10555  aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
nist         lines=22140  cases=19849  aliases=2306  debt=8     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=23 schema_errors=0 CLEAN=false
oasis        lines=45     cases=45     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
ogc          lines=88     cases=88     aliases=0     debt=0     neg=6    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
oiml         lines=62     cases=58     aliases=4     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
omg          lines=6      cases=6      aliases=0     debt=0     neg=4    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
plateau      lines=115    cases=115    aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
tgpp         lines=32     cases=32     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
un           lines=5      cases=4      aliases=1     debt=0     neg=5    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
w3c          lines=29     cases=29     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
xsf          lines=49     cases=49     aliases=0     debt=0     neg=0    quar=0   divergent=0     | closes=true | verify: mismatch=0 schema_errors=0 CLEAN=true
```
