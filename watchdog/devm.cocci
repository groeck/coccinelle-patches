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

@prb depends on probe@
identifier initfn, pdev;
expression e, e1;
position p;
@@
initfn(struct platform_device *pdev, ...) {
  <+...
- e = watchdog_register_device@p(e1)
+ e = devm_watchdog_register_device(&pdev->dev, e1)
  ...
?-watchdog_unregister_device(e1);
  ...+>
}

@rem depends on prb@
identifier remove.removefn;
expression e, e2;
@@
removefn(...) {
  <...
- watchdog_unregister_device(e);
?-watchdog_set_drvdata(e2, NULL);
  ...>
}

@script:python@
p << prb.p;
@@

print >> f, "%s:devm1:%s" % (p[0].file, p[0].line)
