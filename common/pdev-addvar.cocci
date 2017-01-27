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

// Make sure that a variable named 'dev' does not already exist.

@script:python expected@
dev;
@@
coccinelle.dev = 'dev'

@have_dev depends on probe exists@
identifier initfn;
identifier expected.dev;
identifier pdev;
type ptype.T;
position p;
@@

  initfn@p(T *pdev, ...)
  {
  ...
  dev
  ... when any
  }

@count@
identifier initfn != have_dev.initfn;
identifier pdev;
type ptype.T;
position p;
position p1;
@@

initfn@p(T *pdev, ...) {
  <...
  &pdev@p1->dev
  ...>
}

@script:python pcount depends on count@
p << count.p1;
@@

if (len(p) < 3):
    cocci.include_match(False)

@new depends on probe && !have_dev && pcount@
identifier initfn != e.initfn;
identifier pdev;
type ptype.T;
position count.p;
identifier i;
@@

  initfn@p(T *pdev, ...) {
+ struct device *dev = &pdev->dev;
  <...
(
- &pdev->dev
+ dev
|
- pdev->dev.i
+ dev->i
)
  ...>
}

@script:python depends on new@
p << count.p;
@@

print >> f, "%s:pdev2:%s" % (p[0].file, p[0].line)

// formatting cleanup

@depends on new@
identifier fn != dev_name;
expression list es;
identifier expected.dev;
@@

- fn(dev, es)
+ fn(dev, es)
