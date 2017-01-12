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

@a depends on probe@
identifier initfn, pdev;
expression d, d2;
position p;
type ptype.T;
@@
initfn@p(T *pdev, ...) {
  <+...
- d = input_allocate_device()
+ d = devm_input_allocate_device(&pdev->dev)
  ... when any
  d2 = d;
  ... when any
?-input_unregister_device(\(d\|d2\));
  ...
?-\(d\|d2\) = NULL;
  ... when any
?-input_free_device(\(d\|d2\));
  ...+>
}

@a2 depends on probe && !a@
identifier initfn, pdev;
expression d;
position p;
type ptype.T;
@@
initfn@p(T *pdev, ...) {
  <+...
- d = input_allocate_device()
+ d = devm_input_allocate_device(&pdev->dev)
  ... when any
?-input_unregister_device(d);
  ...
?-d = NULL;
  ... when any
?-input_free_device(d);
  ...+>
}

@rema depends on a || a2@
identifier remove.removefn;
@@
removefn(...) {
  <...
- input_unregister_device(...);
  ...>
}

@ap depends on probe@
identifier initfn, pdev;
expression d, d2;
position p;
type ptype.T;
@@
initfn@p(T *pdev, ...) {
  <+...
- d = input_allocate_polled_device()
+ d = devm_input_allocate_polled_device(&pdev->dev)
  ... when any
  d2 = d;
  ... when any
?-input_unregister_polled_device(\(d\|d2\));
  ... when any
?-input_free_polled_device(\(d\|d2\));
  ...+>
}

@ap2 depends on probe@
identifier initfn, pdev;
expression d;
position p;
type ptype.T;
@@
initfn@p(T *pdev, ...) {
  <+...
- d = input_allocate_polled_device()
+ d = devm_input_allocate_polled_device(&pdev->dev)
  ... when any
?-input_unregister_polled_device(d);
  ... when any
?-input_free_polled_device(d);
  ...+>
}

@remap depends on ap || ap2@
identifier remove.removefn;
@@
removefn(...) {
  <...
- input_unregister_polled_device(...);
  ...>
}

@remapf depends on ap || ap2@
identifier remove.removefn;
@@
removefn(...) {
  <...
- input_free_polled_device(...);
  ...>
}

@script:python@
p << a.p;
@@

print >> f, "%s:devm1:%s" % (p[0].file, p[0].line)

@script:python@
p << a2.p;
@@

print >> f, "%s:devm1:%s" % (p[0].file, p[0].line)

@script:python@
p << ap.p;
@@

print >> f, "%s:devm1:%s" % (p[0].file, p[0].line)

@script:python@
p << ap2.p;
@@

print >> f, "%s:devm1:%s" % (p[0].file, p[0].line)
