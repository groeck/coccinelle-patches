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

@shutdown@
identifier probe.p, shutdownfn;
position pos;
@@

  struct platform_driver p = {
    .shutdown = \(__exit_p(shutdownfn)\|shutdownfn\),
  };

@stop@
identifier ops, stopfn;
@@

  struct watchdog_ops ops = {
    .stop = stopfn,
  };

@sstop@
identifier stop.stopfn, shutdown.shutdownfn;
@@

  shutdownfn(...) {
  <+...
  stopfn(...);
  ...+>
  }

@wreg depends on probe@
expression e, e1;
position p;

@@

e = watchdog_register_device@p(..., e1);

@prb depends on probe && shutdown && sstop@
expression e, wreg.e1;
position wreg.p;
@@

+ watchdog_stop_on_reboot(e1);
  e = watchdog_register_device@p(e1);

@wreg2 depends on probe@
expression e, e1;
position p;
@@

e = devm_watchdog_register_device@p(..., e1);

@prb2 depends on probe && shutdown && sstop@
expression e, wreg2.e1;
position wreg2.p;
@@

+ watchdog_stop_on_reboot(e1);
  e = devm_watchdog_register_device@p(..., e1);

@srem depends on prb || prb2@
identifier shutdown.shutdownfn;
@@

- shutdownfn(...) {
- ...
- }

@depends on srem@
identifier probe.p, shutdown.shutdownfn;
@@

struct platform_driver p = {
- .shutdown = shutdownfn,
};

@rshut depends on srem@
identifier pdev, remove.removefn, shutdown.shutdownfn, stop.stopfn;
@@

removefn(struct platform_device *pdev)
{
  <...
- shutdownfn(pdev);
+ stopfn(platform_get_drvdata(pdev));
  ...>
}

@depends on rshut@
type T;
identifier pdev, x;
identifier remove.removefn, stop.stopfn;
@@

removefn(struct platform_device *pdev)
{
  ...
  T x = platform_get_drvdata(pdev);
  <...
- stopfn(platform_get_drvdata(pdev));
+ stopfn(x);
  ...>
}

@script:python depends on prb || prb2@
p << probe.pos;
@@

print >> f, "%s:shutdown1:%s" % (p[0].file, p[0].line)
