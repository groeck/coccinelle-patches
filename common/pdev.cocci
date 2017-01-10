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

@e depends on probe@
identifier probe.probefn;
identifier d;
identifier pdev;
@@

probefn(struct platform_device *pdev) {
  ...
  struct device *d = &pdev->dev;
  ...
}

@prb depends on probe@
identifier e.d;
identifier initfn;
identifier e.pdev;
identifier func;
expression list es;
position p;
@@

initfn@p(struct platform_device *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
<+...
- &pdev->dev
+ d
...+> }

@script:python@
p << prb.p;
@@

print >> f, "%s:pdev1:%s" % (p[0].file, p[0].line)