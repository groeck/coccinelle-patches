virtual patch

@initialize:python@
@@

f = open('watchdog-clkreturn.log', 'w')

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

@r depends on probe@
identifier initfn;
expression e;
position p;
identifier rv;
@@
initfn(...)
{
  ...
  int rv;
<+...
  clk_prepare_enable@p(e);
...+>
}

@prb@
identifier r.initfn, pdev;
identifier r.rv;
expression e1;
position r.p;
@@

initfn(struct platform_device *pdev, ...)
{
  <+...
- clk_prepare_enable@p(e1);
+ rv = clk_prepare_enable(e1);
+ if (rv)
+     return rv;
  ...+>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:c3:%s" % (p[0].file, p[0].line)
