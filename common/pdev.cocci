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

// Get type of device.
// Using it ensures that we don't touch any other data structure
// which might have a '->dev' object.

@ptype depends on probe@
type T;
identifier probe.probefn;
identifier pdev;
@@
probefn(T *pdev, ...) { ... }

@e depends on probe exists@
identifier initfn;
identifier d;
identifier pdev;
type ptype.T;
position p;
@@

initfn@p(T *pdev, ...) {
  <+...
  struct device *d = &pdev->dev;
  ...+>
}

// Do some reference counting. this is needed because otherwise
// it is difficult to determine if the rule was applied or not.
// Assume that we need to apply the rule if the dev variable exists
// and if pdev->dev is dereferenced at least twice.

@countprb depends on e exists@
identifier initfn;
identifier pdev;
type ptype.T;
position p;
position p1;
identifier i;
identifier d;
@@

initfn@p(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
  <...
(
  &pdev@p1->dev
|
  pdev@p1->dev.i
)
  ...>
}

@prb depends on countprb@
identifier e.d;
identifier initfn;
identifier e.pdev;
position e.p;
type ptype.T;
identifier i;
position p1;
@@

initfn@p(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
<...
(
- &pdev@p1->dev
+ d
|
- pdev@p1->dev.i
+ dev->i
)
...> }

// logging and formatting cleanup

@script:python depends on prb@
p << e.p;
p1 << prb.p1;
@@

print >> f, "%s:pdev1:%s:%d" % (p[0].file, p[0].line, len(p1))

@depends on prb@
identifier e.d;
identifier fn != dev_name;
expression list es;
identifier prb.initfn;
@@

  initfn(...) {
  <...
- fn(d, es)
+ fn(d, es)
  ...>
  }
