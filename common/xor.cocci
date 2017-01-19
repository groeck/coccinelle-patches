virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@xor@
expression e1, e2;
statement S;
position p;
@@
  if@p (
(
- (!e1 && e2) || (e1 && !e2)
|
- (e1 && !e2) || (!e1 && e2)
)
+ !e1 ^ !e2
  ) S

@script:python@
p << xor.p;
@@

print >> f, "%s:xor:%s" % (p[0].file, p[0].line)
