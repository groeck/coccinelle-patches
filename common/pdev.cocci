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
  ...
  struct device *d = &pdev->dev;
  ... when any
}

// Use existing 'struct device *' variable for transformations if available

@prb@
identifier e.d;
identifier initfn;
identifier e.pdev;
position e.p;
type ptype.T;
@@

initfn@p(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
<+...
- &pdev->dev
+ d
...+> }

// Otherwise make sure that a variable named 'dev' does not already exist.

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

// Idea is to only replace &pdev->dev if it is used at least twice
// and if no variable with the same name exists. The rule below doesn't
// seem to work, though.
// Q: How do we determine that &pdev->dev exists at least twice ?

@count exists@
identifier initfn;
identifier pdev;
type ptype.T;
position p;
@@

initfn@p(T *pdev, ...) {
  ...
  &pdev->dev
  ... when any
  &pdev->dev
  ... when any
}

@new depends on probe && !have_dev && !e && count@
identifier initfn;
identifier pdev;
type ptype.T;
position count.p;
@@

  initfn@p(T *pdev, ...) {
+ struct device *dev = &pdev->dev;
  <...
- &pdev->dev
+ dev
  ...>
}

@script:python depends on prb@
p << e.p;
@@

print >> f, "%s:pdev1:%s" % (p[0].file, p[0].line)

@script:python depends on new@
p << count.p;
@@

print >> f, "%s:pdev2:%s" % (p[0].file, p[0].line)
