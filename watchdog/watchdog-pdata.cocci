virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@probe@
identifier p, probefn;
declarer name module_platform_driver_probe;
@@
(
  module_platform_driver_probe(p, probefn);
|
  struct platform_driver p = {
    .probe = probefn,
  };
)

@remove@
identifier probe.p, removefn;
@@

  struct platform_driver p = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };

@used depends on probe@
identifier fn != probe.probefn;
@@

fn(...) {
 <+...
(
platform_get_drvdata(...)
|
dev_get_drvdata(...)
)
 ...+>
}

@r1 depends on !used@
identifier probe.probefn;
position p;
@@

probefn(...) {
<...
- platform_set_drvdata@p(...);
...> }

@r2 depends on !used@
identifier probe.probefn;
position p;
@@

probefn(...) {
<...
- dev_set_drvdata@p(...);
...> }

@script:python@
p << r1.p;
@@

print >> f, "%s:p1:%s" % (p[0].file, p[0].line)

@script:python@
p << r2.p;
@@

print >> f, "%s:p2:%s" % (p[0].file, p[0].line)
