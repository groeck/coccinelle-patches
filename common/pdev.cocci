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

@countprb depends on e@
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

@script:python pcountprb@
p << countprb.p1;
@@

if (len(p) < 1):
    cocci.include_match(False)

@script:python depends on countprb && pcountprb@
p << countprb.p1;
@@

print >> f, "%s:pdev1:%s:%d" % (p[0].file, p[0].line, len(p))

// Use existing 'struct device *' variable for transformations if available

@prb depends on countprb@
identifier e.d;
identifier initfn;
identifier e.pdev;
position e.p;
type ptype.T;
identifier i;
@@

initfn@p(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
<...
(
- &pdev->dev
+ d
|
- pdev->dev.i
+ dev->i
)
...> }

// formatting cleanup

@depends on prb@
identifier e.d;
identifier fn != dev_name;
expression list es;
@@

- fn(d, es)
+ fn(d, es)

// Otherwise make sure that a variable named 'dev' does not already exist.

@script:python expected@
dev;
@@
coccinelle.dev = 'dev'

@have_dev depends on probe exists@
identifier initfn != prb.initfn;
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

if (len(p) < 2):
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

// try again, slight variance

@e2 depends on probe exists@
identifier initfn != e.initfn;
identifier d;
identifier pdev;
type ptype.T;
position p;
@@

initfn@p(...) {
  ...
  T *pdev;
  <+...
  struct device *d = &pdev->dev;
  ...+>
}

@have_dev2 depends on probe exists@
identifier initfn != {prb.initfn, have_dev.initfn, e.initfn};
identifier expected.dev;
identifier pdev;
type ptype.T;
position p;
@@

  initfn@p(...)
  {
  ...
  T *pdev;
  ...
  dev
  ... when any
  }

@count2@
identifier initfn != {have_dev2.initfn, have_dev.initfn, prb.initfn, e.initfn, e2.initfn};
identifier pdev;
type ptype.T;
position p;
position p1;
expression E;
@@

initfn@p(...) {
  ...
  T *pdev = E;
  <...
  &pdev@p1->dev
  ...>
}

@script:python pcount2 depends on count2@
p << count2.p1;
@@

if (len(p) < 2):
    cocci.include_match(False)

@new2 depends on probe && !have_dev2 && pcount2@
identifier initfn != {e.initfn, e2.initfn};
identifier pdev;
type ptype.T;
position count2.p;
identifier i;
@@

  initfn@p(...) {
  ...
  T *pdev;
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

@script:python depends on new2@
p << count2.p;
@@

print >> f, "%s:pdev2:%s" % (p[0].file, p[0].line)

// final formatting cleanup

@depends on new || new2@
identifier fn != dev_name;
expression list es;
identifier expected.dev;
@@

- fn(dev, es)
+ fn(dev, es)
