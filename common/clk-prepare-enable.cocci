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
|
  struct i2c_driver p = {
    .probe = probefn,
  };
|
  struct spi_driver p = {
    .probe = probefn,
  };
)

@remove@
identifier probe.p, removefn;
@@
  struct
(
  platform_driver
|
  i2c_driver
|
  spi_driver
)
  p = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };

// Get type of device.
// Using it ensures that we don't touch any other data structure
// which might have a '->dev' object.

@ptype depends on probe@
type T;
identifier probe.probefn;
identifier pdev;
@@
probefn(T pdev, ...) { ... }

@script:python fname@
func << probe.probefn;
clkfunc;
@@

coccinelle.clkfunc = '_'.join([func.split('_')[0], 'clk_disable_unprepare']);

@check depends on probe@
identifier initfn, pdev;
position p;
type ptype.T;
@@
initfn(T pdev, ...)
{
<... when any
  clk_prepare_enable@p(...)
...>
}

@prb depends on probe@
identifier check.pdev;
expression e1;
position check.p;
identifier fname.clkfunc;
@@

- clk_prepare_enable@p(e1)
+ devm_add_action_or_reset(&pdev->dev, clkfunc, e1)
  ... when any
?-clk_disable_unprepare(e1);

@devm depends on prb@
identifier probe.probefn;
identifier fname.clkfunc;
@@
+ static void clkfunc(void *data) { clk_disable_unprepare(data); }
  probefn(...) { ... }

@rem depends on prb@
identifier remove.removefn;
expression prb.e1;
@@

removefn(...)
{
  <...
- clk_disable_unprepare(e1);
  ...>
}

@a depends on prb@
expression prb.e1, e2;
@@
e2 = e1;

@rem2 depends on a@
identifier remove.removefn;
expression a.e2;
@@
removefn(...)
{
  <...
- clk_disable_unprepare(e2);
  ...>
}

@script:python depends on prb@
p << check.p;
@@

print >> f, "%s:clk1:%s" % (p[0].file, p[0].line)
