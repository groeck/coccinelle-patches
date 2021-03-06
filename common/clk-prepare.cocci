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

@ptype depends on probe@
type T;
identifier probe.probefn;
identifier pdev;
@@
probefn(T pdev, ...) { ... }

@check depends on probe@
identifier initfn, pdev;
position p;
type ptype.T;
@@
initfn(T pdev, ...)
{
<... when any
  clk_prepare@p(...)
...>
}

@prb depends on probe@
identifier check.pdev;
expression e1;
position check.p;
@@

- clk_prepare@p(e1)
+ devm_clk_prepare(&pdev->dev, e1)
  ... when any
?-clk_unprepare(e1);

@rem depends on prb@
identifier remove.removefn;
expression prb.e1;
@@

removefn(...)
{
  <...
- clk_unprepare(e1);
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
- clk_unprepare(e2);
  ...>
}

@script:python depends on prb@
p << check.p;
@@

print >> f, "%s:clkprep1:%s" % (p[0].file, p[0].line)
