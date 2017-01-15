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
probefn(T *pdev, ...) { ... }

@r depends on probe@
identifier initfn;
expression irq;
position p;
@@
initfn(...)
{
<+...
(
request_irq@p(irq, ...)
|
request_threaded_irq@p(irq, ...)
|
request_any_context_irq@p(irq, ...)
)
...+>
}

@prb@
identifier r.initfn, pdev;
expression list es;
position r.p;
expression irq;
type ptype.T;
@@

initfn(T *pdev, ...)
{
  <+...
(
- request_irq@p(irq, es)
+ devm_request_irq(&pdev->dev, irq, es)
|
- request_threaded_irq@p(irq, es)
+ devm_request_threaded_irq(&pdev->dev, irq, es)
|
- request_any_context_irq(irq, es)
+ devm_request_any_context_irq(&pdev->dev, irq, es)
)
  ...
  when any
?-free_irq(irq, ...);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.irq;
@@

removefn(...)
{
  <...
- free_irq(irq, ...);
  ...>
}

@a depends on prb@
expression prb.irq, irq2;
@@
irq2 = irq;

@rem2 depends on a@
identifier remove.removefn;
expression a.irq2;
@@
removefn(...)
{
  <+...
- free_irq(irq2, ...);
  ...+>
}

@ia depends on prb@
expression prb.irq;
expression e;
@@
irq = e;

@remi depends on prb@
expression ia.e;
@@
  <+...
- free_irq(e,...);
  ...+>

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:irq1:%s" % (p[0].file, p[0].line)
