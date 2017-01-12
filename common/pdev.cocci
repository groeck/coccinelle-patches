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

@e depends on probe@
identifier initfn;
identifier d;
identifier pdev;
type ptype.T;
@@

initfn(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
  ...
}

@prb@
identifier e.d;
identifier initfn;
identifier e.pdev;
position p;
type ptype.T;
@@

initfn@p(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
<+...
- &pdev->dev
+ d
...+> }

// Make sure that a variable named 'dev' does not already exist.

@script:python expected@
dev;
@@
coccinelle.dev = 'dev'

@have_dev depends on !prb@
identifier initfn != e.initfn;
identifier expected.dev;
position p;
@@
  initfn@p(...)
  {
  ... when any
  dev
  ... when any
  }

// Only replace &pdev->dev if it is used at least twice
// and if no variable with the same name exists.

@count depends on !prb@
identifier initfn;
identifier pdev;
type ptype.T;
position p != have_dev.p;
@@

  initfn@p(T *pdev, ...) {
  ... when any
  &pdev->dev
  <+...
  &pdev->dev
  ...+>
  }

@new@
identifier count.initfn;
identifier count.pdev;
type ptype.T;
position p;
@@

  initfn@p(T *pdev, ...) {
+ struct device *dev = &pdev->dev;
<+...
- &pdev->dev
+ dev
...+> }

@script:python@
p << prb.p;
@@

print >> f, "%s:pdev1:%s" % (p[0].file, p[0].line)

@script:python@
p << new.p;
@@

print >> f, "%s:pdev2:%s" % (p[0].file, p[0].line)
