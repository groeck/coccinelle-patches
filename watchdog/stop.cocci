virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@probe@
identifier p, probefn;
declarer name module_platform_driver_probe;
position pos;
@@
(
  module_platform_driver_probe(p, probefn@pos);
|
  struct platform_driver p = {
    .probe = probefn@pos,
  };
)

@remove@
identifier probe.p, removefn;
@@

  struct platform_driver p = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };

@stop@
identifier ops, stopfn;
@@

  struct watchdog_ops ops = {
    .stop = stopfn,
  };

@sstop@
identifier stop.stopfn, remove.removefn;
identifier i;
@@

  removefn(...) {
  <+...
(
  stopfn(...);
|
  i = stopfn(...);
)
  ...+>
  }

@wreg depends on probe@
expression e, e1;
position p;

@@

e = watchdog_register_device@p(..., e1);

@prb depends on probe && remove && sstop@
expression e, wreg.e1;
position wreg.p;
@@

+ watchdog_stop_on_unregister(e1);
  e = watchdog_register_device@p(e1);

@wreg2 depends on probe@
expression e, e1;
position p;
@@

e = devm_watchdog_register_device@p(..., e1);

@prb2 depends on probe && remove && sstop@
expression e, wreg2.e1;
position wreg2.p;
@@

+ watchdog_stop_on_unregister(e1);
  e = devm_watchdog_register_device@p(..., e1);

@rstop depends on prb || prb2@
identifier pdev, remove.removefn, stop.stopfn;
identifier i;
@@

removefn(struct platform_device *pdev)
{
  <...
(
- stopfn(...);
|
- i = stopfn(...);
)
  ...>
}

@script:python depends on prb || prb2@
p << probe.pos;
@@

print >> f, "%s:stop1:%s" % (p[0].file, p[0].line)
